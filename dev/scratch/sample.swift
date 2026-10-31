// 采样菜单栏截图里那个绿色圆环的颜色。
import AppKit

guard let image = NSImage(contentsOfFile: "/tmp/t_on2.png"),
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else { exit(1) }

var best: (score: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) = (-1, 0, 0, 0)
let width = rep.pixelsWide, height = rep.pixelsHigh
for y in 0..<height {
    for x in 0..<width {
        guard let color = rep.colorAt(x: x, y: y) else { continue }
        let r = color.redComponent, g = color.greenComponent, b = color.blueComponent
        let score = g - max(r, b)
        if score > best.score { best = (score, r, g, b) }
    }
}

print(String(format: "最绿像素: R %.0f G %.0f B %.0f  (#%02X%02X%02X)",
             best.r * 255, best.g * 255, best.b * 255,
             Int(best.r * 255), Int(best.g * 255), Int(best.b * 255)))
