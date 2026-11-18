import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  private var statusItem: NSStatusItem?
  private var bridge: FlutterMethodChannel?
  private let credential: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "dev.fdmedia.openticklyApp.session",
    kSecAttrAccount as String: "connection"
  ]

  override func awakeFromNib() {
    super.awakeFromNib()
    let controller = FlutterViewController()
    contentViewController = controller
    title = "OpenTickly"
    isReleasedWhenClosed = false
    contentMinSize = NSSize(width: 420, height: 360)
    let frameName = "OpenTicklyTracker"
    if !setFrameUsingName(frameName) {
      setContentSize(NSSize(width: 520, height: 590))
      let mouse = NSEvent.mouseLocation
      if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main {
        let area = screen.visibleFrame
        let origin = NSPoint(x: (area.midX - frame.width / 2).rounded(),
                             y: (area.midY - frame.height / 2).rounded())
        setFrame(constrainFrameRect(NSRect(origin: origin, size: frame.size), to: screen), display: false)
      } else {
        center()
      }
    }
    setFrameAutosaveName(frameName)
    RegisterGeneratedPlugins(registry: controller)
    let channel = FlutterMethodChannel(name: "opentickly/mac", binaryMessenger: controller.engine.binaryMessenger)
    bridge = channel
    channel.setMethodCallHandler { [weak self] call, reply in
      guard let self else { return reply(nil) }
      switch call.method {
      case "read", "save", "delete": self.credentials(call, reply)
      case "readLanguage":
        reply(UserDefaults.standard.string(forKey: "interfaceLanguage"))
      case "setLanguage":
        let choice = call.arguments as? String
        if choice == "en" || choice == "de" {
          UserDefaults.standard.set(choice, forKey: "interfaceLanguage")
        } else {
          UserDefaults.standard.removeObject(forKey: "interfaceLanguage")
        }
        self.statusItem?.button?.setAccessibilityLabel(self.openLabel)
        reply(nil)
      case "status":
        let badge = call.arguments as? String
        NSApp.dockTile.badgeLabel = badge
        let item = self.statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        item.button?.image = NSImage(systemSymbolName: "timer", accessibilityDescription: self.openLabel)
        item.button?.title = badge.map { " " + $0 } ?? ""
        item.button?.target = self
        item.button?.action = #selector(self.reveal)
        reply(nil)
      default: reply(FlutterMethodNotImplemented)
      }
    }
  }

  private var openLabel: String {
    let language = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? Bundle.main.preferredLocalizations.first
    return language == "de" ? "OpenTickly öffnen" : "Open OpenTickly"
  }

  @objc func reveal() {
    makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func credentials(_ call: FlutterMethodCall, _ reply: FlutterResult) {
    var query = credential
    var status: OSStatus
    switch call.method {
    case "read":
      query[kSecReturnData as String] = true
      var value: CFTypeRef?
      status = SecItemCopyMatching(query as CFDictionary, &value)
      if status == errSecItemNotFound { return reply(nil) }
      if status == errSecSuccess, let data = value as? Data {
        return reply(String(data: data, encoding: .utf8))
      }
    case "save":
      guard let session = call.arguments as? String else { return reply(FlutterMethodNotImplemented) }
      let data = Data(session.utf8)
      status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
      if status == errSecItemNotFound {
        query[kSecValueData as String] = data
        query[kSecAttrLabel as String] = "OpenTickly · App-Anmeldung"
        status = SecItemAdd(query as CFDictionary, nil)
      }
    default:
      status = SecItemDelete(query as CFDictionary)
      if status == errSecItemNotFound { return reply(nil) }
    }
    if status == errSecSuccess { reply(nil) }
    else { reply(FlutterError(code:"keychain", message:"Schlüsselbund nicht verfügbar (\(status)).", details:nil)) }
  }
}
