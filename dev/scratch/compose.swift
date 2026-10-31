// 把 5 张图标截图拼成一张对比图。
import AppKit

let styles: [(String, String)] = [
    ("chevron", "chevron 粗箭头"),
    ("chevronThin", "chevron 细箭头"),
    ("triangle", "triangle 三角"),
    ("toLine", "toLine 到边箭头"),
    ("symbol", "SF Symbol")
]

let rowHeight: CGFloat = 56
let labelWidth: CGFloat = 190
let padding: CGFloat = 10
var images: [(String, NSImage)] = []
for (id, label) in styles {
    if let image = NSImage(contentsOfFile: "/tmp/icon_\(id).png") { images.append((label, image)) }
}

let width = labelWidth + (images.map { $0.1.size.width }.max() ?? 200) + padding * 2
let height = rowHeight * CGFloat(images.count) + padding * 2

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()
NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

for (index, entry) in images.enumerated() {
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
    try? png.write(to: URL(fileURLWithPath: "/tmp/icon_compare.png"))
    print("wrote /tmp/icon_compare.png \(Int(width))x\(Int(height))")
}
