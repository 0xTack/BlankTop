//
//  HandPress.swift
//  留白 v1.1 · 无聊盒子的「小手」
//
//  展开 10 秒后，从屏幕上方伸下一只手，按在开关上，
//  把开关按回去，再缩回屏幕外。
//
//  面板不接收鼠标、不激活 App，只负责画手。
//

import AppKit

final class PressPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class HandView: NSView {
    /// 0 = 正常，1 = 按下时压扁一点
    var squash: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        ctx.translateBy(x: center.x, y: center.y)
        ctx.scaleBy(x: 1 + squash * 0.10, y: 1 - squash * 0.10)
        ctx.translateBy(x: -center.x, y: -center.y)

        drawHand()
        ctx.restoreGState()
    }

    private func drawHand() {
        let outline = NSColor.black.withAlphaComponent(0.82)
        let cream = NSColor(srgbRed: 0.97, green: 0.93, blue: 0.86, alpha: 1)
        let shade = NSColor(srgbRed: 0.90, green: 0.84, blue: 0.75, alpha: 1)
        let pink = NSColor(srgbRed: 0.91, green: 0.64, blue: 0.62, alpha: 1)

        // 手掌
        let palm = NSBezierPath(roundedRect: NSRect(x: 4.5, y: 19.0, width: 21.0, height: 22.0),
                                xRadius: 7.0, yRadius: 7.0)
        // 食指，朝下
        let finger = NSBezierPath(roundedRect: NSRect(x: 10.0, y: 2.0, width: 10.0, height: 24.0),
                                  xRadius: 4.5, yRadius: 4.5)
        // 拇指，从左侧探出
        let thumb = NSBezierPath(ovalIn: NSRect(x: 1.8, y: 22.0, width: 8.0, height: 13.0))

        // 先画粗描边，再用填充盖住内侧，只留下外轮廓
        outline.setStroke()
        for path in [palm, finger, thumb] {
            path.lineWidth = 3.2
            path.stroke()
        }
        cream.setFill()
        for path in [palm, finger, thumb] {
            path.fill()
        }

        // 袖口
        let cuff = NSBezierPath(roundedRect: NSRect(x: 8.2, y: 40.0, width: 13.6, height: 7.2),
                                xRadius: 2.6, yRadius: 2.6)
        shade.setFill()
        cuff.fill()
        outline.setStroke()
        cuff.lineWidth = 1.1
        cuff.stroke()

        // 指节
        outline.withAlphaComponent(0.35).setStroke()
        for y in [10.5, 15.0] as [CGFloat] {
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 13.4, y: y))
            line.line(to: NSPoint(x: 16.6, y: y))
            line.lineWidth = 0.8
            line.stroke()
        }

        // 蜷起来的手指
        for (x, y, w, h) in [(17.5, 25.0, 6.0, 9.0),
                             (17.0, 20.5, 6.2, 4.2),
                             (16.6, 16.8, 5.8, 4.0)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
            let curl = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h),
                                    xRadius: 2.0, yRadius: 2.0)
            outline.withAlphaComponent(0.45).setStroke()
            curl.lineWidth = 0.8
            curl.stroke()
        }

        // 指甲
        pink.setFill()
        NSBezierPath(roundedRect: NSRect(x: 12.7, y: 3.2, width: 4.6, height: 3.2),
                     xRadius: 1.6, yRadius: 1.6).fill()
    }
}

final class HandPress {
    private let panel: PressPanel
    private let view: HandView
    private let startY: CGFloat
    private let pressY: CGFloat
    private var timer: Timer?
    private var startedAt = Date()
    private var phase = 0            // 0 下降，1 按住，2 收回
    private var didPress = false
    private var cancelled = false

    var onPress: (() -> Void)?
    var onFinish: (() -> Void)?

    init(anchor: NSRect, screen: NSScreen) {
        let size = NSSize(width: 30, height: 48)
        let x = anchor.midX - size.width / 2
        startY = screen.frame.maxY + 6
        pressY = anchor.midY - 2

        panel = PressPanel(contentRect: NSRect(x: x, y: startY, width: size.width, height: size.height),
                           styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered,
                           defer: false)
        view = HandView(frame: NSRect(origin: .zero, size: size))
        view.wantsLayer = true
        panel.contentView = view
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true
        panel.isMovable = false
    }

    func start() {
        startedAt = Date()
        panel.orderFrontRegardless()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.tick(timer)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func cancel() {
        cancelled = true
        timer?.invalidate()
        timer = nil
        panel.orderOut(nil)
    }

    private func tick(_ timer: Timer) {
        guard !cancelled else { timer.invalidate(); return }
        let elapsed = Date().timeIntervalSince(startedAt)

        switch phase {
        case 0:
            let t = min(1, elapsed / 0.26)
            let eased = t * t
            setHandY(startY + (pressY - startY) * eased)
            if t >= 1 {
                phase = 1
                startedAt = Date()
                view.squash = 1
                view.needsDisplay = true
                if !didPress {
                    didPress = true
                    onPress?()
                }
            }
        case 1:
            view.squash = 0.75
            view.needsDisplay = true
            if elapsed >= 0.12 {
                phase = 2
                startedAt = Date()
                view.squash = 0
                view.needsDisplay = true
            }
        default:
            let t = min(1, elapsed / 0.24)
            let eased = 1 - (1 - t) * (1 - t)
            setHandY(pressY + (startY - pressY) * eased)
            if t >= 1 {
                timer.invalidate()
                self.timer = nil
                panel.orderOut(nil)
                onFinish?()
            }
        }
    }

    private func setHandY(_ y: CGFloat) {
        var frame = panel.frame
        frame.origin.y = y
        panel.setFrame(frame, display: false)
    }
}
