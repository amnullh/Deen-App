package org.deenapp.mobile

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import org.deenapp.mobile.generated.LocationApi
import org.deenapp.mobile.generated.LocationFix
import org.deenapp.mobile.generated.LocationPermission
import org.deenapp.mobile.generated.LocationResult
import kotlin.coroutines.resume

/**
 * Android [LocationApi] on the platform `LocationManager`. No Google Play Services.
 *
 * Foreground use only; no background location permission is requested. Coordinates are never
 * logged. Android cannot tell "never asked" from "denied", so the app remembers that it has
 * asked once ([KEY_ASKED]) to report `notDetermined` before the first prompt.
 *
 * [activityProvider] supplies the foreground activity for the permission prompt; the result
 * arrives through [onRequestPermissionsResult], which `MainActivity` forwards.
 */
class LocationApiImpl(
    private val context: Context,
    private val activityProvider: () -> Activity?,
) : LocationApi {

    private var pendingPrompt: CancellableContinuation<LocationPermission>? = null

    override fun getPermission(): LocationPermission = when {
        isGranted(Manifest.permission.ACCESS_FINE_LOCATION) -> LocationPermission.WHEN_IN_USE
        isGranted(Manifest.permission.ACCESS_COARSE_LOCATION) -> LocationPermission.APPROXIMATE_ONLY
        wasAsked() -> LocationPermission.DENIED
        else -> LocationPermission.NOT_DETERMINED
    }

    override suspend fun requestWhenInUse(): LocationPermission {
        val current = getPermission()
        if (current == LocationPermission.WHEN_IN_USE) return current
        val activity = activityProvider() ?: return current
        return suspendCancellableCoroutine { continuation ->
            // A second prompt while one is open resolves the first with the current state.
            pendingPrompt?.resume(getPermission())
            pendingPrompt = continuation
            continuation.invokeOnCancellation { pendingPrompt = null }
            activity.requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                REQUEST_CODE,
            )
        }
    }

    /** Forwarded from `Activity.onRequestPermissionsResult`. Returns true when it was ours. */
    fun onRequestPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        markAsked()
        val continuation = pendingPrompt
        pendingPrompt = null
        continuation?.resume(getPermission())
        return true
    }

    override suspend fun getCurrentFix(timeoutSeconds: Long): LocationResult {
        val permission = getPermission()
        if (permission != LocationPermission.WHEN_IN_USE &&
            permission != LocationPermission.APPROXIMATE_ONLY
        ) {
            return LocationResult(errorCode = "permission_denied")
        }
        return try {
            findFix(timeoutSeconds)
        } catch (e: CancellationException) {
            throw e
        } catch (e: SecurityException) {
            LocationResult(errorCode = "permission_denied")
        } catch (e: RuntimeException) {
            Log.w(TAG, "location failed: ${e.javaClass.simpleName}")
            LocationResult(errorCode = "unavailable")
        }
    }

    /** A fresh fix within the timeout, else the newest last-known location, else an error code. */
    private suspend fun findFix(timeoutSeconds: Long): LocationResult {
        val manager = context.getSystemService(LocationManager::class.java)
        val providers = enabledProviders(manager)
        val fresh = if (providers.isEmpty()) {
            null
        } else {
            withTimeoutOrNull(timeoutSeconds.coerceAtLeast(1L) * 1000L) {
                awaitSingleFix(manager, providers)
            }
        }
        val location = fresh ?: lastKnown(manager)
        return when {
            location != null -> LocationResult(fix = toFix(location))
            providers.isEmpty() -> LocationResult(errorCode = "unavailable")
            else -> LocationResult(errorCode = "timeout")
        }
    }

    override fun openLocationSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (e: RuntimeException) {
            Log.w(TAG, "could not open app settings")
        }
    }

    /** Providers that are on and allowed by the granted permission, best first. */
    private fun enabledProviders(manager: LocationManager): List<String> {
        val fine = isGranted(Manifest.permission.ACCESS_FINE_LOCATION)
        val candidates = ArrayList<String>()
        // The platform "fused" provider (Android 12+) needs no Play Services.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            candidates.add(LocationManager.FUSED_PROVIDER)
        }
        candidates.add(LocationManager.NETWORK_PROVIDER)
        if (fine) candidates.add(LocationManager.GPS_PROVIDER)
        return candidates.filter { manager.allProviders.contains(it) && manager.isProviderEnabled(it) }
    }

    /**
     * Waits for the first location from any of [providers]. Cancelling (the timeout) removes the
     * listener, so nothing keeps the radios on.
     */
    private suspend fun awaitSingleFix(manager: LocationManager, providers: List<String>): Location =
        suspendCancellableCoroutine { continuation ->
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    manager.removeUpdates(this)
                    if (continuation.isActive) continuation.resume(location)
                }

                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

                override fun onProviderEnabled(provider: String) {}

                override fun onProviderDisabled(provider: String) {}
            }
            continuation.invokeOnCancellation { manager.removeUpdates(listener) }
            for (provider in providers) {
                manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
            }
        }

    /** The newest last-known location across providers, or null. */
    private fun lastKnown(manager: LocationManager): Location? {
        var best: Location? = null
        for (provider in manager.allProviders) {
            val candidate = try {
                manager.getLastKnownLocation(provider)
            } catch (e: SecurityException) {
                null
            } catch (e: IllegalArgumentException) {
                null
            }
            if (candidate != null && (best == null || candidate.time > best.time)) best = candidate
        }
        return best
    }

    private fun toFix(location: Location) = LocationFix(
        latitude = location.latitude,
        longitude = location.longitude,
        accuracyMeters = if (location.hasAccuracy()) location.accuracy.toDouble() else null,
        timestampEpochMs = location.time,
        approximate = !isGranted(Manifest.permission.ACCESS_FINE_LOCATION),
    )

    private fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    private fun wasAsked(): Boolean = prefs().getBoolean(KEY_ASKED, false)

    private fun markAsked() = prefs().edit().putBoolean(KEY_ASKED, true).apply()

    private fun prefs() = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private companion object {
        const val TAG = "LocationApiImpl"
        const val REQUEST_CODE = 4301
        const val PREFS = "location_api"
        const val KEY_ASKED = "asked"
    }
}
