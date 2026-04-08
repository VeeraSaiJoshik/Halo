import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first {
      let visualEffect = NSVisualEffectView()
      visualEffect.blendingMode = .behindWindow
      visualEffect.state = .active
      visualEffect.material = .hudWindow // or .sidebar, .menu, .sheet, etc.
      visualEffect.frame = window.contentView!.bounds
      visualEffect.autoresizingMask = [.width, .height]
      
      window.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
    }

    super.applicationDidFinishLaunching(notification)
  }
}
