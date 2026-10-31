// 把新图标截图拼成一张对比图（含展开/折叠两种状态）。
import AppKit

let styles: [(String, String)] = [
    ("eye", "眼睛 eye / eye.slash"),
    ("dot", "圆点 ○ / ●"),
    ("bar", "竖线 ❘"),
    ("sidebar", "侧边栏 sidebar.left / right")
]

let rowHeight: CGFloat = 56
let labelWidth: CGFloat = 210
let padding: CGFloat = 10
var rows: [(String, NSImage)] = []

for (id, label) in styles {
    guard let image = NSImage(contentsOfFile: "/tmp/icon2_\(id).png") else { continue }
    rows.append((label, image))
}

let width = labelWidth + (rows.map { $0.1.size.width }.max() ?? 240) + padding * 2
let height = rowHeight * CGFloat(rows.count) + padding * 2

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()
NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

for (index, entry) in rows.enumerated() {
    let y = height - padding - rowHeight * CGFloat(index + 1)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13),
        .foregroundColor: NSColor.white
    ]
    NSAttributedString(string: entry.0, attributes: attributes)
        .draw(at: NSPoint(x: padding, y: y + rowHeight / 2 - 8))
    let image = entry.1
    image.draw(in: NSRect(x: labelWidth, y: y + (rowHeight - image.size.height) / 2,
                          width: image.size.width, height: image.size.height))
}
output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/icon_compare2.png"))
    print("wrote /tmp/icon_compare2.png")
}
