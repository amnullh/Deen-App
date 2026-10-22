package org.deenapp.mobile

/**
 * Source of "now" for native scheduling code, so tests can fix the time. Nothing in this
 * module reads the system clock directly except [SYSTEM].
 */
fun interface Clock {
    fun nowMs(): Long

    companion object {
        val SYSTEM: Clock = Clock { System.currentTimeMillis() }
    }
}
