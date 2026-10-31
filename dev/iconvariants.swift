// 生成 BlankTop 图标的三个变体，并输出小尺寸预览。
import AppKit

let canvas: CGFloat = 1024
let contentInset: CGFloat = 100
let content = CGRect(x: contentInset, y: contentInset,
                     width: canvas - contentInset * 2,
                     height: canvas - contentInset * 2)

func squircle(_ rect: CGRect, n: CGFloat = 5) -> CGPath {
    let a = rect.width / 2, b = rect.height / 2
    let path = CGMutablePath()
    let steps = 720
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let ct = cos(t), st = sin(t)
        let x = rect.midX + a * (ct < 0 ? -1 : 1) * pow(abs(ct), 2 / n)
        let y = rect.midY + b * (st < 0 ? -1 : 1) * pow(abs(st), 2 / n)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

func context() -> CGContext {
    CGContext(data: nil, width: Int(canvas), height: Int(canvas),
              bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func gradient(_ ctx: CGContext, path: CGPath, colors: [CGColor], start: CGPoint, end: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let g = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: start, end: end, options: [])
    ctx.restoreGState()
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

// 底板：深蓝渐变 + 顶部内高光
func drawPlate(_ ctx: CGContext) {
    let shape = squircle(content)
    gradient(ctx, path: shape,
             colors: [color(0x3D4880), color(0x2A3462), color(0x1D2648)],
             start: CGPoint(x: content.midX, y: content.maxY),
             end: CGPoint(x: content.midX, y: content.minY))

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.setStrokeColor(color(0xFFFFFF, 0.14))
    ctx.setLineWidth(3)
    ctx.addPath(CGPath(roundedRect: content.insetBy(dx: 2, dy: 2),
                       cornerWidth: 178, cornerHeight: 178, transform: nil))
    ctx.strokePath()
    ctx.restoreGState()
}

// 顶部菜单栏示意：一条横贯的浅色带，右侧几个小图标块
func drawMenuBar(_ ctx: CGContext, width: CGFloat, alpha: CGFloat) {
    let barH = content.height * 0.085
    let barW = content.width * width
    let barRect = CGRect(x: content.midX - barW / 2,
                         y: content.maxY - content.height * 0.135 - barH,
                         width: barW, height: barH)

    ctx.saveGState()
    ctx.setFillColor(color(0xFFFFFF, 0.09 * alpha))
    ctx.addPath(CGPath(roundedRect: barRect, cornerWidth: barH * 0.34,
                       cornerHeight: barH * 0.34, transform: nil))
    ctx.fillPath()

    // 右侧的状态项：几个小圆角块
    let itemH = barH * 0.42
    let widths: [CGFloat] = [itemH * 2.6, itemH, itemH * 0.9, itemH * 1.7]
    var x = barRect.maxX - barH * 0.5
    for w in widths.reversed() {
        let rect = CGRect(x: x - w, y: barRect.midY - itemH / 2, width: w, height: itemH)
        ctx.setFillColor(color(0xD9DEFF, 0.75 * alpha))
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: itemH * 0.3,
                           cornerHeight: itemH * 0.3, transform: nil))
        ctx.fillPath()
        x -= w + barH * 0.28
    }
    ctx.restoreGState()
}

// 开关
func drawToggle(_ ctx: CGContext, width: CGFloat, height: CGFloat, centerY: CGFloat, knob: CGFloat) {
    let trackW = content.width * width
    let trackH = content.height * height
    let track = CGRect(x: content.midX - trackW / 2,
                       y: centerY - trackH / 2,
                       width: trackW, height: trackH)
    let trackPath = CGPath(roundedRect: track, cornerWidth: trackH / 2,
                           cornerHeight: trackH / 2, transform: nil)

    // 轨道投影
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -trackH * 0.07),
                  blur: trackH * 0.16,
                  color: color(0x0B1026, 0.26))
    ctx.addPath(trackPath)
    ctx.setFillColor(color(0x36B94F))
    ctx.fillPath()
    ctx.restoreGState()

    // 绿色渐变 + 顶部高光
    gradient(ctx, path: trackPath,
             colors: [color(0x6FD45F), color(0x45C34F), color(0x2EA845)],
             start: CGPoint(x: track.midX, y: track.maxY),
             end: CGPoint(x: track.midX, y: track.minY))

    ctx.saveGState()
    ctx.addPath(trackPath)
    ctx.clip()
    ctx.setFillColor(color(0xFFFFFF, 0.12))
    ctx.fill(CGRect(x: track.minX, y: track.maxY - trackH * 0.30,
                    width: track.width, height: trackH * 0.30))
    ctx.restoreGState()

    // 白色圆钮
    let knobD = trackH * knob
    let knobRect = CGRect(x: track.maxX - knobD - trackH * 0.07,
                          y: track.midY - knobD / 2,
                          width: knobD, height: knobD)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -knobD * 0.035),
                  blur: knobD * 0.10,
                  color: color(0x0B1026, 0.16))
    ctx.addPath(CGPath(ellipseIn: knobRect, transform: nil))
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillPath()
    ctx.restoreGState()

}

func render(variant: Int) -> NSImage {
    let ctx = context()
    drawPlate(ctx)
    switch variant {
    case 1:
        drawMenuBar(ctx, width: 0.84, alpha: 1.0)
        drawToggle(ctx, width: 0.58, height: 0.285,
                   centerY: content.midY - content.height * 0.05, knob: 0.74)
    case 2:
        drawToggle(ctx, width: 0.66, height: 0.325,
                   centerY: content.midY, knob: 0.74)
    default:
        drawMenuBar(ctx, width: 0.84, alpha: 1.0)
        drawToggle(ctx, width: 0.60, height: 0.295,
                   centerY: content.midY - content.height * 0.06, knob: 0.74)
    }
    let image = ctx.makeImage()!
    return NSImage(cgImage: image, size: NSSize(width: canvas, height: canvas))
}

func png(_ image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
}

// 输出三张 1024 原图
for variant in 1...3 {
    let image = render(variant: variant)
    png(image, path: "/tmp/bt_v\(variant).png")
}

// 对比图：每个变体一行，256/128/64/32
let sizes: [CGFloat] = [256, 128, 64, 32]
let rowH: CGFloat = 280
let labelW: CGFloat = 120
let gap: CGFloat = 24
let sheetW = labelW + sizes.reduce(0) { $0 + $1 + gap } + gap
let sheetH = rowH * 3 + gap * 2

let sheet = NSImage(size: NSSize(width: sheetW, height: sheetH))
sheet.lockFocus()
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: sheetW, height: sheetH).fill()

for variant in 1...3 {
    let image = render(variant: variant)
    let y = sheetH - CGFloat(variant) * rowH
    NSAttributedString(string: "V\(variant)", attributes: [
        .font: NSFont.boldSystemFont(ofSize: 18),
        .foregroundColor: NSColor.black
    ]).draw(at: NSPoint(x: gap, y: y + rowH / 2 - 10))

    var x = labelW
    for size in sizes {
        image.draw(in: NSRect(x: x, y: y + (rowH - size) / 2, width: size, height: size),
                   from: .zero, operation: .sourceOver, fraction: 1,
                   respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high.rawValue])
        x += size + gap
    }
}
sheet.unlockFocus()
png(sheet, path: "/tmp/bt_variants.png")
print("done")
