// 把真实的菜单栏截图（展开/折叠）拼成一张图。
import AppKit

let items: [(String, String)] = [
    ("展开（开）：圆点在右，左侧底板绿", "/tmp/g_expanded.png"),
    ("折叠（关）：圆点在左，右侧底板灰", "/tmp/g_collapsed.png")
]

let rowHeight: CGFloat = 76
let labelWidth: CGFloat = 290
let padding: CGFloat = 12
var rows: [(String, NSImage)] = []
for (label, path) in items {
    if let image = NSImage(contentsOfFile: path) { rows.append((label, image)) }
}

let width = labelWidth + (rows.map { $0.1.size.width }.max() ?? 240) + padding * 2
let height = rowHeight * CGFloat(rows.count) + padding * 2
let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()
NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

for (index, row) in rows.enumerated() {
    let y = height - padding - rowHeight * CGFloat(index + 1)
    NSAttributedString(string: row.0, attributes: [
        .font: NSFont.systemFont(ofSize: 13),
        .foregroundColor: NSColor.white
    ]).draw(at: NSPoint(x: padding, y: y + rowHeight / 2 - 8))
    row.1.draw(in: NSRect(x: labelWidth, y: y + (rowHeight - row.1.size.height) / 2,
                          width: row.1.size.width, height: row.1.size.height))
}
output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/toggle_pair.png"))
    print("wrote /tmp/toggle_pair.png")
}
