//
//  ContentView.swift
//  bsphp.app.demo.card
//
//  卡模式（AppEn .ic）演示主界面（iPhone）：
//  - Tab1 卡密：login.ic 验证 → 全屏「主控制面板」
//  - Tab2 机器码：AddCardFeatures.key.ic + login.ic；充值续费 chong.ic
//
//  流程要点：任何业务请求前须先 `bootstrap()`（internet.in + BSphpSeSsL.in），与 Mac 演示一致。
//

import SwiftUI

// MARK: - 本地配置（与 BSPHP 后台「当前应用」一致）

/// 卡模式演示用的 BSPHP 连接参数。
///
/// **重要**
/// - `url` / `mutualKey` / 两把 RSA 必须同属一个应用；任一改错会导致解密失败或 `appsafecode` 校验失败。
/// - `serverPrivateKey` 用于 **解密服务器响应**（须与后台「服务器私钥」一致）；勿与 `clientPublicKey` 对调。
/// - `clientPublicKey` 用于 **加密发往服务器的签名段**（须与后台「客户端公钥」一致）。
/// - 切换演示站 / 正式站：只改本枚举内常量；勿将真实商业密钥提交到公开仓库。
private enum BSPHPCardConfig {
    /// AppEn 完整入口 URL（含 `appid`、`m` 通信密码、`lang` 等），POST 加密包发往该地址。
    static let url = "https://demo.bsphp.com/AppEn.php?appid=66666666&m=3a9d8b17c0a10b1b77f0544d35e835fa&lang=0"
    /// 通信密钥 `mutualkey`，与后台应用绑定。
    static let mutualKey = "417a696c5ee663c14bc6fa48b3f53d51"
    /// 服务器私钥（Base64 DER，PKCS#8）。用于从响应 RSA 段解出 AES 密钥并解密 `response` 正文。
    static let serverPrivateKey = "MIIEqQIBADANBgkqhkiG9w0BAQEFAASCBJMwggSPAgEAAoH+DZkOodN4q3IMn6momlnOTRSQS86cbHQBxePy3gyIxpayPnm11Y0sYbWyFJhDuTSAZYHbzQLRLRZvgQ1Nk1UmEQRxzUCp5Hkhig53CVfoQA5lgXln0Qgyhe5oOXAbeiLdqwkLIw27cOQyico+s2HniSHxPEl0ikqkXj+AWu5/z18x7PmDiSDRDf26cDteSwLv4on7uYWYsQCv+r8RF63l0ZkjjjCe91Z90aEI0ZTiZT6m0yIabHOHWHN4jhI2b++s8AQRDrN4uD317o9Z7gLeBtC+XDt5kvtJFeOfb9U8+wuneiIZkOhMybqnv1/8OzVfomPvub3Rs8+4q6OeEK8CAwEAAQKB/gG+LHHxePYAmD2esU2XVSnsCNKumL4N4GxM20Q6tw09I3t+fh/xCE89yqV5HrUOVaatDk8onUb6KTCRU/AeadKkjzGPqDbwj6vyTq+T5ODQ95Gwze2s70zbUeCKzfrJnT/e2N6VVAEUPqYKlh7H3bVl9FWV1KolBwxNd1YwW5FZsS6wV5OhAS7Jg8AsxQ+DEj7p8CD5JedTjzFC76WbDh33uyEegvnWRADOiixK43mo/IwleZjC/XkSIg6OOkKCo0EXndebKZF8Jw/GrxVidJgAHYG1JiX6f/0TlIhM+EVvwGs5JU2cDpJzGAcB8n/9NRRwACW9ffm/CHj2FeqBAn88dEttycnA9kDt053qnE09z57KN4d2vpLLywzlzpbwUUVfr/vbAy/j4srmpRBZwdso+KKWxv2zr58FWlTcqwZh6pDcVLZg/6W3RP9TqBk5tb3x4XyCAD7e6XOjm6zG84P/cp/Axx9NrYihsHaKT6GJ1ISsFbnoGBsHeOo8w5MlAn85lOc6lwFt2Vgx9SeiB9WJlTuTbBdxoQ1W1DQAPdqfuNgdYUKPBdNbRAO5kULIizB4elh3pWgG2FT+HTos/IR3pAaQmzXqFjAYt2XLFuNeEI9uiuX7jPtYKzpHR6qhCvn5AsgL+QDsK7vtP6HD1IapcD81hH22Z3TKIcRfFfZDAn8HykCSBCegWtshClzWB5AYf/GJQ0CMd6A47JBb6JQgoYhb/TRqE24PYoEc2XZS6p0QGYHyBfBZQC8wpGQ9DzjCU1SZX70koKy9AgIYyJd/jUDNs2203s07Mj/5fCz2chi3SRD26XHKM6tgknmj9wDs3tq9xgrvsnOBMf6VF+qVAn8SGiCzR6O4X/qdAgAqrSHRdevbxcB9BW+HG4EZjlh7nAW8/sWI5wDyESjGnscK+s8LIRNM0eApPrtBg/i1CdGvNw6lSVYiuET4kDddKF3kRXqB+wKgGUsvBa/1lq8qn6PER76SHP7QQFN9G2MEiHypKdOFRJiszktl/EWayvG3An8BTmEK8TCs7Pq9SHQ9DEq6NQPOk5cTt5UN++mp4gqHGifzv3TBy4/+GQ2jm5xZCBJY73yhQ7YpJuVnfoQ+4Ya6PvdiuMWLDXXP0YuWzjWgbSt985dVkTNCyPR0p7NCk3CBTRKmAx7+jNyhFlbvkoAdCoOYqBxyPpbdT5ouDpek"
    /// 客户端公钥（Base64 DER）。用于构造请求中的 RSA 签名段。
    static let clientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/gu5s9VMT323+6PzHKyNyESY0oBHdDgaq7rT5VyG7ETJZtI/Q9gaILfOv+ciobZA0WGlQHi/7ri/TDA1cEszg4uvPDEMw9lCLrY9kof5m3JJhLbJAov072oevMUdDcu92Szyl1qZXQ400zYXNVJDs95JNvvyK5OBIdGVsHi0JbczWMQF9QWYrn8dF8n3WWu8a3abslHV7W/JewBhYLlEgys1SkQqe7eIZfeTGi8elbVoXPwn2Bs+FSzViH9kxp4Out9eDjr/AeCDeuqFR39UfMLPDgXAKKv7HdskCWgZYDJSVk5CM3hpNj6RDBYNor83iurU3Y3+o/EDHNKyvRI3AgMBAAE="
}

// MARK: - 主界面

struct ContentView: View {
    @Environment(\.openURL) private var openURL

    private let client = BSPHPClient(config: .init(
        url: BSPHPCardConfig.url,
        mutualKey: BSPHPCardConfig.mutualKey,
        serverPrivateKey: BSPHPCardConfig.serverPrivateKey,
        clientPublicKey: BSPHPCardConfig.clientPublicKey
    ))

    @State private var noticeMessage = "加载中..."
    @State private var cardInput = ""
    @State private var cardPwd = ""
    /// 充值续费：`chong.ic` 的 pwd（与 Mac 演示绑定名一致，历史原因仍为 mcCardId）
    @State private var mcCardId = ""
    /// 充值续费：`chong.ic` 的 ka（充值卡号）
    @State private var mcCardPwd = ""
    @State private var machineCodeInput = BSPHPClient.machineCode
    @State private var statusMessage = "待操作"
    @State private var isLoading = false
    @State private var vipExpiryText = "-"
    @State private var loggedCardId = ""
    /// 机器码 Tab 内：0 验证使用 | 1 充值续费
    @State private var machineModeSubTab = 0
    /// 登录成功后以全屏呈现主控制面板（对应 Mac 独立窗口）
    @State private var showControlPanel = false
    @State private var mainTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $mainTab) {
                cardModeTab
                    .tabItem { Label("制作卡密登陆", systemImage: "creditcard") }
                    .tag(0)

                machineModeTab
                    .tabItem { Label("机器码账号", systemImage: "cpu") }
                    .tag(1)
            }
            .navigationTitle("BSPHP 卡模式")
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.top, 4)
        .task {
            // 必须先 bootstrap：写入 BSphpSeSsL，否则后续 .ic（含 chong.ic）无效
            do {
                try await client.bootstrap()
                noticeMessage = (await client.getNotice()).message
            } catch {
                noticeMessage = "初始化失败（见 Xcode 控制台 [BSPHP] 加密错误详情）"
                statusMessage = String(describing: error)
            }
        }
        // 关闭面板（含下滑手势）时清空登录态展示；注销接口在面板内「注销并返回登录」调用
        .fullScreenCover(isPresented: $showControlPanel, onDismiss: {
            loggedCardId = ""
            vipExpiryText = "-"
        }) {
            CardMainControlPanelView(
                client: client,
                loggedCardId: loggedCardId,
                initialVipExpiry: vipExpiryText,
                onLogout: { showControlPanel = false }
            )
        }
    }

    /// Tab1：卡串 + 密码，`login.ic` 验证；售卡链接走系统浏览器。
    private var cardModeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GroupBox("公告") {
                    Text(noticeMessage.isEmpty ? "暂无公告" : noticeMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                }

                GroupBox("制作的卡密直接登录") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("卡串") {
                            TextField("请输入卡串", text: $cardInput)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        LabeledContent("密码") {
                            TextField("无密码可留空", text: $cardPwd)
                                .textFieldStyle(.roundedBorder)
                        }

                        FlowActionRow {
                            Button("验证使用") { verifyCard() }
                                .buttonStyle(.borderedProminent)
                            Button("网络测试") { testNet() }
                            Button("版本检测") { checkVersion() }
                            Button("续费充值") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: cardInput), openURL: openURL) }
                            Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL, openURL: openURL) }
                            Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL, openURL: openURL) }
                        }

                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .overlay {
            if isLoading { ProgressView().scaleEffect(1.2).allowsHitTesting(true) }
        }
    }

    /// Tab2：机器码作账号；子分段为验证 / 充值续费。
    private var machineModeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GroupBox("公告") {
                    Text(noticeMessage.isEmpty ? "暂无公告" : noticeMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("机器码直接注册做卡号模式（账号就是机器码）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $machineModeSubTab) {
                        Text("机器码验证使用").tag(0)
                        Text("机器码充值续费").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if machineModeSubTab == 0 {
                        machineVerifyTabContent
                    } else {
                        machineRenewTabContent
                    }

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .overlay {
            if isLoading { ProgressView().scaleEffect(1.2) }
        }
    }

    /// 仅账号一行；先 `AddCardFeatures.key.ic` 再 `login.ic`（无密码栏，key/maxoror 为本机 `BSPHPClient.machineCode`）。
    private var machineVerifyTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("机器码") {
                TextField("默认本机特征码，可作账号", text: $machineCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            FlowActionRow {
                Button("验证使用") { verifyMachineAccount() }
                    .buttonStyle(.borderedProminent)
                Button("网络测试") { testNet() }
                Button("版本检测") { checkVersion() }
            }
        }
    }

    /// `chong.ic`：icid=机器码账号，ka=充值卡号，pwd=充值密码（界面绑定 mcCardPwd / mcCardId）。
    private var machineRenewTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("机器码") {
                TextField("账号即机器码", text: $machineCodeInput)
                    .textFieldStyle(.roundedBorder)
            }
            LabeledContent("充值卡号") {
                TextField("充值卡号", text: $mcCardPwd)
                    .textFieldStyle(.roundedBorder)
            }
            LabeledContent("充值密码") {
                TextField("没有留空", text: $mcCardId)
                    .textFieldStyle(.roundedBorder)
            }
            FlowActionRow {
                Button("确认充值") { activate() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                Button("一键支付续费") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: machineCodeInput), openURL: openURL) }
                Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL, openURL: openURL) }
                Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL, openURL: openURL) }
            }
        }
    }

    /// 卡密模式：`login.ic`。成功（含 code/message 1081）则拉到期并打开主控制面板。
    private func verifyCard() {
        guard !cardInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "请输入卡串"
            return
        }
        Task {
            isLoading = true
            defer { isLoading = false }
            let r = await client.loginIC(icid: cardInput, icpwd: cardPwd)
            let msg = r.message.isEmpty ? "验证失败" : r.message
            statusMessage = msg
            if msg.contains("1081") || (r.code == 1081) {
                let cid = cardInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let exp = (await client.getDateIC()).message
                let expDisplay = exp.isEmpty ? "-" : exp
                loggedCardId = cid
                vipExpiryText = expDisplay
                showControlPanel = true
                statusMessage = "验证成功，已打开主控制面板"
            }
        }
    }

    /// 机器码账号：先 `AddCardFeatures.key.ic`（carid=账号，key/maxoror=本机全局机器码），再 `login.ic`。
    private func verifyMachineAccount() {
        let id = machineCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            statusMessage = "【机器码】请输入机器码（账号）"
            return
        }
        let globalUUID = BSPHPClient.machineCode
        Task {
            isLoading = true
            defer { isLoading = false }
            let feat = await client.addCardFeatures(carid: id, key: globalUUID, maxoror: globalUUID)
            let featMsg = feat.message.isEmpty ? "（无 data）" : feat.message
            let featOk = (feat.code == 1011 || feat.code == 1081)
                || featMsg.contains("1081")
                || featMsg.contains("成功")
            statusMessage = "[AddCardFeatures.key.ic] code=\(feat.code.map(String.init) ?? "nil") \(featMsg)"
            guard featOk else { return }

            let r = await client.loginIC(icid: id, icpwd: "", key: globalUUID, maxoror: globalUUID)
            let msg = r.message.isEmpty ? "验证失败" : r.message
            statusMessage = "[login.ic] \(msg)"
            if msg.contains("1081") || (r.code == 1081) {
                let exp = (await client.getDateIC()).message
                let expDisplay = exp.isEmpty ? "-" : exp
                loggedCardId = id
                vipExpiryText = expDisplay
                showControlPanel = true
                statusMessage = "验证成功（机器码账号），已打开主控制面板"
            }
        }
    }

    /// `internet.in` 连通性探测。
    private func testNet() {
        Task {
            isLoading = true
            defer { isLoading = false }
            statusMessage = await client.connect() ? "网络连接正常" : "网络连接异常"
        }
    }

    /// `v.in` 版本信息。
    private func checkVersion() {
        Task {
            isLoading = true
            defer { isLoading = false }
            let v = await client.getVersion().message
            statusMessage = v.isEmpty ? "版本获取失败" : "当前版本：\(v)"
        }
    }

    /// 机器码充值：`chong.ic`。
    private func activate() {
        let icid = machineCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !icid.isEmpty else {
            statusMessage = "【机器码】请输入机器码（账号）"
            return
        }
        let ka = mcCardPwd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ka.isEmpty else {
            statusMessage = "请输入充值卡号"
            return
        }
        let pwd = mcCardId.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            isLoading = true
            defer { isLoading = false }
            let r = await client.rechargeCard(icid: icid, ka: ka, pwd: pwd)
            let msg = r.message.isEmpty ? "（无 data）" : r.message
            statusMessage = "[chong.ic] code=\(r.code.map(String.init) ?? "nil") \(msg)"
        }
    }
}

// MARK: - 操作按钮换行布局（触控友好）

/// 宽屏横排、窄屏自动改为纵排，避免按钮被截断。
private struct FlowActionRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8, content: content)
            VStack(alignment: .leading, spacing: 8, content: content)
        }
    }
}

#Preview {
    ContentView()
}
