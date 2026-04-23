import Cocoa
import FlutterMacOS
import WebKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    flutterViewController.backgroundColor = .clear
    self.backgroundColor = NSColor.clear

    let channel = FlutterMethodChannel(
      name: "com.example.frontend/cookies",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      if call.method == "deleteCookiesForDomain" {
        guard let args = call.arguments as? [String: Any],
              let domain = args["domain"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing domain", details: nil))
          return
        }

        let store = WKWebsiteDataStore.default()
        store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
          let matching = records.filter { $0.displayName.contains(domain) }
          print("Deleting \(matching.count) records for domain: \(domain)")
          store.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            for: matching
          ) {
            result(matching.count)
          }
        }
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}