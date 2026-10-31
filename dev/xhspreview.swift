// 8 张拼成一张预览图。
import AppKit

let names = ["01-cover", "02-pain", "03-pain2", "04-solution",
             "05-pillars", "06-compare", "07-usage", "08-end"]

let cellW: CGFloat = 270, cellH: CGFloat = 360, gap: CGFloat = 16
let cols = 4, rows = 2
let width = CGFloat(cols) * cellW + CGFloat(cols - 1) * gap + gap * 2
let height = CGFloat(rows) * cellH + CGFloat(rows - 1) * gap + gap * 2

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()
NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

for (index, name) in names.enumerated() {
    guard let image = NSImage(contentsOfFile: "/tmp/xhs/\(name).png") else { continue }
    let col = index % cols
    let row = index / cols
    let x = gap + CGFloat(col) * (cellW + gap)
    let y = height - gap - CGFloat(row + 1) * cellH - CGFloat(row) * gap
    image.draw(in: NSRect(x: x, y: y, width: cellW, height: cellH))
}
output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/xhs-preview.png"))
    print("ok")
}
