// 移动鼠标到指定坐标（用于判断高亮是不是 hover 引起的）。
import AppKit

let args = CommandLine.arguments
let x = args.count > 2 ? Double(args[1]) ?? 300 : 300
let y = args.count > 2 ? Double(args[2]) ?? 600 : 600
CGWarpMouseCursorPosition(CGPoint(x: x, y: y))
print("warped to \(x),\(y)")
