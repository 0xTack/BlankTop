//
//  CustomMode.swift
//  BlankTop — 自定义模式
//
//  延时 / 到时动作 / 两张状态图 / 两个音效 / 过渡效果
//  配置保存在 config.json，上传的文件拷到 Application Support/BlankTop/custom/
//

import AppKit
import UniformTypeIdentifiers

struct BuiltinAsset {
    let token: String
    let name: String
    let image: NSImage?
}

struct CustomSettings {
    var delay: Double = 10
    /// collapse / expand / none
    var action: String = "collapse"
    /// 文件名（custom 目录下），空 = 用内置手势图
    var imageOpen: String = ""
    var imageClosed: String = ""
    /// none / bundle:xxx / system:xxx / file:xxx
    var soundOpen: String = "none"
    var soundClosed: String = "none"
    /// none / fade / drop
    var transition: String = "fade"
    /// 单色模板（跟随菜单栏明暗）
    var monochrome: Bool = true

    init() {}

    init(json: [String: Any]) {
        if let v = json["delay"] as? Double { delay = v }
        if let v = json["action"] as? String, ["collapse", "expand", "none"].contains(v) { action = v }
        if let v = json["imageOpen"] as? String { imageOpen = v }
        if let v = json["imageClosed"] as? String { imageClosed = v }
        if let v = json["soundOpen"] as? String { soundOpen = v }
        if let v = json["soundClosed"] as? String { soundClosed = v }
        if let v = json["transition"] as? String, ["none", "fade", "drop"].contains(v) { transition = v }
        if let v = json["monochrome"] as? Bool { monochrome = v }
    }

    var json: [String: Any] {
        [
            "delay": delay,
            "action": action,
            "imageOpen": imageOpen,
            "imageClosed": imageClosed,
            "soundOpen": soundOpen,
            "soundClosed": soundClosed,
            "transition": transition,
            "monochrome": monochrome
        ]
    }
}

enum CustomStore {
    static var directory: URL {
        ConfigStore.directory.appendingPathComponent("custom", isDirectory: true)
    }

    static func url(_ name: String) -> URL? {
        guard !name.isEmpty else { return nil }
        let url = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// 把用户选的文件拷进 custom 目录，返回文件名。
    static func importFile(from source: URL, prefix: String) -> String? {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension
        let name = "\(prefix).\(ext)"
        let dest = directory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: source, to: dest)
            return name
        } catch {
            btLog("BlankTop: 自定义素材拷贝失败 \(error.localizedDescription)")
            return nil
        }
    }
}

final class CustomModeWindow: NSObject {
    private var window: NSWindow?
    private var settings = CustomSettings()
    private var onSave: ((CustomSettings) -> Void)?
    private var assets: [BuiltinAsset] = []
    private var openBuiltinButton: NSButton?
    private var closedBuiltinButton: NSButton?
    private var builtinIsOpen = true

    private let delayField = NSTextField(string: "10")
    private let actionPopup = NSPopUpButton()
    private let transitionPopup = NSPopUpButton()
    private let openImageLabel = NSTextField(labelWithString: "内置手势")
    private let closedImageLabel = NSTextField(labelWithString: "内置手势")
    private let openSoundPopup = NSPopUpButton()
    private let closedSoundPopup = NSPopUpButton()
    private let monochromeCheck = NSButton(checkboxWithTitle: "单色模板（跟随菜单栏明暗）", target: nil, action: nil)

    private let actions = ["collapse", "expand", "none"]
    private let actionsTitle = ["收起", "展开", "不动"]
    private let transitions = ["none", "fade", "drop"]
    private let transitionsTitle = ["直接切换", "淡入淡出", "从上落下"]

    private let soundTokens = ["none", "bundle:box-close", "bundle:box-open-wood",
                               "bundle:box-open-paper", "bundle:box-open-air", "bundle:box-open-pop",
                               "bundle:box-open-double", "bundle:box-open-tick",
                               "bundle:chess-place", "bundle:chess-leap",
                               "system:Tink", "system:Pop", "system:Purr",
                               "system:Bottle", "system:Glass", "choose"]
    private let soundTitles = ["不响", "纸箱合上", "木盖轻抬", "纸板摩擦", "空气轻推",
                               "低沉啵", "两声轻叩", "轻叩 + 气流",
                               "落子", "棋子飞出",
                               "Tink", "Pop", "Purr", "Bottle", "Glass", "选择文件…"]

    func show(settings: CustomSettings, assets: [BuiltinAsset],
              onSave: @escaping (CustomSettings) -> Void) {
        self.settings = settings
        self.assets = assets
        self.onSave = onSave
        if window == nil { build() }
        syncFields()
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func build() {
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 430, height: 400),
                           styleMask: [.titled, .closable],
                           backing: .buffered, defer: false)
        win.title = "自定义模式"
        win.isReleasedWhenClosed = false
        win.appearance = NSAppearance(named: .aqua)
        win.level = .floating

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18)
        ])
        win.contentView = content

        // 延时 + 动作
        delayField.formatter = NumberFormatter()
        (delayField.formatter as? NumberFormatter)?.maximumFractionDigits = 1
        delayField.widthAnchor.constraint(equalToConstant: 54).isActive = true
        let delayRow = NSStackView(views: [NSTextField(labelWithString: "展开后"), delayField,
                                            NSTextField(labelWithString: "秒")])
        delayRow.orientation = .horizontal
        delayRow.spacing = 6
        stack.addArrangedSubview(delayRow)

        actionPopup.addItems(withTitles: actionsTitle)
        let actionRow = NSStackView(views: [NSTextField(labelWithString: "到时"), actionPopup])
        actionRow.orientation = .horizontal
        actionRow.spacing = 6
        stack.addArrangedSubview(actionRow)

        transitionPopup.addItems(withTitles: transitionsTitle)
        let transRow = NSStackView(views: [NSTextField(labelWithString: "切换效果"), transitionPopup])
        transRow.orientation = .horizontal
        transRow.spacing = 6
        stack.addArrangedSubview(transRow)

        stack.addArrangedSubview(separator())

        stack.addArrangedSubview(imageRow(title: "展开时图标", label: openImageLabel, open: true))
        stack.addArrangedSubview(imageRow(title: "收起时图标", label: closedImageLabel, open: false))

        stack.addArrangedSubview(monochromeCheck)

        stack.addArrangedSubview(separator())

        stack.addArrangedSubview(soundRow(title: "收起音", popup: closedSoundPopup, preview: #selector(previewClosedSound)))
        stack.addArrangedSubview(soundRow(title: "展开音", popup: openSoundPopup, preview: #selector(previewOpenSound)))

        let save = NSButton(title: "保存并启用", target: self, action: #selector(saveTapped))
        save.keyEquivalent = "\r"
        let cancel = NSButton(title: "取消", target: self, action: #selector(cancelTapped))
        let buttons = NSStackView(views: [cancel, save])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        stack.addArrangedSubview(buttons)

        window = win
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func imageRow(title: String, label: NSTextField, open: Bool) -> NSView {
        let choose = NSButton(title: "选择…", target: self,
                              action: open ? #selector(chooseOpenImage) : #selector(chooseClosedImage))
        let builtin = NSButton(title: "内置 ▾", target: self, action: #selector(showBuiltinMenu(_:)))
        builtin.tag = open ? 1 : 0
        if open { openBuiltinButton = builtin } else { closedBuiltinButton = builtin }
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.widthAnchor.constraint(equalToConstant: 110).isActive = true
        let row = NSStackView(views: [NSTextField(labelWithString: title), choose, builtin, label])
        row.orientation = .horizontal
        row.spacing = 6
        return row
    }

    @objc private func showBuiltinMenu(_ sender: NSButton) {
        builtinIsOpen = sender.tag == 1
        let menu = NSMenu()
        for asset in assets {
            let item = NSMenuItem(title: asset.name, action: #selector(pickBuiltin(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = asset.token
            item.image = asset.image
            if #available(macOS 27.0, *) {
                item.preferredImageVisibility = .visible
            }
            menu.addItem(item)
        }
        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: sender.bounds.height + 4),
                   in: sender)
    }

    @objc private func pickBuiltin(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? String else { return }
        if builtinIsOpen {
            settings.imageOpen = token
            openImageLabel.stringValue = displayName(token)
        } else {
            settings.imageClosed = token
            closedImageLabel.stringValue = displayName(token)
        }
    }

    private func displayName(_ token: String) -> String {
        if token.isEmpty { return "默认手势" }
        return assets.first(where: { $0.token == token })?.name ?? token
    }

    private func soundRow(title: String, popup: NSPopUpButton, preview: Selector) -> NSView {
        popup.addItems(withTitles: soundTitles)
        popup.target = self
        popup.action = #selector(soundPopupChanged(_:))
        let button = NSButton(title: "试听", target: self, action: preview)
        let row = NSStackView(views: [NSTextField(labelWithString: title), popup, button])
        row.orientation = .horizontal
        row.spacing = 6
        return row
    }

    private func syncFields() {
        delayField.stringValue = String(format: "%g", settings.delay)
        actionPopup.selectItem(at: actions.firstIndex(of: settings.action) ?? 0)
        transitionPopup.selectItem(at: transitions.firstIndex(of: settings.transition) ?? 1)
        openImageLabel.stringValue = displayName(settings.imageOpen)
        closedImageLabel.stringValue = displayName(settings.imageClosed)
        monochromeCheck.state = settings.monochrome ? .on : .off

        openSoundPopup.selectItem(at: indexOfSound(settings.soundOpen))
        closedSoundPopup.selectItem(at: indexOfSound(settings.soundClosed))
    }

    private func indexOfSound(_ token: String) -> Int {
        if soundTokens.contains(token) { return soundTokens.firstIndex(of: token) ?? 0 }
        return soundTokens.firstIndex(of: "choose") ?? 0
    }

    private func token(for popup: NSPopUpButton) -> String {
        let index = popup.indexOfSelectedItem
        return soundTokens[max(0, min(index, soundTokens.count - 1))]
    }

    @objc private func chooseOpenImage() { chooseImage(open: true) }
    @objc private func chooseClosedImage() { chooseImage(open: false) }

    private func chooseImage(open: Bool) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .gif, .svg]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let name = CustomStore.importFile(from: url, prefix: open ? "open" : "closed") else { return }
        if open {
            settings.imageOpen = name
            openImageLabel.stringValue = name
        } else {
            settings.imageClosed = name
            closedImageLabel.stringValue = name
        }
    }

    @objc private func soundPopupChanged(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem == soundTokens.count - 1 else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        guard panel.runModal() == .OK, let url = panel.url,
              let name = CustomStore.importFile(from: url, prefix: sender === openSoundPopup ? "open-sound" : "closed-sound") else { return }
        let token = "file:\(name)"
        if sender === openSoundPopup { settings.soundOpen = token }
        else { settings.soundClosed = token }
        sender.addItem(withTitle: name)
        sender.selectItem(at: sender.numberOfItems - 1)
    }

    @objc private func previewOpenSound() {
        preview(token(for: openSoundPopup), override: true)
    }

    @objc private func previewClosedSound() {
        preview(token(for: closedSoundPopup), override: true)
    }

    private func preview(_ token: String, override: Bool) {
        guard override, token != "none", token != "choose" else { return }
        CustomSoundPlayer.shared.play(token)
    }

    @objc private func saveTapped() {
        settings.delay = max(0, delayField.doubleValue)
        settings.action = actions[max(0, actionPopup.indexOfSelectedItem)]
        settings.transition = transitions[max(0, transitionPopup.indexOfSelectedItem)]
        settings.soundOpen = token(for: openSoundPopup)
        settings.soundClosed = token(for: closedSoundPopup)
        settings.monochrome = monochromeCheck.state == .on
        onSave?(settings)
        window?.orderOut(nil)
    }

    @objc private func cancelTapped() {
        window?.orderOut(nil)
    }
}

/// 自定义音效播放：none / bundle:xxx / system:xxx / file:xxx
final class CustomSoundPlayer {
    static let shared = CustomSoundPlayer()
    private var active: [NSSound] = []
    var volume: Double = 0.12

    func play(_ token: String) {
        guard token != "none", token != "choose" else { return }
        let url: URL?
        if token.hasPrefix("bundle:") {
            url = Bundle.main.url(forResource: String(token.dropFirst(7)), withExtension: "wav")
        } else if token.hasPrefix("system:") {
            url = URL(fileURLWithPath: "/System/Library/Sounds/\(token.dropFirst(7)).aiff")
        } else if token.hasPrefix("file:") {
            url = CustomStore.url(String(token.dropFirst(5)))
        } else {
            url = nil
        }
        guard let url, let sound = NSSound(contentsOf: url, byReference: false) else { return }
        sound.volume = Float(volume * 0.8)
        active.append(sound)
        if active.count > 4 { active.removeFirst() }
        if !sound.play() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { _ = sound.play() }
        }
    }
}
