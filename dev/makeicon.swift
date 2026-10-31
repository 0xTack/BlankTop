// 从设计稿生成 macOS 图标（1024×1024，透明背景，圆角方）。
import AppKit

let sourcePath = "assets/icon-source.jpeg"
guard let source = NSImage(contentsOfFile: sourcePath),
      let tiff = source.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    print("cannot load \(sourcePath)")
    exit(1)
}

let width = rep.pixelsWide
let height = rep.pixelsHigh

// 找出深色圆角方的边界
var minX = width, minY = height, maxX = 0, maxY = 0
for y in 0..<height {
    for x in 0..<width {
        guard let c = rep.colorAt(x: x, y: y) else { continue }
        guard let rgb = c.usingColorSpace(.deviceRGB) else { continue }
        let luma = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        if luma < 0.55 {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }
}
print("source \(width)x\(height), icon box x:\(minX)-\(maxX) y:\(minY)-\(maxY)")

let inset = 2
let cropRect = NSRect(x: CGFloat(minX + inset),
                      y: CGFloat(minY + inset),
                      width: CGFloat(maxX - minX - inset * 2),
                      height: CGFloat(maxY - minY - inset * 2))

// macOS 图标栅格：1024 画布，内容 824×824 居中，圆角半径约 185
let canvas: CGFloat = 1024
let content: CGFloat = 824
let margin = (canvas - content) / 2
let radius: CGFloat = 185

guard let ctx = CGContext(data: nil,
                          width: Int(canvas), height: Int(canvas),
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    print("cannot create context")
    exit(1)
}

guard let cgSource = rep.cgImage else { print("no cgImage"); exit(1) }
let sourceHeight = CGFloat(cgSource.height)

// 从原图裁出图标方形（CoreGraphics 原点在左下，需翻转 y）
let cgCrop = CGRect(x: cropRect.minX,
                    y: sourceHeight - cropRect.maxY,
                    width: cropRect.width,
                    height: cropRect.height)
guard let cropped = cgSource.cropping(to: cgCrop) else { print("crop failed"); exit(1) }

let target = CGRect(x: margin, y: margin, width: content, height: content)
let clip = CGPath(roundedRect: target, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(clip)
ctx.clip()
ctx.interpolationQuality = .high
ctx.draw(cropped, in: target)

guard let output = ctx.makeImage() else { print("no image"); exit(1) }
let outRep = NSBitmapImageRep(cgImage: output)
guard let png = outRep.representation(using: .png, properties: [:]) else { print("no png"); exit(1) }
try! png.write(to: URL(fileURLWithPath: "assets/icon_1024.png"))
print("wrote assets/icon_1024.png")
