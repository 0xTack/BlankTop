//
//  iconwhite.swift
//  留白 v1.1 · 去掉边框，全部白底
//
//  白底圆角方块 + 原图的手和眼睛；不画任何边框。
//
//  运行：
//    swiftc -O dev/iconwhite.swift -framework AppKit -framework CoreImage -o /tmp/iconwhite && /tmp/iconwhite
//

import AppKit
import CoreImage

let sourcePath = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop/留白.jpg")
let url = URL(fileURLWithPath: sourcePath)
guard let source = CIImage(contentsOf: url) else {
    print("missing \(sourcePath)")
    exit(1)
}

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
guard let cg = CIContext().createCGImage(cropped, from: cropped.extent) else {
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

// 白底圆角方块，没有边框。
let plate = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                         xRadius: 200, yRadius: 200)
plate.addClip()
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

// 原图黑框在 63..960，内沿约 95；从内沿裁起，去掉整条边框。
// 手和眼睛的形态不变，只是放大到白底里。
processed.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: NSRect(x: 96, y: 96, width: 832, height: 832),
               operation: .sourceOver,
               fraction: 1)

NSGraphicsContext.restoreGraphicsState()

let out = "/tmp/blanktop-white-1024.png"
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
        try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-white-\(s).png"))
        print("wrote /tmp/blanktop-white-\(s).png")
    }
}
