//
//  IOSCardVerifyEntry.swift
//  dylib.ios.card
//
//  行为对齐 verify/entry.mm：constructor 延迟拉起、gg.in 公告、login.ic 卡密、持久化 activationDeviceID。
//

import UIKit

@objc(IOSCardVerifyEntry)
public final class IOSCardVerifyEntry: NSObject {

    @objc public static let shared = IOSCardVerifyEntry()

    private let client: BSPHPClient
    private var bootstrapped = false

    private override init() {
        self.client = BSPHPClient(config: IOSCardConfig.makeClientConfig())
        super.init()
    }

    /// 由 C 构造函数调用，在动态库加载后执行
    @objc public static func runConstructor() {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.1) {
            shared.performEntrySequence()
        }
    }

    private func performEntrySequence() {
        if let saved = UserDefaults.standard.string(forKey: IOSCardConfig.savedActivationDefaultsKey), !saved.isEmpty {
            Task { await silentRevalidate(savedCode: saved) }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task { await self.processActivate() }
            }
        }
    }

    // MARK: - Bootstrap

    private func ensureBootstrap() async throws {
        if bootstrapped { return }
        try await client.bootstrap()
        bootstrapped = true
    }

    // MARK: - Silent login (constructor path)

    private func silentRevalidate(savedCode: String) async {
        do {
            try await ensureBootstrap()
            let result = await client.loginIC(icid: savedCode, icpwd: "", key: nil, maxoror: nil)
            let dataString = result.message
            let apiCode = result.code
            if loginSucceeded(code: apiCode, dataString: dataString) {
                applyLoginSuccess(dataString: dataString)
                return
            }
            clearUserInfo()
            await scheduleActivateUI()
        } catch {
            await scheduleActivateUI()
        }
    }

    private func scheduleActivateUI() async {
        await MainActor.run {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task { await self.processActivate() }
            }
        }
    }

    // MARK: - gg.in + 激活弹窗

    private func processActivate() async {
        do {
            try await ensureBootstrap()
            let resp = try await client.send(api: "gg.in")
            let notice = Self.parseGgNotice(from: resp)
            let body = "【软件公告 · gg.in 接口获取】\n\n\(notice)\n\n————————————————\n\(IOSCardConfig.activationAlertFooter)"
            await MainActor.run { presentActivationAlert(message: body) }
        } catch {
            let fallback = "（公告 gg.in 获取失败：\(error.localizedDescription)）"
            let body = "\(fallback)\n\n————————————————\n\(IOSCardConfig.activationAlertFooter)"
            await MainActor.run { presentActivationAlert(message: body) }
        }
    }

    private static func parseGgNotice(from response: [String: Any]?) -> String {
        guard let data = response?["data"] else {
            return "（后台暂无公告内容）"
        }
        let notice: String
        if let s = data as? String {
            notice = s
        } else if data is NSNull {
            notice = ""
        } else {
            notice = "\(data)"
        }
        let trimmed = notice.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "（后台暂无公告内容）" : trimmed
    }

    // MARK: - login.ic

    private func loginSucceeded(code: Int?, dataString: String) -> Bool {
        let c = code ?? 0
        let okByCode = (c == 1011 || c == 9908 || c == 1081)
        let okByPipe = dataString.range(of: "|1081|") != nil
        return okByCode || okByPipe
    }

    private func applyLoginSuccess(dataString: String) {
        let arr = dataString.components(separatedBy: "|")
        guard arr.count >= 6 else { return }
        let u = UserInfoStore.shared
        u.state01 = arr[0]
        u.state1081 = arr[1]
        u.deviceID = arr[2]
        u.returnData = arr[3]
        u.expirationTime = arr[4]
        u.activationTime = arr[5]
    }

    private func clearUserInfo() {
        let u = UserInfoStore.shared
        u.state01 = nil
        u.state1081 = nil
        u.deviceID = nil
        u.returnData = nil
        u.expirationTime = nil
        u.activationTime = nil
    }

    private func submitActivation(code: String) async {
        do {
            try await ensureBootstrap()
            let result = await client.loginIC(icid: code, icpwd: "", key: nil, maxoror: nil)
            let dataString = result.message
            let apiCode = result.code
            if loginSucceeded(code: apiCode, dataString: dataString) {
                UserDefaults.standard.set(code, forKey: IOSCardConfig.savedActivationDefaultsKey)
                applyLoginSuccess(dataString: dataString)
                let arr = dataString.components(separatedBy: "|")
                await MainActor.run {
                    if arr.count >= 6 {
                        presentSuccessAlert(message: "过期时间: \(arr[4])")
                    } else if !dataString.isEmpty {
                        presentSuccessAlert(message: dataString)
                    }
                }
            } else {
                clearUserInfo()
                let msg = result.message.isEmpty ? "验证失败" : result.message
                await MainActor.run { presentInfoAlert(message: msg) }
                await processActivate()
            }
        } catch {
            await processActivate()
        }
    }

    // MARK: - UI

    private func presentActivationAlert(message: String) {
        guard let host = Self.topPresenter() else { return }
        let alert = UIAlertController(title: "卡密激活", message: message, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "请输入授权码" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            Task { await self?.processActivate() }
        })
        alert.addAction(UIAlertAction(title: "激活", style: .default) { [weak self] _ in
            let raw = alert.textFields?.first?.text ?? ""
            let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if code.isEmpty {
                Task { await self?.processActivate() }
            } else {
                Task { await self?.submitActivation(code: code) }
            }
        })
        host.present(alert, animated: true)
    }

    private func presentSuccessAlert(message: String) {
        guard let host = Self.topPresenter() else { return }
        let alert = UIAlertController(title: "验证成功", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        host.present(alert, animated: true)
    }

    private func presentInfoAlert(message: String) {
        guard let host = Self.topPresenter() else { return }
        let alert = UIAlertController(title: "信息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        host.present(alert, animated: true)
    }

    private static func topPresenter() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return nil }
        let window = scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
        guard var top = window?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        if let nav = top as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = top as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return top
    }
}
