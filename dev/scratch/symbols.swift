// 检查候选 SF Symbol 在当前系统上是否存在。
import AppKit

let candidates = [
    "menubar.rectangle", "menubar.dock.rectangle",
    "tray", "tray.fill", "tray.full", "tray.full.fill",
    "archivebox", "archivebox.fill",
    "rectangle.compress.vertical", "rectangle.expand.vertical",
    "chevron.left.2", "chevron.right.2",
    "chevron.compact.left", "chevron.compact.right",
    "circle.lefthalf.filled", "circle.righthalf.filled",
    "circle.lefthalf.striped.horizontal", "circle.righthalf.striped.horizontal",
    "arrow.down.right.and.arrow.up.left", "arrow.up.left.and.arrow.down.right",
    "rectangle.lefthalf.inset.filled", "rectangle.righthalf.inset.filled",
    "square.stack", "square.stack.fill", "square.stack.3d.up", "square.stack.3d.up.fill",
    "ellipsis", "ellipsis.circle", "ellipsis.circle.fill",
    "capsule", "capsule.fill", "capsule.portrait", "capsule.portrait.fill",
    "dot.circle.and.hand.point.up.left.fill",
    "chevron.left.forwardslash.chevron.right",
    "line.3.horizontal.decrease.circle", "line.3.horizontal.decrease",
    "square.dashed", "square.dashed.inset.filled",
    "moon", "moon.fill", "moon.circle", "moon.circle.fill",
    "text.line.first.and.arrowtriangle.forward",
    "arrow.left.and.line.vertical.and.arrow.right",
    "rectangle.split.2x1", "rectangle.split.2x1.fill",
    "sidebar.left", "sidebar.right"
]

for name in candidates {
    let exists = NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    print("\(exists ? "OK  " : "MISS") \(name)")
}
