//
//  main.swift
//  BlankTop — 最小化的菜单栏折叠工具
//
//  箭头左边（LTR）的图标在折叠时被隐藏，箭头右边保持可见。
//  隐藏通过 macOS 27 的菜单栏白名单（MenuBarClientCore）实现，
//  需要「辅助功能」权限来读取其它 App 的图标位置。
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CryptoKit

// MARK: - 图标样式

enum IconStyle: String, CaseIterable {
    case chevron        // ‹ › 粗
    case chevronThin    // ‹ › 细
    case triangle       // ◀ ▶
    case toLine         // ⇤ ⇥
    case symbol         // SF Symbol 箭头
    case eye            // 眼睛：展开时「眼睛关闭」= 点了会藏
    case dot            // ● / ○ 实心表示有东西收着
    case bar            // 一条竖线，没有方向感
    case sidebar        // SF Symbol 侧边栏
    case tray           // 收纳盘，收起时装满
    case archive        // 归档盒
    case moon           // 月亮
    case stack          // 一叠卡片
    case compress       // 压缩 / 展开矩形
    case doubleChevron  // 双箭头
    case halfCircle     // 半圆填充
    case menubar        // 菜单栏图标本身
    case toggle         // 自绘开关

    var label: String {
        switch self {
        case .chevron: return "‹ ›  粗箭头"
        case .chevronThin: return "‹ ›  细箭头"
        case .triangle: return "◀ ▶  三角"
        case .toLine: return "⇤ ⇥  到边箭头"
        case .symbol: return "SF Symbol 箭头"
        case .eye: return "👁  眼睛（语义）"
        case .dot: return "● ○  圆点（状态）"
        case .bar: return "｜  竖线（无方向）"
        case .sidebar: return "▤  侧边栏图标"
        case .tray: return "📥  收纳盘（收起来装满）"
        case .archive: return "🗃  归档盒"
        case .moon: return "🌙  月亮"
        case .stack: return "🗂  一叠卡片"
        case .compress: return "⤡  压缩 / 展开"
        case .doubleChevron: return "« »  双箭头"
        case .halfCircle: return "◐  半圆"
        case .menubar: return "▬  菜单栏图标"
        case .toggle: return "◉—  开关（自绘）"
        }
    }

    var groupStart: Bool {
        switch self {
        case .eye, .tray, .menubar: return true
        default: return false
        }
    }
}

// MARK: - 配置

enum PlayMode: String {
    case manual
    case box
    case crazy

    var label: String {
        switch self {
        case .manual: return "手动（现有图标）"
        case .box: return "无聊盒子（10 秒自动合上）"
        case .crazy: return "抓狂棋子（点 3 次才抓得住）"
        }
    }
}

struct Config {
    var hotkeyText = "opt+cmd+h"
    var autoCollapseSeconds: Double = 10
    var icon = IconStyle.toggle.rawValue
    /// "manual"：原来的开关；"box"：无聊盒子；"crazy"：抓狂棋子
    var mode = PlayMode.box.rawValue
    /// "allowlist"：展开时只改白名单，不释放（交给系统一次过渡）
    /// "release"：展开时直接释放限制，整条菜单栏重建
    var expandMode = "allowlist"
    /// 折叠/展开时播放的系统音，`none` 表示静音
    var soundName = "tink"
    var soundVolume: Double = 0.12

    var hotKey: (keyCode: UInt32, modifiers: UInt32)? {
        ConfigStore.parseHotKey(hotkeyText)
    }

    var autoDelay: Double {
        autoCollapseSeconds > 0 ? autoCollapseSeconds : 10
    }
}

enum ConfigStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("BlankTop", isDirectory: true)
    }

    static var file: URL { directory.appendingPathComponent("config.json") }

    static func load() -> Config {
        var config = Config()
        guard let data = try? Data(contentsOf: file),
              let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return config
        }
        if let text = raw["hotkey"] as? String, parseHotKey(text) != nil { config.hotkeyText = text }
        if let seconds = raw["autoCollapseSeconds"] as? Double { config.autoCollapseSeconds = seconds }
        if let icon = raw["icon"] as? String, IconStyle(rawValue: icon) != nil { config.icon = icon }
        if let mode = raw["mode"] as? String {
            let migrated = (mode == "auto") ? PlayMode.box.rawValue : mode
            if PlayMode(rawValue: migrated) != nil { config.mode = migrated }
        }
        if let mode = raw["expandMode"] as? String, ["allowlist", "release"].contains(mode) { config.expandMode = mode }
        if let sound = raw["sound"] as? String { config.soundName = sound }
        if let volume = raw["soundVolume"] as? Double { config.soundVolume = volume }
        return config
    }

    static func save(_ config: Config) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let json: [String: Any] = [
            "hotkey": config.hotkeyText,
            "autoCollapseSeconds": config.autoCollapseSeconds,
            "icon": config.icon,
            "mode": config.mode,
            "expandMode": config.expandMode,
            "sound": config.soundName,
            "soundVolume": config.soundVolume
        ]
        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: file)
        }
    }

    static func writeDefaultIfMissing() {
        guard !FileManager.default.fileExists(atPath: file.path) else { return }
        save(Config())
    }

    // "opt+cmd+h" -> (keyCode, Carbon modifiers)
    static func parseHotKey(_ text: String) -> (UInt32, UInt32)? {
        var modifiers: UInt32 = 0
        var key: String?
        for part in text.lowercased().split(separator: "+").map(String.init) {
            switch part {
            case "opt", "option", "alt": modifiers |= UInt32(optionKey)
            case "cmd", "command": modifiers |= UInt32(cmdKey)
            case "shift": modifiers |= UInt32(shiftKey)
            case "ctrl", "control": modifiers |= UInt32(controlKey)
            default: key = part
            }
        }
        guard let key, let code = keyCodes[key] else { return nil }
        return (UInt32(code), modifiers)
    }

    private static let keyCodes: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
        "8": kVK_ANSI_8, "9": kVK_ANSI_9
    ]
}

// MARK: - 菜单栏扫描（辅助功能）

struct MenuBarItem {
    let bundleIdentifier: String?
    let pid: pid_t
    let frame: CGRect
}

enum MenuBarInventory {
    static var isAuthorized: Bool { AXIsProcessTrusted() }

    static func requestAuthorization() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 读取其它 App 的状态栏项。辅助功能往返较慢，放到后台线程。
    static func snapshot(completion: @escaping ([MenuBarItem]) -> Void) {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let apps: [(pid_t, String?)] = NSWorkspace.shared.runningApplications
            .filter { $0.processIdentifier != ownPID && $0.bundleURL?.pathExtension == "app" }
            .map { ($0.processIdentifier, $0.bundleIdentifier) }

        DispatchQueue.global(qos: .userInitiated).async {
            // 每个 App 的辅助功能查询互相独立，并发跑能把 60+ 个 App 的扫描
            // 从约 1 秒压到几十毫秒。
            var results = [[MenuBarItem]](repeating: [], count: apps.count)
            results.withUnsafeMutableBufferPointer { buffer in
                DispatchQueue.concurrentPerform(iterations: apps.count) { index in
                    buffer[index] = statusItems(of: apps[index].0, bundle: apps[index].1)
                }
            }
            DispatchQueue.main.async { completion(results.flatMap { $0 }) }
        }
    }

    private static func statusItems(of pid: pid_t, bundle: String?) -> [MenuBarItem] {
        var items: [MenuBarItem] = []
        let element = AXUIElementCreateApplication(pid)
        // 默认超时是数秒，一个卡住的 App 就会拖垮整次折叠。
        AXUIElementSetMessagingTimeout(element, 0.1)

        var barRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, "AXExtrasMenuBar" as CFString, &barRef) == .success,
              let barRef else { return items }
        let bar = barRef as! AXUIElement

        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(bar, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return items }

        for child in children {
            guard let frame = frame(of: child) else { continue }
            items.append(MenuBarItem(bundleIdentifier: bundle, pid: pid, frame: frame))
        }
        return items
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let positionRef, let sizeRef else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }
}

// MARK: - 应用主体

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let label = "com.xa.blanktop"

    private var statusItem: NSStatusItem!
    private var assertion: AnyObject?
    private var isCollapsed = false
    private var isBusy = false
    private var config = Config()
    private var playMode: PlayMode { PlayMode(rawValue: config.mode) ?? .manual }

    /// 上一次算出的分区，折叠时直接用，避免每次都扫一遍辅助功能。
    private var visibleBundles: [String] = []
    private var hiddenBundles: [String] = []
    private var hasScan = false
    private var scannedPIDs: Set<pid_t> = []
    private var didHintEmpty = false
    private var launchRefresh: DispatchWorkItem?
    private var rescanWorkItem: DispatchWorkItem?

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var autoTimer: Timer?
    private var boxAnimTimer: Timer?
    private var leverAngle: CGFloat = -42
    private var boxHandVisible = false
    private var isBoxBusy = false
    private var isAutoClosing = false
    private var crazyGame: CrazyGame?
    private var isCrazyGameActive = false
    private var didFinishLaunch = false
    private var didShowAccessibilityAlert = false

    private let launchAgentPath = ("~/Library/LaunchAgents/com.xa.blanktop.plist" as NSString).expandingTildeInPath

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 只允许一个实例：重复启动会让两个开关互相打架，点击看起来像“没反应”
        if let id = Bundle.main.bundleIdentifier {
            let me = ProcessInfo.processInfo.processIdentifier
            if let other = NSRunningApplication.runningApplications(withBundleIdentifier: id)
                .first(where: { $0.processIdentifier != me }) {
                NSLog("BlankTop: 已有实例在运行（pid \(other.processIdentifier)），本次启动退出")
                other.activate(options: [])
                NSApp.terminate(nil)
                return
            }
        }

        ConfigStore.writeDefaultIfMissing()
        config = ConfigStore.load()
        // 换签名/换二进制后，TCC 里旧记录会“勾着但不生效”，先清掉再让系统重新弹。
        resetStalePermissionIfNeeded()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // 去掉点击/悬停时系统画在图标后面的那层底板
            button.isBordered = false
        }
        leverAngle = isCollapsed ? -42 : 42
        applyIcon()

        installHotKey()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil)

        // 不在启动时弹系统授权框。用户真正点折叠时再说明一次，
        // 避免每次启动都“要权限”。
        if !MenuBarInventory.isAuthorized {
            NSLog("BlankTop: 辅助功能权限未生效，等用户操作时再提示")
        }

        if !Bundle.main.bundlePath.hasPrefix("/Applications/") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let notice = NSAlert()
                notice.messageText = "请把「留白」放到 /Applications"
                notice.informativeText = """
                系统的菜单栏白名单只对 /Applications 下的 App 生效。
                当前路径：\(Bundle.main.bundlePath)
                否则折叠时连它自己的箭头也会被藏起来。
                """
                notice.runModal()
            }
        }

        NSLog("BlankTop: started, native visibility available = \(HBNativeVisibilityIsAvailable()), accessibility trusted = \(MenuBarInventory.isAuthorized)")

        // 预览/截图用：open -a BlankTop --args --donate
        if CommandLine.arguments.contains("--donate") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showDonate()
            }
        }
        didFinishLaunch = true
    }

    func applicationWillTerminate(_ notification: Notification) {
        rescanWorkItem?.cancel()
        launchRefresh?.cancel()
        autoTimer?.invalidate()
        boxAnimTimer?.invalidate()
        crazyGame?.close()
        crazyGame = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        releaseAssertion()
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let hotKeyHandler { RemoveEventHandler(hotKeyHandler) }
    }

    // MARK: 交互

    @objc private func statusItemClicked() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            switch playMode {
            case .manual:
                toggle()
            case .box:
                boxPrimaryClick()
            case .crazy:
                startCrazyGame()
            }
        }
    }

    private var pendingToggle = false

    private func toggle() {
        // 正在扫描/切换时不要丢掉这次点击，等当前动作结束再补上
        if isBusy {
            pendingToggle = true
            return
        }
        if isCollapsed { expand() } else { collapse() }
    }

    private func runPendingToggleIfNeeded() {
        guard pendingToggle else { return }
        pendingToggle = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.toggle()
        }
    }

    // MARK: 无聊盒子（自动模式）

    private func boxPrimaryClick() {
        if isBoxBusy || isAutoClosing { return }
        // 倒计时中：点盒子不关，只让拨杆抖一下
        if !isCollapsed, autoTimer != nil {
            wiggleLever()
            return
        }
        boxToggle()
    }

    /// 自动模式的切换；热键和菜单也走这里。
    private func boxToggle() {
        guard !isBoxBusy, !isAutoClosing, !isBusy else { return }
        let wasCollapsed = isCollapsed
        toggle()
        waitForSettle { [weak self] in
            guard let self else { return }
            guard self.isCollapsed != wasCollapsed else {
                // 失败：如果本来该合上，过一会儿再试
                if !self.isCollapsed { self.armAutoTimer() }
                return
            }
            if self.isCollapsed {
                self.cancelAutoTimer()
                self.animateLever(on: false)
            } else {
                self.animateLever(on: true) { self.armAutoTimer() }
            }
        }
    }

    private func waitForSettle(_ completion: @escaping () -> Void,
                               deadline: Date? = nil) {
        let end = deadline ?? Date().addingTimeInterval(3)
        if !isBusy { completion(); return }
        if Date() >= end { completion(); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            self?.waitForSettle(completion, deadline: end)
        }
    }

    private func armAutoTimer() {
        cancelAutoTimer()
        let timer = Timer(timeInterval: config.autoDelay, repeats: false) { [weak self] _ in
            self?.autoTimer = nil
            self?.autoClose()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoTimer = timer
        NSLog("BlankTop: box auto close in \(config.autoDelay)s")
    }

    private func cancelAutoTimer() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    private func autoClose() {
        guard !isCollapsed, !isAutoClosing else { return }
        if isBusy || isBoxBusy {
            armAutoTimer()
            return
        }
        isAutoClosing = true
        // 小手先按在拨杆上，然后拨回去
        NSLog("BlankTop: auto close, box hand")
        boxHandVisible = true
        applyBoxIcon()

        let wasCollapsed = isCollapsed
        toggle()
        waitForSettle { [weak self] in
            guard let self else { return }
            guard self.isCollapsed != wasCollapsed else {
                self.boxHandVisible = false
                self.applyBoxIcon()
                self.isAutoClosing = false
                self.armAutoTimer()
                return
            }
            guard self.isCollapsed else {
                self.boxHandVisible = false
                self.applyBoxIcon()
                self.isAutoClosing = false
                return
            }
            self.animateLever(on: false) { [weak self] in
                guard let self else { return }
                self.boxHandVisible = false
                self.applyBoxIcon()
                self.isAutoClosing = false
            }
        }
    }

    private func wiggleLever() {
        guard !isBoxBusy else { return }
        isBoxBusy = true
        boxAnimTimer?.invalidate()
        let base = leverAngle
        var frame = 0
        let total = 8
        let timer = Timer(timeInterval: 0.025, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            frame += 1
            let wobble = sin(CGFloat(frame) / CGFloat(total) * .pi) * 7
            self.leverAngle = base + wobble
            self.applyBoxIcon()
            if frame >= total {
                timer.invalidate()
                self.boxAnimTimer = nil
                self.leverAngle = base
                self.isBoxBusy = false
                self.applyBoxIcon()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        boxAnimTimer = timer
    }

    private func animateLever(on: Bool, completion: (() -> Void)? = nil) {
        boxAnimTimer?.invalidate()
        isBoxBusy = true
        let start = leverAngle
        let target: CGFloat = on ? 42 : -42
        let overshoot: CGFloat = target + (on ? 12 : -12)
        var frame = 0
        let total = 12
        let timer = Timer(timeInterval: 0.028, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            frame += 1
            let t = min(1, CGFloat(frame) / CGFloat(total))
            let angle: CGFloat
            if t < 0.72 {
                let p = t / 0.72
                angle = start + (overshoot - start) * p
            } else {
                let p = (t - 0.72) / 0.28
                angle = overshoot + (target - overshoot) * p
            }
            self.leverAngle = angle
            self.applyBoxIcon()
            if frame >= total {
                timer.invalidate()
                self.boxAnimTimer = nil
                self.leverAngle = target
                self.isBoxBusy = false
                self.applyBoxIcon()
                completion?()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        boxAnimTimer = timer
    }

    private func handleHotKey() {
        switch playMode {
        case .manual:
            toggle()
        case .box:
            // 倒计时中热键仍然可以提前关
            if !isCollapsed { cancelAutoTimer() }
            boxToggle()
        case .crazy:
            if isCrazyGameActive {
                finishCrazyGame(toggle: true)
            } else {
                toggle()
            }
        }
    }

    // MARK: 抓狂棋子

    private func startCrazyGame() {
        guard !isCrazyGameActive, crazyGame == nil else { return }
        guard requestAccessibility() else { return }
        guard let anchor = statusItem.button?.window?.frame else { return }
        let center = NSPoint(x: anchor.midX, y: anchor.midY)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.main else { return }

        isCrazyGameActive = true
        statusItem.isVisible = false

        let game = CrazyGame(anchor: anchor, screen: screen, image: knightImage())
        game.onCatch = { [weak self] in self?.finishCrazyGame(toggle: true) }
        game.onCancel = { [weak self] in self?.finishCrazyGame(toggle: false) }
        game.onSound = { [weak self] name in self?.playCue(name) }
        game.onMenu = { [weak self] in
            self?.finishCrazyGame(toggle: false)
            self?.showMenu()
        }
        crazyGame = game
        game.start()
        NSLog("BlankTop: crazy game started")
    }

    private func finishCrazyGame(toggle doToggle: Bool) {
        guard isCrazyGameActive || crazyGame != nil else { return }
        crazyGame?.close()
        crazyGame = nil
        isCrazyGameActive = false
        statusItem.isVisible = true
        applyIcon()
        if doToggle { toggle() }
        NSLog("BlankTop: crazy game finished, toggle=\(doToggle)")
    }

    private func stopCrazyGame() {
        guard isCrazyGameActive || crazyGame != nil else { return }
        crazyGame?.close()
        crazyGame = nil
        isCrazyGameActive = false
        statusItem.isVisible = true
        NSLog("BlankTop: crazy game stopped")
    }

    private func playCue(_ name: String) {
        guard config.soundName != "none" else { return }
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard let sound = NSSound(contentsOf: url, byReference: true) else { return }
        sound.volume = 0.16
        activeSounds.append(sound)
        if activeSounds.count > 4 { activeSounds.removeFirst() }
        _ = sound.play()
    }

    private func showMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: isCollapsed ? "展开" : "折叠",
                                    action: #selector(menuToggle),
                                    keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        // 模式
        let playModeMenu = NSMenu()
        for mode in [PlayMode.manual, .box, .crazy] {
            let item = NSMenuItem(title: mode.label,
                                  action: #selector(menuSetPlayMode(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (playMode == mode) ? .on : .off
            playModeMenu.addItem(item)
        }
        let playModeItem = NSMenuItem(title: "模式", action: nil, keyEquivalent: "")
        playModeItem.submenu = playModeMenu
        menu.addItem(playModeItem)

        // 图标
        let iconMenu = NSMenu()
        for style in IconStyle.allCases {
            if style.groupStart { iconMenu.addItem(.separator()) }
            let item = NSMenuItem(title: style.label, action: #selector(menuSetIcon(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = (config.icon == style.rawValue) ? .on : .off
            iconMenu.addItem(item)
        }
        let iconItem = NSMenuItem(title: "图标", action: nil, keyEquivalent: "")
        iconItem.submenu = iconMenu
        iconItem.isEnabled = (playMode == .manual)
        menu.addItem(iconItem)

        // 展开方式
        let modeMenu = NSMenu()
        let modes: [(String, String)] = [
            ("allowlist", "白名单过渡（不重建菜单栏）"),
            ("release", "释放限制（整栏重建）")
        ]
        for (value, title) in modes {
            let item = NSMenuItem(title: title, action: #selector(menuSetExpandMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = (config.expandMode == value) ? .on : .off
            modeMenu.addItem(item)
        }
        let modeItem = NSMenuItem(title: "展开方式", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        let rescan = NSMenuItem(title: "重新扫描图标位置", action: #selector(menuRescan), keyEquivalent: "")
        rescan.target = self
        menu.addItem(rescan)

        menu.addItem(.separator())

        let soundItem = NSMenuItem(title: "音效",
                                   action: #selector(menuToggleSound),
                                   keyEquivalent: "")
        soundItem.target = self
        soundItem.state = (config.soundName == "none") ? .off : .on
        menu.addItem(soundItem)

        let login = NSMenuItem(title: "开机自启",
                               action: #selector(menuToggleLoginItem),
                               keyEquivalent: "")
        login.target = self
        login.state = FileManager.default.fileExists(atPath: launchAgentPath) ? .on : .off
        menu.addItem(login)

        let permission = NSMenuItem(title: "辅助功能权限…",
                                    action: #selector(menuOpenAccessibilitySettings),
                                    keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)

        menu.addItem(.separator())

        let donate = NSMenuItem(title: "请作者喝个咖啡 ☕",
                                action: #selector(menuDonate),
                                keyEquivalent: "")
        donate.target = self
        menu.addItem(donate)

        let quit = NSMenuItem(title: "退出 留白", action: #selector(menuQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuToggle() { handleHotKey() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    @objc private func menuSetPlayMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = PlayMode(rawValue: raw) else { return }
        config.mode = raw
        ConfigStore.save(config)
        cancelAutoTimer()
        boxHandVisible = false
        boxAnimTimer?.invalidate()
        boxAnimTimer = nil
        isBoxBusy = false
        isAutoClosing = false
        leverAngle = isCollapsed ? -42 : 42
        if mode != .crazy { stopCrazyGame() }
        applyIcon()
        if mode == .box, !isCollapsed, didFinishLaunch {
            armAutoTimer()
        }
    }

    @objc private func menuSetIcon(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let style = IconStyle(rawValue: raw) else { return }
        config.icon = style.rawValue
        ConfigStore.save(config)
        applyIcon()
    }

    @objc private func menuSetExpandMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? String else { return }
        config.expandMode = mode
        ConfigStore.save(config)
    }

    @objc private func menuRescan() {
        rescanLayout(force: true)
    }

    @objc private func menuOpenAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func menuToggleLoginItem() {
        setLoginItem(enabled: !FileManager.default.fileExists(atPath: launchAgentPath))
    }

    @objc private func menuToggleSound() {
        config.soundName = (config.soundName == "none") ? "tink" : "none"
        ConfigStore.save(config)
        if config.soundName != "none" { playSound(collapsing: false) }
    }

    // MARK: 赞赏

    private var donateWindow: NSWindow?

    @objc private func menuDonate() {
        showDonate()
    }

    func showDonate() {
        if let window = donateWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let width: CGFloat = 380
        let height: CGFloat = 470
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = "请作者喝个咖啡"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.white.cgColor

        let title = NSTextField(labelWithString: "请作者喝个咖啡 ☕")
        title.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        title.textColor = NSColor.black
        title.alignment = .center
        title.frame = NSRect(x: 0, y: height - 54, width: width, height: 26)
        content.addSubview(title)

        let subtitle = NSTextField(labelWithString: "如果这个小工具帮到了你，欢迎扫码支持一下")
        subtitle.font = NSFont.systemFont(ofSize: 12)
        subtitle.textColor = NSColor(white: 0.35, alpha: 1)
        subtitle.alignment = .center
        subtitle.frame = NSRect(x: 0, y: height - 78, width: width, height: 18)
        content.addSubview(subtitle)

        let imageView = NSImageView()
        imageView.image = donateImage()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.frame = NSRect(x: 40, y: 132, width: width - 80, height: 250)
        content.addSubview(imageView)

        let note = NSTextField(labelWithString: "感谢使用留白 · BlankTop")
        note.font = NSFont.systemFont(ofSize: 11)
        note.textColor = NSColor(white: 0.55, alpha: 1)
        note.alignment = .center
        note.frame = NSRect(x: 0, y: 96, width: width, height: 18)
        content.addSubview(note)

        window.contentView = content
        donateWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func donateImage() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "donate", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    // MARK: 音效

    private var activeSounds: [NSSound] = []

    /// 用独立的实例播放，避免共用缓存实例时 isPlaying 导致偶发没声音。
    private func playSound(collapsing: Bool) {
        guard config.soundName != "none" else { return }
        let file: String
        switch config.soundName {
        case "pop": file = "Pop"
        case "purr": file = "Purr"
        case "bottle": file = "Bottle"
        default: file = collapsing ? "Pop" : "Tink"
        }
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(file).aiff")
        guard let sound = NSSound(contentsOf: url, byReference: true) else {
            NSLog("BlankTop: 音效文件不可用 \(file)")
            return
        }
        sound.volume = Float(config.soundVolume)
        NSLog("BlankTop: sound \(file)")
        activeSounds.append(sound)
        if activeSounds.count > 4 { activeSounds.removeFirst() }

        if !sound.play() {
            // 输出设备刚切换、或上一声还没结束时会失败，稍后重试一次
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                _ = sound.play()
            }
        }
    }

    // MARK: 折叠 / 展开

    private func collapse() {
        guard !isBusy, !isCollapsed else { return }
        guard HBNativeVisibilityIsAvailable() else {
            alert("这台 macOS 上找不到可用的隐藏接口（MenuBarClientCore）。\n系统更新后该私有框架可能被改动。")
            return
        }
        guard requestAccessibility() else { return }

        // 每次折叠都重新读一遍位置：用户可能刚用 ⌘ 拖动过图标。
        guard let arrowFrame = statusItem.button?.window?.frame else { return }
        playSound(collapsing: true)
        isBusy = true
        let started = Date()
        MenuBarInventory.snapshot { [weak self] items in
            guard let self else { return }

            let hidden = Set(items.filter { $0.frame.midX < arrowFrame.midX }.compactMap { $0.bundleIdentifier })
            let all = Set(items.compactMap { $0.bundleIdentifier })
            self.hiddenBundles = Array(hidden)
            self.visibleBundles = Array(all.subtracting(hidden))
            self.hasScan = true
            self.scannedPIDs = Set(items.map { $0.pid })
            NSLog("BlankTop: scan \(items.count) items in \(Int(Date().timeIntervalSince(started) * 1000))ms")

            if ProcessInfo.processInfo.environment["MBF_DEBUG"] == "1" {
                NSLog("BlankTop: arrow@\(Int(arrowFrame.midX)) inventory " + items
                    .sorted { $0.frame.midX < $1.frame.midX }
                    .map { "\($0.bundleIdentifier ?? "?")@\(Int($0.frame.midX))" }
                    .joined(separator: " "))
            }
            // 系统白名单只认 /Applications 下的 App：可见区里若有别处的 App，
            // 折叠时它仍会被藏起来，这里提前告警。
            let outside = Array(all.subtracting(hidden))
                .filter { !$0.hasPrefix("com.apple.") && self.isOutsideApplications($0) }
            if !outside.isEmpty {
                NSLog("BlankTop: 这些 App 不在 /Applications，折叠时可能被误藏：\(outside.sorted())")
            }

            if hidden.isEmpty {
                self.hintNothingToHide()
            }

            self.activate(allowed: self.visibleBundles) { [weak self] ok in
                guard let self else { return }
                self.isBusy = false
                guard ok else { return }
                self.isCollapsed = true
                self.applyIcon()
                NSLog("BlankTop: collapsed, hid \(self.hiddenBundles.sorted())")
                self.runPendingToggleIfNeeded()
            }
        }
    }

    private func expand() {
        if isCollapsed { playSound(collapsing: false) }
        isBusy = true

        guard config.expandMode == "allowlist", hasScan, assertion != nil else {
            releaseAndMarkExpanded()
            NSLog("BlankTop: expanded (release)")
            return
        }

        // 折叠期间有新 App 启动时，它的图标是在限制生效的状态下创建的，
        // 只把它加进白名单系统也不会重新摆放——必须先释放一次再重建。
        if hasNewAppsSinceScan() {
            NSLog("BlankTop: 折叠期间有新 App 启动，重排一次白名单")
            releaseAssertion()
            // 注意：这里不能再判断 !isCollapsed —— 此刻状态还是「折叠中」，
            // 那样会直接 return，展开永远完不成（点几下都没反应）。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.finishAllowlistExpand()
            }
            return
        }

        // 常规情况：不释放限制，只把折叠区也加进白名单，
        // 系统一次过渡把图标放回来，不会整条菜单栏重建。
        finishAllowlistExpand()
    }

    private func releaseAndMarkExpanded() {
        releaseAssertion()
        isCollapsed = false
        isBusy = false
        applyIcon()
        runPendingToggleIfNeeded()
    }

    private func finishAllowlistExpand() {
        activate(allowed: allVisibleBundleIdentifiers()) { [weak self] ok in
            guard let self, ok else {
                self?.releaseAndMarkExpanded()
                return
            }
            self.isCollapsed = false
            self.isBusy = false
            self.applyIcon()
            NSLog("BlankTop: expanded (allowlist)")
            self.scheduleRescan()
            self.runPendingToggleIfNeeded()
        }
    }

    /// 折叠之后是否有新 App 启动（它们的图标是在限制生效时创建的）。
    private func hasNewAppsSinceScan() -> Bool {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.contains { app in
            guard app.bundleURL?.pathExtension == "app",
                  app.processIdentifier != ownPID else { return false }
            return !scannedPIDs.contains(app.processIdentifier)
        }
    }

    /// 展开状态下该放行的 App：已扫描到的可见/折叠区，加上此刻所有运行中的 App。
    private func allVisibleBundleIdentifiers() -> [String] {
        let running = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        return visibleBundles + hiddenBundles + running
    }

    /// 折叠期间、或展开状态下新启动的 App，需要重新提交一次白名单才看得见。
    private func refreshExpandedAllowListIfNeeded() {
        guard !isCollapsed, config.expandMode == "allowlist", assertion != nil, hasScan else { return }
        activate(allowed: allVisibleBundleIdentifiers()) { _ in }
        scheduleRescan()
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard !isCollapsed, config.expandMode == "allowlist", assertion != nil, hasScan else { return }
        launchRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refreshExpandedAllowListIfNeeded() }
        launchRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// 展开后等布局稳定，再把分区刷新一遍，保持和用户拖动后的顺序一致。
    private func scheduleRescan() {
        rescanWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isCollapsed, !self.isBusy else { return }
            self.rescanLayout(force: false)
        }
        rescanWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    private func rescanLayout(force: Bool) {
        guard !isCollapsed, !isBusy else { return }
        guard MenuBarInventory.isAuthorized else { return }
        guard let arrowFrame = statusItem.button?.window?.frame else { return }

        isBusy = true
        MenuBarInventory.snapshot { [weak self] items in
            guard let self else { return }
            self.isBusy = false
            let hidden = Set(items.filter { $0.frame.midX < arrowFrame.midX }.compactMap { $0.bundleIdentifier })
            let all = Set(items.compactMap { $0.bundleIdentifier })
            self.hiddenBundles = Array(hidden)
            self.visibleBundles = Array(all.subtracting(hidden))
            self.hasScan = true
            if force {
                NSLog("BlankTop: rescan -> visible \(self.visibleBundles.sorted()), hidden \(self.hiddenBundles.sorted())")
            }
        }
    }

    private func activate(allowed bundles: [String], completion: @escaping (Bool) -> Void) {
        var allowed = bundles
        if let own = Bundle.main.bundleIdentifier { allowed.append(own) }
        // 老式 Menu Extra（时间机器等）没有系统项 ID，显式放行以免被误藏。
        allowed.append("com.apple.systemuiserver")

        let systemItems = (0..<64).map { NSNumber(value: $0) }
        HBNativeVisibilityActivate(systemItems, allowed) { [weak self] assertion, error in
            guard let self else { return }
            guard let assertion else {
                NSLog("BlankTop: activation failed: \(error?.localizedDescription ?? "unknown")")
                self.alert("折叠失败：\(error?.localizedDescription ?? "未知错误")")
                completion(false)
                return
            }
            let old = self.assertion
            self.assertion = assertion as AnyObject
            old.map { HBNativeVisibilityInvalidate($0) }
            completion(true)
        }
    }

    private func releaseAssertion() {
        guard let assertion else { return }
        HBNativeVisibilityInvalidate(assertion)
        self.assertion = nil
    }

    /// 开关左边一个图标都没有时，折叠不会有任何效果，提示一次怎么用。
    private func hintNothingToHide() {
        guard !didHintEmpty else { return }
        didHintEmpty = true
        let hint = NSAlert()
        hint.messageText = "开关左边还没有图标"
        hint.informativeText = """
        折叠只会隐藏开关左边的图标。
        按住 ⌘ 把想隐藏的图标拖到开关左边，再点开关试试。
        """
        hint.addButton(withTitle: "知道了")
        hint.runModal()
    }

    // MARK: 图标

    private func applyBoxIcon() {
        guard let button = statusItem.button else { return }
        button.title = ""
        button.image = boxImage(leverAngle: leverAngle, hand: boxHandVisible)
        button.imagePosition = .imageOnly
    }

    /// 正面盒子 + 拨杆。拨杆角度 -42° = 关，+42° = 开。
    private func boxImage(leverAngle: CGFloat, hand: Bool) -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(logical.width * scale),
                                   pixelsHigh: Int(logical.height * scale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)

        let appearance = statusItem.button?.effectiveAppearance ?? NSApp.effectiveAppearance
        appearance.performAsCurrentDrawingAppearance {
            let line = NSColor.labelColor
            let on = leverAngle > 0
            let green = NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 1)
            let cream = NSColor(srgbRed: 0.96, green: 0.91, blue: 0.82, alpha: 1)
            let pink = NSColor(srgbRed: 0.91, green: 0.64, blue: 0.62, alpha: 1)
            let metal = NSColor(srgbRed: 0.79, green: 0.75, blue: 0.69, alpha: 1)

            // 盒体
            let body = NSBezierPath(roundedRect: NSRect(x: 3.0, y: 2.8, width: 14.0, height: 10.4),
                                    xRadius: 1.4, yRadius: 1.4)
            line.setStroke()
            body.lineWidth = 1.25
            body.stroke()

            // 盖子缝
            let lid = NSBezierPath()
            lid.move(to: NSPoint(x: 3.2, y: 11.9))
            lid.line(to: NSPoint(x: 16.8, y: 11.9))
            lid.lineWidth = 1.1
            lid.stroke()

            // 顶部胶带
            let tape = NSBezierPath(rect: NSRect(x: 9.2, y: 11.9, width: 1.6, height: 1.2))
            line.withAlphaComponent(0.55).setStroke()
            tape.lineWidth = 0.7
            tape.stroke()

            // 面单
            let label = NSBezierPath(roundedRect: NSRect(x: 4.2, y: 3.4, width: 3.0, height: 1.8),
                                     xRadius: 0.3, yRadius: 0.3)
            line.withAlphaComponent(0.55).setStroke()
            label.lineWidth = 0.6
            label.stroke()
            line.withAlphaComponent(0.35).setStroke()
            for y in [4.0, 4.5] as [CGFloat] {
                let l = NSBezierPath()
                l.move(to: NSPoint(x: 4.6, y: y))
                l.line(to: NSPoint(x: 6.8, y: y))
                l.lineWidth = 0.5
                l.stroke()
            }

            // 拨杆底座
            let base = NSBezierPath(roundedRect: NSRect(x: 7.0, y: 4.3, width: 6.0, height: 2.2),
                                    xRadius: 1.0, yRadius: 1.0)
            metal.setFill()
            base.fill()
            line.setStroke()
            base.lineWidth = 0.9
            base.stroke()

            // 指示灯
            let led = NSBezierPath(ovalIn: NSRect(x: 7.7, y: 4.9, width: 0.8, height: 0.8))
            (on ? green : line.withAlphaComponent(0.30)).setFill()
            led.fill()

            // 拨杆
            let pivot = NSPoint(x: 10.0, y: 5.7)
            let radians = leverAngle * .pi / 180
            let length: CGFloat = 4.6
            let tip = NSPoint(x: pivot.x + sin(radians) * length,
                              y: pivot.y + cos(radians) * length)
            let stick = NSBezierPath()
            stick.move(to: pivot)
            stick.line(to: tip)
            line.setStroke()
            stick.lineWidth = 1.7
            stick.lineCapStyle = .round
            stick.stroke()
            line.setFill()
            NSBezierPath(ovalIn: NSRect(x: pivot.x - 0.55, y: pivot.y - 0.55,
                                        width: 1.1, height: 1.1)).fill()

            // 球头
            let ball = NSBezierPath(ovalIn: NSRect(x: tip.x - 1.35, y: tip.y - 1.35,
                                                    width: 2.7, height: 2.7))
            (on ? green : line.withAlphaComponent(0.35)).setFill()
            ball.fill()
            line.setStroke()
            ball.lineWidth = 0.9
            ball.stroke()

            // 小手
            if hand {
                let start = NSPoint(x: 15.8, y: 13.6)
                let target = NSPoint(x: tip.x + 1.0, y: tip.y + 0.2)
                let arm = NSBezierPath()
                arm.move(to: start)
                arm.curve(to: NSPoint(x: target.x + 1.4, y: target.y + 1.3),
                          controlPoint1: NSPoint(x: 15.6, y: 12.2),
                          controlPoint2: NSPoint(x: target.x + 2.6, y: target.y + 3.0))
                line.setStroke()
                arm.lineWidth = 1.9
                arm.lineCapStyle = .round
                arm.stroke()
                cream.setStroke()
                arm.lineWidth = 1.2
                arm.stroke()

                let paw = NSBezierPath(roundedRect: NSRect(x: target.x - 1.3, y: target.y - 1.1,
                                                            width: 3.0, height: 2.4),
                                       xRadius: 1.1, yRadius: 1.1)
                cream.setFill()
                paw.fill()
                line.setStroke()
                paw.lineWidth = 0.55
                paw.stroke()
                pink.setFill()
                for dx in [-0.75, 0.0, 0.75] as [CGFloat] {
                    NSBezierPath(ovalIn: NSRect(x: target.x + dx - 0.28, y: target.y + 0.9,
                                                width: 0.56, height: 0.5)).fill()
                }
                NSBezierPath(ovalIn: NSRect(x: target.x - 0.5, y: target.y - 0.35,
                                            width: 1.0, height: 0.8)).fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    private func applyCrazyIcon() {
        guard let button = statusItem.button else { return }
        button.title = ""
        button.image = knightImage()
        button.imagePosition = .imageOnly
    }

    private func knightImage() -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(logical.width * scale),
                                   pixelsHigh: Int(logical.height * scale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)

        let appearance = statusItem.button?.effectiveAppearance ?? NSApp.effectiveAppearance
        appearance.performAsCurrentDrawingAppearance {
            let attr = NSAttributedString(string: "♞", attributes: [
                .font: NSFont.systemFont(ofSize: 21, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ])
            let s = attr.size()
            attr.draw(at: NSPoint(x: (20 - s.width) / 2, y: (20 - s.height) / 2))
        }
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    private func applyIcon() {
        guard let button = statusItem.button else { return }
        switch playMode {
        case .box:
            applyBoxIcon()
            return
        case .crazy:
            applyCrazyIcon()
            return
        case .manual:
            break
        }
        let style = IconStyle(rawValue: config.icon) ?? .chevron

        // 语义图标：展开时显示「点了会隐藏」，折叠时显示「点了会显示」
        var symbolName: String?
        switch style {
        case .symbol: symbolName = isCollapsed ? "chevron.right" : "chevron.left"
        case .eye: symbolName = isCollapsed ? "eye" : "eye.slash"
        case .sidebar: symbolName = isCollapsed ? "sidebar.right" : "sidebar.left"
        case .tray: symbolName = isCollapsed ? "tray.full.fill" : "tray"
        case .archive: symbolName = isCollapsed ? "archivebox.fill" : "archivebox"
        case .moon: symbolName = isCollapsed ? "moon.fill" : "moon"
        case .stack: symbolName = isCollapsed ? "square.stack.3d.up.fill" : "square.stack.3d.up"
        case .compress: symbolName = isCollapsed ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
        case .doubleChevron: symbolName = isCollapsed ? "chevron.right.2" : "chevron.left.2"
        case .halfCircle: symbolName = isCollapsed ? "circle.righthalf.filled" : "circle.lefthalf.filled"
        case .menubar: symbolName = "menubar.rectangle"
        default: break
        }

        if style == .toggle {
            button.title = ""
            button.image = toggleImage(on: !isCollapsed)
            button.imagePosition = .imageOnly
            return
        }

        if let symbolName {
            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)
            image?.isTemplate = true
            button.title = ""
            button.image = image
            button.imagePosition = .imageOnly
            return
        }

        button.image = nil
        switch style {
        case .chevron:
            button.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
            button.title = isCollapsed ? "›" : "‹"
        case .chevronThin:
            button.font = NSFont.systemFont(ofSize: 14, weight: .regular)
            button.title = isCollapsed ? "›" : "‹"
        case .triangle:
            button.font = NSFont.systemFont(ofSize: 9, weight: .bold)
            button.title = isCollapsed ? "▶" : "◀"
        case .toLine:
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.title = isCollapsed ? "⇥" : "⇤"
        case .dot:
            button.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            button.title = isCollapsed ? "●" : "○"
        case .bar:
            button.font = NSFont.systemFont(ofSize: 13, weight: .light)
            button.title = "❘"
        case .symbol, .eye, .sidebar, .tray, .archive, .moon, .stack,
             .compress, .doubleChevron, .halfCircle, .menubar, .toggle:
            break
        }
    }

    /// 自绘的 iPhone 风格开关：展开中 = 右（开，绿底板），折叠中 = 左（关，灰底板）。
    /// 颜色只铺在露出的那一半底板上，圆点保持深色。
    private func toggleImage(on: Bool) -> NSImage {
        let logical = NSSize(width: 20, height: 12)
        let scale: CGFloat = 2
        let width = logical.width * scale
        let height = logical.height * scale

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(width), pixelsHigh: Int(height),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        let inset: CGFloat = 0.75 * scale
        let radius = (height - inset * 2) / 2
        let track = NSBezierPath(roundedRect: NSRect(x: inset, y: inset,
                                                     width: width - inset * 2,
                                                     height: height - inset * 2),
                                 xRadius: radius, yRadius: radius)

        // 只在「露出」的那一半底板上着色；绿取自右侧那个圆环图标 (#79BC51)
        NSGraphicsContext.saveGraphicsState()
        track.addClip()
        let tint = on
            ? NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 0.62)
            : NSColor.black.withAlphaComponent(0.15)
        tint.setFill()
        let reveal = NSRect(x: on ? inset : width / 2,
                            y: inset,
                            width: width / 2 - inset,
                            height: height - inset * 2)
        reveal.fill()
        NSGraphicsContext.restoreGraphicsState()

        // 轨道描边：跟旁边的深色图标接近，不用纯黑
        NSColor.black.withAlphaComponent(0.78).setStroke()
        track.lineWidth = 1.2 * scale
        track.stroke()

        // 开关钮：小圆点
        let knob = 5.2 * scale
        let margin = 2.4 * scale
        let knobX = on ? width - margin - knob : margin
        NSColor.black.withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: NSRect(x: knobX, y: (height - knob) / 2,
                                    width: knob, height: knob)).fill()

        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    /// 系统白名单只对 /Applications 下的 App 生效。
    private func isOutsideApplications(_ bundleIdentifier: String) -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first,
              let url = app.bundleURL else { return false }
        return !url.path.hasPrefix("/Applications/")
    }

    // MARK: 快捷键

    private func installHotKey() {
        guard let hotKey = config.hotKey else { return }
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D424644), id: 1) // 'MBFD'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(hotKey.keyCode, hotKey.modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            NSLog("BlankTop: hotkey registration failed (\(status))")
            return
        }
        hotKeyRef = ref

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }
            var received = EventHotKeyID()
            let result = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &received)
            guard result == noErr, received.id == 1 else { return OSStatus(eventNotHandledErr) }
            DispatchQueue.main.async { AppDelegate.shared?.handleHotKey() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &hotKeyHandler)
    }

    static weak var shared: AppDelegate?

    // MARK: 开机自启

    private func setLoginItem(enabled: Bool) {
        let manager = FileManager.default
        if enabled {
            try? manager.createDirectory(atPath: (launchAgentPath as NSString).deletingLastPathComponent,
                                         withIntermediateDirectories: true)
            let plist: [String: Any] = [
                "Label": Self.label,
                "ProgramArguments": [Bundle.main.executablePath ?? ""],
                "RunAtLoad": true,
                "KeepAlive": false
            ]
            if let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
                try? data.write(to: URL(fileURLWithPath: launchAgentPath))
            }
        } else {
            try? manager.removeItem(atPath: launchAgentPath)
        }
    }


    /// 重新编译后签名会变，系统里那条旧的授权记录看着是勾上的，实际对新程序无效。
    /// 这里在检测到「换了二进制但权限没生效」时清掉旧记录，让系统的授权弹窗能真正起作用。
    private func resetStalePermissionIfNeeded() {
        guard !MenuBarInventory.isAuthorized else { return }
        guard let executable = Bundle.main.executableURL,
              let data = try? Data(contentsOf: executable) else { return }
        let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        let key = "binaryHash"
        let stored = UserDefaults.standard.string(forKey: key)

        // 同一个二进制且权限没生效：不要每次启动都重置，否则会一直弹。
        if let stored, stored == hash { return }

        NSLog("BlankTop: 检测到新版本且权限未生效，清除旧的授权记录")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "com.xa.blanktop"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            UserDefaults.standard.set(hash, forKey: key)
        }
    }

    // MARK: 提示

    /// 请求辅助功能授权，返回是否已授权。
    ///
    /// 不在启动时弹系统框，也不在每次点击时反复弹。每次启动最多说明一次，
    /// 之后用户自己去系统设置里勾选；勾选后下一次点击直接通过。
    @discardableResult
    private func requestAccessibility() -> Bool {
        if MenuBarInventory.isAuthorized { return true }
        guard !didShowAccessibilityAlert else { return false }
        didShowAccessibilityAlert = true

        let alert = NSAlert()
        alert.messageText = "需要「辅助功能」权限"
        alert.informativeText = """
        留白 需要读取其它 App 的菜单栏图标位置，才能判断哪些在箭头左边。

        打开「系统设置 → 隐私与安全性 → 辅助功能」：
        • 点「+」添加 /Applications/BlankTop.app
        • 如果列表里已经有旧的「留白」，先按「−」删掉，再添加新的

        添加并勾选后，回来再点一次即可，不需要重启。
        """
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        alert.window.level = .floating

        // 用户如果就在弹窗期间勾选，自动收起。
        let timer = Timer(timeInterval: 0.5, repeats: true) { timer in
            guard MenuBarInventory.isAuthorized else { return }
            timer.invalidate()
            alert.window.orderOut(nil)
            NSApp.abortModal()
        }
        RunLoop.main.add(timer, forMode: .common)
        let response = alert.runModal()
        timer.invalidate()

        if MenuBarInventory.isAuthorized { return true }
        if response == .alertFirstButtonReturn {
            menuOpenAccessibilitySettings()
        }
        return false
    }

    private func alert(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "留白 · BlankTop"
        alert.informativeText = text
        alert.runModal()
    }
}

// MARK: - 入口

let application = NSApplication.shared
let delegate = AppDelegate()
AppDelegate.shared = delegate
application.delegate = delegate
application.run()
