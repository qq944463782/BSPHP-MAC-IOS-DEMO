//
//  CardMainControlPanelView.swift
//  bsphp.mac.demo.card
//
//  卡密 / 机器码登录成功后在「独立 NSWindow」中展示的主控制面板：
//  聚合常用 .ic/.in 调试按钮（到期、心跳、自定义配置、绑定本机等）与售卡 Web 入口。
//

import SwiftUI
import AppKit

// MARK: - 售卡 Web（浏览器打开，非 AppEn 加密接口）

/// 售卡 / 续费 webapi 链接（与后台 daihao 一致时改这里）
enum BSPHPCardSaleWeb {
    //后台地址->软件管理->软件配置->软件销售
    private static let renewURLBase = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=index&daihao=66666666"
    static let genURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=index&daihao=66666666"
    static let stockURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=index&daihao=66666666"

    /// 续费链接，附带 `user` 查询参数（一般为当前卡号 `loggedCardId`）
    static func renewURL(forUser user: String) -> String {
        guard var c = URLComponents(string: renewURLBase) else { return renewURLBase }
        var items = c.queryItems ?? []
        let t = user.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty {
            items.append(URLQueryItem(name: "user", value: t))
        }
        c.queryItems = items
        return c.string ?? renewURLBase
    }

    static func openInBrowser(_ urlString: String) {
        if let u = URL(string: urlString) { NSWorkspace.shared.open(u) }
    }
}

// MARK: - 主控制面板视图

/// 依赖已登录的 `BSPHPClient` 会话，展示卡号、到期与各类 API 快捷调用。
struct CardMainControlPanelView: View {
    let client: BSPHPClient
    let loggedCardId: String
    let onLogout: () -> Void

    @State private var vipExpiryText: String
    @State private var cardAuxPwd = ""
    @State private var panelDetail = ""
    @State private var isLoading = false

    init(client: BSPHPClient, loggedCardId: String, initialVipExpiry: String, onLogout: @escaping () -> Void) {
        self.client = client
        self.loggedCardId = loggedCardId
        self.onLogout = onLogout
        _vipExpiryText = State(initialValue: initialVipExpiry)
    }

    var body: some View {
        ScrollView {
            GroupBox("主控制面板") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前卡号：\(loggedCardId)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("VIP 到期：\(vipExpiryText)")
                        .font(.headline)

                    HStack(spacing: 8) {
                        panelBtn("刷新到期") {
                            let r = await client.getDateIC()
                            let t = r.message
                            if !t.isEmpty { vipExpiryText = t }
                            return r
                        }
                        panelBtn("登录状态") { await client.getLoginInfo() }
                        panelBtn("心跳") { await client.heartbeat() }
                        panelBtn("公告") { await client.getNotice() }
                    }
                    HStack(spacing: 8) {
                        panelBtn("服务器时间") { await client.getServerDate() }
                        panelBtn("版本") { await client.getVersion() }
                        panelBtn("软件描述") { await client.getSoftInfo() }
                        panelBtn("预设URL") { await client.getPresetURL() }
                        panelBtn("Web地址") { await client.getWebURL() }
                    }

                    Text("自定义配置模型")
                        .font(.headline)
                    HStack(spacing: 8) {
                        panelBtn("软件配置") { await client.getAppCustom(info: "myapp") }
                        panelBtn("VIP配置") { await client.getAppCustom(info: "myvip") }
                        panelBtn("登录配置") { await client.getAppCustom(info: "mylogin") }
                    }
                    Text("公共函数")
                        .font(.headline)
                    HStack(spacing: 8) {
                        panelBtn("全局配置") { await client.getGlobalInfo() }
                        panelBtn("逻辑A") { await client.getLogicA() }
                        panelBtn("逻辑B") { await client.getLogicB() }
                        panelBtn("激活查询") { await client.queryCard(cardid: loggedCardId) }
                    }
                    HStack(spacing: 8) {
                        panelBtn("卡信息示例") {
                            await client.getCardInfo(ic_carid: loggedCardId, ic_pwd: cardAuxPwd, info: "UserName", type: nil)
                        }
                    }

                    Divider().padding(.vertical, 2)
                    Text("卡密（解绑、绑定本机、卡信息 等需要时填写）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("可选：卡密码", text: $cardAuxPwd)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        panelBtn("绑定本机") {
                            await client.bindCard(key: BSPHPClient.machineCode, icid: loggedCardId, icpwd: cardAuxPwd)
                        }
                        panelBtn("解除绑定") {
                            await client.unbindCard(icid: loggedCardId, icpwd: cardAuxPwd)
                        }
                    }

                    Divider().padding(.vertical, 2)
                    Text("后台页面")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button("续费充值") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: loggedCardId)) }.buttonStyle(.bordered)
                        Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL) }.buttonStyle(.bordered)
                        Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL) }.buttonStyle(.bordered)
                    }

                    Button("注销并返回登录") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            _ = await client.logout()
                            onLogout()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isLoading)

                    if !panelDetail.isEmpty {
                        Text("接口返回")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ScrollView {
                            Text(panelDetail)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 120)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
    }

    private func panelBtn(_ title: String, call: @escaping () async -> BSPHPAPIResult) -> some View {
        Button(title) {
            Task {
                isLoading = true
                defer { isLoading = false }
                let r = await call()
                let body = r.message.isEmpty ? "（无 data 文本）" : r.message
                panelDetail = "[\(title)] code=\(r.code.map(String.init) ?? "nil")\n\(body)"
            }
        }
        .buttonStyle(.bordered)
        .disabled(isLoading || loggedCardId.isEmpty)
    }
}
