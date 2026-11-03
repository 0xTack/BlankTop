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

// MARK: - 语言 / 日志

var appLanguage = "zh"

func t(_ zh: String) -> String {
    appLanguage == "en" ? (enStrings[zh] ?? zh) : zh
}

let enStrings: [String: String] = [
    "展开": "Expand",
    "折叠": "Collapse",
    "模式": "Mode",
    "图标": "Icon",
    "展开方式": "Expand Method",
    "重新扫描图标位置": "Rescan Icon Positions",
    "音效": "Sound",
    "开机自启": "Launch at Login",
    "辅助功能权限…": "Accessibility Permission…",
    "👏  有你真好": "👏  You are the best",
    "有你真好": "So glad to have you",
    "你真好看": "You look great",
    "今天的你，比昨天更好看": "You look even better today than yesterday",
    "你的品味，真的很在线": "Your taste is impeccable",
    "你一笑，天气都变好了": "Your smile makes the weather better",
    "你认真生活的样子，很迷人": "The way you live is charming",
    "你值得所有温柔和好运": "You deserve all the kindness and luck",
    "你一来，整个房间都亮了": "The room lights up when you walk in",
    "你的眼光，从来不会让人失望": "Your taste never disappoints",
    "你不仅好看，还很有眼光": "You're not just good-looking; you have great taste",
    "有你在，平凡的一天也会发光": "With you around, an ordinary day shines",
    "去爱发电支持": "Support on Afdian",
    "或 微信扫码": "or scan WeChat",
    "自愿赞赏 · 不换取任何功能或服务 · 不支持退款": "Voluntary tip · No features or services in return · Non-refundable",
    "关闭": "Close",
    "天气从未如此明媚": "The weather has never been so bright",
    "你这么好看，在犹豫什么": "You look so great. What are you waiting for?",
    "退出 BlankTop": "Quit BlankTop",
    "语言": "Language",
    "检查更新…": "Check for Updates…",
    "打开日志": "Open Log",
    "白名单过渡（不重建菜单栏）": "Allowlist transition (no rebuild)",
    "释放限制（整栏重建）": "Release assertion (full rebuild)",
    "开关": "Switch",
    "不看还看": "Peek",
    "无聊盒子": "Boring Box",
    "抓狂模式": "Crazy Mode",
    "决定权在自己": "You decide",
    "就是想看": "Just wants to look",
    "屏幕外的手永远多管闲事": "The hand off-screen always meddles",
    "别点，会发生未知情况": "Do not click. Unknown things will happen",

    "粗箭头": "Bold arrow",
    "细箭头": "Thin arrow",
    "三角": "Triangle",
    "到边箭头": "To edge",
    "SF Symbol 箭头": "SF Symbol arrow",
    "眼睛": "Eye",
    "圆点": "Dot",
    "竖线": "Vertical bar",
    "侧边栏图标": "Sidebar",
    "收纳盘": "Tray",
    "归档盒": "Archive box",
    "月亮": "Moon",
    "一叠卡片": "Stack",
    "压缩 / 展开": "Compress / expand",
    "双箭头": "Double chevron",
    "半圆": "Half circle",
    "菜单栏图标": "Menu bar",
    "混沌模式": "Chaos Mode",
    "自定义设置…": "Custom Settings…",
]

/// 长文本用：中文一套、英文一套，不塞进字典。
func tt(_ zh: String, _ en: String) -> String {
    appLanguage == "en" ? en : zh
}

// MARK: - 更新源

/// 检查更新用的仓库。换仓库只改这一行。
let repoSlug = "0xTack/BlankTop"
let releasesPageURL = URL(string: "https://github.com/\(repoSlug)/releases/latest")!
let latestReleaseAPI = URL(string: "https://api.github.com/repos/\(repoSlug)/releases/latest")!

var appVersion: String {
    (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
}

let logFileURL = FileManager.default
    .urls(for: .libraryDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Logs", isDirectory: true)
    .appendingPathComponent("BlankTop.log")

func btLog(_ message: String) {
    NSLog("%@", message)
    let dir = logFileURL.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let line = ISO8601DateFormatter().string(from: Date()) + " " + message + "\n"
    guard let data = line.data(using: .utf8) else { return }
    if let handle = try? FileHandle(forWritingTo: logFileURL) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    } else {
        try? data.write(to: logFileURL)
    }
}


// MARK: - 模式说明气泡

final class ModeHintPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class ModeHintView: NSView {
    private let text: String

    init(text: String) {
        self.text = text
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let bg = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                              xRadius: 6, yRadius: 6)
        NSColor(calibratedWhite: 0.97, alpha: 0.93).setFill()
        bg.fill()
        NSColor(calibratedWhite: 0.0, alpha: 0.07).setStroke()
        bg.lineWidth = 1
        bg.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(calibratedWhite: 0.26, alpha: 0.72)
        ]
        let string = NSAttributedString(string: text, attributes: attrs)
        let size = string.size()
        string.draw(at: NSPoint(x: (bounds.width - size.width) / 2,
                                y: (bounds.height - size.height) / 2))
    }
}

// MARK: - 配置

enum PlayMode: String {
    case manual
    case peek
    case box
    case crazy
    case custom

    var label: String {
        switch self {
        case .manual: return "开关"
        case .peek: return "不看还看"
        case .box: return "无聊盒子"
        case .crazy: return "抓狂模式"
        case .custom: return "混沌模式"
        }
    }

    var hint: String {
        switch self {
        case .manual: return "决定权在自己"
        case .peek: return "就是想看"
        case .box: return "屏幕外的手永远多管闲事"
        case .crazy: return "别点，会发生未知情况"
        case .custom: return "自己的规则"
        }
    }
}

struct Config {
    var hotkeyText = "opt+cmd+h"
    var autoCollapseSeconds: Double = 10
    var icon = IconStyle.toggle.rawValue
    /// "manual"：原来的开关；"peek"：不看还看；"box"：无聊盒子；"crazy"：抓狂棋子
    var mode = PlayMode.peek.rawValue
    /// "allowlist"：展开时只改白名单，不释放（交给系统一次过渡）
    /// "release"：展开时直接释放限制，整条菜单栏重建
    var expandMode = "allowlist"
    /// 折叠/展开时播放的系统音，`none` 表示静音
    var soundName = "tink"
    var soundVolume: Double = 0.12
    /// "zh" / "en"
    var language = "zh"
    var custom = CustomSettings()

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
        if let language = raw["language"] as? String, ["zh", "en"].contains(language) {
            config.language = language
        }
        if let custom = raw["custom"] as? [String: Any] {
            config.custom = CustomSettings(json: custom)
        }
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
            "soundVolume": config.soundVolume,
            "language": config.language,
            "custom": config.custom.json
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

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
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
    private var peekCover: CGFloat = 0
    private var peekAnimTimer: Timer?
    private var peekOpenImage: NSImage?
    private var peekClosedImage: NSImage?
    private var peekOpenPath: HandDrawing?
    private var peekClosedPath: HandDrawing?
    private var hintTimer: Timer?
    private var hintPanel: NSPanel?
    private var handPress: HandPress?
    private var isAutoClosing = false
    private var crazyGame: CrazyGame?
    private var isCrazyGameActive = false
    private var didFinishLaunch = false
    private var didShowAccessibilityAlert = false
    private var isCheckingUpdates = false
    private let customWindow = CustomModeWindow()
    private var customImageCache: [String: NSImage] = [:]
    private var customLastCollapsed: Bool?
    private var customAnimTimer: Timer?
    private var customTimer: Timer?
    private var appearanceObservation: NSKeyValueObservation?
    private var barWatchTimer: Timer?
    private var lastBarDark: Bool?

    private let launchAgentPath = ("~/Library/LaunchAgents/com.xa.blanktop.plist" as NSString).expandingTildeInPath

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 只允许一个实例：重复启动会让两个开关互相打架，点击看起来像“没反应”
        if let id = Bundle.main.bundleIdentifier {
            let me = ProcessInfo.processInfo.processIdentifier
            if let other = NSRunningApplication.runningApplications(withBundleIdentifier: id)
                .first(where: { $0.processIdentifier != me }) {
                btLog("BlankTop: 已有实例在运行（pid \(other.processIdentifier)），本次启动退出")
                other.activate(options: [])
                NSApp.terminate(nil)
                return
            }
        }

        ConfigStore.writeDefaultIfMissing()
        config = ConfigStore.load()
        appLanguage = config.language
        peekOpenImage = Bundle.main.url(forResource: "hand-open", withExtension: "pdf")
            .flatMap { NSImage(contentsOf: $0) }
        peekClosedImage = Bundle.main.url(forResource: "hand-closed", withExtension: "pdf")
            .flatMap { NSImage(contentsOf: $0) }
        peekOpenPath = Bundle.main.url(forResource: "hand-open", withExtension: "svg")
            .flatMap { HandSVG.load(url: $0) }
        peekClosedPath = Bundle.main.url(forResource: "hand-closed", withExtension: "svg")
            .flatMap { HandSVG.load(url: $0) }
        PeekIcons.load()
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
        applyIcon()

        installHotKey()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil)

        // 深浅色切换后重绘自绘开关（深色下要用白色轮廓）
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main) { [weak self] _ in
                self?.applyIcon()
            }

        // 不在启动时弹系统授权框。用户真正点折叠时再说明一次，
        // 避免每次启动都“要权限”。
        if !MenuBarInventory.isAuthorized {
            btLog("BlankTop: 辅助功能权限未生效，等用户操作时再提示")
        }

        if !Bundle.main.bundlePath.hasPrefix("/Applications/"),
           ProcessInfo.processInfo.environment["BLANKTOP_SKIP_PATH_ALERT"] != "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let notice = NSAlert()
                notice.messageText = tt("请把 BlankTop 放到 /Applications",
                                        "Please move BlankTop to /Applications")
                notice.informativeText = tt("""
                系统的菜单栏白名单只对 /Applications 下的 App 生效。
                当前路径：\(Bundle.main.bundlePath)
                否则折叠时连它自己的箭头也会被藏起来。
                """, """
                The menu bar allowlist only applies to apps in /Applications.
                Current path: \(Bundle.main.bundlePath)
                Otherwise its own arrow can be hidden when collapsing.
                """)
                notice.runModal()
            }
        }

        btLog("BlankTop: started, native visibility available = \(HBNativeVisibilityIsAvailable()), accessibility trusted = \(MenuBarInventory.isAuthorized)")

        // 开发预览用：BLANKTOP_PREVIEW_DONATE=1 启动时直接打开赞赏窗口，便于截图。
        // 正常启动（Dock/Finder/开机自启）不会设置这个变量，因此不会弹窗。
        if ProcessInfo.processInfo.environment["BLANKTOP_PREVIEW_CUSTOM"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.menuCustomSettings()
            }
        }

        if ProcessInfo.processInfo.environment["BLANKTOP_PREVIEW_DONATE"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showDonate()
            }
        }
        didFinishLaunch = true
        armCustomTimerIfNeeded()
        startBarAppearanceWatch()

        // 启动时如果已经是展开状态，也要开始倒计时；以前只有手动点开后才计时。
        if (playMode == .peek || playMode == .box), !isCollapsed {
            armAutoTimer()
            btLog("BlankTop: auto timer armed at launch")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        rescanWorkItem?.cancel()
        launchRefresh?.cancel()
        autoTimer?.invalidate()
        peekAnimTimer?.invalidate()
        peekAnimTimer = nil
        cancelModeHint()
        handPress?.cancel()
        handPress = nil
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
            case .peek:
                peekPrimaryClick()
            case .box:
                boxPrimaryClick()
            case .crazy:
                startCrazyGame()
            case .custom:
                toggle()
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
        boxToggle()
    }

    /// 自动模式的切换；热键和菜单也走这里。
    private func boxToggle() {
        guard !isAutoClosing else { return }
        let wasCollapsed = isCollapsed
        cancelAutoTimer()
        toggle()
        waitForSettle { [weak self] in
            guard let self else { return }
            guard self.isCollapsed != wasCollapsed else {
                // 失败：如果还开着，继续等下一次
                if !self.isCollapsed { self.armAutoTimer() }
                return
            }
            if self.isCollapsed {
                self.cancelAutoTimer()
            } else {
                self.armAutoTimer()
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
        btLog("BlankTop: box auto close in \(config.autoDelay)s")
    }

    private func cancelAutoTimer() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    /// 到点后从屏幕上方伸出一只手，按在开关上，把开关按回去。
    private func autoClose() {
        if playMode == .peek {
            peekAutoClose()
            return
        }
        guard !isCollapsed, !isAutoClosing, handPress == nil else { return }
        if isBusy {
            armAutoTimer()
            return
        }
        guard let anchor = statusItem.button?.window?.frame else { return }
        let center = NSPoint(x: anchor.midX, y: anchor.midY)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.main else { return }

        isAutoClosing = true
        btLog("BlankTop: auto close, hand press")

        let hand = HandPress(anchor: anchor, screen: screen)
        handPress = hand
        hand.onPress = { [weak self] in
            guard let self, !self.isCollapsed else { return }
            self.toggle()
        }
        hand.onFinish = { [weak self] in
            guard let self else { return }
            self.handPress = nil
            self.isAutoClosing = false
            if !self.isCollapsed {
                self.armAutoTimer()
            }
        }
        hand.start()
    }

    private func cancelHandPress() {
        handPress?.cancel()
        handPress = nil
        isAutoClosing = false
    }

    // MARK: 不看还看（手遮眼）

    private func peekPrimaryClick() {
        peekToggle()
    }

    private func peekToggle() {
        guard !isAutoClosing else { return }
        let wasCollapsed = isCollapsed
        cancelAutoTimer()
        if wasCollapsed {
            peekCover = 0
            applyIcon()
        }
        toggle()
        waitForSettle { [weak self] in
            guard let self else { return }
            guard self.isCollapsed != wasCollapsed else {
                self.peekCover = self.isCollapsed ? 1 : 0
                self.applyIcon()
                if !self.isCollapsed { self.armAutoTimer() }
                return
            }
            if self.isCollapsed {
                self.peekCover = 1
                self.applyIcon()
            } else {
                self.peekCover = 0
                self.applyIcon()
                self.armAutoTimer()
            }
        }
    }

    /// 到点后直接合眼，随菜单栏一起收起。
    private func peekAutoClose() {
        guard !isCollapsed, !isAutoClosing else { return }
        if isBusy {
            armAutoTimer()
            return
        }
        isAutoClosing = true
        cancelAutoTimer()
        btLog("BlankTop: peek auto close")

        peekCover = 1
        applyIcon()
        let wasCollapsed = isCollapsed
        toggle()
        waitForSettle { [weak self] in
            guard let self else { return }
            guard self.isCollapsed != wasCollapsed else {
                self.isAutoClosing = false
                self.peekCover = 0
                self.applyIcon()
                self.armAutoTimer()
                return
            }
            self.isAutoClosing = false
            self.peekCover = self.isCollapsed ? 1 : 0
            self.applyIcon()
        }
    }

    private func animatePeekCover(to target: CGFloat, duration: TimeInterval,
                                  completion: (() -> Void)? = nil) {
        peekAnimTimer?.invalidate()
        let start = peekCover
        let started = Date()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let t = min(1, Date().timeIntervalSince(started) / duration)
            let eased = t * t * (3 - 2 * t)
            self.peekCover = start + (target - start) * eased
            self.applyIcon()
            if t >= 1 {
                timer.invalidate()
                self.peekAnimTimer = nil
                completion?()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        peekAnimTimer = timer
    }

    private func handleHotKey() {
        switch playMode {
        case .manual:
            toggle()
        case .peek:
            if !isCollapsed { cancelAutoTimer() }
            peekToggle()
        case .box:
            // 倒计时中热键仍然可以提前关
            if !isCollapsed { cancelAutoTimer() }
            boxToggle()
        case .custom:
            toggle()
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

        isCrazyGameActive = true
        // 把开关撑宽成一块空地：其它图标被挤到两边，棋子就在这块空地里跳。
        statusItem.length = 120
        setStatusIconHidden(true)

        // 等菜单栏把图标挤开、状态项的宽度稳定下来，再量它的位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
            guard let self, self.isCrazyGameActive, self.crazyGame == nil else { return }
            guard let area = self.statusItem.button?.window?.frame, area.width > 40 else {
                self.stopCrazyGame()
                return
            }

            let game = CrazyGame(area: area, image: self.knightImage())
            game.onCatch = { [weak self] in self?.finishCrazyGame(toggle: true) }
            game.onCancel = { [weak self] in self?.finishCrazyGame(toggle: false) }
            game.onSound = { [weak self] name in self?.playCue(name) }
            game.onMenu = { [weak self] in
                self?.finishCrazyGame(toggle: false)
                self?.showMenu()
            }
            self.crazyGame = game
            game.start()
            btLog("BlankTop: crazy game started, area=\(area)")
        }
    }

    private func finishCrazyGame(toggle doToggle: Bool) {
        guard isCrazyGameActive || crazyGame != nil else { return }
        crazyGame?.close()
        crazyGame = nil
        isCrazyGameActive = false
        statusItem.length = NSStatusItem.variableLength
        btLog("BlankTop: status item frame=\(statusItem.button?.window?.frame ?? .zero)")
        setStatusIconHidden(false)
        if doToggle { toggle() }
        btLog("BlankTop: crazy game finished, toggle=\(doToggle)")
    }

    private func stopCrazyGame() {
        guard isCrazyGameActive || crazyGame != nil else { return }
        crazyGame?.close()
        crazyGame = nil
        isCrazyGameActive = false
        statusItem.length = NSStatusItem.variableLength
        btLog("BlankTop: status item frame=\(statusItem.button?.window?.frame ?? .zero)")
        setStatusIconHidden(false)
        btLog("BlankTop: crazy game stopped")
    }

    private func playCue(_ name: String) {
        guard config.soundName != "none" else { return }
        if Bundle.main.url(forResource: name, withExtension: "wav") != nil {
            playBundledSound(name)
            return
        }
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard let sound = NSSound(contentsOf: url, byReference: true) else { return }
        sound.volume = 0.16
        activeSounds.append(sound)
        if activeSounds.count > 4 { activeSounds.removeFirst() }
        _ = sound.play()
    }

    private func playBundledSound(_ name: String, volume: Double? = nil) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            btLog("BlankTop: 缺少音效 \(name).wav")
            return
        }
        guard let sound = NSSound(contentsOf: url, byReference: false) else { return }
        sound.volume = Float((volume ?? config.soundVolume) * 0.6)
        btLog("BlankTop: sound \(name)")
        activeSounds.append(sound)
        if activeSounds.count > 4 { activeSounds.removeFirst() }
        if !sound.play() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { _ = sound.play() }
        }
    }

    private func showMenu() {
        cancelModeHint()
        let menu = NSMenu()
        menu.delegate = self

        let toggleItem = NSMenuItem(title: t(isCollapsed ? "展开" : "折叠"),
                                    action: #selector(menuToggle),
                                    keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        // 模式
        let playModeMenu = NSMenu()
        playModeMenu.delegate = self
        for mode in [PlayMode.manual, .peek, .box, .crazy, .custom] {
            let item = NSMenuItem(title: t(mode.label),
                                  action: #selector(menuSetPlayMode(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (playMode == mode) ? .on : .off
            playModeMenu.addItem(item)
        }
        let playModeItem = NSMenuItem(title: t("模式"), action: nil, keyEquivalent: "")
        playModeItem.submenu = playModeMenu
        menu.addItem(playModeItem)

        // 图标
        let iconMenu = NSMenu()
        for style in IconStyle.allCases {
            let item = NSMenuItem(title: t(style.label), action: #selector(menuSetIcon(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = (config.icon == style.rawValue) ? .on : .off
            item.image = IconRenderer.image(style: style, collapsed: false, size: 22)
            // macOS 27 默认会隐藏菜单项里的图片，这里显式要求显示。
            if #available(macOS 27.0, *) {
                item.preferredImageVisibility = .visible
            }
            iconMenu.addItem(item)
        }
        let iconItem = NSMenuItem(title: t("图标"), action: nil, keyEquivalent: "")
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
            let item = NSMenuItem(title: t(title), action: #selector(menuSetExpandMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = (config.expandMode == value) ? .on : .off
            modeMenu.addItem(item)
        }
        let modeItem = NSMenuItem(title: t("展开方式"), action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        let rescan = NSMenuItem(title: t("重新扫描图标位置"), action: #selector(menuRescan), keyEquivalent: "")
        rescan.target = self
        menu.addItem(rescan)

        menu.addItem(.separator())

        let soundItem = NSMenuItem(title: t("音效"),
                                   action: #selector(menuToggleSound),
                                   keyEquivalent: "")
        soundItem.target = self
        soundItem.state = (config.soundName == "none") ? .off : .on
        menu.addItem(soundItem)

        let login = NSMenuItem(title: t("开机自启"),
                               action: #selector(menuToggleLoginItem),
                               keyEquivalent: "")
        login.target = self
        login.state = FileManager.default.fileExists(atPath: launchAgentPath) ? .on : .off
        menu.addItem(login)

        let permission = NSMenuItem(title: t("辅助功能权限…"),
                                    action: #selector(menuOpenAccessibilitySettings),
                                    keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)

        // 语言
        let languageMenu = NSMenu()
        for (value, title) in [("zh", "中文"), ("en", "English")] {
            let item = NSMenuItem(title: title, action: #selector(menuSetLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = (config.language == value) ? .on : .off
            languageMenu.addItem(item)
        }
        let languageItem = NSMenuItem(title: t("语言"), action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        let donate = NSMenuItem(title: t("👏  有你真好"),
                                action: #selector(menuDonate),
                                keyEquivalent: "")
        donate.target = self
        menu.addItem(donate)

        menu.addItem(.separator())

        let checkUpdates = NSMenuItem(title: t("检查更新…"),
                                      action: #selector(menuCheckForUpdates),
                                      keyEquivalent: "")
        checkUpdates.target = self
        menu.addItem(checkUpdates)

        let openLog = NSMenuItem(title: t("打开日志"),
                                 action: #selector(menuOpenLog),
                                 keyEquivalent: "")
        openLog.target = self
        menu.addItem(openLog)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: t("退出 BlankTop"), action: #selector(menuQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: 模式说明

    func menuDidClose(_ menu: NSMenu) {
        cancelModeHint()
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        cancelModeHint()
        guard let raw = item?.representedObject as? String,
              let mode = PlayMode(rawValue: raw) else { return }
        scheduleModeHint(t(mode.hint))
    }

    private func scheduleModeHint(_ text: String) {
        let timer = Timer(timeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.hintTimer = nil
            self?.showModeHint(text)
        }
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.add(timer, forMode: .eventTracking)
        hintTimer = timer
    }

    private func cancelModeHint() {
        hintTimer?.invalidate()
        hintTimer = nil
        hintPanel?.orderOut(nil)
        hintPanel = nil
    }

    private func showModeHint(_ text: String) {
        guard hintPanel == nil else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular)
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let size = NSSize(width: ceil(textSize.width) + 18, height: ceil(textSize.height) + 9)

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        let statusFrame = statusItem.button?.window?.frame

        // 紧贴模式子菜单右边缘；右边放不下就翻到主菜单左侧
        let anchorX = statusFrame?.midX ?? mouse.x
        var x = anchorX + 290
        var y = mouse.y - size.height / 2
        if let frame = screen?.visibleFrame {
            if x + size.width > frame.maxX - 8 {
                x = anchorX - size.width - 230
            }
            x = max(frame.minX + 8, x)
            // 贴着当前选项的高度，放在菜单右侧，不覆盖菜单
            y = min(frame.maxY - size.height - 8, max(frame.minY + 8, y))
        }

        let panel = ModeHintPanel(contentRect: NSRect(x: x, y: y, width: size.width, height: size.height),
                                  styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered,
                                  defer: false)
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        let view = ModeHintView(text: text)
        view.frame = NSRect(origin: .zero, size: size)
        panel.contentView = view
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 1
        }
        hintPanel = panel
    }

    @objc private func menuToggle() { handleHotKey() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    @objc private func menuSetPlayMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = PlayMode(rawValue: raw) else { return }
        config.mode = raw
        ConfigStore.save(config)
        cancelModeHint()
        cancelAutoTimer()
        cancelHandPress()
        peekAnimTimer?.invalidate()
        peekAnimTimer = nil
        peekCover = (mode == .peek && isCollapsed) ? 1 : 0
        if mode != .crazy { stopCrazyGame() }
        applyIcon()
        if (mode == .box || mode == .peek), !isCollapsed, didFinishLaunch {
            armAutoTimer()
        }
        if mode == .custom {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.openCustomSettings()
            }
        }
    }

    private func builtinAssets() -> [BuiltinAsset] {
        var list: [BuiltinAsset] = [
            BuiltinAsset(token: "", name: "默认手势", image: peekImage(cover: 0)),
            BuiltinAsset(token: "builtin:hand-open", name: "手势 · 睁眼", image: peekImage(cover: 0)),
            BuiltinAsset(token: "builtin:hand-closed", name: "手势 · 闭眼", image: peekImage(cover: 1)),
            BuiltinAsset(token: "builtin:cat-open", name: "猫箱 · 打开", image: BoxCat.image(open: true)),
            BuiltinAsset(token: "builtin:cat-closed", name: "猫箱 · 关闭", image: BoxCat.image(open: false)),
            BuiltinAsset(token: "builtin:knight", name: "棋子", image: knightImage())
        ]
        for style in IconStyle.allCases {
            list.append(BuiltinAsset(token: "builtin:icon:\(style.rawValue)",
                                     name: style.label,
                                     image: IconRenderer.image(style: style, collapsed: false, size: 22)))
        }
        return list
    }

    @objc private func menuCustomSettings() {
        openCustomSettings()
    }

    private func openCustomSettings() {
        customWindow.show(settings: config.custom, assets: builtinAssets()) { [weak self] settings in
            guard let self else { return }
            self.config.custom = settings
            self.config.mode = PlayMode.custom.rawValue
            ConfigStore.save(self.config)
            self.customImageCache.removeAll()
            self.customLastCollapsed = nil
            self.applyIcon()
            self.armCustomTimerIfNeeded()
            btLog("BlankTop: custom mode saved")
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

    @objc private func menuSetLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? String,
              ["zh", "en"].contains(language) else { return }
        config.language = language
        appLanguage = language
        ConfigStore.save(config)
        // 赞赏窗口的文案在创建时写死，换语言后重建，下次打开就是新语言。
        donateWindow?.close()
        donateWindow = nil
        donateStack = nil
        donatePraiseLabel = nil
        donateGlass = nil
        donateGlassRow = nil
        donateGlassLabel = nil
        btLog("BlankTop: language -> \(language)")
    }

    // MARK: 检查更新

    @objc private func menuCheckForUpdates() {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        btLog("BlankTop: checking updates, current \(appVersion), repo \(repoSlug)")

        var request = URLRequest(url: latestReleaseAPI)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("BlankTop/\(appVersion)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.finishUpdateCheck(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func finishUpdateCheck(data: Data?, response: URLResponse?, error: Error?) {
        isCheckingUpdates = false

        if let error {
            btLog("BlankTop: update check failed: \(error.localizedDescription)")
            showUpdateAlert(
                title: tt("检查更新失败", "Update check failed"),
                text: tt("网络请求没有成功：\(error.localizedDescription)\n可以手动打开 GitHub Releases 看看。",
                         "The request failed: \(error.localizedDescription)\nYou can open GitHub Releases manually."),
                downloadURL: nil)
            return
        }

        guard let http = response as? HTTPURLResponse else {
            btLog("BlankTop: update check failed: no response")
            showUpdateAlert(title: tt("检查更新失败", "Update check failed"),
                            text: tt("没有拿到服务器响应。", "No response from the server."),
                            downloadURL: nil)
            return
        }

        guard http.statusCode == 200,
              let data,
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            btLog("BlankTop: update check failed: HTTP \(http.statusCode)")
            showUpdateAlert(
                title: tt("检查更新失败", "Update check failed"),
                text: tt("GitHub 返回了 \(http.statusCode)。可以手动打开 Releases 页面。",
                         "GitHub returned \(http.statusCode). You can open the Releases page manually."),
                downloadURL: nil)
            return
        }

        let tag = (json["tag_name"] as? String) ?? ""
        let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let page = (json["html_url"] as? String).flatMap(URL.init(string:)) ?? releasesPageURL
        guard !latest.isEmpty else {
            btLog("BlankTop: update check failed: empty tag_name")
            showUpdateAlert(title: tt("检查更新失败", "Update check failed"),
                            text: tt("没有读到版本号。", "No version number in the response."),
                            downloadURL: nil)
            return
        }

        if Self.version(latest, isNewerThan: appVersion) {
            btLog("BlankTop: update available \(latest) (current \(appVersion))")
            showUpdateAlert(
                title: tt("发现新版本 \(latest)", "Version \(latest) is available"),
                text: tt("当前版本 \(appVersion)。要打开下载页面吗？",
                         "You have \(appVersion). Open the download page?"),
                downloadURL: page)
        } else {
            btLog("BlankTop: up to date (\(appVersion))")
            let alert = NSAlert()
            alert.messageText = tt("已是最新版本", "You're up to date")
            alert.informativeText = tt("当前版本 \(appVersion)。", "Version \(appVersion).")
            alert.addButton(withTitle: tt("好", "OK"))
            alert.runModal()
        }
    }

    private func showUpdateAlert(title: String, text: String, downloadURL: URL?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        if downloadURL != nil {
            alert.addButton(withTitle: tt("下载", "Download"))
            alert.addButton(withTitle: tt("稍后", "Later"))
        } else {
            alert.addButton(withTitle: tt("好", "OK"))
            alert.addButton(withTitle: tt("打开 Releases", "Open Releases"))
        }
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let downloadURL {
                NSWorkspace.shared.open(downloadURL)
            }
        } else if downloadURL == nil {
            NSWorkspace.shared.open(releasesPageURL)
        }
    }

    /// "1.2.0" > "1.1.9"，按数字段比较，忽略末尾的 0。
    private static func version(_ a: String, isNewerThan b: String) -> Bool {
        let left = a.split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }
        let right = b.split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }
        for i in 0..<max(left.count, right.count) {
            let x = i < left.count ? left[i] : 0
            let y = i < right.count ? right[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    @objc private func menuOpenLog() {
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            btLog("BlankTop: log created")
        }
        NSWorkspace.shared.open(logFileURL)
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

    private static let praiseTexts = [
        "你真好看",
        "今天的你，比昨天更好看",
        "你的品味，真的很在线",
        "你一笑，天气都变好了",
        "你认真生活的样子，很迷人",
        "你值得所有温柔和好运",
        "你一来，整个房间都亮了",
        "你的眼光，从来不会让人失望",
        "你不仅好看，还很有眼光",
        "有你在，平凡的一天也会发光"
    ]

    /// 两条彩蛋文案，按时间顺序触发。微信赞赏码没有支付回调，这里只是开窗计时。
    private static let eggTexts = ["天气从未如此明媚", "你这么好看，在犹豫什么"]

    private static let afdianURL = URL(string: "https://afdian.com/a/tack123")!

    private var donateWindow: NSWindow?
    private var donateStack: NSStackView?
    private var donatePraiseLabel: NSTextField?
    private var donateGlass: NSVisualEffectView?
    private var donateGlassRow: NSStackView?
    private var donateGlassLabel: NSTextField?
    private var donateWorkItems: [DispatchWorkItem] = []
    private var donateRevertWorkItem: DispatchWorkItem?
    private var donateChime: NSSound?
    private var donateMessageGeneration = 0

    @objc private func menuDonate() {
        showDonate()
    }

    func showDonate() {
        let window = donateWindow ?? makeDonateWindow()
        donateWindow = window

        // 每次打开都重新抽一条吹捧，并重置彩蛋时间线
        donatePraiseLabel?.stringValue = t(Self.praiseTexts.randomElement() ?? Self.praiseTexts[0])
        cancelDonateEasterEgg()
        resizeDonateWindow(window)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        armDonateEasterEgg()
    }

    private func makeDonateWindow() -> NSWindow {
        let width: CGFloat = 340
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 400),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = t("有你真好")
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.appearance = NSAppearance(named: .aqua)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 400))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.white.cgColor

        // 340 宽、左右各 18 内边距；纵向间距 10
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18),
            stack.widthAnchor.constraint(equalToConstant: width - 36)
        ])
        donateStack = stack

        let praise = NSTextField(wrappingLabelWithString: "")
        praise.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        praise.textColor = NSColor(white: 0.12, alpha: 1)
        praise.alignment = .center
        praise.maximumNumberOfLines = 2
        praise.preferredMaxLayoutWidth = 300
        praise.translatesAutoresizingMaskIntoConstraints = false
        praise.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        stack.addArrangedSubview(praise)
        donatePraiseLabel = praise

        // 主入口：爱发电（紫色胶囊）
        let afdian = NSButton(title: t("去爱发电支持"), target: self, action: #selector(openAfdianPage))
        afdian.isBordered = false
        afdian.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)
        afdian.imagePosition = .imageLeading
        afdian.contentTintColor = .white
        afdian.attributedTitle = NSAttributedString(string: t("去爱发电支持"), attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white
        ])
        afdian.translatesAutoresizingMaskIntoConstraints = false

        let afdianWrap = NSView()
        afdianWrap.wantsLayer = true
        afdianWrap.layer?.backgroundColor = NSColor(srgbRed: 0.56, green: 0.66, blue: 1.0, alpha: 1).cgColor
        afdianWrap.layer?.cornerRadius = 17
        afdianWrap.translatesAutoresizingMaskIntoConstraints = false
        afdianWrap.addSubview(afdian)
        NSLayoutConstraint.activate([
            afdian.leadingAnchor.constraint(equalTo: afdianWrap.leadingAnchor, constant: 20),
            afdian.trailingAnchor.constraint(equalTo: afdianWrap.trailingAnchor, constant: -20),
            afdian.centerYAnchor.constraint(equalTo: afdianWrap.centerYAnchor),
            afdianWrap.heightAnchor.constraint(equalToConstant: 34)
        ])
        stack.addArrangedSubview(afdianWrap)

        // 次入口：微信赞赏码（图片缺失时整块隐藏）
        if let qrImage = Self.donateQRImage() {
            let divider = NSStackView()
            divider.orientation = .horizontal
            divider.alignment = .centerY
            divider.spacing = 8
            divider.translatesAutoresizingMaskIntoConstraints = false

            let lineColor = NSColor(white: 0, alpha: 0.15)
            let left = NSView()
            left.wantsLayer = true
            left.layer?.backgroundColor = lineColor.cgColor
            left.translatesAutoresizingMaskIntoConstraints = false
            left.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            let right = NSView()
            right.wantsLayer = true
            right.layer?.backgroundColor = lineColor.cgColor
            right.translatesAutoresizingMaskIntoConstraints = false
            right.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            let dividerLabel = NSTextField(labelWithString: t("或 微信扫码"))
            dividerLabel.font = NSFont.systemFont(ofSize: 9)
            dividerLabel.textColor = NSColor(white: 0.55, alpha: 1)
            dividerLabel.setContentHuggingPriority(.required, for: .horizontal)

            divider.addArrangedSubview(left)
            divider.addArrangedSubview(dividerLabel)
            divider.addArrangedSubview(right)
            left.widthAnchor.constraint(equalTo: right.widthAnchor).isActive = true
            stack.addArrangedSubview(divider)
            divider.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

            let qr = NSImageView()
            qr.image = qrImage
            qr.imageScaling = .scaleProportionallyUpOrDown
            qr.wantsLayer = true
            qr.layer?.cornerRadius = 8
            qr.layer?.masksToBounds = true
            qr.layer?.backgroundColor = NSColor.white.cgColor
            qr.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                qr.widthAnchor.constraint(equalToConstant: 120),
                qr.heightAnchor.constraint(equalToConstant: 120)
            ])
            stack.addArrangedSubview(qr)
        }

        // 26pt 消息条：默认空，彩蛋时出现玻璃条
        let strip = NSView()
        strip.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(strip)
        NSLayoutConstraint.activate([
            strip.widthAnchor.constraint(equalTo: stack.widthAnchor),
            strip.heightAnchor.constraint(equalToConstant: 26)
        ])

        let glass = NSVisualEffectView()
        glass.material = .popover
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.alphaValue = 0.5
        glass.wantsLayer = true
        glass.layer?.cornerRadius = 10
        glass.layer?.masksToBounds = true
        glass.layer?.borderWidth = 0.5
        glass.layer?.borderColor = NSColor(white: 1, alpha: 0.18).cgColor
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.isHidden = true

        let heart = NSTextField(labelWithString: "💖")
        heart.font = NSFont.systemFont(ofSize: 14)
        let sparkle = NSTextField(labelWithString: "✨")
        sparkle.font = NSFont.systemFont(ofSize: 12)

        let glassLabel = NSTextField(labelWithString: "")
        glassLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        glassLabel.textColor = NSColor(white: 0.08, alpha: 0.9)
        glassLabel.alignment = .center
        glassLabel.lineBreakMode = .byTruncatingTail

        let row = NSStackView(views: [heart, glassLabel, sparkle])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isHidden = true

        strip.addSubview(glass)
        strip.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: strip.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: strip.centerYAnchor),
            glass.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: -10),
            glass.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: 10),
            glass.topAnchor.constraint(equalTo: row.topAnchor, constant: -4),
            glass.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: 4),
            glass.widthAnchor.constraint(lessThanOrEqualTo: strip.widthAnchor)
        ])
        donateGlass = glass
        donateGlassRow = row
        donateGlassLabel = glassLabel

        let disclaimer = NSTextField(wrappingLabelWithString: t("自愿赞赏 · 不换取任何功能或服务 · 不支持退款"))
        disclaimer.font = NSFont.systemFont(ofSize: 9)
        disclaimer.textColor = NSColor(white: 0.45, alpha: 1)
        disclaimer.alignment = .center
        disclaimer.preferredMaxLayoutWidth = width - 36
        stack.addArrangedSubview(disclaimer)

        let close = NSButton(title: t("关闭"), target: self, action: #selector(closeDonateWindow))
        close.bezelStyle = .rounded
        close.font = NSFont.systemFont(ofSize: 12)
        close.keyEquivalent = "\u{1b}"
        close.keyEquivalentModifierMask = []
        stack.addArrangedSubview(close)

        window.contentView = content
        resizeDonateWindow(window)
        return window
    }

    /// 先排版再取 fittingSize 定窗口高度，最后居中；顺序反了会偏。
    private func resizeDonateWindow(_ window: NSWindow) {
        guard let stack = donateStack else { return }
        stack.layoutSubtreeIfNeeded()
        let height = stack.fittingSize.height + 36
        window.setContentSize(NSSize(width: 340, height: max(height, 120)))
        if !window.isVisible { centerOnMouseScreen(window) }
    }

    /// 在鼠标所在屏幕的可视区域居中，避免多显示器时跑到另一块屏或超出边缘。
    private func centerOnMouseScreen(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            window.center()
            return
        }
        let size = window.frame.size
        var origin = NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        origin.x = max(visible.minX + 8, min(origin.x, visible.maxX - size.width - 8))
        origin.y = max(visible.minY + 8, min(origin.y, visible.maxY - size.height - 8))
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    @objc private func openAfdianPage() {
        NSWorkspace.shared.open(Self.afdianURL)
    }

    @objc private func closeDonateWindow() {
        donateWindow?.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === donateWindow else { return }
        cancelDonateEasterEgg()
    }

    // MARK: 赞赏码

    private static var donateQRImageCache: NSImage?
    private static var donateQRImageLoaded = false

    /// 扫描深色像素找二维码本体包围盒（忽略金色徽章），裁成以本体为中心的正方形。
    private static func donateQRImage() -> NSImage? {
        if donateQRImageLoaded { return donateQRImageCache }
        donateQRImageLoaded = true

        guard let url = Bundle.main.url(forResource: "donation-qr", withExtension: "png"),
              let original = NSImage(contentsOf: url),
              let cg = original.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        donateQRImageCache = original

        let w = cg.width
        let h = cg.height
        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)
        guard let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return original
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w, maxX = 0, minY = h, maxY = 0
        var found = false
        for y in 0..<h {
            for x in 0..<w {
                let i = y * bytesPerRow + x * 4
                guard data[i + 3] > 16 else { continue }
                if max(data[i], data[i + 1], data[i + 2]) < 160 {
                    found = true
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard found else { return original }

        let centerX = CGFloat(minX + maxX) / 2
        let centerY = CGFloat(minY + maxY) / 2
        let contentSide = CGFloat(max(maxX - minX, maxY - minY) + 1)
        let margin = max(16, contentSide / 12)
        let side = min(CGFloat(min(w, h)), contentSide + margin * 2)

        var rect = CGRect(x: centerX - side / 2, y: centerY - side / 2, width: side, height: side)
        rect.origin.x = max(0, min(rect.origin.x, CGFloat(w) - side))
        rect.origin.y = max(0, min(rect.origin.y, CGFloat(h) - side))

        guard let cropped = cg.cropping(to: rect) else { return original }
        let result = NSImage(cgImage: cropped, size: NSSize(width: side, height: side))
        donateQRImageCache = result
        return result
    }

    // MARK: 赞赏彩蛋

    private func armDonateEasterEgg() {
        let first = DispatchWorkItem { [weak self] in
            guard let self, self.donateWindow?.isVisible == true else { return }
            self.playDonateChime()
            self.showDonateMessage(Self.eggTexts[0], duration: 3)
        }
        let second = DispatchWorkItem { [weak self] in
            guard let self, self.donateWindow?.isVisible == true else { return }
            self.showDonateMessage(Self.eggTexts[1], duration: 4)
        }
        donateWorkItems = [first, second]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: first)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: second)
    }

    /// 关窗或重开时调用：取消未触发的任务，停掉还在响的音效。
    private func cancelDonateEasterEgg() {
        donateWorkItems.forEach { $0.cancel() }
        donateWorkItems = []
        donateRevertWorkItem?.cancel()
        donateRevertWorkItem = nil
        donateChime?.stop()
        donateChime = nil
        hideDonateMessage(animated: false)
    }

    private func showDonateMessage(_ text: String, duration: TimeInterval) {
        guard let glass = donateGlass, let row = donateGlassRow, let label = donateGlassLabel else { return }
        donateMessageGeneration += 1
        label.stringValue = t(text)
        glass.isHidden = false
        row.isHidden = false
        glass.alphaValue = 0
        row.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            glass.animator().alphaValue = 1
            row.animator().alphaValue = 1
        }

        donateRevertWorkItem?.cancel()
        let revert = DispatchWorkItem { [weak self] in
            self?.hideDonateMessage(animated: true)
        }
        donateRevertWorkItem = revert
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: revert)
    }

    private func hideDonateMessage(animated: Bool) {
        guard let glass = donateGlass, let row = donateGlassRow else { return }
        donateMessageGeneration += 1
        let generation = donateMessageGeneration
        let finish = { [weak self] in
            guard let self, self.donateMessageGeneration == generation else { return }
            glass.isHidden = true
            row.isHidden = true
            glass.alphaValue = 1
            row.alphaValue = 1
            self.donateGlassLabel?.stringValue = ""
        }
        guard animated else {
            finish()
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            glass.animator().alphaValue = 0
            row.animator().alphaValue = 0
        }, completionHandler: finish)
    }

    private func playDonateChime() {
        guard config.soundName != "none" else { return }
        guard let data = Self.donateChimeWAV else { return }
        donateChime?.stop()
        let sound = NSSound(data: data)
        sound?.volume = 0.4
        donateChime = sound
        _ = sound?.play()
    }

    /// 1.5 秒上行琶音 + 柔和和弦，内存合成 16-bit 单声道 WAV，不依赖额外音频文件。
    private static let donateChimeWAV: Data? = makeDonateChimeWAV()

    private static func makeDonateChimeWAV() -> Data? {
        let rate = 44100.0
        let total = Int(rate * 1.5)
        var mix = [Double](repeating: 0, count: total)

        let chord = [523.251, 659.255, 783.991, 1046.502] // C5 E5 G5 C6
        for (index, freq) in chord.enumerated() {
            let begin = Int(Double(index) * 0.18 * rate)
            let length = min(Int(0.42 * rate), total - begin)
            for i in 0..<length {
                let t = Double(i) / rate
                let attack = min(1, t / 0.012)
                let decay = exp(-t * 6.0)
                let tone = sin(2 * .pi * freq * t) * 0.6 + sin(2 * .pi * freq * 2 * t) * 0.12
                mix[begin + i] += tone * attack * decay * 0.32
            }
        }

        let chordStart = Int(0.72 * rate)
        for i in 0..<(total - chordStart) {
            let t = Double(i) / rate
            let attack = min(1, t / 0.09)
            let decay = exp(-t * 2.6)
            var tone = 0.0
            for freq in chord {
                tone += sin(2 * .pi * freq * t) * 0.08
                tone += sin(2 * .pi * freq * 2 * t) * 0.012
            }
            mix[chordStart + i] += tone * attack * decay
        }

        // 结尾 80ms 淡出，避免爆音
        let fade = min(Int(0.08 * rate), total)
        for i in 0..<fade {
            mix[total - fade + i] *= Double(fade - i) / Double(fade)
        }

        let peak = mix.reduce(0) { max($0, abs($1)) }
        let gain = 0.85 / max(peak, 0.001)

        var data = Data()
        func put32(_ value: UInt32) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        func put16(_ value: UInt16) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        let dataBytes = UInt32(total * 2)
        data.append(contentsOf: Array("RIFF".utf8))
        put32(36 + dataBytes)
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        put32(16)
        put16(1)
        put16(1)
        put32(UInt32(rate))
        put32(UInt32(rate) * 2)
        put16(2)
        put16(16)
        data.append(contentsOf: Array("data".utf8))
        put32(dataBytes)
        for sample in mix {
            let value = Int16(max(-1, min(1, sample * gain)) * 32767)
            put16(UInt16(bitPattern: value))
        }
        return data
    }

    // MARK: 音效

    private var activeSounds: [NSSound] = []

    /// 用独立的实例播放，避免共用缓存实例时 isPlaying 导致偶发没声音。
    private func playSound(collapsing: Bool) {
        guard config.soundName != "none" else { return }
        if playMode == .box {
            playBundledSound(collapsing ? "box-close" : "box-open")
            return
        }
        let file: String
        if playMode == .peek {
            // 手慢慢盖住眼睛：收起时用 Purr，和普通开关区分开
            file = collapsing ? "Purr" : "Tink"
        } else {
            switch config.soundName {
            case "pop": file = "Pop"
            case "purr": file = "Purr"
            case "bottle": file = "Bottle"
            default: file = collapsing ? "Pop" : "Tink"
            }
        }
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(file).aiff")
        guard let sound = NSSound(contentsOf: url, byReference: true) else {
            btLog("BlankTop: 音效文件不可用 \(file)")
            return
        }
        sound.volume = Float(max(0.35, config.soundVolume))
        btLog("BlankTop: sound \(file)")
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
        customTimer?.invalidate()
        customTimer = nil
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
            btLog("BlankTop: scan \(items.count) items in \(Int(Date().timeIntervalSince(started) * 1000))ms")

            if ProcessInfo.processInfo.environment["MBF_DEBUG"] == "1" {
                btLog("BlankTop: arrow@\(Int(arrowFrame.midX)) inventory " + items
                    .sorted { $0.frame.midX < $1.frame.midX }
                    .map { "\($0.bundleIdentifier ?? "?")@\(Int($0.frame.midX))" }
                    .joined(separator: " "))
            }
            // 系统白名单只认 /Applications 下的 App：可见区里若有别处的 App，
            // 折叠时它仍会被藏起来，这里提前告警。
            let outside = Array(all.subtracting(hidden))
                .filter { !$0.hasPrefix("com.apple.") && self.isOutsideApplications($0) }
            if !outside.isEmpty {
                btLog("BlankTop: 这些 App 不在 /Applications，折叠时可能被误藏：\(outside.sorted())")
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
                btLog("BlankTop: collapsed, hid \(self.hiddenBundles.sorted())")
                self.runPendingToggleIfNeeded()
            }
        }
    }

    private func expand() {
        if isCollapsed { playSound(collapsing: false) }
        isBusy = true

        guard config.expandMode == "allowlist", hasScan, assertion != nil else {
            releaseAndMarkExpanded()
            btLog("BlankTop: expanded (release)")
            return
        }

        // 折叠期间有新 App 启动时，它的图标是在限制生效的状态下创建的，
        // 只把它加进白名单系统也不会重新摆放——必须先释放一次再重建。
        if hasNewAppsSinceScan() {
            btLog("BlankTop: 折叠期间有新 App 启动，重排一次白名单")
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
            btLog("BlankTop: expanded (allowlist)")
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
                btLog("BlankTop: rescan -> visible \(self.visibleBundles.sorted()), hidden \(self.hiddenBundles.sorted())")
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
                btLog("BlankTop: activation failed: \(error?.localizedDescription ?? "unknown")")
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
        hint.messageText = tt("开关左边还没有图标", "Nothing on the left yet")
        hint.informativeText = tt("""
        折叠只隐藏开关左边的图标。
        按住 ⌘ 把图标拖到开关左边；想留谁，就把它拖回右边。
        """, """
        Collapsing only hides icons to the left of the switch.
        Hold ⌘ and drag icons to the left of the switch; drag them back to keep them visible.
        """)
        hint.addButton(withTitle: tt("知道了", "Got it"))
        hint.runModal()
    }

    // MARK: 图标

    private func applyCrazyIcon() {
        guard let button = statusItem.button else { return }
        button.title = ""
        button.image = knightImage()
        button.imagePosition = .imageOnly
    }

    /// 抓狂模式开局时把图标变透明，但保留状态项宽度，菜单栏不会重排。
    private func setStatusIconHidden(_ hidden: Bool) {
        guard let button = statusItem.button else { return }
        if hidden {
            button.title = ""
            button.image = NSImage(size: NSSize(width: 20, height: 18))
            button.imagePosition = .imageOnly
        } else {
            applyIcon()
        }
    }

    /// ♞ 字符按墨迹裁出来，缓存一份，和底座拼成棋子。
    private static var knightGlyph: NSImage?

    private static func loadKnightGlyph() -> NSImage? {
        if let knightGlyph { return knightGlyph }
        let canvas: CGFloat = 400
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(canvas * 2), pixelsHigh: Int(canvas * 2),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let attr = NSAttributedString(string: "♞", attributes: [
            .font: NSFont.systemFont(ofSize: 240),
            .foregroundColor: NSColor.black
        ])
        let size = attr.size()
        attr.draw(at: NSPoint(x: (canvas - size.width) / 2, y: (canvas - size.height) / 2))
        NSGraphicsContext.restoreGraphicsState()

        let pixels = Int(canvas * 2)
        var minX = pixels, minY = pixels, maxX = -1, maxY = -1
        for y in 0..<pixels {
            for x in 0..<pixels {
                if let color = rep.colorAt(x: x, y: y), color.alphaComponent > 0.05 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY,
              let cg = rep.cgImage?.cropping(to: CGRect(x: minX, y: minY,
                                                        width: maxX - minX + 1,
                                                        height: maxY - minY + 1)) else { return nil }
        let image = NSImage(cgImage: cg, size: NSSize(width: CGFloat(maxX - minX + 1) / 2,
                                                     height: CGFloat(maxY - minY + 1) / 2))
        knightGlyph = image
        return image
    }

    private func knightImage() -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(logical.width * scale),
                                         pixelsHigh: Int(logical.height * scale),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else {
            return NSImage(size: logical)
        }
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)
        context.cgContext.translateBy(x: 0, y: 1.9)   // 内容在 20pt 里居中
        // 再放大 1/10，和旁边的系统图标更接近
        context.cgContext.translateBy(x: 10, y: 10)
        context.cgContext.scaleBy(x: 1.1, y: 1.1)
        context.cgContext.translateBy(x: -10, y: -10)

        // 棋子底座
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 4.7, y: 0.6, width: 10.6, height: 1.9),
                     xRadius: 0.7, yRadius: 0.7).fill()
        NSBezierPath(roundedRect: NSRect(x: 6.3, y: 2.4, width: 7.4, height: 2.0),
                     xRadius: 0.5, yRadius: 0.5).fill()

        // 马头
        if let glyph = Self.loadKnightGlyph() {
            let h: CGFloat = 11.6
            let w = h * (glyph.size.width / glyph.size.height)
            glyph.draw(in: NSRect(x: 10 - w/2, y: 4.0, width: w, height: h),
                       from: .zero, operation: .sourceOver, fraction: 1)
        }
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }

    // MARK: 自定义模式

    private func customStatusImage(collapsed: Bool) -> NSImage {
        let name = collapsed ? config.custom.imageClosed : config.custom.imageOpen
        if name.isEmpty {
            // 没选图时沿用内置手势
            return peekImage(cover: collapsed ? 1 : 0)
        }
        if name.hasPrefix("builtin:") {
            switch String(name.dropFirst(8)) {
            case "hand-open": return peekImage(cover: 0)
            case "hand-closed": return peekImage(cover: 1)
            case "cat-open": return BoxCat.image(open: true)
            case "cat-closed": return BoxCat.image(open: false)
            case "knight": return knightImage()
            default:
                let raw = String(name.dropFirst(8))
                if raw.hasPrefix("icon:"), let style = IconStyle(rawValue: String(raw.dropFirst(5))) {
                    return IconRenderer.image(style: style, collapsed: collapsed, size: 20)
                }
                return peekImage(cover: collapsed ? 1 : 0)
            }
        }
        if let cached = customImageCache[name] { return cached }
        guard let url = CustomStore.url(name), let source = NSImage(contentsOf: url) else {
            let symbol = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
                ?? NSImage(size: NSSize(width: 20, height: 20))
            symbol.isTemplate = true
            return symbol
        }
        let image = renderCustomImage(source)
        customImageCache[name] = image
        return image
    }

    private func renderCustomImage(_ source: NSImage) -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(logical.width * scale),
                                         pixelsHigh: Int(logical.height * scale),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else {
            return source
        }
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)
        context.imageInterpolation = .high
        let s = min(20 / max(1, source.size.width), 20 / max(1, source.size.height))
        let w = source.size.width * s, h = source.size.height * s
        source.draw(in: NSRect(x: (20 - w) / 2, y: (20 - h) / 2, width: w, height: h),
                    from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = config.custom.monochrome
        return image
    }

    private func applyCustomIcon() {
        guard let button = statusItem.button else { return }
        let image = customStatusImage(collapsed: isCollapsed)
        let changed = customLastCollapsed != isCollapsed
        customLastCollapsed = isCollapsed
        button.title = ""
        button.imagePosition = .imageOnly
        if changed, config.custom.transition != "none", let from = button.image {
            animateCustomIcon(from: from, to: image)
        } else {
            button.image = image
        }
    }

    private func animateCustomIcon(from: NSImage, to: NSImage) {
        customAnimTimer?.invalidate()
        let kind = config.custom.transition
        let started = Date()
        let duration: TimeInterval = 0.22
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let p = min(1, Date().timeIntervalSince(started) / duration)
            let eased = p * p * (3 - 2 * p)
            self.statusItem.button?.image = self.customComposite(from: from, to: to,
                                                                 progress: CGFloat(eased), kind: kind)
            if p >= 1 {
                timer.invalidate()
                self.customAnimTimer = nil
                self.statusItem.button?.image = to
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        customAnimTimer = timer
    }

    private func customComposite(from: NSImage, to: NSImage,
                                 progress: CGFloat, kind: String) -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(logical.width * scale),
                                         pixelsHigh: Int(logical.height * scale),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else { return to }
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)
        let rect = NSRect(x: 0, y: 0, width: 20, height: 20)
        from.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1 - progress)
        let target = kind == "drop" ? rect.offsetBy(dx: 0, dy: (1 - progress) * 8) : rect
        to.draw(in: target, from: .zero, operation: .sourceOver, fraction: progress)
        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = config.custom.monochrome
        return image
    }

    /// 菜单栏的底色可能因为壁纸/全屏应用变化，这里每秒看一次按钮的 appearance，
    /// 变了才重绘；系统外观切换本身不会影响它。
    private func startBarAppearanceWatch() {
        barWatchTimer?.invalidate()
        if let button = statusItem.button {
            lastBarDark = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let button = self.statusItem.button else { return }
            let dark = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            guard dark != self.lastBarDark else { return }
            self.lastBarDark = dark
            btLog("BlankTop: bar appearance changed dark=\(dark)")
            self.applyIcon()
        }
        RunLoop.main.add(timer, forMode: .common)
        barWatchTimer = timer
    }

    private func armCustomTimerIfNeeded() {
        customTimer?.invalidate()
        customTimer = nil
        guard playMode == .custom, !isCollapsed, config.custom.delay > 0 else { return }
        let timer = Timer(timeInterval: config.custom.delay, repeats: false) { [weak self] _ in
            guard let self, !self.isCollapsed else { return }
            switch self.config.custom.action {
            case "collapse": self.collapse()
            case "expand": self.expand()
            default: break
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        customTimer = timer
    }

    private func applyIcon() {
        guard let button = statusItem.button else { return }
        switch playMode {
        case .peek:
            button.title = ""
            button.image = peekImage(cover: peekCover)
            button.imagePosition = .imageOnly
            return
        case .box:
            button.title = ""
            button.image = BoxCat.image(open: !isCollapsed)
            button.imagePosition = .imageOnly
            return
        case .crazy:
            applyCrazyIcon()
            return
        case .custom:
            applyCustomIcon()
            return
        case .manual:
            break
        }

        let style = IconStyle(rawValue: config.icon) ?? .chevron
        // 只看菜单栏本身的明暗，跟系统外观设置无关
        let isDark = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        lastBarDark = isDark
        button.title = ""
        button.image = IconRenderer.image(style: style, collapsed: isCollapsed, size: 20, dark: isDark)
        button.imagePosition = .imageOnly
        btLog("BlankTop: icon dark=\(isDark)")
    }

    /// 自绘的 iPhone 风格开关：展开中 = 右（开，绿底板），折叠中 = 左（关，灰底板）。
    /// 颜色只铺在露出的那一半底板上，圆点保持深色。
    /// 不看还看：用 potrace 从原图描出来的 1:1 矢量（PDF）。
    /// `cover` 0 → 睁眼，1 → 无眼，中间交叉淡入。
    private func peekImage(cover: CGFloat) -> NSImage {
        if let art = (cover >= 0.5 ? PeekIcons.closed : PeekIcons.open),
           let image = art.image(size: 20) {
            return image
        }

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
        context.imageInterpolation = .high

        let box = NSRect(x: 0, y: 0, width: logical.width, height: logical.height)
        let p = min(1, max(0, cover))
        if let drawing = (p >= 0.5 ? peekClosedPath : peekOpenPath) {
            // 直接用 SVG 路径填色；再描一圈细边，把线加粗到和菜单图标接近
            NSColor.black.setFill()
            drawing.path.fill()
            drawing.path.lineWidth = 0.55
            drawing.path.lineJoinStyle = .round
            drawing.path.lineCapStyle = .round
            NSColor.black.setStroke()
            drawing.path.stroke()
        } else {
            // 兜底：SVG 读不到时用 PDF 淡入淡出
            if let open = peekOpenImage { drawFitted(open, in: box, alpha: 1 - p) }
            if let closed = peekClosedImage { drawFitted(closed, in: box, alpha: p) }
        }

        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }

    private func drawFitted(_ image: NSImage, in rect: NSRect, alpha: CGFloat) {
        guard alpha > 0.001 else { return }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        let dest = NSRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
        image.draw(in: dest, from: .zero, operation: .sourceOver, fraction: alpha)
    }

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

        // 用 template：系统会根据菜单栏明暗自动把图形渲染成黑/白，
        // 深色壁纸下也能看清轮廓和圆点。
        let ink = NSColor.black
        let inset: CGFloat = 0.75 * scale
        let radius = (height - inset * 2) / 2
        let track = NSBezierPath(roundedRect: NSRect(x: inset, y: inset,
                                                     width: width - inset * 2,
                                                     height: height - inset * 2),
                                 xRadius: radius, yRadius: radius)

        // 只在「露出」的那一半底板上着色；绿取自右侧那个圆环图标 (#79BC51)
        NSGraphicsContext.saveGraphicsState()
        track.addClip()
        let tint = ink.withAlphaComponent(0.92)
        tint.setFill()
        let reveal = NSRect(x: on ? inset : width / 2,
                            y: inset,
                            width: width / 2 - inset,
                            height: height - inset * 2)
        reveal.fill()
        NSGraphicsContext.restoreGraphicsState()

        // 轨道描边
        ink.setStroke()
        track.lineWidth = 1.2 * scale
        track.stroke()

        // 开关钮：小圆点
        let knob = 5.2 * scale
        let margin = 2.4 * scale
        let knobX = on ? width - margin - knob : margin
        ink.setFill()
        NSBezierPath(ovalIn: NSRect(x: knobX, y: (height - knob) / 2,
                                    width: knob, height: knob)).fill()

        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = true
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
            btLog("BlankTop: hotkey registration failed (\(status))")
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

        btLog("BlankTop: 检测到新版本且权限未生效，清除旧的授权记录")
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
        alert.messageText = tt("需要「辅助功能」权限", "Accessibility permission required")
        alert.informativeText = tt("""
        BlankTop 需要读取其它 App 的菜单栏图标位置，才能判断哪些在箭头左边。

        打开「系统设置 → 隐私与安全性 → 辅助功能」：
        • 点「+」添加 /Applications/BlankTop.app
        • 如果列表里已经有旧的「BlankTop」，先按「−」删掉，再添加新的

        添加并勾选后，回来再点一次即可，不需要重启。
        """, """
        BlankTop reads the menu bar icon positions of other apps to know which ones are left of the arrow.

        Open System Settings → Privacy & Security → Accessibility:
        • Click “+” and add /Applications/BlankTop.app
        • If an old “BlankTop” entry exists, remove it with “−” first, then add the new one

        After enabling it, click again — no restart needed.
        """)
        alert.addButton(withTitle: tt("打开系统设置", "Open System Settings"))
        alert.addButton(withTitle: tt("稍后", "Later"))
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
        alert.messageText = "BlankTop"
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
