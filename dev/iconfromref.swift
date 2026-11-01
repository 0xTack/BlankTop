//
//  iconfromref.swift
//  留白 v1.1 · 保持参考图形状，只把边缘做光滑
//
//  原图 1024×1024：裁掉四周白边，圆角透明；线条用 2× 重采样 + 中值 + 轻微模糊，
//  去掉 JPEG 毛刺，但不改手和眼睛的形态。
//
//  运行：
//    swiftc -O dev/iconfromref.swift -framework AppKit -framework CoreImage -o /tmp/iconfromref && /tmp/iconfromref
//

import AppKit
import CoreImage

let sourcePath = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop/留白.jpg")
let url = URL(fileURLWithPath: sourcePath)
guard let source = CIImage(contentsOf: url) else {
    print("missing \(sourcePath)")
    exit(1)
}

// 2× 放大 → 中值去噪 → 轻微模糊 → 缩回 1024。形态不变，边缘更顺。
func filter(_ name: String, _ input: CIImage, _ params: [String: Any]) -> CIImage {
    guard let f = CIFilter(name: name) else { return input }
    f.setValue(input, forKey: kCIInputImageKey)
    for (k, v) in params { f.setValue(v, forKey: k) }
    return f.outputImage ?? input
}

var image = filter("CILanczosScaleTransform", source, [
    kCIInputScaleKey: 2.0,
    kCIInputAspectRatioKey: 1.0
])
image = filter("CIMedianFilter", image, [:])
image = filter("CIGaussianBlur", image, [kCIInputRadiusKey: 1.1])
image = filter("CILanczosScaleTransform", image, [
    kCIInputScaleKey: 0.5,
    kCIInputAspectRatioKey: 1.0
])
let cropped = image.cropped(to: CGRect(x: 0, y: 0, width: 1024, height: 1024))
let context = CIContext()
guard let cg = context.createCGImage(cropped, from: cropped.extent) else {
    print("render failed")
    exit(1)
}
let processed = NSImage(cgImage: cg, size: NSSize(width: 1024, height: 1024))

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.current?.imageInterpolation = .high

// 找黑框的包围盒，裁到框边，外面不留白。
let bitmap = NSBitmapImageRep(data: try! Data(contentsOf: url))!
var minX = 1024, minY = 1024, maxX = 0, maxY = 0
for y in 0..<1024 {
    for x in 0..<1024 {
        guard let c = bitmap.colorAt(x: x, y: y) else { continue }
        if c.redComponent < 0.30 && c.greenComponent < 0.30 && c.blueComponent < 0.30 {
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
        }
    }
}
let cropSide = max(CGFloat(maxX - minX), CGFloat(maxY - minY)) + 4
let cropOrigin = NSPoint(x: 512 - cropSide / 2, y: 512 - cropSide / 2)
print("border bounds \(minX),\(minY) - \(maxX),\(maxY), crop \(Int(cropSide))")

// 裁到框边后再往里切 2px：最外圈就是黑线，不会露出白边。
let clip = NSBezierPath(roundedRect: NSRect(x: 2, y: 2, width: 1020, height: 1020),
                        xRadius: 193, yRadius: 193)
clip.addClip()
processed.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: NSRect(x: cropOrigin.x, y: cropOrigin.y, width: cropSide, height: cropSide),
               operation: .sourceOver,
               fraction: 1)

NSGraphicsContext.restoreGraphicsState()

let out = "/tmp/blanktop-ref-1024.png"
if let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}

for s in [256, 128, 64, 32] {
    let small = NSImage(size: NSSize(width: s, height: s))
    small.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSImage(contentsOfFile: out)?.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    small.unlockFocus()
    if let tiff = small.tiffRepresentation,
       let r = NSBitmapImageRep(data: tiff),
       let png = r.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-ref-\(s).png"))
        print("wrote /tmp/blanktop-ref-\(s).png")
    }
}
