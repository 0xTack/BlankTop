//
//  CrazyGame.swift
//  留白 v1.1 · 抓狂模式
//
//  点击棋子开始一局：棋子跳到菜单栏的空隙里。
//  前 3 次点不中；第 4 次抓住，棋子摔下菜单栏 + 音效，然后切换菜单栏。
//
//  落点只选图标之间的空隙，不压住别人的图标。
//  面板用非激活 NSPanel，层级高于菜单栏，只存在几秒。
//

import AppKit

final class ClickPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// 允许把面板放到屏幕上方（菜单栏外面），这样棋子才能真正「从上面掉下来」。
    /// 默认 AppKit 会把窗口夹回可见屏幕内。
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class PieceView: NSView {
    var image: NSImage?
    var rotation: CGFloat = 0
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var opacity: CGFloat = 1
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
        ctx.setAlpha(opacity)
        ctx.translateBy(x: bounds.midX, y: bounds.midY + offsetY)
        ctx.rotate(by: rotation)
        ctx.scaleBy(x: scaleX, y: scaleY)
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
    private let area: NSRect
    private let panelSize = NSSize(width: 26, height: 34)
    /// 棋子第一次出现的位置，最后被抓时回到这里落下。
    private let homeX: CGFloat

    private var dodges = 0
    private var isAnimating = false
    private var isFinished = false
    private var jumpTimer: Timer?
    private var watchdog: Timer?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onCatch: (() -> Void)?
    var onCancel: (() -> Void)?
    var onSound: ((String) -> Void)?
    var onMenu: (() -> Void)?

    init(area: NSRect, image: NSImage) {
        self.area = area
        self.homeX = area.midX

        let rect = NSRect(x: area.midX - panelSize.width / 2,
                          y: area.midY - panelSize.height / 2,
                          width: panelSize.width,
                          height: panelSize.height)
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
        btLog("CrazyGame: start panel=\(panel.frame)")
        panel.orderFrontRegardless()
        installClickTap()
        onSound?("chess-place")
        let timer = Timer(timeInterval: 10, repeats: false) { [weak self] _ in
            self?.cancel()
        }
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
        debugAutoplayIfNeeded()
    }

    /// 开发自测：BLANKTOP_CRAZY_AUTOPLAY=1 时自动跳三下再被抓。
    private func debugAutoplayIfNeeded() {
        guard ProcessInfo.processInfo.environment["BLANKTOP_CRAZY_AUTOPLAY"] == "1" else { return }
        var delay: TimeInterval = 0.7
        for _ in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.jump() }
            delay += 0.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.catchPiece() }
    }

    func close() {
        isFinished = true
        cleanup()
    }

    deinit {
        removeClickTap()
    }

    private func cleanup() {
        jumpTimer?.invalidate()
        jumpTimer = nil
        watchdog?.invalidate()
        watchdog = nil
        removeClickTap()
        panel.orderOut(nil)
    }

    // MARK: 点击拦截
    //
    // 菜单栏会先吃掉落在菜单栏区域里的点击，普通 NSPanel 收不到，
    // 所以用事件 tap 在系统分发之前截住棋子范围内的点击。

    private func installClickTap() {
        let mask = (CGEventMask(1) << CGEventType.leftMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.leftMouseUp.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseUp.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                          place: .headInsertEventTap,
                                          options: .defaultTap,
                                          eventsOfInterest: mask,
                                          callback: CrazyGame.tapCallback,
                                          userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            btLog("CrazyGame: click tap unavailable")
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        runLoopSource = source
    }

    private func removeClickTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private static let tapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let game = Unmanaged<CrazyGame>.fromOpaque(refcon).takeUnretainedValue()
        return game.handleTap(type: type, event: event)
    }

    private func handleTap(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        let interesting: [CGEventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp]
        guard interesting.contains(type) else {
            return Unmanaged.passUnretained(event)
        }

        let p = event.location
        let screen = panel.screen ?? NSScreen.main
        let cocoa = NSPoint(x: p.x, y: (screen?.frame.maxY ?? 1080) - p.y)
        if !panel.frame.contains(cocoa) {
            return Unmanaged.passUnretained(event)
        }
        // 摔倒动画期间不再响应，但仍然吃掉点击，别让菜单栏弹菜单
        guard !isFinished else { return nil }

        if type == .leftMouseDown {
            handleClick()
        } else if type == .rightMouseDown {
            handleRightClick()
        }
        return nil // 吃掉这次点击（按下和抬起都吃掉，避免菜单栏收到抬起事件后弹菜单）
    }

    private func handleClick() {
        btLog("CrazyGame: click dodges=\(dodges)")
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

    /// 开关撑宽后留出的空地，棋子只在这块区域里跳。
    private func safeRange() -> ClosedRange<CGFloat> {
        let half = panelSize.width / 2 + 6
        let lower = area.minX + half
        let upper = area.maxX - half
        return lower...max(lower, upper)
    }

    private func chooseTarget(from current: CGFloat) -> CGFloat {
        let range = safeRange()
        let span = range.upperBound - range.lowerBound
        guard span > 6 else { return range.lowerBound }
        let minMove = max(18, span * 0.35)
        for _ in 0..<24 {
            let x = CGFloat.random(in: range)
            if abs(x - current) > minMove { return x }
        }
        let mid = (range.lowerBound + range.upperBound) / 2
        return current < mid ? range.upperBound : range.lowerBound
    }

    private func jump() {
        isAnimating = true
        let current = panel.frame
        let targetX = chooseTarget(from: current.midX)

        btLog("CrazyGame: jump \(Int(current.midX)) -> \(Int(targetX))")
        let startX = current.midX
        let startY = current.minY
        let frames = 26
        var frame = 0
        let direction: CGFloat = targetX > startX ? -1 : 1

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            frame += 1
            let t = min(1, CGFloat(frame) / CGFloat(frames))
            let eased = t * t * (3 - 2 * t)
            let x = startX + (targetX - startX) * eased
            // 菜单栏在最上面，往上跳会被屏幕裁掉，所以只向下轻轻一沉
            let dip = -sin(.pi * t) * 5
            self.panel.setFrameOrigin(NSPoint(x: x - self.panelSize.width / 2,
                                              y: startY + dip))
            let air = sin(.pi * t)
            self.view.rotation = air * 0.20 * direction
            self.view.scaleX = 1 - 0.05 * air
            self.view.scaleY = 1 + 0.08 * air
            if t > 0.86 {
                let k = (t - 0.86) / 0.14
                self.view.scaleX = 1 + 0.12 * k
                self.view.scaleY = 1 - 0.18 * k
            }
            self.view.needsDisplay = true
            if frame >= frames {
                timer.invalidate()
                self.jumpTimer = nil
                self.panel.setFrameOrigin(NSPoint(x: targetX - self.panelSize.width / 2,
                                                  y: startY))
                self.view.rotation = 0
                self.view.scaleX = 1
                self.view.scaleY = 1
                self.view.needsDisplay = true
                self.isAnimating = false
                self.onSound?("chess-place")
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        jumpTimer = timer
    }

    private func catchPiece() {
        btLog("CrazyGame: catch")
        isAnimating = true
        isFinished = true
        watchdog?.invalidate()
        watchdog = nil

        let start = Date()
        let duration: TimeInterval = 1.25
        let restY = panel.frame.minY
        let dropHeight: CGFloat = 140
        var didLand = false
        var didShow = false

        // 先把面板藏起来，再挪到初始位置的正上方。
        // 这样不会出现「从左边滑回中间」的一帧。
        panel.orderOut(nil)
        var homeFrame = panel.frame
        homeFrame.origin.x = homeX - panelSize.width / 2
        homeFrame.origin.y = restY + dropHeight
        panel.setFrame(homeFrame, display: false)
        btLog("CrazyGame: catch start panel=\(panel.frame) homeX=\(homeX)")

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = Date().timeIntervalSince(start)
            var y = restY

            if elapsed < 0.22 {
                // 屏幕外，完全不可见
                self.view.opacity = 0
                y = restY + dropHeight
            } else if elapsed < 0.80 {
                if !didShow {
                    didShow = true
                    self.view.opacity = 0
                    self.panel.orderFrontRegardless()
                }
                // 从正上方垂直落下
                let p = (elapsed - 0.22) / 0.58
                let e = p * p
                y = restY + dropHeight * (1 - e)
                self.view.opacity = min(1, p * 5)
                self.view.rotation = -0.10 * (1 - p)
                self.view.scaleX = 1
                self.view.scaleY = 1.04
            } else if elapsed < 0.98 {
                // 落地压扁 + 落子声
                let p = (elapsed - 0.80) / 0.18
                y = restY
                self.view.rotation = 0
                self.view.scaleX = 1 + 0.14 * sin(.pi * p)
                self.view.scaleY = 1 - 0.18 * sin(.pi * p)
                self.view.opacity = 1
                if !didLand {
                    didLand = true
                    btLog("CrazyGame: catch landed panel=\(self.panel.frame)")
                    self.onSound?("chess-place")
                }
            } else {
                y = restY
                self.view.scaleX = 1
                self.view.scaleY = 1
            }

            var frame = self.panel.frame
            frame.origin.x = self.homeX - self.panelSize.width / 2
            frame.origin.y = y
            self.panel.setFrame(frame, display: false)
            self.view.needsDisplay = true

            if elapsed >= duration {
                timer.invalidate()
                self.jumpTimer = nil
                self.cleanup()
                self.onCatch?()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        jumpTimer = timer
    }

    private func cancel() {
        btLog("CrazyGame: cancel")
        guard !isFinished else { return }
        isFinished = true
        cleanup()
        onCancel?()
    }
}
