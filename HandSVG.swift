//
//  HandSVG.swift
//  留白 · 手势图标 SVG 路径
//
//  直接读取 potrace 生成的 SVG，把 d 里的路径转成 NSBezierPath，
//  这样图标本身是矢量，后续改 SVG 就能直接生效。
//

import AppKit

struct HandDrawing {
    let path: NSBezierPath
}

enum HandSVG {
    static func load(url: URL) -> HandDrawing? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        guard let d = firstCapture(text, pattern: "<path[^>]*d=\"([^\"]+)\""),
              let viewBoxText = firstCapture(text, pattern: "viewBox=\"([^\"]+)\"") else { return nil }

        let viewBox = viewBoxText.split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { Double($0) }
        guard viewBox.count == 4 else { return nil }
        let vbWidth = CGFloat(viewBox[2])
        let vbHeight = CGFloat(viewBox[3])
        guard vbWidth > 0, vbHeight > 0 else { return nil }

        let path = parsePath(d)
        guard !path.isEmpty else { return nil }

        // potrace 的 <g transform="translate(tx,ty) scale(sx,sy)">
        var tx: CGFloat = 0
        var ty: CGFloat = vbHeight
        var sx: CGFloat = 0.1
        var sy: CGFloat = -0.1
        if let transform = firstCapture(text, pattern: "transform=\"([^\"]+)\"") {
            if let t = firstTwoCaptures(transform, pattern: "translate\\(([-0-9.]+)[ ,]+([-0-9.]+)\\)"),
               let x = Double(t.0 ?? ""), let y = Double(t.1 ?? "") {
                tx = CGFloat(x); ty = CGFloat(y)
            }
            if let s = firstTwoCaptures(transform, pattern: "scale\\(([-0-9.]+)[ ,]+([-0-9.]+)\\)"),
               let x = Double(s.0 ?? ""), let y = Double(s.1 ?? "") {
                sx = CGFloat(x); sy = CGFloat(y)
            }
        }

        // 先应用 SVG 的 transform，再等比缩放到 20pt
        let svgTransform = AffineTransform(m11: sx, m12: 0, m21: 0, m22: sy, tX: tx, tY: ty)
        path.transform(using: svgTransform)

        let target: CGFloat = 20
        let scale = min(target / vbWidth, target / vbHeight)
        let offsetX = (target - vbWidth * scale) / 2
        let offsetY = (target - vbHeight * scale) / 2
        let fit = AffineTransform(m11: scale, m12: 0, m21: 0, m22: scale, tX: offsetX, tY: offsetY)
        path.transform(using: fit)
        // SVG 的 y 轴向下，NSImage 向上：翻转一次
        let flip = AffineTransform(m11: 1, m12: 0, m21: 0, m22: -1, tX: 0, tY: 20)
        path.transform(using: flip)
        return HandDrawing(path: path)
    }

    private static func firstCapture(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    // 返回两个捕获组
    private static func firstTwoCaptures(_ text: String, pattern: String) -> (String?, String?)? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 2 else { return nil }
        var a: String? = nil
        var b: String? = nil
        if let r = Range(match.range(at: 1), in: text) { a = String(text[r]) }
        if let r = Range(match.range(at: 2), in: text) { b = String(text[r]) }
        return (a, b)
    }

    private static func parsePath(_ d: String) -> NSBezierPath {
        var scanner = Scanner(d)
        let path = NSBezierPath()
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var command: Character? = nil

        while true {
            if let c = scanner.nextCommand() {
                command = c
            } else if command == nil {
                break
            }
            guard let c = command else { break }

            switch c {
            case "M", "m":
                guard let x = scanner.nextNumber(), let y = scanner.nextNumber() else { return path }
                if c == "m" { current.x += x; current.y += y } else { current = CGPoint(x: x, y: y) }
                path.move(to: current)
                subpathStart = current
                // 后面的坐标对是隐式 lineto
                while scanner.peekNumber() {
                    guard let lx = scanner.nextNumber(), let ly = scanner.nextNumber() else { break }
                    if c == "m" { current.x += lx; current.y += ly } else { current = CGPoint(x: lx, y: ly) }
                    path.line(to: current)
                }
                command = nil

            case "L", "l":
                while scanner.peekNumber() {
                    guard let x = scanner.nextNumber(), let y = scanner.nextNumber() else { break }
                    if c == "l" { current.x += x; current.y += y } else { current = CGPoint(x: x, y: y) }
                    path.line(to: current)
                }
                command = nil

            case "H", "h":
                while scanner.peekNumber() {
                    guard let x = scanner.nextNumber() else { break }
                    current.x = (c == "h") ? current.x + x : x
                    path.line(to: current)
                }
                command = nil

            case "V", "v":
                while scanner.peekNumber() {
                    guard let y = scanner.nextNumber() else { break }
                    current.y = (c == "v") ? current.y + y : y
                    path.line(to: current)
                }
                command = nil

            case "C", "c":
                while scanner.peekNumber() {
                    guard let x1 = scanner.nextNumber(), let y1 = scanner.nextNumber(),
                          let x2 = scanner.nextNumber(), let y2 = scanner.nextNumber(),
                          let x = scanner.nextNumber(), let y = scanner.nextNumber() else { break }
                    let c1 = (c == "c") ? CGPoint(x: current.x + x1, y: current.y + y1) : CGPoint(x: x1, y: y1)
                    let c2 = (c == "c") ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
                    let end = (c == "c") ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                    path.curve(to: end, controlPoint1: c1, controlPoint2: c2)
                    current = end
                }
                command = nil

            case "Z", "z":
                path.close()
                current = subpathStart
                command = nil

            default:
                command = nil
                return path
            }
        }
        return path
    }

    private struct Scanner {
        let chars: [Character]
        var index = 0

        init(_ text: String) { chars = Array(text) }

        private mutating func skipSeparators() {
            while index < chars.count {
                let c = chars[index]
                if c == " " || c == "," || c == "\n" || c == "\r" || c == "\t" { index += 1 } else { break }
            }
        }

        mutating func nextCommand() -> Character? {
            skipSeparators()
            guard index < chars.count, chars[index].isLetter else { return nil }
            let c = chars[index]
            index += 1
            return c
        }

        mutating func peekNumber() -> Bool {
            skipSeparators()
            guard index < chars.count else { return false }
            let c = chars[index]
            return c.isNumber || c == "-" || c == "+" || c == "."
        }

        mutating func nextNumber() -> CGFloat? {
            skipSeparators()
            let start = index
            guard index < chars.count else { return nil }
            if chars[index] == "-" || chars[index] == "+" { index += 1 }
            var hasDigit = false
            while index < chars.count, chars[index].isNumber {
                index += 1; hasDigit = true
            }
            if index < chars.count, chars[index] == "." {
                index += 1
                while index < chars.count, chars[index].isNumber {
                    index += 1; hasDigit = true
                }
            }
            if index < chars.count, chars[index] == "e" || chars[index] == "E" {
                index += 1
                if index < chars.count, chars[index] == "-" || chars[index] == "+" { index += 1 }
                while index < chars.count, chars[index].isNumber { index += 1 }
            }
            guard hasDigit, start < index else { return nil }
            return CGFloat(Double(String(chars[start..<index])) ?? 0)
        }
    }
}
