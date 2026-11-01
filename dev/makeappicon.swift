//
//  makeappicon.swift
//  把参考图裁成 macOS 应用图标：去掉四周白边，圆角透明。
//
//  运行：
//    swiftc -O dev/makeappicon.swift -framework AppKit -o /tmp/makeappicon && /tmp/makeappicon
//

import AppKit

let sourcePath = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop/留白.jpg")
guard let source = NSImage(contentsOfFile: sourcePath) else {
    print("missing \(sourcePath)")
    exit(1)
}

let size: CGFloat = 1024
let inset: CGFloat = 6
let canvas = NSRect(x: 0, y: 0, width: size, height: size)
let content = canvas.insetBy(dx: inset, dy: inset)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.clear(canvas)

// 圆角裁剪：参考图的黑框外面还有一圈白边，裁掉大部分白边再套圆角。
let clip = NSBezierPath(roundedRect: content,
                        xRadius: content.width * 0.19,
                        yRadius: content.height * 0.19)
clip.addClip()

// 参考图 1024×1024，黑框大约在 52..972，取中间的 920×920。
let sourceRect = NSRect(x: 52, y: 52, width: 920, height: 920)
source.draw(in: content, from: sourceRect, operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()

let out = "/tmp/blanktop-appicon-1024.png"
if let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out) \(rep.pixelsWide)x\(rep.pixelsHigh)")
} else {
    print("failed to encode png")
    exit(1)
}
