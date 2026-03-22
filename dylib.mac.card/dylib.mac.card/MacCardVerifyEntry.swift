//
//  MacCardVerifyEntry.swift
//  dylib.mac.card
//
//  与 dylib.verify.macos/entry.m 流程对齐：constructor → App 就绪 → gg.in + 独立窗口（激活/提示）+ login.ic；
//  网络与加解密走 bsphp_api_http（Swift），不引用 verify.macos 的 ObjC 源码。
//

import AppKit
import Foundation
import ObjectiveC

// MARK: - 与 verify.macos/Config.h 同源（改后台时只改此处）

private enum MacCardBSPHPConfig {
    static let host = "https://demo.bsphp.com/AppEn.php?appid=66666666&m=3a9d8b17c0a10b1b77f0544d35e835fa&lang=0"
    static let mutualKey = "417a696c5ee663c14bc6fa48b3f53d51"
    static let serverPrivateKey = "MIIEqQIBADANBgkqhkiG9w0BAQEFAASCBJMwggSPAgEAAoH+DZkOodN4q3IMn6momlnOTRSQS86cbHQBxePy3gyIxpayPnm11Y0sYbWyFJhDuTSAZYHbzQLRLRZvgQ1Nk1UmEQRxzUCp5Hkhig53CVfoQA5lgXln0Qgyhe5oOXAbeiLdqwkLIw27cOQyico+s2HniSHxPEl0ikqkXj+AWu5/z18x7PmDiSDRDf26cDteSwLv4on7uYWYsQCv+r8RF63l0ZkjjjCe91Z90aEI0ZTiZT6m0yIabHOHWHN4jhI2b++s8AQRDrN4uD317o9Z7gLeBtC+XDt5kvtJFeOfb9U8+wuneiIZkOhMybqnv1/8OzVfomPvub3Rs8+4q6OeEK8CAwEAAQKB/gG+LHHxePYAmD2esU2XVSnsCNKumL4N4GxM20Q6tw09I3t+fh/xCE89yqV5HrUOVaatDk8onUb6KTCRU/AeadKkjzGPqDbwj6vyTq+T5ODQ95Gwze2s70zbUeCKzfrJnT/e2N6VVAEUPqYKlh7H3bVl9FWV1KolBwxNd1YwW5FZsS6wV5OhAS7Jg8AsxQ+DEj7p8CD5JedTjzFC76WbDh33uyEegvnWRADOiixK43mo/IwleZjC/XkSIg6OOkKCo0EXndebKZF8Jw/GrxVidJgAHYG1JiX6f/0TlIhM+EVvwGs5JU2cDpJzGAcB8n/9NRRwACW9ffm/CHj2FeqBAn88dEttycnA9kDt053qnE09z57KN4d2vpLLywzlzpbwUUVfr/vbAy/j4srmpRBZwdso+KKWxv2zr58FWlTcqwZh6pDcVLZg/6W3RP9TqBk5tb3x4XyCAD7e6XOjm6zG84P/cp/Axx9NrYihsHaKT6GJ1ISsFbnoGBsHeOo8w5MlAn85lOc6lwFt2Vgx9SeiB9WJlTuTbBdxoQ1W1DQAPdqfuNgdYUKPBdNbRAO5kULIizB4elh3pWgG2FT+HTos/IR3pAaQmzXqFjAYt2XLFuNeEI9uiuX7jPtYKzpHR6qhCvn5AsgL+QDsK7vtP6HD1IapcD81hH22Z3TKIcRfFfZDAn8HykCSBCegWtshClzWB5AYf/GJQ0CMd6A47JBb6JQgoYhb/TRqE24PYoEc2XZS6p0QGYHyBfBZQC8wpGQ9DzjCU1SZX70koKy9AgIYyJd/jUDNs2203s07Mj/5fCz2chi3SRD26XHKM6tgknmj9wDs3tq9xgrvsnOBMf6VF+qVAn8SGiCzR6O4X/qdAgAqrSHRdevbxcB9BW+HG4EZjlh7nAW8/sWI5wDyESjGnscK+s8LIRNM0eApPrtBg/i1CdGvNw6lSVYiuET4kDddKF3kRXqB+wKgGUsvBa/1lq8qn6PER76SHP7QQFN9G2MEiHypKdOFRJiszktl/EWayvG3An8BTmEK8TCs7Pq9SHQ9DEq6NQPOk5cTt5UN++mp4gqHGifzv3TBy4/+GQ2jm5xZCBJY73yhQ7YpJuVnfoQ+4Ya6PvdiuMWLDXXP0YuWzjWgbSt985dVkTNCyPR0p7NCk3CBTRKmAx7+jNyhFlbvkoAdCoOYqBxyPpbdT5ouDpek"
    static let clientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/gu5s9VMT323+6PzHKyNyESY0oBHdDgaq7rT5VyG7ETJZtI/Q9gaILfOv+ciobZA0WGlQHi/7ri/TDA1cEszg4uvPDEMw9lCLrY9kof5m3JJhLbJAov072oevMUdDcu92Szyl1qZXQ400zYXNVJDs95JNvvyK5OBIdGVsHi0JbczWMQF9QWYrn8dF8n3WWu8a3abslHV7W/JewBhYLlEgys1SkQqe7eIZfeTGi8elbVoXPwn2Bs+FSzViH9kxp4Out9eDjr/AeCDeuqFR39UfMLPDgXAKKv7HdskCWgZYDJSVk5CM3hpNj6RDBYNor83iurU3Y3+o/EDHNKyvRI3AgMBAAE="
}

private let kActivationDeviceIDKey = "activationDeviceID"

/// 自定义 `beginSheet`/`endSheet` 的 `returnCode`。勿用 `alertFirst/SecondButtonReturn`：部分系统/场景下 `endSheet` 传入的 1001 在 completion 里会变成 **1000**，与「取消」混淆，导致点「激活」却走取消分支。
private enum ActivationSheetReturnCode {
    static let cancel = NSApplication.ModalResponse(rawValue: 440_000)
    static let activate = NSApplication.ModalResponse(rawValue: 440_001)
}

private enum MacCardMessageKind {
    case success
    case info
    case error

    var windowTitle: String {
        switch self {
        case .success: return "验证成功"
        case .info: return "提示"
        case .error: return "错误"
        }
    }
}

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

private final class ActivationWindowDelegate: NSObject, NSWindowDelegate {
    var onWillClose: (() -> Void)?
    /// 仅 `presentActivationWindow` / `presentMessagePanel` 走 `NSApp.runModal(for:)` 时为 true。
    var stopsAppModalLoop = false
    /// 点「激活/确定」等已主动 `stopModal` 后再 `close` 时，仍会进 `windowWillClose`；若此处再 `stopModal` 会二次结束模态会话，破坏栈并闪退（无父窗、纯 `runModal` 时常见）。
    var suppressStopModalOnClose = false

    func windowWillClose(_ notification: Notification) {
        if stopsAppModalLoop, !suppressStopModalOnClose,
           let win = notification.object as? NSWindow, NSApp.modalWindow === win
        {
            NSApp.stopModal(withCode: ActivationSheetReturnCode.cancel)
        }
        onWillClose?()
    }
}

/// `objc_setAssociatedObject` 不能绑 Swift 闭包，用 `NSObject` 包一层。
private final class ActivationHandlerBox: NSObject {
    let handler: (NSApplication.ModalResponse, NSTextField) -> Void
    init(_ handler: @escaping (NSApplication.ModalResponse, NSTextField) -> Void) {
        self.handler = handler
        super.init()
    }
}

private final class MessageDismissBox: NSObject {
    private var block: (() -> Void)?
    init(_ block: @escaping () -> Void) {
        self.block = block
        super.init()
    }

    func invokeOnce() {
        let b = block
        block = nil
        b?()
    }
}

// MARK: - 入口（供 ObjC constructor 调用）

@objc(MacCardVerifyEntry)
public final class MacCardVerifyEntry: NSObject {
    @objc public static let shared = MacCardVerifyEntry()

    private let client: BSPHPClient
    private var didBootstrap = false
    private let defaults = UserDefaults.standard
    private var bootstrapFlowScheduled = false
    private var presentedActivationWindow: NSWindow?
    private var activationWindowDelegate: ActivationWindowDelegate?
    private var presentedMessageWindow: NSWindow?
    private var messageWindowDelegate: ActivationWindowDelegate?

    private override init() {
        client = BSPHPClient(
            url: MacCardBSPHPConfig.host,
            mutualKey: MacCardBSPHPConfig.mutualKey,
            serverPrivateKey: MacCardBSPHPConfig.serverPrivateKey,
            clientPublicKey: MacCardBSPHPConfig.clientPublicKey
        )
        super.init()
    }

    /// 辨认本模块来源；放在窗口正文区由 `NSTextField(wrappingLabelWithString:)` 排版，避免 `NSAlert` 标题栏断行。
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

    private static let messageWindowWidth: CGFloat = 440
    private static let messageBodyMaxHeight: CGFloat = 320
    private static let messageWindowMargin: CGFloat = 16

    private static func estimatedTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height)
    }

    private static func scrollablePlainText(_ text: String, textWidth: CGFloat) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder
        scroll.drawsBackground = true
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.drawsBackground = false
        tv.font = .systemFont(ofSize: NSFont.systemFontSize)
        tv.textColor = .labelColor
        tv.string = text
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.lineFragmentPadding = 2
        tv.textContainer?.containerSize = NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        tv.minSize = NSSize(width: 0, height: 0)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.translatesAutoresizingMaskIntoConstraints = true

        scroll.documentView = tv
        return scroll
    }

    /// 授权表单主体（公告滚动区 + 卡密输入）。
    private static func activationFormColumn(
        notice: String,
        textField: NSTextField,
        innerWidth: CGFloat,
        scrollMinHeight: CGFloat
    ) -> NSView {
        let innerW = innerWidth

        let topText = """
        【软件公告 · gg.in 接口获取】

        \(notice)

        ——————————————————————————

        上方「软件公告」正文由 gg.in 接口获取。

        首次激活成功后会保存卡密；第二次及以后打开会先静默验证一次（login.ic），通过则不再显示本窗口。
        """
        let scroll = scrollablePlainText(topText, textWidth: innerW - 8)

        let caption = NSTextField(labelWithString: "请输入激活码：")
        caption.font = .systemFont(ofSize: NSFont.systemFontSize)
        caption.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)

        let bottomStack = NSStackView(views: [caption, textField])
        bottomStack.orientation = .vertical
        bottomStack.alignment = .leading
        bottomStack.spacing = 6
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.setContentHuggingPriority(.required, for: .vertical)
        bottomStack.setContentCompressionResistancePriority(.required, for: .vertical)

        let mainStack = NSStackView(views: [scroll, bottomStack])
        mainStack.orientation = .vertical
        mainStack.alignment = .width
        mainStack.spacing = 12
        mainStack.distribution = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        scroll.setContentHuggingPriority(.init(1), for: .vertical)
        scroll.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: scrollMinHeight),
            textField.widthAnchor.constraint(equalToConstant: innerW),
            textField.heightAnchor.constraint(equalToConstant: 26),
        ])
        return mainStack
    }

    /// 独立窗口：标题栏单独占一行，内容区有足够高度。
    private static let activationWindowWidth: CGFloat = 520
    private static let activationWindowHeight: CGFloat = 560
    private static let activationWindowMargin: CGFloat = 16

    private func dismissActivationWindow(_ window: NSWindow, returnCode: NSApplication.ModalResponse, parent: NSWindow?) {
        if let parent {
            // 切勿在 endSheet 前 release `activationWindowDelegate`：`window.delegate` 为 weak，提前置 nil 会导致 sheet 收尾阶段野指针/闪退。
            // `presentedActivationWindow` / delegate 在 `beginSheet` 的 completion 里统一清理。
            parent.endSheet(window, returnCode: returnCode)
        } else {
            activationWindowDelegate?.suppressStopModalOnClose = true
            NSApp.stopModal(withCode: returnCode)
            window.close()
            presentedActivationWindow = nil
            activationWindowDelegate = nil
        }
    }

    private func presentActivationWindow(notice: String, parent: NSWindow?, handle: @escaping (NSApplication.ModalResponse, NSTextField) -> Void) {
        if let existing = presentedActivationWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            Self.log("激活窗口已在显示，忽略重复弹出")
            return
        }

        let margin = Self.activationWindowMargin
        let innerW = Self.activationWindowWidth - margin * 2
        let tf = NSTextField(frame: .zero)
        tf.placeholderString = "请输入激活码"
        tf.stringValue = ""
        tf.isBezeled = true
        tf.bezelStyle = .squareBezel

        let form = Self.activationFormColumn(
            notice: notice,
            textField: tf,
            innerWidth: innerW,
            scrollMinHeight: 200
        )
        form.translatesAutoresizingMaskIntoConstraints = false

        let activationTag = NSTextField(wrappingLabelWithString: Self.alertTag())
        activationTag.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        activationTag.textColor = .secondaryLabelColor
        activationTag.translatesAutoresizingMaskIntoConstraints = false
        activationTag.preferredMaxLayoutWidth = innerW

        let cancelBtn = NSButton(title: "取消", target: nil, action: nil)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.keyEquivalent = "\u{1b}"

        let okBtn = NSButton(title: "激活", target: nil, action: nil)
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.keyEquivalent = "\r"

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)

        let buttonRow = NSStackView(views: [spacer, cancelBtn, okBtn])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 12
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let rootStack = NSStackView(views: [activationTag, form, buttonRow])
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 14
        rootStack.edgeInsets = NSEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: .zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: content.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.widthAnchor.constraint(equalToConstant: Self.activationWindowWidth),
            content.heightAnchor.constraint(equalToConstant: Self.activationWindowHeight),
        ])

        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.activationWindowWidth, height: Self.activationWindowHeight),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = "输入授权码"
        window.contentView = content
        window.contentMinSize = NSSize(width: 440, height: 420)
        window.isReleasedWhenClosed = false
        window.level = .floating

        let del = ActivationWindowDelegate()
        del.stopsAppModalLoop = parent == nil
        del.onWillClose = { [weak self, weak window] in
            guard let self, let window else { return }
            if self.presentedActivationWindow === window {
                self.presentedActivationWindow = nil
            }
            // 不在此处 release `activationWindowDelegate`，避免与 `endSheet` completion 竞态；无 parent 的 runModal 路径在 dismissActivationWindow 末尾已清理。
        }
        window.delegate = del
        activationWindowDelegate = del
        presentedActivationWindow = window

        cancelBtn.target = self
        cancelBtn.action = #selector(MacCardVerifyEntry._activationCancelClicked(_:))
        okBtn.target = self
        okBtn.action = #selector(MacCardVerifyEntry._activationOKClicked(_:))

        let box = ActivationHandlerBox(handle)
        objc_setAssociatedObject(window, &AssociatedKeys.handlerBox, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(window, &AssociatedKeys.textField, tf, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(window, &AssociatedKeys.parentWindow, parent as Any?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if let parent {
            parent.beginSheet(window) { [weak self] response in
                guard let self else {
                    objc_setAssociatedObject(window, &AssociatedKeys.handlerBox, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    return
                }
                self.presentedActivationWindow = nil
                self.activationWindowDelegate = nil
                let tf2 = objc_getAssociatedObject(window, &AssociatedKeys.textField) as? NSTextField
                let handlerBox = objc_getAssociatedObject(window, &AssociatedKeys.handlerBox) as? ActivationHandlerBox
                objc_setAssociatedObject(window, &AssociatedKeys.handlerBox, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                if let tf2, let handlerBox {
                    Self.log("激活窗 sheet 已结束，returnCode=\(response.rawValue)，进入回调")
                    handlerBox.handler(response, tf2)
                } else {
                    Self.log("激活窗 sheet 结束但未取到 handler/textField（异常）")
                }
            }
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            let response = NSApp.runModal(for: window)
            let tf2 = objc_getAssociatedObject(window, &AssociatedKeys.textField) as? NSTextField
            let handlerBox = objc_getAssociatedObject(window, &AssociatedKeys.handlerBox) as? ActivationHandlerBox
            objc_setAssociatedObject(window, &AssociatedKeys.handlerBox, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let tf2, let handlerBox {
                handlerBox.handler(response, tf2)
            }
            presentedActivationWindow = nil
            activationWindowDelegate = nil
        }
    }

    private struct AssociatedKeys {
        static var handlerBox: UInt8 = 0
        static var textField: UInt8 = 0
        static var parentWindow: UInt8 = 0
        static var messageParentWindow: UInt8 = 0
        static var messageOnDismiss: UInt8 = 0
    }

    @objc private func _activationCancelClicked(_ sender: NSButton) {
        Self.log("激活窗：取消")
        guard let window = sender.window else { return }
        let parent = objc_getAssociatedObject(window, &AssociatedKeys.parentWindow) as? NSWindow
        dismissActivationWindow(window, returnCode: ActivationSheetReturnCode.cancel, parent: parent)
    }

    @objc private func _activationOKClicked(_ sender: NSButton) {
        Self.log("激活窗：点击「激活」→ endSheet / stopModal → 将调用 login.ic")
        guard let window = sender.window else { return }
        let parent = objc_getAssociatedObject(window, &AssociatedKeys.parentWindow) as? NSWindow
        if let tf = objc_getAssociatedObject(window, &AssociatedKeys.textField) as? NSTextField {
            let t = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty {
                Self.log("激活窗：卡密为空，提示请输入激活码（不关激活窗）")
                // 以本窗为 parent 做 sheet，避免先 endSheet 后 bestParentWindow 为空或 returnCode 异常导致用户看不到提示
                presentMessagePanel(kind: .info, body: "请输入激活码", parent: window, onDismiss: nil)
                return
            }
        }
        dismissActivationWindow(window, returnCode: ActivationSheetReturnCode.activate, parent: parent)
    }

    private func invokeMessageOnDismiss(for window: NSWindow) {
        guard let box = objc_getAssociatedObject(window, &AssociatedKeys.messageOnDismiss) as? MessageDismissBox else { return }
        box.invokeOnce()
        objc_setAssociatedObject(window, &AssociatedKeys.messageOnDismiss, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 成功 / 错误 / 提示：独立 `NSWindow`，与激活窗同一套 sheet / `runModal` 语义，避免 `NSAlert` 标题断行与 accessory 被压扁。
    /// - Parameter onDismiss: 在 sheet 结束或 `runModal` 返回后调用一次（用于提示后再打开输入窗等）。
    private func presentMessagePanel(kind: MacCardMessageKind, body: String, parent: NSWindow?, onDismiss: (() -> Void)? = nil) {
        if let existing = presentedMessageWindow, existing.isVisible {
            existing.close()
            presentedMessageWindow = nil
            messageWindowDelegate = nil
        }

        activateAppIgnoringOthers()
        let margin = Self.messageWindowMargin
        let innerW = Self.messageWindowWidth - margin * 2

        let tagField = NSTextField(wrappingLabelWithString: Self.alertTag())
        tagField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        tagField.textColor = .secondaryLabelColor
        tagField.translatesAutoresizingMaskIntoConstraints = false
        tagField.preferredMaxLayoutWidth = innerW

        var stackViews: [NSView] = [tagField]
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBody.isEmpty {
            let textW = innerW - 16
            let bodyH = min(
                max(Self.estimatedTextHeight(trimmedBody, width: textW) + 28, 88),
                Self.messageBodyMaxHeight
            )
            let scroll = Self.scrollablePlainText(trimmedBody, textWidth: textW)
            scroll.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                scroll.widthAnchor.constraint(equalToConstant: innerW),
                scroll.heightAnchor.constraint(equalToConstant: bodyH),
            ])
            stackViews.append(scroll)
        }

        let okBtn = NSButton(title: "确定", target: nil, action: nil)
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.keyEquivalent = "\r"
        okBtn.target = self
        okBtn.action = #selector(MacCardVerifyEntry._messageOKClicked(_:))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let buttonRow = NSStackView(views: [spacer, okBtn])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 12
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        stackViews.append(buttonRow)

        let rootStack = NSStackView(views: stackViews)
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 14
        rootStack.edgeInsets = NSEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: .zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: content.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.widthAnchor.constraint(equalToConstant: Self.messageWindowWidth),
        ])

        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.messageWindowWidth, height: 220),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = kind.windowTitle
        window.contentView = content
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.contentMinSize = NSSize(width: Self.messageWindowWidth, height: 140)

        let del = ActivationWindowDelegate()
        del.stopsAppModalLoop = parent == nil
        del.onWillClose = { [weak self] in
            guard let self else { return }
            if self.presentedMessageWindow === window {
                self.presentedMessageWindow = nil
                self.messageWindowDelegate = nil
            }
        }
        window.delegate = del
        messageWindowDelegate = del
        presentedMessageWindow = window

        objc_setAssociatedObject(window, &AssociatedKeys.messageParentWindow, parent as Any?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if let onDismiss {
            objc_setAssociatedObject(
                window,
                &AssociatedKeys.messageOnDismiss,
                MessageDismissBox(onDismiss),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

        content.layoutSubtreeIfNeeded()
        let fitH = max(rootStack.fittingSize.height, 120)
        window.setContentSize(NSSize(width: Self.messageWindowWidth, height: fitH))

        if let parent {
            parent.beginSheet(window) { [weak self] _ in
                guard let self else { return }
                self.invokeMessageOnDismiss(for: window)
                if self.presentedMessageWindow === window {
                    self.presentedMessageWindow = nil
                    self.messageWindowDelegate = nil
                }
            }
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            _ = NSApp.runModal(for: window)
            invokeMessageOnDismiss(for: window)
            presentedMessageWindow = nil
            messageWindowDelegate = nil
        }
    }

    @objc private func _messageOKClicked(_ sender: NSButton) {
        guard let window = sender.window else { return }
        let parent = objc_getAssociatedObject(window, &AssociatedKeys.messageParentWindow) as? NSWindow
        if let parent {
            parent.endSheet(window)
        } else {
            messageWindowDelegate?.suppressStopModalOnClose = true
            NSApp.stopModal(withCode: .OK)
            window.close()
        }
    }

    @objc public func showAlertMsg(_ show: String?, error: Bool) {
        Self.runOnMain { [weak self] in
            guard let self else { return }
            let kind: MacCardMessageKind = error ? .error : .info
            self.presentMessagePanel(kind: kind, body: show ?? "", parent: self.bestParentWindow())
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
        let parts = dataString.split(separator: "|", omittingEmptySubsequences: false)
        let okByCode = (apiCode == 1011 || apiCode == 9908 || apiCode == 1081)
        let okByPipe = dataString.range(of: "|1081|") != nil
        let okBy200 = (apiCode == 200 && parts.count >= 6)
        return okByCode || okByPipe || okBy200
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
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
            Self.runOnMain { [weak self] in
                guard let self else { return }
                self.presentMessagePanel(
                    kind: .info,
                    body: "请输入激活码",
                    parent: self.bestParentWindow(),
                    onDismiss: { [weak self] in
                        finish?(["ok": false, "reason": "empty_code"] as [AnyHashable: Any])
                        self?.processActivate()
                    }
                )
            }
            return
        }
        Task { [weak self] in
            guard let self else {
                finish?(nil)
                return
            }
            Self.log("startProcessActivateProcess：开始 login.ic，icid 长度 \(trimmed.count)")
            do {
                try await self.ensureBootstrapped()
            } catch {
                Self.runOnMain {
                    self.processActivate()
                    finish?(["ok": false, "reason": "bootstrap_failed", "error": error.localizedDescription] as [AnyHashable: Any])
                }
                return
            }
            let machine = self.getIDFA()
            let result = await self.client.loginIC(icid: trimmed, icpwd: "", key: machine, maxoror: machine)
            Self.log("login.ic 返回 code=\(result.code.map(String.init) ?? "nil") message=\(result.message.prefix(80))")
            await MainActor.run { [weak self] in
                guard let self else {
                    finish?(nil)
                    return
                }
                // 与 entry.m login.ic `myfailure` 一致：网络层失败只重开输入框，不清用户信息、不弹错误
                if result.code == nil, let s = result.data as? String, s == "系统错误，登录失败！" {
                    self.processActivate()
                    finish?([
                        "ok": false,
                        "reason": "login_ic_transport",
                        "message": s
                    ] as [AnyHashable: Any])
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
                        self.activateAppIgnoringOthers()
                        let showMsg = "过期时间: \(arr[4])"
                        self.presentMessagePanel(kind: .success, body: showMsg, parent: self.bestParentWindow())
                        finish?([
                            "ok": true,
                            "code": apiCode,
                            "data": dataString
                        ] as [AnyHashable: Any])
                    } else if (apiCode == 1011 || apiCode == 9908 || apiCode == 1081 || apiCode == 200), !dataString.isEmpty {
                        self.activateAppIgnoringOthers()
                        self.presentMessagePanel(kind: .success, body: dataString, parent: self.bestParentWindow())
                        finish?([
                            "ok": true,
                            "code": apiCode,
                            "data": dataString
                        ] as [AnyHashable: Any])
                    } else {
                        // 与 entry.m 对齐：okByCode 成功但无 6 段管道、且 data 为空时，原先两个分支都不进，用户会感觉「没返回」
                        self.activateAppIgnoringOthers()
                        Self.log("login.ic：服务端判成功（code=\(apiCode)）但 data 非标准格式（段数=\(arr.count)），仍提示激活成功")
                        self.presentMessagePanel(kind: .success, body: "激活成功", parent: self.bestParentWindow())
                        finish?([
                            "ok": true,
                            "code": apiCode,
                            "data": dataString
                        ] as [AnyHashable: Any])
                    }
                } else {
                    self.clearUserInfo()
                    var messageStr = self.jsonString(from: result.data)
                    if messageStr.isEmpty { messageStr = "验证失败" }
                    self.showAlertMsg(messageStr, error: true)
                    self.processActivate()
                    finish?([
                        "ok": false,
                        "code": apiCode,
                        "message": messageStr
                    ] as [AnyHashable: Any])
                }
            }
        }
    }

    @objc public func processActivate() {
        Self.log("拉取 gg.in 公告后显示授权码输入框")
        Task { [weak self] in
            guard let self else { return }
            let notice = await self.fetchGgNoticeText()
            Self.runOnMain { [weak self] in
                guard let self else { return }
                self.activateAppIgnoringOthers()
                Self.log("显示授权码输入框（独立 NSWindow），公告长度 \(notice.count)")
                let parent = self.bestParentWindow()
                self.presentActivationWindow(notice: notice, parent: parent) { [weak self] r, tf in
                    guard let self else { return }
                    if r == ActivationSheetReturnCode.activate {
                        let t = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        Self.log("激活回调：activate，卡密长度 \(t.count)")
                        self.startProcessActivateProcess(t, finish: nil)
                    } else {
                        Self.log("激活回调：非激活按钮 returnCode=\(r.rawValue)，重新拉公告")
                        self.processActivate()
                    }
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
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if result.code == nil, let s = result.data as? String, s == "系统错误，登录失败！" {
                        self.processActivate()
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
                        self.processActivate()
                    }
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
