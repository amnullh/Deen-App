import CoreLocation
import Flutter
import UIKit

/// iOS implementation of the Pigeon `LocationApi` (contract: platform-device.md).
///
/// Foreground, when-in-use location only. No "Always" permission is ever requested, and coordinates are never
/// logged or stored here: they are returned to Dart, which keeps them in the local `Location` row.
///
/// Threading: Pigeon calls the synchronous methods on the main thread and the async ones from a main-actor task,
/// and `CLLocationManager` delivers its delegate callbacks on the thread it was created on (the main thread, since
/// `AppDelegate` creates this object). The async methods are marked `@MainActor` so a Swift concurrency hop can
/// never move `CLLocationManager` calls to a background thread.
final class LocationApiImpl: NSObject, LocationApi, CLLocationManagerDelegate {
  private let manager = CLLocationManager()

  /// Callers of `requestWhenInUse()` waiting for the user to answer the system prompt.
  private var permissionWaiters: [CheckedContinuation<LocationPermission, Never>] = []

  /// Callers of `getCurrentFix` waiting for the one in-flight request. Concurrent calls share one request.
  private var fixWaiters: [CheckedContinuation<LocationResult, Never>] = []
  private var fixTimeout: DispatchWorkItem?

  override init() {
    super.init()
    manager.delegate = self
  }

  // MARK: LocationApi

  func getPermission() throws -> LocationPermission {
    return currentPermission()
  }

  @MainActor
  func requestWhenInUse() async -> LocationPermission {
    guard manager.authorizationStatus == .notDetermined else {
      return currentPermission()
    }
    return await withCheckedContinuation { continuation in
      permissionWaiters.append(continuation)
      // Only the first caller shows the prompt; the system ignores repeated requests anyway.
      if permissionWaiters.count == 1 {
        manager.requestWhenInUseAuthorization()
      }
    }
  }

  @MainActor
  func getCurrentFix(timeoutSeconds: Int64) async -> LocationResult {
    switch currentPermission() {
    case .whenInUse, .approximateOnly:
      break
    case .notDetermined, .denied, .restricted:
      return LocationResult(fix: nil, errorCode: "permission_denied")
    }
    return await withCheckedContinuation { continuation in
      fixWaiters.append(continuation)
      guard fixWaiters.count == 1 else { return }
      // Prayer times need a city-level position, not a precise one: a coarse request answers faster and uses
      // less battery. Reduced-accuracy users cannot get better than this anyway.
      manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      manager.requestLocation()
      let timeout = DispatchWorkItem { [weak self] in
        self?.finishFix(failure: "timeout")
      }
      fixTimeout = timeout
      let seconds = max(1, timeoutSeconds)
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(min(seconds, 600))), execute: timeout)
    }
  }

  func openLocationSettings() throws {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  // MARK: CLLocationManagerDelegate

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // Also called when the delegate is set; wait until the user has actually answered.
    guard manager.authorizationStatus != .notDetermined else { return }
    let permission = currentPermission()
    let waiters = permissionWaiters
    permissionWaiters = []
    for waiter in waiters {
      waiter.resume(returning: permission)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    finishFix(with: location)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError, clError.code == .denied {
      finishFix(failure: "permission_denied")
    } else {
      finishFix(failure: "unavailable")
    }
  }

  // MARK: Helpers

  /// Maps the system state. Never prompts. "Always" cannot be requested by this app but may have been granted
  /// by an earlier build or a settings change; it is treated as when-in-use.
  private func currentPermission() -> LocationPermission {
    switch manager.authorizationStatus {
    case .notDetermined:
      return .notDetermined
    case .restricted:
      return .restricted
    case .denied:
      return .denied
    case .authorizedWhenInUse, .authorizedAlways:
      return manager.accuracyAuthorization == .reducedAccuracy ? .approximateOnly : .whenInUse
    @unknown default:
      return .denied
    }
  }

  private func finishFix(with location: CLLocation) {
    let fix = LocationFix(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      accuracyMeters: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil,
      timestampEpochMs: Int64(location.timestamp.timeIntervalSince1970 * 1000),
      approximate: manager.accuracyAuthorization == .reducedAccuracy
    )
    resolveFix(LocationResult(fix: fix, errorCode: nil))
  }

  /// Ends the in-flight request with the last known location when there is one (the contract's fallback),
  /// otherwise with the given error code.
  private func finishFix(failure code: String) {
    if let lastKnown = manager.location {
      finishFix(with: lastKnown)
    } else {
      resolveFix(LocationResult(fix: nil, errorCode: code))
    }
  }

  private func resolveFix(_ result: LocationResult) {
    fixTimeout?.cancel()
    fixTimeout = nil
    manager.stopUpdatingLocation()
    let waiters = fixWaiters
    fixWaiters = []
    for waiter in waiters {
      waiter.resume(returning: result)
    }
  }
}
