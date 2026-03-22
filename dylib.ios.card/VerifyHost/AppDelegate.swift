import Darwin
import UIKit

@main
final class VerifyHostAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let root = UIViewController()
        root.view.backgroundColor = .systemBackground
        window.rootViewController = root
        window.makeKeyAndVisible()

        let exeDir = Bundle.main.executableURL!.deletingLastPathComponent()
        let dylibURL = exeDir.appendingPathComponent("libdylib.ios.card.dylib")
        let path = dylibURL.path

        guard dlopen(path, RTLD_NOW) != nil else {
            let errPtr = dlerror()
            let detail = errPtr.map { String(cString: $0) } ?? "unknown"
            NSLog("[VerifyHost] dlopen 失败: %@ — %@", path, detail)
            let alert = UIAlertController(
                title: "VerifyHost：未加载 libdylib.ios.card.dylib",
                message: """
                路径：\(path)

                \(detail)

                请先编译 dylib.ios.card 目标，并确认 Copy Files 已将 dylib 拷入 App 包内（与可执行文件同目录）。
                """,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "好", style: .default))
            root.present(alert, animated: true)
            return true
        }

        NSLog("[VerifyHost] 已 dlopen %@（constructor 将拉起验证流程）", path)
        return true
    }
}
