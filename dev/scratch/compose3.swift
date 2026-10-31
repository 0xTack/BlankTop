// 两列对比图：左=展开，右=折叠。
import AppKit

let styles: [(String, String)] = [
    ("tray", "收纳盘 tray"),
    ("archive", "归档盒 archivebox"),
    ("moon", "月亮 moon"),
    ("stack", "一叠卡片 square.stack.3d.up"),
    ("compress", "压缩 rectangle.compress"),
    ("doubleChevron", "双箭头 chevron.2"),
    ("halfCircle", "半圆 circle.half"),
    ("menubar", "菜单栏 menubar.rectangle"),
    ("toggle", "开关（自绘）")
]

let rowHeight: CGFloat = 54
let labelWidth: CGFloat = 240
let cellWidth: CGFloat = 230
let padding: CGFloat = 10

var rows: [(String, NSImage?, NSImage?)] = []
for (id, label) in styles {
    let a = NSImage(contentsOfFile: "/tmp/ic_\(id)_a.png")
    let b = NSImage(contentsOfFile: "/tmp/ic_\(id)_b.png")
    rows.append((label, a, b))
}

let width = labelWidth + cellWidth * 2 + padding * 2
let height = rowHeight * CGFloat(rows.count) + padding * 2 + 24

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()
NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

let header: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 12),
    .foregroundColor: NSColor.lightGray
]
NSAttributedString(string: "展开", attributes: header)
    .draw(at: NSPoint(x: labelWidth, y: height - padding - 16))
NSAttributedString(string: "折叠", attributes: header)
    .draw(at: NSPoint(x: labelWidth + cellWidth, y: height - padding - 16))

for (index, row) in rows.enumerated() {
    let y = height - padding - 24 - rowHeight * CGFloat(index + 1)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13),
        .foregroundColor: NSColor.white
    ]
    NSAttributedString(string: row.0, attributes: attributes)
        .draw(at: NSPoint(x: padding, y: y + rowHeight / 2 - 8))

    for (column, image) in [row.1, row.2].enumerated() {
        guard let image else { continue }
        let x = labelWidth + cellWidth * CGFloat(column)
        image.draw(in: NSRect(x: x, y: y + (rowHeight - image.size.height) / 2,
                              width: image.size.width, height: image.size.height))
        NSColor(calibratedWhite: 0.3, alpha: 1).setStroke()
        NSBezierPath(rect: NSRect(x: x, y: y, width: cellWidth - 6, height: rowHeight)).stroke()
    }
}
output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/icon_compare3.png"))
    print("wrote /tmp/icon_compare3.png")
}
