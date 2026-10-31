// 诊断：打印辅助功能能读到的所有菜单栏图标及其横坐标。
import AppKit
import ApplicationServices

func frame(of element: AXUIElement) -> CGRect? {
    var p: CFTypeRef?, s: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &p) == .success,
          AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &s) == .success,
          let p, let s else { return nil }
    var point = CGPoint.zero, size = CGSize.zero
    AXValueGetValue(p as! AXValue, .cgPoint, &point)
    AXValueGetValue(s as! AXValue, .cgSize, &size)
    return CGRect(origin: point, size: size)
}

print("accessibility trusted = \(AXIsProcessTrusted())")
let own = ProcessInfo.processInfo.processIdentifier
let apps = NSWorkspace.shared.runningApplications
    .filter { $0.processIdentifier != own && $0.bundleURL?.pathExtension == "app" }
print("apps = \(apps.count)")

for app in apps {
    let element = AXUIElementCreateApplication(app.processIdentifier)
    AXUIElementSetMessagingTimeout(element, 0.1)
    var barRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, "AXExtrasMenuBar" as CFString, &barRef) == .success,
          let barRef else { continue }
    var kidsRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(barRef as! AXUIElement, kAXChildrenAttribute as CFString, &kidsRef) == .success,
          let kids = kidsRef as? [AXUIElement] else { continue }
    for kid in kids {
        if let f = frame(of: kid) {
            print(String(format: "%7.1f  %@", f.midX, app.bundleIdentifier ?? "?"))
        }
    }
}
