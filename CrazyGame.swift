//
//  CrazyGame.swift
//  留白 v1.1 · 抓狂棋子
//
//  点击棋子开始一局：棋子跳到菜单栏别的位置。
//  前 3 次点不中；第 4 次抓住，棋子摔倒 + 音效，然后切换菜单栏。
//
//  面板用非激活 NSPanel，层级高于菜单栏，只存在几秒。
//

import AppKit

final class ClickPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class PieceView: NSView {
    var image: NSImage?
    var rotation: CGFloat = 0
    var offsetY: CGFloat = 0
    var onClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) { onClick?() }
    override func rightMouseDown(with event: NSEvent) { onRightClick?() }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        guard let image else { return }
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: bounds.midX, y: bounds.midY + offsetY)
        ctx.rotate(by: rotation)
        let size = image.size
        image.draw(in: NSRect(x: -size.width / 2, y: -size.height / 2,
                              width: size.width, height: size.height),
                   from: .zero, operation: .sourceOver, fraction: 1)
        ctx.restoreGState()
    }
}

final class CrazyGame {
    private let panel: ClickPanel
    private let view: PieceView
    private let anchor: NSRect
    private let screen: NSScreen
    private let panelSize = NSSize(width: 32, height: 30)

    private var dodges = 0
    private var isAnimating = false
    private var isFinished = false
    private var jumpTimer: Timer?
    private var watchdog: Timer?

    var onCatch: (() -> Void)?
    var onCancel: (() -> Void)?
    var onSound: ((String) -> Void)?
    var onMenu: (() -> Void)?

    init(anchor: NSRect, screen: NSScreen, image: NSImage) {
        self.anchor = anchor
        self.screen = screen

        let height = max(24, anchor.height)
        let rect = NSRect(x: anchor.midX - panelSize.width / 2,
                          y: anchor.minY,
                          width: panelSize.width,
                          height: height)
        panel = ClickPanel(contentRect: rect,
                           styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered,
                           defer: false)
        view = PieceView(frame: NSRect(origin: .zero, size: rect.size))
        view.image = image
        view.wantsLayer = true
        panel.contentView = view
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = false
        panel.isMovable = false

        view.onClick = { [weak self] in self?.handleClick() }
        view.onRightClick = { [weak self] in self?.handleRightClick() }
    }

    func start() {
        NSLog("CrazyGame: start panel=\(panel.frame)")
        panel.orderFrontRegardless()
        let timer = Timer(timeInterval: 10, repeats: false) { [weak self] _ in
            self?.cancel()
        }
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
    }

    func close() {
        isFinished = true
        cleanup()
    }

    private func cleanup() {
        jumpTimer?.invalidate()
        jumpTimer = nil
        watchdog?.invalidate()
        watchdog = nil
        panel.orderOut(nil)
    }

    private func handleClick() {
        NSLog("CrazyGame: click dodges=\(dodges)")
        guard !isAnimating, !isFinished else { return }
        if dodges < 3 {
            dodges += 1
            jump()
        } else {
            catchPiece()
        }
    }

    private func handleRightClick() {
        guard !isFinished else { return }
        isFinished = true
        cleanup()
        onMenu?()
    }

    private func safeRange() -> ClosedRange<CGFloat> {
        var lower = max(screen.frame.minX + 40, anchor.midX - 180)
        let upper = min(screen.frame.maxX - 40, anchor.midX + 180)

        // 有刘海时，尽量待在刘海右侧。
        if let right = screen.auxiliaryTopRightArea, anchor.midX > right.midX {
            lower = max(lower, right.minX + 24)
        }
        return lower...max(lower, upper)
    }

    private func jump() {
        isAnimating = true
        let current = panel.frame
        let range = safeRange()
        var targetX = current.midX
        for _ in 0..<12 {
            let candidate = CGFloat.random(in: range)
            if abs(candidate - current.midX) > 70 {
                targetX = candidate
                break
            }
        }
        if abs(targetX - current.midX) < 30 {
            targetX = current.midX < range.lowerBound + (range.upperBound - range.lowerBound) / 2
                ? range.upperBound - 40 : range.lowerBound + 40
        }

        NSLog("CrazyGame: jump to \(Int(targetX))")
        let startX = current.midX
        let startY = current.minY
        let frames = 14
        var frame = 0
        let direction: CGFloat = targetX > startX ? -1 : 1

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            frame += 1
            let t = min(1, CGFloat(frame) / CGFloat(frames))
            let x = startX + (targetX - startX) * t
            let y = startY + sin(.pi * t) * 7
            self.panel.setFrameOrigin(NSPoint(x: x - self.panelSize.width / 2, y: y))
            self.view.rotation = sin(.pi * t) * 0.22 * direction
            self.view.needsDisplay = true
            if frame >= frames {
                timer.invalidate()
                self.jumpTimer = nil
                self.view.rotation = 0
                self.view.needsDisplay = true
                self.isAnimating = false
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        jumpTimer = timer
    }

    private func catchPiece() {
        NSLog("CrazyGame: catch")
        isAnimating = true
        isFinished = true
        watchdog?.invalidate()
        watchdog = nil
        onSound?("Glass")

        let frames = 26
        var frame = 0
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            frame += 1
            let t = min(1, CGFloat(frame) / CGFloat(frames))
            let rotation = -CGFloat.pi / 2 * min(1, t * 1.25)
            let drop = -9 * min(1, t * 1.25)
            let bounce: CGFloat = t > 0.82 ? sin((t - 0.82) / 0.18 * .pi) * 2.5 : 0
            self.view.rotation = rotation
            self.view.offsetY = drop + bounce
            self.view.needsDisplay = true
            if frame >= frames {
                timer.invalidate()
                self.jumpTimer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                    guard let self else { return }
                    self.cleanup()
                    self.onCatch?()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        jumpTimer = timer
    }

    private func cancel() {
        NSLog("CrazyGame: cancel")
        guard !isFinished else { return }
        isFinished = true
        cleanup()
        onCancel?()
    }
}
