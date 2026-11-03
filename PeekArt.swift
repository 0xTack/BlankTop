//
//  PeekArt.swift
//  BlankTop — 「不看还看」的手势图标
//
//  读取两张 PNG：
//    hand-open.png   睁眼
//    hand-closed.png 闭眼
//  把「黑形 + 白底/白线」转成 alpha 遮罩，按 template 画到 20pt，
//  深浅色菜单栏都能用。
//

import AppKit

struct PeekArt {
    let bbox: CGRect
    private let cg: CGImage?

    init?(url: URL, maxSide: CGFloat = 600) {
        guard let source = NSImage(contentsOf: url),
              let image = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let scale = min(1, maxSide / CGFloat(max(image.width, image.height)))
        let w = max(1, Int(CGFloat(image.width) * scale))
        let h = max(1, Int(CGFloat(image.height) * scale))
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        pixels.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.interpolationQuality = .high
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }

        var ink = [UInt8](repeating: 0, count: w * h)
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            for x in 0..<w {
                let i = (y * w + x) * 4
                let a = Double(pixels[i + 3]) / 255
                let lum = (0.2126 * Double(pixels[i]) +
                           0.7152 * Double(pixels[i + 1]) +
                           0.0722 * Double(pixels[i + 2])) / 255
                let value = UInt8(max(0, min(255, Int((a * (1 - lum) * 255).rounded()))))
                ink[y * w + x] = value
                if value > 8 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY else { return nil }

        // 原图线条在 20pt 下太细，膨胀加粗一点
        let thick = PeekArt.dilate(ink, w: w, h: h, radius: 7)
        var mask = [UInt8](repeating: 0, count: w * h * 4)
        for index in 0..<(w * h) { mask[index * 4 + 3] = thick[index] }

        let box = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        self.bbox = box
        var cropped = [UInt8](repeating: 0, count: Int(box.width) * Int(box.height) * 4)
        for y in 0..<Int(box.height) {
            for x in 0..<Int(box.width) {
                let si = ((y + Int(box.minY)) * w + (x + Int(box.minX))) * 4
                let di = (y * Int(box.width) + x) * 4
                cropped[di + 3] = mask[si + 3]
            }
        }

        var imageOut: CGImage?
        cropped.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress,
                                      width: Int(box.width), height: Int(box.height),
                                      bitsPerComponent: 8, bytesPerRow: Int(box.width) * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            imageOut = ctx.makeImage()
        }
        self.cg = imageOut
    }

    private static func dilate(_ alpha: [UInt8], w: Int, h: Int, radius: Int) -> [UInt8] {
        guard radius > 0 else { return alpha }
        var horizontal = [UInt8](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                var value: UInt8 = 0
                let low = max(0, x - radius), high = min(w - 1, x + radius)
                for xx in low...high { value = max(value, alpha[y * w + xx]) }
                horizontal[y * w + x] = value
            }
        }
        var out = [UInt8](repeating: 0, count: w * h)
        for y in 0..<h {
            let low = max(0, y - radius), high = min(h - 1, y + radius)
            for x in 0..<w {
                var value: UInt8 = 0
                for yy in low...high { value = max(value, horizontal[yy * w + x]) }
                out[y * w + x] = value
            }
        }
        return out
    }

    func image(size: CGFloat) -> NSImage? {
        guard let cg else { return nil }
        let logical = NSSize(width: size, height: size)
        let scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(logical.width * scale),
                                         pixelsHigh: Int(logical.height * scale),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)
        context.imageInterpolation = .high

        let s = min(size / bbox.width, size / bbox.height)
        let w = bbox.width * s, h = bbox.height * s
        context.cgContext.draw(cg, in: CGRect(x: (size - w) / 2, y: (size - h) / 2,
                                              width: w, height: h))
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }
}

enum PeekIcons {
    static var open: PeekArt?
    static var closed: PeekArt?

    static func load() {
        open = Bundle.main.url(forResource: "hand-open", withExtension: "png").flatMap { PeekArt(url: $0) }
        closed = Bundle.main.url(forResource: "hand-closed", withExtension: "png").flatMap { PeekArt(url: $0) }
    }
}
