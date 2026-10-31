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

struct Config {
    var hotkeyText = "opt+cmd+h"
    var autoCollapseSeconds: Double = 0
    var icon = IconStyle.toggle.rawValue
    /// "allowlist"：展开时只改白名单，不释放（交给系统一次过渡）
    /// "release"：展开时直接释放限制，整条菜单栏重建
    var expandMode = "allowlist"
    /// 折叠/展开时播放的系统音，`none` 表示静音
    var soundName = "tink"
    var soundVolume: Double = 0.12

    var hotKey: (keyCode: UInt32, modifiers: UInt32)? {
        ConfigStore.parseHotKey(hotkeyText)
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
    private var autoCollapseTimer: Timer?

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

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // 去掉点击/悬停时系统画在图标后面的那层底板
            button.isBordered = false
        }
        applyIcon()

        installHotKey()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil)

        if !MenuBarInventory.isAuthorized {
            // 只弹系统自己的授权提示。自己的说明留到真正要折叠时再出现，
            // 免得启动时两个窗口叠在一起。
            MenuBarInventory.requestAuthorization()
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        rescanWorkItem?.cancel()
        launchRefresh?.cancel()
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
            toggle()
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

    private func showMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: isCollapsed ? "展开" : "折叠",
                                    action: #selector(menuToggle),
                                    keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

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

    @objc private func menuToggle() { toggle() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

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
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil

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

    private func applyIcon() {
        guard let button = statusItem.button else { return }
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
            DispatchQueue.main.async { AppDelegate.shared?.toggle() }
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

    // MARK: 提示

    /// 请求辅助功能授权，返回是否已授权。
    ///
    /// 系统不会在授权变化时通知进程，所以弹窗期间每 0.5 秒轮询一次：
    /// 用户去系统设置里勾选后，弹窗自动收起并继续，而不是等你关掉它再
    /// 重新点一次折叠。
    @discardableResult
    private func requestAccessibility() -> Bool {
        if MenuBarInventory.isAuthorized { return true }
        MenuBarInventory.requestAuthorization()

        let alert = NSAlert()
        alert.messageText = "需要「辅助功能」权限"
        alert.informativeText = """
        留白 需要读取其它 App 的菜单栏图标位置，才能判断哪些在箭头左边。
        请在「系统设置 → 隐私与安全性 → 辅助功能」里勾选「留白」。

        如果列表里已经有「留白」，先按「−」删掉再重新勾选：
        重新编译过的 App 会被系统当成另一个程序，旧的勾选不生效。
        """
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        alert.window.level = .floating

        // 模态循环只跑 .modalPanel 模式，定时器必须加进 .common 才会触发。
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
