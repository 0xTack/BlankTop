// 实验：只允许某个 bundle 可见，看它是否被保留。
// 用法：./probe2 <bundle-id> [秒数]
import AppKit

func log(_ text: String) { print(text); fflush(stdout) }

let bundle = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "local.deepseekcost"
let seconds = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2]) ?? 6 : 6

log("available = \(HBNativeVisibilityIsAvailable()); allowing only \(bundle)")
HBNativeVisibilityActivate((0..<64).map { NSNumber(value: $0) }, [bundle, "com.xa.menubarfold"]) { assertion, error in
    if let error { log("FAILED: \(error.localizedDescription)"); exit(1) }
    guard let assertion else { log("FAILED: no assertion"); exit(1) }
    log("activated for \(seconds)s")
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        HBNativeVisibilityInvalidate(assertion)
        log("restored")
        exit(0)
    }
}
RunLoop.main.run()
