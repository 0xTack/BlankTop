// 测试用：点一下留白自己的菜单栏图标。
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

guard let app = NSWorkspace.shared.runningApplications
    .first(where: { $0.bundleIdentifier == "com.xa.blanktop" }) else {
    print("BlankTop not running"); exit(1)
}
let element = AXUIElementCreateApplication(app.processIdentifier)
var barRef: CFTypeRef?
guard AXUIElementCopyAttributeValue(element, "AXExtrasMenuBar" as CFString, &barRef) == .success,
      let barRef else { print("no menu bar"); exit(1) }
var kidsRef: CFTypeRef?
guard AXUIElementCopyAttributeValue(barRef as! AXUIElement, kAXChildrenAttribute as CFString, &kidsRef) == .success,
      let kids = kidsRef as? [AXUIElement], let kid = kids.first, let f = frame(of: kid) else {
    print("no item"); exit(1)
}
print("item frame \(f)")
let screenH = NSScreen.screens[0].frame.height
let point = CGPoint(x: f.midX, y: f.midY)
print("click at \(point)")
let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                   mouseCursorPosition: point, mouseButton: .left)
let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                 mouseCursorPosition: point, mouseButton: .left)
down?.post(tap: .cghidEventTap)
usleep(60_000)
up?.post(tap: .cghidEventTap)
print("clicked")
