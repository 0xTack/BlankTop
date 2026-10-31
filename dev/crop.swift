// 直接从真实菜单栏截图里裁一段（不打码）：以开关为中心，避开左边的 App 菜单和右边的时间。
import AppKit

let args = CommandLine.arguments
guard args.count >= 5 else {
    print("usage: crop <in.png> <out.png> <centerXPoints> <halfWidthPoints>")
    exit(1)
}
let input = args[1], output = args[2]
let centerX = CGFloat(Double(args[3]) ?? 900)
let halfWidth = CGFloat(Double(args[4]) ?? 200)
let scale: CGFloat = 2

guard let data = try? Data(contentsOf: URL(fileURLWithPath: input)),
      let rep = NSBitmapImageRep(data: data),
      let full = rep.cgImage else { print("load failed"); exit(1) }

let cropWidth = Int(halfWidth * 2 * scale)
let cropHeight = full.height
let cropX = max(0, min(full.width - cropWidth, Int((centerX - halfWidth) * scale)))

guard let crop = full.cropping(to: CGRect(x: cropX, y: 0, width: cropWidth, height: cropHeight)) else {
    print("crop failed"); exit(1)
}

let out = NSBitmapImageRep(cgImage: crop)
guard let png = out.representation(using: .png, properties: [:]) else { exit(1) }
try? png.write(to: URL(fileURLWithPath: output))
print("wrote \(output) \(cropWidth)x\(cropHeight)")
