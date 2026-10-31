// 把真实菜单栏截图做脱敏：以开关为中心裁一条，其余图标做马赛克，开关保持清晰。
import AppKit

func load(_ path: String) -> CGImage? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let rep = NSBitmapImageRep(data: data) else { return nil }
    return rep.cgImage
}

func save(_ image: CGImage, to path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
guard args.count >= 5 else {
    print("usage: mask <in.png> <out.png> <centerXPoints> <halfWidthPoints>")
    exit(1)
}
let input = args[1], output = args[2]
let centerX = CGFloat(Double(args[3]) ?? 900)
let halfWidth = CGFloat(Double(args[4]) ?? 180)
let scale: CGFloat = 2   // 截图为 2x

guard let full = load(input) else { print("load failed"); exit(1) }

let cropWidth = Int(halfWidth * 2 * scale)
let cropHeight = full.height
let cropX = max(0, min(full.width - cropWidth, Int((centerX - halfWidth) * scale)))

guard let crop = full.cropping(to: CGRect(x: cropX, y: 0, width: cropWidth, height: cropHeight)) else {
    print("crop failed"); exit(1)
}

// 马赛克：缩小再放大
let mosaicBlock: CGFloat = 9
let smallW = max(1, Int(CGFloat(cropWidth) / mosaicBlock))
let smallH = max(1, Int(CGFloat(cropHeight) / mosaicBlock))

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let smallCtx = CGContext(data: nil, width: smallW, height: smallH, bitsPerComponent: 8,
                         bytesPerRow: 0, space: space,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
smallCtx.interpolationQuality = .low
smallCtx.draw(crop, in: CGRect(x: 0, y: 0, width: smallW, height: smallH))
let small = smallCtx.makeImage()!

let outCtx = CGContext(data: nil, width: cropWidth, height: cropHeight, bitsPerComponent: 8,
                       bytesPerRow: 0, space: space,
                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
outCtx.interpolationQuality = .none
outCtx.draw(small, in: CGRect(x: 0, y: 0, width: cropWidth, height: cropHeight))

// 开关区域保持清晰
let clearHalf = 19 * scale
let clearRect = CGRect(x: CGFloat(cropWidth) / 2 - clearHalf, y: 0,
                       width: clearHalf * 2, height: CGFloat(cropHeight))
if let clear = crop.cropping(to: clearRect) {
    outCtx.draw(clear, in: clearRect)
}

guard let out = outCtx.makeImage() else { print("render failed"); exit(1) }
save(out, to: output)
print("wrote \(output) \(cropWidth)x\(cropHeight)")
