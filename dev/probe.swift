// 探针：验证 macOS 27 的菜单栏白名单接口在当前系统上可用。
// 用法：./probe [秒数]   —— 期间除系统图标外全部隐藏，到时自动恢复。

import AppKit

func log(_ text: String) { print(text); fflush(stdout) }

log("available = \(HBNativeVisibilityIsAvailable())")

let keepSeconds = CommandLine.arguments.count > 1 ? Double(CommandLine.arguments[1]) ?? 5 : 5
let systemItems = (0..<64).map { NSNumber(value: $0) }

HBNativeVisibilityActivate(systemItems, []) { assertion, error in
    if let error {
        log("FAILED: \(error.localizedDescription)")
        exit(1)
    }
    guard let assertion else {
        log("FAILED: no assertion")
        exit(1)
    }
    log("activated, hiding everything for \(keepSeconds)s")
    DispatchQueue.main.asyncAfter(deadline: .now() + keepSeconds) {
        HBNativeVisibilityInvalidate(assertion)
        log("restored")
        exit(0)
    }
}

RunLoop.main.run()
