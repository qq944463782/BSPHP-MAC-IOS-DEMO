//
//  CardMainControlPanelWindowHost.swift
//  bsphp.mac.demo.card
//
//  用 NSWindow + NSHostingController 承载 CardMainControlPanelView；
//  已打开时再次 present 会前置窗口；关闭时回调 onSessionEnd 清理状态。
//

import AppKit
import SwiftUI

private final class CardMainControlPanelWindowDelegate: NSObject, NSWindowDelegate {
    var onWillClose: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        onWillClose?()
        onWillClose = nil
    }
}

/// 管理「主控制面板」专用窗口；已打开时再次调用会前置该窗口。
@MainActor
final class CardMainControlPanelWindowHost: ObservableObject {
    private var panelWindow: NSWindow?
    private let windowDelegate = CardMainControlPanelWindowDelegate()

    func presentPanel(
        client: BSPHPClient,
        loggedCardId: String,
        initialVipExpiry: String,
        onSessionEnd: @escaping () -> Void
    ) {
        if let w = panelWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        panelWindow?.close()
        panelWindow = nil

        windowDelegate.onWillClose = { [weak self] in
            self?.panelWindow = nil
            onSessionEnd()
        }

        let root = CardMainControlPanelView(
            client: client,
            loggedCardId: loggedCardId,
            initialVipExpiry: initialVipExpiry,
            onLogout: { [weak self] in
                onSessionEnd()
                self?.panelWindow?.close()
            }
        )

        let hosting = NSHostingController(rootView: root)
        let win = NSWindow(contentViewController: hosting)
        win.title = "主控制面板 — \(loggedCardId)"
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        win.setContentSize(NSSize(width: 680, height: 620))
        win.minSize = NSSize(width: 520, height: 400)
        win.delegate = windowDelegate
        win.setFrameAutosaveName("BSPHPCardMainControlPanel")
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panelWindow = win
    }
}
