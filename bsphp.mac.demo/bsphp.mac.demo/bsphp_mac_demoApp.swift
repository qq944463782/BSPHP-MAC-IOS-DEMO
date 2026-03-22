//
//  bsphp_mac_demoApp.swift
//  bsphp.mac.demo
//
//  Created by enzu zhou on 2026/3/17.
//

import SwiftUI

@main
struct bsphp_mac_demoApp: App {
    @StateObject private var api = BSPHPAPIViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
        }

        Window("控制台", id: "console") {
            DemoBSphpConsoleWindowView()
                .environmentObject(api)
        }
        .defaultSize(width: 800, height: 400)

        Window("Web登录", id: "webLogin") {
            WebLoginWindowView()
                .environmentObject(api)
        }
        .defaultSize(width: 800, height: 800)
    }
}
