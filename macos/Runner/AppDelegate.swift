import Cocoa
import FlutterMacOS
import Sparkle

@main
class AppDelegate: FlutterAppDelegate {
  @IBOutlet private var updateController: SPUStandardUpdaterController!

  @IBAction private func toggleUpdateChecks(_ sender: NSMenuItem) {
    updateController.updater.automaticallyChecksForUpdates.toggle()
  }

  @objc func validateMenuItem(_ item: NSMenuItem) -> Bool {
    if item.action == #selector(toggleUpdateChecks(_:)) {
      item.state = updateController.updater.automaticallyChecksForUpdates ? .on : .off
    }
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    (mainFlutterWindow as? MainFlutterWindow)?.reveal()
    return true
  }
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
