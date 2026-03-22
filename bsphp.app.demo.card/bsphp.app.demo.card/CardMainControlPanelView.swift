//
//  CardMainControlPanelView.swift
//  bsphp.app.demo.card
//
//  卡密 / 机器码登录成功后的主控制面板（全屏呈现，对应 Mac 独立窗口）。
//  依赖已 `bootstrap` 且已登录的 `BSPHPClient` 会话。
//

import SwiftUI

// MARK: - 售卡 Web（系统浏览器打开，非 AppEn 加密接口）

/// 售卡 / 续费 **webapi** 链接。
///
/// **配置说明**
/// - `daihao=66666666` 须与 BSPHP 后台「软件代号」一致；换应用时改各 URL 中的 `daihao`。
/// - 与 Mac 演示使用同一组演示站地址。
enum BSPHPCardSaleWeb {
    /// 续费页基础地址；`renewURL(forUser:)` 会追加 `user` 查询参数。
    private static let renewURLBase = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=index&daihao=66666666"
    /// 购买充值卡
    static let genURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=index&daihao=66666666"
    /// 购买库存卡
    static let stockURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=index&daihao=66666666"

    /// 续费链接，附带 `user`（一般为当前卡号 / 机器码账号）。
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

    /// 使用系统浏览器打开（SwiftUI `OpenURLAction`，等同 Mac 的 `NSWorkspace.open`）。
    static func openInBrowser(_ urlString: String, openURL: OpenURLAction) {
        guard let u = URL(string: urlString) else { return }
        openURL(u)
    }
}

// MARK: - 主控制面板

/// 已登录会话下的调试与常用 `.ic` / `.in` 入口聚合页。
struct CardMainControlPanelView: View {
    @Environment(\.openURL) private var openURL

    let client: BSPHPClient
    let loggedCardId: String
    let onLogout: () -> Void

    @State private var vipExpiryText: String
    @State private var cardAuxPwd = ""
    @State private var panelDetail = ""
    @State private var isLoading = false

    /// - Parameters:
    ///   - client: 与登录页共用同一实例，保持 `BSphpSeSsL` 一致。
    ///   - loggedCardId: 当前卡串或机器码账号。
    ///   - initialVipExpiry: 打开面板前已拉取的到期文案。
    ///   - onLogout: 关闭面板或注销后回调（收起 `fullScreenCover`）。
    init(client: BSPHPClient, loggedCardId: String, initialVipExpiry: String, onLogout: @escaping () -> Void) {
        self.client = client
        self.loggedCardId = loggedCardId
        self.onLogout = onLogout
        _vipExpiryText = State(initialValue: initialVipExpiry)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox("主控制面板") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("当前卡号：\(loggedCardId)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("VIP 到期：\(vipExpiryText)")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
                            panelBtn("刷新到期") {
                                let r = await client.getDateIC()
                                let t = r.message
                                if !t.isEmpty { vipExpiryText = t }
                                return r
                            }
                            panelBtn("登录状态") { await client.getLoginInfo() }
                            panelBtn("心跳") { await client.heartbeat() }
                            panelBtn("公告") { await client.getNotice() }
                            panelBtn("服务器时间") { await client.getServerDate() }
                            panelBtn("版本") { await client.getVersion() }
                            panelBtn("软件描述") { await client.getSoftInfo() }
                            panelBtn("预设URL") { await client.getPresetURL() }
                            panelBtn("Web地址") { await client.getWebURL() }
                        }

                        Text("自定义配置模型")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
                            panelBtn("软件配置") { await client.getAppCustom(info: "myapp") }
                            panelBtn("VIP配置") { await client.getAppCustom(info: "myvip") }
                            panelBtn("登录配置") { await client.getAppCustom(info: "mylogin") }
                        }
                        Text("公共函数")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
                            panelBtn("全局配置") { await client.getGlobalInfo() }
                            panelBtn("逻辑A") { await client.getLogicA() }
                            panelBtn("逻辑B") { await client.getLogicB() }
                            panelBtn("激活查询") { await client.queryCard(cardid: loggedCardId) }
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
                            .textContentType(.password)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
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
                            Button("续费充值") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: loggedCardId), openURL: openURL) }
                                .buttonStyle(.bordered)
                            Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL, openURL: openURL) }
                                .buttonStyle(.bordered)
                            Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL, openURL: openURL) }
                                .buttonStyle(.bordered)
                        }

                        // `cancellation.ic`，成功后客户端内会清空 SeSsL 并重新 `getSeSsL`（见 BSPHPClient.logout）
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
                            .frame(maxHeight: 160)
                            .padding(6)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("主控制面板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // 不调用 cancellation.ic，仅关闭 UI（与 Mac 关窗清理展示态一致）
                    Button("关闭") {
                        onLogout()
                    }
                }
            }
        }
    }

    /// 统一调用 BSPHP 接口并将 `code` / `data` 文本写入 `panelDetail`。
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
