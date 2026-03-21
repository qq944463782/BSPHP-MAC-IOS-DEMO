//
//  ContentView.swift
//  bsphp.mac.demo.card
//
//  卡模式（AppEn .ic）演示主界面：
//  - Tab1 卡密：login.ic 验证 → 独立窗口「主控制面板」
//  - Tab2 机器码：AddCardFeatures.key.ic + login.ic 验证；充值续费子页 chong.ic
//  配置项见 BSPHPCardConfig（与 BSPHP 后台应用密钥一致）。
//

import SwiftUI

// MARK: - 本地配置（AppEn URL / mutualKey / RSA 密钥）

/// 卡模式演示用的 BSPHP 连接参数，对应后台「软件管理 → 当前应用」里的 **AppEn 接口地址** 与 **通信密钥 / RSA 密钥对**。
///
/// **注意**
/// - `url` / `mutualKey` / 两把 RSA 必须同属一个应用；任一改错会导致解密失败或 `appsafecode` 校验失败。
/// - `serverPrivateKey` 用于 **解密服务器响应**（须与后台「服务器私钥」一致）；勿与 `clientPublicKey` 对调。
/// - `clientPublicKey` 用于 **加密发往服务器的签名段**（须与后台「客户端公钥」一致）。
/// - 演示站可与正式站切换：只改本枚举内常量，勿提交真实商业密钥到公开仓库。
private enum BSPHPCardConfig {
    /// AppEn 完整入口 URL（含 `appid`、`m` 通信密码、`lang` 等查询参数），POST 加密包发往该地址。
    static let url = "https://demo.bsphp.com/AppEn.php?appid=66666666&m=3a9d8b17c0a10b1b77f0544d35e835fa&lang=0"
    /// 通信密钥 `mutualkey`，参与请求体并与后台应用绑定；与 Python/Java 等示例中的 mutualkey 同义。
    static let mutualKey = "417a696c5ee663c14bc6fa48b3f53d51"
    /// 服务器私钥（Base64 DER，PKCS#8）。用于从响应 RSA 段解出 AES 密钥并解密 `response` 正文。
    static let serverPrivateKey = "MIIEqQIBADANBgkqhkiG9w0BAQEFAASCBJMwggSPAgEAAoH+DZkOodN4q3IMn6momlnOTRSQS86cbHQBxePy3gyIxpayPnm11Y0sYbWyFJhDuTSAZYHbzQLRLRZvgQ1Nk1UmEQRxzUCp5Hkhig53CVfoQA5lgXln0Qgyhe5oOXAbeiLdqwkLIw27cOQyico+s2HniSHxPEl0ikqkXj+AWu5/z18x7PmDiSDRDf26cDteSwLv4on7uYWYsQCv+r8RF63l0ZkjjjCe91Z90aEI0ZTiZT6m0yIabHOHWHN4jhI2b++s8AQRDrN4uD317o9Z7gLeBtC+XDt5kvtJFeOfb9U8+wuneiIZkOhMybqnv1/8OzVfomPvub3Rs8+4q6OeEK8CAwEAAQKB/gG+LHHxePYAmD2esU2XVSnsCNKumL4N4GxM20Q6tw09I3t+fh/xCE89yqV5HrUOVaatDk8onUb6KTCRU/AeadKkjzGPqDbwj6vyTq+T5ODQ95Gwze2s70zbUeCKzfrJnT/e2N6VVAEUPqYKlh7H3bVl9FWV1KolBwxNd1YwW5FZsS6wV5OhAS7Jg8AsxQ+DEj7p8CD5JedTjzFC76WbDh33uyEegvnWRADOiixK43mo/IwleZjC/XkSIg6OOkKCo0EXndebKZF8Jw/GrxVidJgAHYG1JiX6f/0TlIhM+EVvwGs5JU2cDpJzGAcB8n/9NRRwACW9ffm/CHj2FeqBAn88dEttycnA9kDt053qnE09z57KN4d2vpLLywzlzpbwUUVfr/vbAy/j4srmpRBZwdso+KKWxv2zr58FWlTcqwZh6pDcVLZg/6W3RP9TqBk5tb3x4XyCAD7e6XOjm6zG84P/cp/Axx9NrYihsHaKT6GJ1ISsFbnoGBsHeOo8w5MlAn85lOc6lwFt2Vgx9SeiB9WJlTuTbBdxoQ1W1DQAPdqfuNgdYUKPBdNbRAO5kULIizB4elh3pWgG2FT+HTos/IR3pAaQmzXqFjAYt2XLFuNeEI9uiuX7jPtYKzpHR6qhCvn5AsgL+QDsK7vtP6HD1IapcD81hH22Z3TKIcRfFfZDAn8HykCSBCegWtshClzWB5AYf/GJQ0CMd6A47JBb6JQgoYhb/TRqE24PYoEc2XZS6p0QGYHyBfBZQC8wpGQ9DzjCU1SZX70koKy9AgIYyJd/jUDNs2203s07Mj/5fCz2chi3SRD26XHKM6tgknmj9wDs3tq9xgrvsnOBMf6VF+qVAn8SGiCzR6O4X/qdAgAqrSHRdevbxcB9BW+HG4EZjlh7nAW8/sWI5wDyESjGnscK+s8LIRNM0eApPrtBg/i1CdGvNw6lSVYiuET4kDddKF3kRXqB+wKgGUsvBa/1lq8qn6PER76SHP7QQFN9G2MEiHypKdOFRJiszktl/EWayvG3An8BTmEK8TCs7Pq9SHQ9DEq6NQPOk5cTt5UN++mp4gqHGifzv3TBy4/+GQ2jm5xZCBJY73yhQ7YpJuVnfoQ+4Ya6PvdiuMWLDXXP0YuWzjWgbSt985dVkTNCyPR0p7NCk3CBTRKmAx7+jNyhFlbvkoAdCoOYqBxyPpbdT5ouDpek"
    /// 客户端公钥（Base64 DER）。用于构造请求中的 RSA 签名段；与后台保存的「客户端公钥」一致。
    static let clientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/gu5s9VMT323+6PzHKyNyESY0oBHdDgaq7rT5VyG7ETJZtI/Q9gaILfOv+ciobZA0WGlQHi/7ri/TDA1cEszg4uvPDEMw9lCLrY9kof5m3JJhLbJAov072oevMUdDcu92Szyl1qZXQ400zYXNVJDs95JNvvyK5OBIdGVsHi0JbczWMQF9QWYrn8dF8n3WWu8a3abslHV7W/JewBhYLlEgys1SkQqe7eIZfeTGi8elbVoXPwn2Bs+FSzViH9kxp4Out9eDjr/AeCDeuqFR39UfMLPDgXAKKv7HdskCWgZYDJSVk5CM3hpNj6RDBYNor83iurU3Y3+o/EDHNKyvRI3AgMBAAE="
}

// MARK: - 主界面

struct ContentView: View {
    private let client = BSPHPClient(config: .init(
        url: BSPHPCardConfig.url,
        mutualKey: BSPHPCardConfig.mutualKey,
        serverPrivateKey: BSPHPCardConfig.serverPrivateKey,
        clientPublicKey: BSPHPCardConfig.clientPublicKey
    ))

    @StateObject private var controlPanelWindow = CardMainControlPanelWindowHost()

    @State private var noticeMessage = "加载中..."
    @State private var cardInput = ""
    @State private var cardPwd = ""
    /// 充值续费：`chong.ic` 的 pwd（界面绑定名历史原因仍为 mcCardId）
    @State private var mcCardId = ""
    /// 充值续费：`chong.ic` 的 ka 充值卡号
    @State private var mcCardPwd = ""
    /// 默认本机全局机器码（IOPlatformUUID / 持久化 UUID）
    @State private var machineCodeInput = BSPHPClient.machineCode
    @State private var statusMessage = "待操作"
    @State private var isLoading = false
    @State private var vipExpiryText = "-"
    @State private var loggedCardId = ""
    /// 机器码账号模式内：验证使用 | 充值续费
    @State private var machineModeSubTab = 0

    var body: some View {
        mainPanel
            .padding(14)
        .frame(minWidth: 520, minHeight: 380)
        .task {
            do {
                // 必须先 bootstrap：`internet.in` + `BSphpSeSsL.in`，写入会话令牌；否则后续 `.ic`（含 chong.ic）无效。
                try await client.bootstrap()
                noticeMessage = (await client.getNotice()).message
            } catch {
                noticeMessage = "初始化失败（见控制台 [BSPHP] 加密错误详情）"
                statusMessage = String(describing: error)
            }
        }
    }

    /// 公告 + 双 Tab（卡密 | 机器码账号）
    private var mainPanel: some View {
        VStack(spacing: 10) {
            GroupBox("公告") {
                ScrollView {
                    Text(noticeMessage.isEmpty ? "暂无公告" : noticeMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .frame(height: 60)
            }

            TabView {
                GroupBox("制作的卡密直接登录") {
                    VStack(spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("卡串：")
                                .frame(width: 56, alignment: .trailing)
                            TextField("请输入卡串", text: $cardInput)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text("密码：")
                                .frame(width: 56, alignment: .trailing)
                            TextField("无密码可留空", text: $cardPwd)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack(spacing: 10) {
                            Button("验证使用") { verifyCard() }
                                .buttonStyle(.borderedProminent)
                            Button("网络测试") { testNet() }
                                .buttonStyle(.bordered)
                            Button("版本检测") { checkVersion() }
                                .buttonStyle(.bordered)
                            Button("续费充值") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: cardInput)) }
                                .buttonStyle(.bordered)
                            Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL) }
                                .buttonStyle(.bordered)
                            Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL) }
                                .buttonStyle(.bordered)
                            Spacer()
                        }

                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(4)
                .tabItem {
                    Label("制作卡密登陆模式", systemImage: "creditcard")
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

                    Group {
                        if machineModeSubTab == 0 {
                            machineVerifyTabContent
                        } else {
                            machineRenewTabContent
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(4)
                .tabItem {
                    Label("一键注册机器码账号", systemImage: "cpu")
                }
            }
            .frame(minHeight: 320)
        }
    }

    /// 机器码模式 · 仅账号一行；验证走 AddCardFeatures + login.ic（无密码栏）
    private var machineVerifyTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("机器码：")
                    .frame(width: 56, alignment: .trailing)
                TextField("默认本机 UUID，可作账号", text: $machineCodeInput)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: 10) {
                Button("验证使用") { verifyMachineAccount() }
                    .buttonStyle(.borderedProminent)
                Button("网络测试") { testNet() }
                    .buttonStyle(.bordered)
                Button("版本检测") { checkVersion() }
                    .buttonStyle(.bordered)
                Spacer()
            }
        }
    }

    /// 机器码模式 · 充值续费（续费带 user=当前机器码账号）
    private var machineRenewTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("机器码：")
                    .frame(width: 80, alignment: .trailing)
                TextField("账号即机器码", text: $machineCodeInput)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("充值卡号：")
                    .frame(width: 80, alignment: .trailing)
                TextField("充值卡号", text: $mcCardPwd)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("充值密码：")
                    .frame(width: 80, alignment: .trailing)
                TextField("充值密码,没有留空", text: $mcCardId)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                Button("确认充值") { activate() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                Button("一键支付续费充值") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.renewURL(forUser: machineCodeInput)) }
                    .buttonStyle(.bordered)
                Button("购买充值卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.genURL) }
                    .buttonStyle(.bordered)
                Button("购买库存卡") { BSPHPCardSaleWeb.openInBrowser(BSPHPCardSaleWeb.stockURL) }
                    .buttonStyle(.bordered)
                Spacer()
            }
        }
    }

    /// 卡密模式：`login.ic`；成功 code 1081 等则拉到期并打开主控制面板窗口。
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
                controlPanelWindow.presentPanel(
                    client: client,
                    loggedCardId: cid,
                    initialVipExpiry: expDisplay,
                    onSessionEnd: {
                        loggedCardId = ""
                        vipExpiryText = "-"
                    }
                )
                statusMessage = "验证成功，主控制面板已在新窗口打开"
            }
        }
    }

    /// 机器码作账号：先 `AddCardFeatures.key.ic`（carid=账号，key/maxoror=本机全局机器码），再 `login.ic` 进主面板
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
                controlPanelWindow.presentPanel(
                    client: client,
                    loggedCardId: id,
                    initialVipExpiry: expDisplay,
                    onSessionEnd: {
                        loggedCardId = ""
                        vipExpiryText = "-"
                    }
                )
                statusMessage = "验证成功（机器码账号），主控制面板已在新窗口打开"
            }
        }
    }

    /// `internet.in` 连通性
    private func testNet() {
        Task {
            isLoading = true
            defer { isLoading = false }
            statusMessage = await client.connect() ? "网络连接正常" : "网络连接异常"
        }
    }

    /// `v.in` 版本信息
    private func checkVersion() {
        Task {
            isLoading = true
            defer { isLoading = false }
            let v = await client.getVersion().message
            statusMessage = v.isEmpty ? "版本获取失败" : "当前版本：\(v)"
        }
    }

    /// `chong.ic`：icid=机器码账号，ka=充值卡号，pwd=充值密码（卡号/密码对应 mcCardPwd / mcCardId 绑定）
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

// MARK: - Preview

#Preview {
    ContentView()
}
