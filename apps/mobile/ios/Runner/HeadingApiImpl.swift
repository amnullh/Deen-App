import CoreLocation
import Flutter
import UIKit

/// Delivers heading samples to the Dart event channel `HeadingEvents.streamHeadings`.
///
/// The Pigeon-generated base class only tracks whether Dart is listening; `HeadingApiImpl` pushes samples
/// through `sink` while it is set.
final class HeadingStreamHandler: StreamHeadingsStreamHandler {
  private(set) var sink: PigeonEventSink<HeadingSample>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<HeadingSample>) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }
}

/// iOS implementation of the Pigeon `HeadingApi` (contract: platform-device.md).
///
/// Uses `CLHeading`, which the system already fuses from magnetometer, gyroscope and accelerometer, so the
/// device can be flat or upright. The sensors run only between `start` and `stop`; the Dart side stops them when
/// the Qibla screen is not visible.
final class HeadingApiImpl: NSObject, HeadingApi, CLLocationManagerDelegate {
  /// Heading accuracy bands in degrees (`CLHeading.headingAccuracy`: smaller is better, negative is invalid).
  /// Proposed values, to be tuned on devices.
  private enum Band {
    static let high = 15.0
    static let medium = 30.0
    static let low = 50.0
  }

  /// Samples go to Dart about ten times per second whatever rate the system delivers headings at.
  private static let emitInterval: TimeInterval = 0.1

  /// Time constant of the low-pass filter. Short enough to follow a deliberate turn, long enough to hide jitter.
  private static let smoothingTimeConstant: TimeInterval = 0.15

  /// A change larger than this between two system updates is a jump, which points to a nearby magnet or metal.
  private static let jumpDegrees = 90.0
  private static let jumpHoldSeconds: TimeInterval = 1.0

  let streamHandler: HeadingStreamHandler
  private let manager = CLLocationManager()

  private var started = false
  private var timer: Timer?
  private var orientationObserver: NSObjectProtocol?

  // Latest state, written by the delegate and read by the timer (both on the main thread).
  private var smoothedX = 0.0
  private var smoothedY = 0.0
  private var hasHeading = false
  private var lastUpdateUptime: TimeInterval = 0
  private var lastRawDegrees = 0.0
  private var lastJumpUptime: TimeInterval = -.infinity
  private var latest: HeadingSample?
  private var latestEmitted = true
  private var calibrationWanted = false

  init(streamHandler: HeadingStreamHandler) {
    self.streamHandler = streamHandler
    super.init()
    manager.delegate = self
  }

  // MARK: HeadingApi

  func isAvailable() throws -> Bool {
    return CLLocationManager.headingAvailable()
  }

  func start(latitude: Double, longitude: Double) throws {
    guard CLLocationManager.headingAvailable() else {
      throw PigeonError(code: "unavailable", message: "No compass on this device.", details: nil)
    }
    stopSensors()
    resetFilter()
    started = true

    manager.headingFilter = kCLHeadingFilterNone
    manager.headingOrientation = Self.headingOrientation(for: UIDevice.current.orientation)
    observeOrientation()
    manager.startUpdatingHeading()

    // `trueHeading` is only valid while the system also has a location, so run a coarse, short-lived location
    // service next to the heading service. It is skipped when location is not allowed: the samples are then
    // magnetic and `isTrueNorth` is false. The coordinates passed in only tell us the app knows where it is.
    if latitude.isFinite, longitude.isFinite, Self.locationAllowed(manager) {
      manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
      manager.distanceFilter = 10_000
      manager.startUpdatingLocation()
    }

    let timer = Timer(timeInterval: Self.emitInterval, repeats: true) { [weak self] _ in
      self?.emitLatest()
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stop() throws {
    stopSensors()
  }

  // MARK: CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    guard started else { return }
    let now = ProcessInfo.processInfo.systemUptime
    let invalid = newHeading.headingAccuracy < 0
    let useTrue = newHeading.trueHeading >= 0
    let raw = useTrue ? newHeading.trueHeading : newHeading.magneticHeading
    guard raw >= 0 else {
      // No usable direction at all: report it so the screen can tell the user to calibrate.
      publish(degrees: currentDegrees(), trueNorth: false, accuracy: .unreliable, invalid: true)
      return
    }

    if hasHeading, Self.angleDifference(raw, lastRawDegrees) > Self.jumpDegrees {
      lastJumpUptime = now
    }
    lastRawDegrees = raw
    smooth(degrees: raw, now: now)

    let accuracy = Self.accuracy(forHeadingAccuracy: newHeading.headingAccuracy)
    publish(degrees: currentDegrees(), trueNorth: useTrue, accuracy: accuracy, invalid: invalid)
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    // The system calibration prompt appears only when the app has decided the compass needs calibration.
    return calibrationWanted
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Required only to keep `trueHeading` valid. The coordinates are not read or stored.
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // A failed location only means the samples stay magnetic; a failed heading is reported by its accuracy.
  }

  // MARK: Filtering

  private func resetFilter() {
    smoothedX = 0
    smoothedY = 0
    hasHeading = false
    lastUpdateUptime = 0
    lastJumpUptime = -.infinity
    latest = nil
    latestEmitted = true
    calibrationWanted = false
  }

  /// Low-pass filter on the unit vector, so 359 and 1 average to 0 and not to 180.
  private func smooth(degrees: Double, now: TimeInterval) {
    let radians = degrees * .pi / 180
    let x = cos(radians)
    let y = sin(radians)
    if !hasHeading {
      smoothedX = x
      smoothedY = y
      hasHeading = true
    } else {
      let dt = max(0, now - lastUpdateUptime)
      let alpha = 1 - exp(-dt / Self.smoothingTimeConstant)
      smoothedX += alpha * (x - smoothedX)
      smoothedY += alpha * (y - smoothedY)
    }
    lastUpdateUptime = now
  }

  private func currentDegrees() -> Double {
    guard hasHeading else { return 0 }
    var degrees = atan2(smoothedY, smoothedX) * 180 / .pi
    if degrees < 0 { degrees += 360 }
    if degrees >= 360 { degrees -= 360 }
    return degrees
  }

  private func publish(degrees: Double, trueNorth: Bool, accuracy: HeadingAccuracy, invalid: Bool) {
    let now = ProcessInfo.processInfo.systemUptime
    let jumped = now - lastJumpUptime < Self.jumpHoldSeconds
    let needsCalibration = accuracy == .low || accuracy == .unreliable
    calibrationWanted = needsCalibration
    latest = HeadingSample(
      headingDegrees: degrees,
      isTrueNorth: trueNorth,
      accuracy: accuracy,
      fieldStrengthMicroTesla: nil,
      interferenceSuspected: invalid || jumped,
      needsCalibration: needsCalibration
    )
    latestEmitted = false
  }

  private func emitLatest() {
    guard started, !latestEmitted, let sample = latest, let sink = streamHandler.sink else { return }
    latestEmitted = true
    sink.success(sample)
  }

  // MARK: Lifecycle and mapping

  private func stopSensors() {
    timer?.invalidate()
    timer = nil
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
    if let observer = orientationObserver {
      NotificationCenter.default.removeObserver(observer)
      orientationObserver = nil
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    started = false
  }

  private func observeOrientation() {
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    orientationObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self = self else { return }
      self.manager.headingOrientation = Self.headingOrientation(for: UIDevice.current.orientation)
    }
  }

  private static func locationAllowed(_ manager: CLLocationManager) -> Bool {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      return true
    default:
      return false
    }
  }

  /// Face up, face down and unknown carry no usable direction, so they keep the portrait reference.
  private static func headingOrientation(for orientation: UIDeviceOrientation) -> CLDeviceOrientation {
    switch orientation {
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    default:
      return .portrait
    }
  }

  private static func accuracy(forHeadingAccuracy degrees: CLLocationDirection) -> HeadingAccuracy {
    if degrees < 0 { return .unreliable }
    if degrees <= Band.high { return .high }
    if degrees <= Band.medium { return .medium }
    if degrees <= Band.low { return .low }
    return .unreliable
  }

  /// Smallest angle between two compass bearings, 0...180.
  private static func angleDifference(_ a: Double, _ b: Double) -> Double {
    let difference = abs(a - b).truncatingRemainder(dividingBy: 360)
    return difference > 180 ? 360 - difference : difference
  }
}
