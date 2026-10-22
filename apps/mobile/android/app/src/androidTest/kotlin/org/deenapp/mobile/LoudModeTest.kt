package org.deenapp.mobile

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import androidx.core.content.ContextCompat
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.JournalState
import org.deenapp.mobile.generated.VolumeChoiceDto
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Loud mode is off by default, only loud mode uses the alarm audio usage, and nothing in the
 * playback path changes a system stream volume without opt-in (spec D7, tasks T108).
 * Written, not run.
 */
@RunWith(AndroidJUnit4::class)
class LoudModeTest {
    private lateinit var context: Context
    private lateinit var audioManager: AudioManager

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        audioManager = context.getSystemService(AudioManager::class.java)
    }

    @After
    fun tearDown() {
        context.stopService(android.content.Intent(context, AzaanPlaybackService::class.java))
    }

    @Test
    fun loudModeIsOffByDefault() {
        assertFalse(PlaybackPolicy.DEFAULT_LOUD_MODE)
    }

    @Test
    fun onlyLoudModeUsesTheAlarmUsage() {
        assertEquals(AudioAttributes.USAGE_NOTIFICATION, PlaybackPolicy.usageFor(false))
        assertEquals(AudioAttributes.USAGE_ALARM, PlaybackPolicy.usageFor(true))
        assertEquals(AudioAttributes.USAGE_NOTIFICATION, PlaybackPolicy.audioAttributes(false).usage)
        assertEquals(AudioAttributes.USAGE_ALARM, PlaybackPolicy.audioAttributes(true).usage)
    }

    @Test
    fun gentleRampMovesOnlyThePlayerVolume() {
        val ramp = TestAlerts.alert("loud:1", 1L, volumeChoice = VolumeChoiceDto.GENTLE_RAMP)
        val keep = TestAlerts.alert("loud:2", 1L, volumeChoice = VolumeChoiceDto.KEEP_CURRENT)
        assertEquals(PlaybackPolicy.RAMP_START_VOLUME, PlaybackPolicy.initialVolume(ramp), 0f)
        assertEquals(1f, PlaybackPolicy.initialVolume(keep), 0f)

        assertEquals(0.2f, PlaybackPolicy.rampVolume(0L), 0.001f)
        assertEquals(1.0f, PlaybackPolicy.rampVolume(PlaybackPolicy.RAMP_DURATION_MS), 0.001f)
        assertEquals(1.0f, PlaybackPolicy.rampVolume(PlaybackPolicy.RAMP_DURATION_MS * 3), 0.001f)
        assertEquals(0.2f, PlaybackPolicy.rampVolume(-5L), 0.001f)
        assertTrue(PlaybackPolicy.rampVolume(2_000L) < PlaybackPolicy.rampVolume(4_000L))
    }

    @Test
    fun runningTheServiceLeavesSystemStreamVolumesUntouched() {
        val streams = listOf(
            AudioManager.STREAM_ALARM,
            AudioManager.STREAM_NOTIFICATION,
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_RING,
        )
        val before = streams.map { audioManager.getStreamVolume(it) }

        val id = TestAlerts.uniqueId("loud-service")
        val alert = TestAlerts.alert(
            id, System.currentTimeMillis(), kind = AlertKind.PRAYER, delivery = DeliveryType.FULL_AZAAN,
            audioRef = "no-such/recording", loudMode = true, volumeChoice = VolumeChoiceDto.GENTLE_RAMP,
        )
        ContextCompat.startForegroundService(context, AlarmReceiver.playbackIntent(context, alert, inexact = false))

        // The recording does not exist, so the service journals failed and stops; by then it has
        // gone through the whole start path (foreground, arbiter, resource lookup).
        val journal = AlertJournal(context)
        assertTrue(
            TestAlerts.waitFor(10_000) { journal.entriesFor(id).any { it.state == JournalState.FAILED } },
        )
        Notifications.cancel(context, id)

        assertEquals(before, streams.map { audioManager.getStreamVolume(it) })
    }
}
