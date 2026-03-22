//
//  bsphp_app_demo_cardApp.swift
//  bsphp.app.demo.card
//
//  iPhone 卡模式（AppEn .ic）演示入口。
//  使用 SwiftUI 生命周期；具体界面与配置说明见 ContentView（BSPHPCardConfig）。
//

import SwiftUI

@main
struct bsphp_app_demo_cardApp: App {
    var body: some Scene {
        // 单场景 iPhone App；卡密/机器码与主控制面板均在 ContentView 内组织
        WindowGroup {
            ContentView()
        }
    }
}
