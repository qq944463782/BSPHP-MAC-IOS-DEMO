//
//  MacCardVerifyEntry.swift
//  dylib.mac.card
//
//  与 dylib.verify.macos/entry.m 流程对齐：constructor → App 就绪 → gg.in + NSAlert + login.ic；
//  网络与加解密走 bsphp_api_http（Swift），不引用 verify.macos 的 ObjC 源码。
//

import AppKit
import Foundation

// MARK: - 与 verify.macos/Config.h 同源（改后台时只改此处）

private enum MacCardBSPHPConfig {
    static let host = "https://demo.bsphp.com/AppEn.php?appid=66666666&m=3a9d8b17c0a10b1b77f0544d35e835fa&lang=0"
    static let mutualKey = "417a696c5ee663c14bc6fa48b3f53d51"
    static let serverPrivateKey = "MIIEqQIBADANBgkqhkiG9w0BAQEFAASCBJMwggSPAgEAAoH+DZkOodN4q3IMn6momlnOTRSQS86cbHQBxePy3gyIxpayPnm11Y0sYbWyFJhDuTSAZYHbzQLRLRZvgQ1Nk1UmEQRxzUCp5Hkhig53CVfoQA5lgXln0Qgyhe5oOXAbeiLdqwkLIw27cOQyico+s2HniSHxPEl0ikqkXj+AWu5/z18x7PmDiSDRDf26cDteSwLv4on7uYWYsQCv+r8RF63l0ZkjjjCe91Z90aEI0ZTiZT6m0yIabHOHWHN4jhI2b++s8AQRDrN4uD317o9Z7gLeBtC+XDt5kvtJFeOfb9U8+wuneiIZkOhMybqnv1/8OzVfomPvub3Rs8+4q6OeEK8CAwEAAQKB/gG+LHHxePYAmD2esU2XVSnsCNKumL4N4GxM20Q6tw09I3t+fh/xCE89yqV5HrUOVaatDk8onUb6KTCRU/AeadKkjzGPqDbwj6vyTq+T5ODQ95Gwze2s70zbUeCKzfrJnT/e2N6VVAEUPqYKlh7H3bVl9FWV1KolBwxNd1YwW5FZsS6wV5OhAS7Jg8AsxQ+DEj7p8CD5JedTjzFC76WbDh33uyEegvnWRADOiixK43mo/IwleZjC/XkSIg6OOkKCo0EXndebKZF8Jw/GrxVidJgAHYG1JiX6f/0TlIhM+EVvwGs5JU2cDpJzGAcB8n/9NRRwACW9ffm/CHj2FeqBAn88dEttycnA9kDt053qnE09z57KN4d2vpLLywzlzpbwUUVfr/vbAy/j4srmpRBZwdso+KKWxv2zr58FWlTcqwZh6pDcVLZg/6W3RP9TqBk5tb3x4XyCAD7e6XOjm6zG84P/cp/Axx9NrYihsHaKT6GJ1ISsFbnoGBsHeOo8w5MlAn85lOc6lwFt2Vgx9SeiB9WJlTuTbBdxoQ1W1DQAPdqfuNgdYUKPBdNbRAO5kULIizB4elh3pWgG2FT+HTos/IR3pAaQmzXqFjAYt2XLFuNeEI9uiuX7jPtYKzpHR6qhCvn5AsgL+QDsK7vtP6HD1IapcD81hH22Z3TKIcRfFfZDAn8HykCSBCegWtshClzWB5AYf/GJQ0CMd6A47JBb6JQgoYhb/TRqE24PYoEc2XZS6p0QGYHyBfBZQC8wpGQ9DzjCU1SZX70koKy9AgIYyJd/jUDNs2203s07Mj/5fCz2chi3SRD26XHKM6tgknmj9wDs3tq9xgrvsnOBMf6VF+qVAn8SGiCzR6O4X/qdAgAqrSHRdevbxcB9BW+HG4EZjlh7nAW8/sWI5wDyESjGnscK+s8LIRNM0eApPrtBg/i1CdGvNw6lSVYiuET4kDddKF3kRXqB+wKgGUsvBa/1lq8qn8PER76SHP7QQFN9G2MEiHypKdOFRJiszktl/EWayvG3An8BTmEK8TCs7Pq9SHQ9DEq6NQPOk5cTt5UN++mp4gqHGifzv3TBy4/+GQ2jm5xZCBJY73yhQ7YpJuVnfoQ+4Ya6PvdiuMWLDXXP0YuWzjWgbSt985dVkTNCyPR0p7NCk3CBTRKmAx7+jNyhFlbvkoAdCoOYqBxyPpbdT5ouDpek"
    static let clientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/gu5s9VMT323+6PzHKyNyESY0oBHdDgaq7rT5VyG7ETJZtI/Q9gaILfOv+ciobZA0WGlQHi/7ri/TDA1cEszg4uvPDEMw9lCLrY9kof5m3JJhLbJAov072oevMUdDcu92Szyl1qZXQ400zYXNVJDs95JNvvyK5OBIdGVsHi0JbczWMQF9QWYrn8dF8n3WWu8a3abslHV7W/JewBhYLlEgys1SkQqe7eIZfeTGi8elbVoXPwn2Bs+FSzViH9kxp4Out9eDjr/AeCDeuqFR39UfMLPDgXAKKv7HdskCWgZYDJSVk5CM3hpNj6RDBYNor83iurU3Y3+o/EDHNKyvRI3AgMBAAE="
}

private let kActivationDeviceIDKey = "activationDeviceID"

// MARK: - 进程内用户信息（对齐 UserInfoManager）

private final class MacCardUserInfoStore {
    static let shared = MacCardUserInfoStore()
    var state01: String?
    var state1081: String?
    var deviceID: String?
    var returnData: String?
    var expirationTime: String?
    var activationTime: String?
}

// MARK: - 入口（供 ObjC constructor 调用）

@objc(MacCardVerifyEntry)
public final class MacCardVerifyEntry: NSObject {
    @objc public static let shared = MacCardVerifyEntry()

    private let client: BSPHPClient
    private var didBootstrap = false
    private let defaults = UserDefaults.standard
    private var bootstrapFlowScheduled = false

    private override init() {
        client = BSPHPClient(
            url: MacCardBSPHPConfig.host,
            mutualKey: MacCardBSPHPConfig.mutualKey,
            serverPrivateKey: MacCardBSPHPConfig.serverPrivateKey,
            clientPublicKey: MacCardBSPHPConfig.clientPublicKey
        )
        super.init()
    }

    private static func alertTag() -> String { "【我的验证dylib · dylib.mac.card】" }

    private static func log(_ message: String) {
        NSLog("[dylib.mac.card] %@", message)
    }

    private static func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    /// 与 verify.macos `getIDFA` 一致：硬件 UUID 或 `BSPHPClient.machineCode` 持久化方案
    @objc public func getIDFA() -> String {
        BSPHPClient.machineCode
    }

    private func activateAppIgnoringOthers() {
        NSApp.activate(ignoringOtherApps: true)
    }

    private func bestParentWindow() -> NSWindow? {
        let main = NSApp.mainWindow ?? NSApp.keyWindow
        if main?.isVisible == true { return main }
        for w in NSApp.windows where w.isVisible && !w.isMiniaturized {
            return w
        }
        return nil
    }

    /// 输入框上方说明：gg.in 接口获取公告；首次激活保存卡密；再次打开静默 login.ic 通过则不弹窗
    private static func activationInputAccessoryStack(textField: NSTextField) -> NSView {
        let contentWidth: CGFloat = 380
        let hint = """
        上方「软件公告」正文由 gg.in 接口获取。

        首次激活成功后会保存卡密；第二次及以后打开会先静默验证一次（login.ic），通过则不再显示本窗口。
        """
        let hintLabel = NSTextField(wrappingLabelWithString: hint)
        hintLabel.preferredMaxLayoutWidth = contentWidth
        hintLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        let caption = NSTextField(labelWithString: "请输入卡密：")
        caption.font = .systemFont(ofSize: NSFont.systemFontSize)
        caption.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [hintLabel, caption, textField])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: contentWidth),
            textField.widthAnchor.constraint(equalToConstant: 320),
        ])
        return stack
    }

    @objc public func showAlertMsg(_ show: String?, error: Bool) {
        Self.runOnMain { [weak self] in
            guard let self else { return }
            self.activateAppIgnoringOthers()
            let alert = NSAlert()
            alert.messageText = error ? "\(Self.alertTag()) 信息" : Self.alertTag()
            alert.informativeText = show ?? ""
            alert.addButton(withTitle: "好")
            let parent = self.bestParentWindow()
            if let parent {
                alert.beginSheetModal(for: parent) { _ in }
            } else {
                alert.runModal()
            }
        }
    }

    private func ensureBootstrapped() async throws {
        if didBootstrap { return }
        try await client.bootstrap()
        didBootstrap = true
    }

    private func jsonString(from any: Any?) -> String {
        if let s = any as? String { return s }
        if let any, !(any is NSNull) { return "\(any)" }
        return ""
    }

    private func loginSucceeded(apiCode: Int, dataString: String) -> Bool {
        let okByCode = (apiCode == 1011 || apiCode == 9908 || apiCode == 1081)
        let okByPipe = dataString.range(of: "|1081|") != nil
        return okByCode || okByPipe
    }

    private func applyUserInfoFromPipeData(_ dataString: String) {
        let arr = dataString.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard arr.count >= 6 else { return }
        let m = MacCardUserInfoStore.shared
        m.state01 = arr[0]
        m.state1081 = arr[1]
        m.deviceID = arr[2]
        m.returnData = arr[3]
        m.expirationTime = arr[4]
        m.activationTime = arr[5]
    }

    private func clearUserInfo() {
        let m = MacCardUserInfoStore.shared
        m.state01 = nil
        m.state1081 = nil
        m.deviceID = nil
        m.returnData = nil
        m.expirationTime = nil
        m.activationTime = nil
    }

    private func fetchGgNoticeText() async -> String {
        do {
            try await ensureBootstrapped()
        } catch {
            return "（公告 gg.in 获取失败：\(error.localizedDescription)）"
        }
        do {
            guard let resp = try await client.send(api: "gg.in") else {
                return "（公告 gg.in 获取失败：无响应）"
            }
            let notice = jsonString(from: resp["data"])
            let trimmed = notice.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "（后台暂无公告内容）" }
            return trimmed
        } catch {
            return "（公告 gg.in 获取失败：\(error.localizedDescription)）"
        }
    }

    @objc public func startProcessActivateProcess(_ code: String, finish: (([AnyHashable: Any]?) -> Void)?) {
        finish?(nil)
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            processActivate()
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.ensureBootstrapped()
            } catch {
                Self.runOnMain { self.processActivate() }
                return
            }
            let machine = self.getIDFA()
            let result = await self.client.loginIC(icid: trimmed, icpwd: "", key: machine, maxoror: machine)
            // 与 entry.m login.ic `myfailure` 一致：网络层失败只重开输入框，不清用户信息、不弹错误
            if result.code == nil, let s = result.data as? String, s == "系统错误，登录失败！" {
                Self.runOnMain { self.processActivate() }
                return
            }
            let apiCode = result.code ?? 0
            let dataString = self.jsonString(from: result.data)

            if self.loginSucceeded(apiCode: apiCode, dataString: dataString) {
                let current = self.defaults.string(forKey: kActivationDeviceIDKey)
                if current != trimmed {
                    self.defaults.set(trimmed, forKey: kActivationDeviceIDKey)
                }
                let arr = dataString.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                if arr.count >= 6 {
                    self.applyUserInfoFromPipeData(dataString)
                    Self.runOnMain {
                        self.activateAppIgnoringOthers()
                        let showMsg = "过期时间: \(arr[4])"
                        let alert = NSAlert()
                        alert.messageText = "\(Self.alertTag()) 验证成功"
                        alert.informativeText = showMsg
                        alert.addButton(withTitle: "确定")
                        let parent = self.bestParentWindow()
                        if let parent {
                            alert.beginSheetModal(for: parent) { _ in }
                        } else {
                            alert.runModal()
                        }
                    }
                } else if (apiCode == 1011 || apiCode == 9908 || apiCode == 1081), !dataString.isEmpty {
                    Self.runOnMain {
                        self.activateAppIgnoringOthers()
                        let alert = NSAlert()
                        alert.messageText = "\(Self.alertTag()) 验证成功"
                        alert.informativeText = dataString
                        alert.addButton(withTitle: "确定")
                        let parent = self.bestParentWindow()
                        if let parent {
                            alert.beginSheetModal(for: parent) { _ in }
                        } else {
                            alert.runModal()
                        }
                    }
                }
            } else {
                self.clearUserInfo()
                var messageStr = self.jsonString(from: result.data)
                if messageStr.isEmpty { messageStr = "验证失败" }
                self.showAlertMsg(messageStr, error: true)
                self.processActivate()
            }
        }
    }

    @objc public func processActivate() {
        Self.log("拉取 gg.in 公告后显示授权码输入框")
        Task { [weak self] in
            guard let self else { return }
            let notice = await self.fetchGgNoticeText()
            Self.runOnMain {
                self.activateAppIgnoringOthers()
                Self.log("显示授权码输入框（NSAlert），公告长度 \(notice.count)")
                let alert = NSAlert()
                alert.messageText = "\(Self.alertTag())\n输入授权码"
                alert.informativeText = "【软件公告 · gg.in 接口获取】\n\n\(notice)\n\n——————————————————————————"
                let tf = NSTextField(frame: .zero)
                tf.placeholderString = "请输入授权码"
                tf.stringValue = ""
                tf.isBezeled = true
                tf.bezelStyle = .squareBezel
                alert.accessoryView = Self.activationInputAccessoryStack(textField: tf)
                alert.addButton(withTitle: "取消")
                alert.addButton(withTitle: "激活")

                let handle: (NSApplication.ModalResponse) -> Void = { [weak self] r in
                    guard let self else { return }
                    if r == .alertSecondButtonReturn {
                        let t = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if t.isEmpty {
                            self.processActivate()
                            return
                        }
                        self.startProcessActivateProcess(t, finish: nil)
                    } else {
                        self.processActivate()
                    }
                }

                let parent = self.bestParentWindow()
                if let parent {
                    alert.beginSheetModal(for: parent, completionHandler: handle)
                } else {
                    let r = alert.runModal()
                    handle(r)
                }
            }
        }
    }

    private func runBootstrapFlowOnce() {
        Task { [weak self] in
            guard let self else { return }
            Self.log("开始校验流程（主线程 App 已就绪）")
            do {
                try await self.ensureBootstrapped()
            } catch {
                Self.runOnMain { self.processActivate() }
                return
            }
            if let saved = self.defaults.string(forKey: kActivationDeviceIDKey), !saved.isEmpty {
                let machine = self.getIDFA()
                let result = await self.client.loginIC(icid: saved, icpwd: "", key: machine, maxoror: machine)
                if result.code == nil, let s = result.data as? String, s == "系统错误，登录失败！" {
                    Self.runOnMain { self.processActivate() }
                    return
                }
                let apiCode = result.code ?? 0
                let dataString = self.jsonString(from: result.data)
                if self.loginSucceeded(apiCode: apiCode, dataString: dataString) {
                    if dataString.split(separator: "|", omittingEmptySubsequences: false).count >= 6 {
                        self.applyUserInfoFromPipeData(dataString)
                    }
                    Self.log("已保存卡密仍有效，静默通过（不弹窗）")
                } else {
                    self.clearUserInfo()
                    Self.runOnMain { self.processActivate() }
                }
            } else {
                Self.runOnMain { self.processActivate() }
            }
        }
    }

    @objc public func scheduleBootstrapWhenAppReady() {
        Self.runOnMain { [weak self] in
            guard let self else { return }
            self.activateAppIgnoringOthers()
            Self.log("NSApplication windows=\(NSApp.windows.count)")

            guard !self.bootstrapFlowScheduled else { return }
            self.bootstrapFlowScheduled = true

            var didScheduleFlow = false
            func scheduleFlowOnce() {
                if didScheduleFlow { return }
                didScheduleFlow = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.runBootstrapFlowOnce()
                }
            }

            var obs: NSObjectProtocol?
            obs = NotificationCenter.default.addObserver(
                forName: NSApplication.didFinishLaunchingNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                if let o = obs {
                    NotificationCenter.default.removeObserver(o)
                    obs = nil
                }
                Self.log("收到 NSApplicationDidFinishLaunching")
                scheduleFlowOnce()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Self.log("1s 兜底：尝试启动校验/弹窗")
                scheduleFlowOnce()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if let o = obs {
                    NotificationCenter.default.removeObserver(o)
                    obs = nil
                    Self.log("8s 兜底：仍未收到 DidFinishLaunching，仍尝试弹窗")
                }
                scheduleFlowOnce()
            }
        }
    }
}
