// 测试用：发一次 ⌥⌘H 全局快捷键。
import AppKit

let source = CGEventSource(stateID: .hidSystemState)
let down = CGEvent(keyboardEventSource: source, virtualKey: 4, keyDown: true)
let up = CGEvent(keyboardEventSource: source, virtualKey: 4, keyDown: false)
down?.flags = [.maskCommand, .maskAlternate]
up?.flags = [.maskCommand, .maskAlternate]
down?.post(tap: .cghidEventTap)
usleep(50_000)
up?.post(tap: .cghidEventTap)
print("posted option+command+h")
