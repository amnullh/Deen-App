import BackgroundTasks
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
  static let refreshTaskIdentifier = "org.deenapp.mobile.refresh"

  /// Tells the Dart side (written separately) that the system gave us a short refresh window.
  static let refreshChannelName = "org.deenapp.mobile/background_refresh"
  static let refreshMethod = "onRefreshWindow"

  /// The system decides when to run the task; this is only the earliest time we ask for.
  private static let refreshEarliestDelay: TimeInterval = 6 * 60 * 60

  private var refreshChannel: FlutterMethodChannel?
  private var locationApi: LocationApiImpl?
  private var headingApi: HeadingApiImpl?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // A background task handler must be registered before this method returns.
    registerRefreshTask()
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.scheduleRefresh()
    }
    // Required by flutter_local_notifications so taps and foreground presentation reach the plugin.
    // FlutterAppDelegate conforms to the delegate protocol and forwards to registered plugins.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeenDeviceChannels") {
      registerDeviceChannels(messenger: registrar.messenger())
    }
  }

  // MARK: Pigeon handlers and channels

  /// `VolumeKeyApi` is Android only and is deliberately not registered here.
  private func registerDeviceChannels(messenger: FlutterBinaryMessenger) {
    let location = LocationApiImpl()
    LocationApiSetup.setUp(binaryMessenger: messenger, api: location)
    locationApi = location

    let streamHandler = HeadingStreamHandler()
    let heading = HeadingApiImpl(streamHandler: streamHandler)
    HeadingApiSetup.setUp(binaryMessenger: messenger, api: heading)
    StreamHeadingsStreamHandler.register(with: messenger, streamHandler: streamHandler)
    headingApi = heading

    refreshChannel = FlutterMethodChannel(
      name: Self.refreshChannelName,
      binaryMessenger: messenger
    )
  }

  // MARK: Best-effort background refresh

  private func registerRefreshTask() {
    // A false result means the identifier is missing from Info.plist; there is nothing to recover at runtime.
    _ = BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.refreshTaskIdentifier,
      using: nil
    ) { [weak self] task in
      DispatchQueue.main.async {
        guard let self = self, let refreshTask = task as? BGAppRefreshTask else {
          task.setTaskCompleted(success: false)
          return
        }
        self.handleRefresh(refreshTask)
      }
    }
  }

  /// Asks for the next refresh window. Failure is normal (Background App Refresh turned off, simulator) and the
  /// schedule is rebuilt on every foreground anyway, so the error is not surfaced.
  private func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: Self.refreshEarliestDelay)
    try? BGTaskScheduler.shared.submit(request)
  }

  private func handleRefresh(_ task: BGAppRefreshTask) {
    // Only one request can be pending, so re-submit first: a crash below must not end the chain.
    scheduleRefresh()

    let completion = RefreshCompletion(task: task)
    task.expirationHandler = {
      DispatchQueue.main.async { completion.finish(success: false) }
    }
    guard let channel = refreshChannel else {
      // The Flutter engine did not start for this launch, so nobody can rebuild the schedule.
      completion.finish(success: false)
      return
    }
    channel.invokeMethod(Self.refreshMethod, arguments: nil) { result in
      let handled = !(result is FlutterError) && (result as AnyObject?) !== FlutterMethodNotImplemented
      completion.finish(success: handled)
    }
  }
}

/// Completes a `BGTask` exactly once, whichever of the Dart reply and the expiration comes first.
/// Used on the main thread only.
private final class RefreshCompletion {
  private let task: BGTask
  private var finished = false

  init(task: BGTask) {
    self.task = task
  }

  func finish(success: Bool) {
    guard !finished else { return }
    finished = true
    task.setTaskCompleted(success: success)
  }
}
