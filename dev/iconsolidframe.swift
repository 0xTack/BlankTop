//
//  iconsolidframe.swift
//  留白 v1.1 · 实心黑框，白底紧贴边框，外面不留任何白边
//
//  保留原图的手和眼睛；只把边框区做成一条干净的实心黑框。
//
//  运行：
//    swiftc -O dev/iconsolidframe.swift -framework AppKit -framework CoreImage -o /tmp/iconsolidframe && /tmp/iconsolidframe
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

// 原图黑框大约 63..960；外框就取这个范围。
let outer = NSRect(x: 63, y: 63, width: 898, height: 898)
let outerRadius: CGFloat = 190
let outerPath = NSBezierPath(roundedRect: outer, xRadius: outerRadius, yRadius: outerRadius)

// 只保留黑框以内的内容，外面全部透明。
outerPath.addClip()
processed.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: .zero, operation: .sourceOver, fraction: 1)

// 实心黑框：外框 898，内框 834（框宽 32）。白底紧贴内框，中间没有白缝。
let inner = outer.insetBy(dx: 32, dy: 32)
let innerPath = NSBezierPath(roundedRect: inner,
                             xRadius: outerRadius - 32,
                             yRadius: outerRadius - 32)
let frame = NSBezierPath()
frame.append(outerPath)
frame.append(innerPath)
frame.windingRule = .evenOdd
NSColor(calibratedWhite: 0.11, alpha: 1).setFill()
frame.fill()

NSGraphicsContext.restoreGraphicsState()

let out = "/tmp/blanktop-solidframe-1024.png"
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
        try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-solidframe-\(s).png"))
        print("wrote /tmp/blanktop-solidframe-\(s).png")
    }
}
