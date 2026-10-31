// 把 18 种图标样式的真实渲染图拼成一张图库（透明背景，适配深色页面）。
import AppKit

let styles: [(String, String, String)] = [
    ("chevron", "粗箭头", "/tmp/icon_chevron.png"),
    ("chevronThin", "细箭头", "/tmp/icon_chevronThin.png"),
    ("triangle", "三角", "/tmp/icon_triangle.png"),
    ("toLine", "到边箭头", "/tmp/icon_toLine.png"),
    ("symbol", "SF 箭头", "/tmp/icon_symbol.png"),
    ("eye", "眼睛", "/tmp/icon2_eye.png"),
    ("dot", "圆点", "/tmp/icon2_dot.png"),
    ("bar", "竖线", "/tmp/icon2_bar.png"),
    ("sidebar", "侧边栏", "/tmp/icon2_sidebar.png"),
    ("tray", "收纳盘", "/tmp/ic_tray_a.png"),
    ("archive", "归档盒", "/tmp/ic_archive_a.png"),
    ("moon", "月亮", "/tmp/ic_moon_a.png"),
    ("stack", "一叠卡片", "/tmp/ic_stack_a.png"),
    ("compress", "压缩", "/tmp/ic_compress_a.png"),
    ("doubleChevron", "双箭头", "/tmp/ic_doubleChevron_a.png"),
    ("halfCircle", "半圆", "/tmp/ic_halfCircle_a.png"),
    ("menubar", "菜单栏", "/tmp/ic_menubar_a.png"),
    ("toggle", "开关", "/tmp/ic_toggle_a.png")
]

let scale: CGFloat = 2
let cols = 3
let rows = (styles.count + cols - 1) / cols
let cardW: CGFloat = 268
let cardH: CGFloat = 104
let gap: CGFloat = 18
let pad: CGFloat = 20

let width = CGFloat(cols) * cardW + CGFloat(cols - 1) * gap + pad * 2
let height = CGFloat(rows) * cardH + CGFloat(rows - 1) * gap + pad * 2

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()

for (index, style) in styles.enumerated() {
    let col = index % cols
    let row = index / cols
    let x = pad + CGFloat(col) * (cardW + gap)
    let y = height - pad - CGFloat(row + 1) * cardH - CGFloat(row) * gap

    // 卡片
    let card = NSRect(x: x, y: y, width: cardW, height: cardH)
    let path = NSBezierPath(roundedRect: card, xRadius: 14, yRadius: 14)
    NSColor(calibratedWhite: 1, alpha: 0.045).setFill()
    path.fill()
    NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
    path.lineWidth = 1
    path.stroke()

    // 名称
    let label = NSAttributedString(string: style.1, attributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.72, alpha: 1)
    ])
    label.draw(at: NSPoint(x: x + 14, y: y + cardH - 26))

    // 真实截图
    guard let image = NSImage(contentsOfFile: style.2) else { continue }
    let maxW = cardW - 36
    let maxH: CGFloat = 34
    let ratio = min(maxW / image.size.width, maxH / image.size.height)
    let drawW = image.size.width * ratio
    let drawH = image.size.height * ratio
    image.draw(in: NSRect(x: x + (cardW - drawW) / 2,
                          y: y + 14 + (maxH - drawH) / 2,
                          width: drawW, height: drawH),
               from: .zero, operation: .sourceOver, fraction: 1,
               respectFlipped: false, hints: nil)
}

output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/icons-grid.png"))
    print("wrote /tmp/icons-grid.png \(Int(width))x\(Int(height)) @2x")
}
