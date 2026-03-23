//
//  ContentView.swift
//  BSPHP macOS 演示 - 主界面
//
//  功能：登录、注册、解绑、充值、找回密码、修改密码、意见反馈
//  - 验证码按 getsetimag.in 多类型组合动态显示/隐藏
//  - Web 登录窗口监控 #login= 变动，心跳 5031 判定登录成功后关闭并跳转控制台
//  - 续费订阅推广在系统浏览器打开
//

//
//  ContentView.swift
//  BSPHP macOS 演示 - 主界面
//
//  功能说明：
//  - 公告展示、Tab 切换（登录/注册/解绑/充值/找回密码/修改密码/意见反馈）
//  - 验证码按 getsetimag.in 多类型组合动态显示/隐藏
//  - Web 登录窗口监控 #login= 变动，心跳包 5031 判定登录后自动关闭并跳转控制台
//  - 控制台：公用接口、自定义配置、登录模式接口、续费订阅推广、注销登录
//

import SwiftUI
import WebKit
import AppKit
//-------------------------------------------------------------------必须配置--------------------------------------------------------------------------------------------------
//服务器地址
// MARK: - API 配置（可改为你的服务端地址）
private let kBSPHPURL = "https://demo.bsphp.com/AppEn.php?appid=8888888&m=95e87faf2f6e41babddaef60273489e1&lang=0"
//通信 KEY（mutualkey）
private let kBSPHPMutualKey = "6600cfcd5ac01b9bb3f2460eb416daa8"
//服务器私钥 Base64（用于 AES 密钥派生、响应解密）
// 服务器私钥 长-接收服务器数据时候进行解密
private let kBSPHPServerPrivateKey = "MIIEqAIBADANBgkqhkiG9w0BAQEFAASCBJIwggSOAgEAAoH+DEr7H5BhMwRA9ZWXVftcCWHznBdl0gQBu5617qSe9in+uloF1sC64Ybdc8Q0JwQkGQANC5PnMqPLgXXIfnl7/LpnQ/BvghQI5cr/4DEezRKrmQaXgYfXHL3woVw7JIsLpPTGa7Ar9S6SEH8RcPIbZjlPVRZPwV3RgWgox2/4lkXsmopqD+mEtOI/ntvti147nEpK2c7cdtCU5M2hQSlIXsTWvri88RTYJ/CtopBOXarUkNBfpWGImiYGsmbZI+YZ6uU0wSYlq8huu+pkTseUUiymzmv8Rpg3coi7YU+pszvB9wnQ1Rz6Z/B6Z3WN7d6OP7f9w0Q0WvgrsKcEJhMCAwEAAQKB/gHa5t6yiRiL0cm902K0VgVMdNjfZww0cpZ/svDaguqfF8PDhhIMb6dNFOo9d6lTpKbpLQ7MOR2ZPkLBJYqAhsdy0dac2BcHMviKk+afQwirgp3LMt3nQ/0gZMnVA0/Wc+Fm1vK1WUzcxEodAuLKhnv8tg4fGdYSdGVU9KJ0MU1bKQZXv0CAIhJYWsiCa5y5bFO7K+ia+UIVBHcvITQLzlgEm+Z/X6ye5cws4pWbk8+spsBDvweb5jpelbkCYs5C5TRNIWXk7+QxTXTg1vrcsmZRcmpRJq7sOd3faZltNHTIlB3HhWnsf47Bz334j9RtU8iqonbuBmcnYbD3+bvBAn891RGdAl+rVU/sJ2kPXmV4eqJOwJfbi8o1WYDp4GcK0ThjrZ1pmaZMj2WTjb3QX1VUoi+7l3389KzzDn0VXLKXZvGxmLikA1FWuuLUmwfNTxyxtGTBVeZCEaQ2lEJuaDGsK0oLi4Bo8ELfQw6JFK7jlgtTlflcYcul99P9BThDAn8y5TpSQy8/07LCgMMZOgJomYzQUmd14Zn2VQLH1u1Z4v2CPlOzGanDt7mmGZCew7iMSO1P0TrwDIreKzYyERuVvZti/IFHH1+J1hAbvk9SJGmdt46W5lyIp3xjdR2QmiK+hSsc8HF9R+zPaSe9yGA8+FwxLRfo0snGP3MC3aXxAn4n2iyABgejZlkc3EnanfzIqkHygC9gUbkCqa1tEDVZw3+Uv1G1vlJxBftyHuk4ZDmbUu1w+zM41nqiLbRxEE4LR06AKO7Yx0qlm86XOVTN/y9/WcWW1saRzs0IYIZwordhQIV463DYMgLn41B7Cdmu1gZ22TLfWCjpz9HSQosCfwMJu9l9OSzOLjV+CidPVyV3RPiKcrKOrOoPWQMkyTY8XnWP0t82APQ121cW35Mai8GT+NZy3tnFZeStH6cNbmAZ2VSnTfA45zMLHBsL2SBGHCfV9ST8yzk9BifJreIb0UceG9y2XY/k4zXeSQkDFPuOt7IXxv2W14SF9Q+Ou4ECfzfRP1hXPwq2w4YJ8sLmqWJT+3aMDucei5MJEAJNifZWhdW0GIrlKRSbhIgLAunxq+KK+mAPqqWw7Prsa21JbXSe3gugusu5d6ESURvLENRKI+Pp9TgRESsydeLy8VcPKRJ5/Ct7/p6QB3A+7F/iPNE2GagGffG9i7e+OdcToYQ="
// 客户端公钥-短-客户端加密用-发送请求时候进行加密
private let kBSPHPClientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/g26m2hYtESqcKW+95Lr+PfCd4bwHW2Z+mM0/vcKQ5j/ZGMigqkgl3QXCEcsCaw0KFSmqAPtLbrl6p5Sp+ZUSYEYQhSxAajE5qRCd3k0r/MIQQanBaOALkP71/u6U2SZhrTXd05n1wQo6ojMH/xVunBOFOa/Eon/Y5FVh6GiJpwwDkFzTlnecmff7Y+VDqRhZ7vu2CQjApOx23N6DiFEmVZYEb/efyASngoZ+3A/DSB5cwbaYVZ21EhPe/GNcwtUleFHn+d4vb0cvolO3Gyw6ObceOT/Q7E3k8ejIml6vPKzmRdtw0FXGOJTclx1CjShRDfXoUjFGyXHy3sZs9VLAgMBAAE="

//---------------------------------------------------------------------必须配置结束------------------------------------------------------------------------------------------------



//图片验证码地址,修改自己地址就可以
private let kBSPHPCodeURL = "https://demo.bsphp.com/index.php?m=coode&sessl="


//-----------------------------------------------------------------------WEBAPI页面地址用不到忽略----------------------------------------------------------------------------------------------

// 网页登录地址 运营管理工具->webapi接口  #login=账号密码/短信/邮箱都跳-时间戳 
private let kBSPHPWebLoginURL = "https://demo.bsphp.com/index.php?m=webapi&c=software_auth&a=index&daihao=8888888&BSphpSeSsL="
//后台位置在-软件配置-软件销售 或者 运营管理工具->webapi接口
//续费购买订阅-直接订阅 &u=推荐人uid &user=续费账号可空
private let kBSPHPRenewURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=index&daihao=8888888"
// 续费购买订阅-购买充值卡 &u=推荐人uid
private let kBSPHPRenewCardURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=index&daihao=8888888"
// 续费购买订阅-购买库存卡 &u=推荐人uid
private let kBSPHPRenewStockCardURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=index&daihao=8888888"




// MARK: - 验证码图片视图（可复用）

/// 验证码图片组件：根据 codeURLPrefix + sessionToken 加载图片
/// - refreshTrigger: bootstrap 后更新，用于追加 &_= 时间戳绕过缓存
/// - 成功/失败/加载中/未连接 四种状态分别展示
struct CodeImageView: View {
    let url: URL?
    let sessionToken: String
    var refreshTrigger: Int = 0

    private var loadURL: URL? {
        guard let u = url, !u.absoluteString.isEmpty else { return nil }
        var comp = URLComponents(url: u, resolvingAgainstBaseURL: false)!
        comp.queryItems = (comp.queryItems ?? []) + [URLQueryItem(name: "_", value: "\(refreshTrigger)")]
        return comp.url
    }

    var body: some View {
        Group {
            if let url = loadURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .failure:
                        Text("加载失败").font(.caption).foregroundColor(.secondary)
                            .frame(width: 120, height: 36)
                            .background(Color.gray.opacity(0.15))
                    default:
                        ProgressView()
                            .frame(width: 120, height: 36)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .frame(width: 120, height: 36)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else {
                Text("请先连接").font(.caption).foregroundColor(.secondary)
                    .frame(width: 120, height: 36)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .id(sessionToken)
    }
}


// MARK: - API 视图模型

/// API 视图模型：持有 BSPHPClient，管理连接状态、登录状态、验证码开关等
@MainActor
final class BSPHPAPIViewModel: ObservableObject {
    let client: BSPHPClient
    @Published var initFailedMessage: String? = nil
    @Published var isReady: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var loginEndTime: String = ""

    /// 各 tab 验证码是否开启（由 getsetimag.in 多类型组合获取）
    /// key 为 BSPHPCodeType，value 为是否开启。未获取时默认 true（显示验证码）
    @Published var codeEnabled: [BSPHPCodeType: Bool] = [:]

    init() {
        var config = BSPHPClientConfig(
            url: kBSPHPURL,
            mutualKey: kBSPHPMutualKey,
            serverPrivateKey: kBSPHPServerPrivateKey,
            clientPublicKey: kBSPHPClientPublicKey
        )
        config.codeURLPrefix = kBSPHPCodeURL
        self.client = BSPHPClient(config: config)
    }

    /// 验证码刷新触发（点击刷新时更新，用于绕过图片缓存）
    @Published var codeRefreshTrigger: Int = 0

    func bootstrap() async {
        do {



            //初始化连接 尝试网络连接 + 获取 BSphpSeSsL 会话令牌
            //try await client.bootstrap()
            guard try await client.connect() else { throw BSPHPClientError.initFailed("连接失败") }
            guard try await client.getSeSsL() else { throw BSPHPClientError.initFailed("获取 BSphpSeSsL 失败") }



            isReady = true
            await fetchCodeEnabled()
            codeRefreshTrigger = Int(Date().timeIntervalSince1970)
        } catch BSPHPClientError.initFailed(let msg) {
            initFailedMessage = msg
        } catch {
            initFailedMessage = String(describing: error)
        }
    }

    /// 获取各类型验证码开关状态（多类型组合）
    func fetchCodeEnabled() async {
        let types = Array(BSPHPCodeType.allCases)
        let r = await client.getCodeEnabled(types: types)
        guard let dataStr = r.data as? String else { return }
        let parts = dataStr.split(separator: "|").map(String.init)
        for (idx, type) in types.enumerated() where idx < parts.count {
            codeEnabled[type] = parts[idx].lowercased() == "checked"
        }
    }

    /// 通过 getUserInfo(UserVipDate) 或 getEndTime 获取到期时间并更新 loginEndTime
    /// 优先 getUserInfo，因接口返回 code 200 时 data 即为到期时间字符串
    func fetchLoginEndTime() async {
        let u = await client.getUserInfo(fields: [.userVipDate])
        if let s = u.data as? String, !s.isEmpty {
            let val = s.contains("=") ? String(s.split(separator: "=").last ?? "").trimmingCharacters(in: .whitespaces) : s.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty { loginEndTime = val; return }
        }
        let r = await client.getEndTime()
        if let s = r.data as? String, !s.isEmpty {
            loginEndTime = s.trimmingCharacters(in: .whitespaces)
        }
    }

    /// 指定类型验证码是否开启，未获取时默认 true
    func isCodeEnabled(for type: BSPHPCodeType) -> Bool {
        codeEnabled[type] ?? true
    }

    func fetchNotice() async -> String {
        let r = await client.getNotice()
        return r.message.isEmpty ? "公告获取失败" : r.message
    }
}

/// Tab 枚举：主界面各功能页
enum BSPTab: Hashable {
    case login
    case register
    case unbind
    case recharge
    case recoverPassword
    case changePassword
    case feedback

    // MARK: - 短信/邮箱 OTP
    case smsLogin
    case smsRegister
    case smsRecoverPassword
    case emailLogin
    case emailRegister
    case emailRecoverPassword
}

// MARK: - 主界面

/// 主界面：公告 + TabView（登录/注册/解绑/充值/找回密码/修改密码/意见反馈）
struct ContentView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @Environment(\.openWindow) private var openWindow  // 用于打开控制台、Web 登录等独立窗口
    @State private var selectedTab: BSPTab = .login
    @State private var showInfoAlert: Bool = false
    @State private var infoAlertText: String = ""
    @State private var infoAlertCode: Int? = nil
    @State private var isBusy: Bool = false
    @State private var showInitError: Bool = false

    @State private var noticeText: String = "加载中..."

    private var infoAlertTitle: String {
        if let c = infoAlertCode {
            return "BSPHP (code=\(c))"
        }
        return "BSPHP"
    }

    // 登录
    @State private var loginUser: String = ""
    @State private var loginPass: String = ""
    @State private var loginCode: String = ""

    // MARK: - 短信 OTP
    @State private var smsLoginMobile: String = ""
    @State private var smsLoginArea: String = "86"
    @State private var smsLoginSmsCode: String = ""
    @State private var smsLoginKey: String = BSPHPClient.machineCode
    @State private var smsLoginMaxoror: String = BSPHPClient.machineCode
    @State private var smsLoginCoode: String = ""
    @State private var smsLoginSent: Bool = false

    @State private var smsRegisterMobile: String = ""
    @State private var smsRegisterArea: String = "86"
    @State private var smsRegisterUser: String = ""
    @State private var smsRegisterSmsCode: String = ""
    @State private var smsRegisterPwd: String = ""
    @State private var smsRegisterPwdb: String = ""
    @State private var smsRegisterKey: String = BSPHPClient.machineCode
    @State private var smsRegisterCoode: String = ""
    @State private var smsRegisterSent: Bool = false

    @State private var smsRecoverMobile: String = ""
    @State private var smsRecoverArea: String = "86"
    @State private var smsRecoverSmsCode: String = ""
    @State private var smsRecoverPwd: String = ""
    @State private var smsRecoverPwdb: String = ""
    @State private var smsRecoverCoode: String = ""
    @State private var smsRecoverSent: Bool = false

    // MARK: - 邮箱 OTP
    @State private var emailLoginEmail: String = ""
    @State private var emailLoginEmailCode: String = ""
    @State private var emailLoginKey: String = BSPHPClient.machineCode
    @State private var emailLoginMaxoror: String = BSPHPClient.machineCode
    @State private var emailLoginCoode: String = ""
    @State private var emailLoginSent: Bool = false

    @State private var emailRegisterEmail: String = ""
    @State private var emailRegisterEmailCode: String = ""
    @State private var emailRegisterUser: String = ""
    @State private var emailRegisterPwd: String = ""
    @State private var emailRegisterPwdb: String = ""
    @State private var emailRegisterKey: String = BSPHPClient.machineCode
    @State private var emailRegisterCoode: String = ""
    @State private var emailRegisterSent: Bool = false

    @State private var emailRecoverEmail: String = ""
    @State private var emailRecoverEmailCode: String = ""
    @State private var emailRecoverPwd: String = ""
    @State private var emailRecoverPwdb: String = ""
    @State private var emailRecoverCoode: String = ""
    @State private var emailRecoverSent: Bool = false

    // 注册
    @State private var regUser: String = ""
    @State private var regPass: String = ""
    @State private var regPass2: String = ""
    @State private var regQQ: String = ""
    @State private var regMail: String = ""
    @State private var regMobile: String = ""
    @State private var regQuestionIndex: Int = 0
    @State private var regAnswer: String = ""
    @State private var regCode: String = ""
    @State private var regExtension: String = ""

    // 解除绑定
    @State private var unbindUser: String = ""
    @State private var unbindPass: String = ""
    @State private var unbindDeviceId: String = ""

    // 充值
    @State private var rechargeUser: String = ""
    @State private var rechargePass: String = ""
    @State private var rechargeVerifyPassword: Bool = true  // userset: 1=验证密码防充错, 0=不验证
    @State private var rechargeCard: String = ""
    @State private var rechargeCardPass: String = ""

    // 找回密码
    @State private var recoverUser: String = ""
    @State private var recoverCode: String = ""
    @State private var recoverQuestionIndex: Int = 0
    @State private var recoverAnswer: String = ""
    @State private var recoverNewPass: String = ""
    @State private var recoverNewPass2: String = ""

    // 修改密码
    @State private var changeUser: String = ""
    @State private var changeCode: String = ""
    @State private var changeOldPass: String = ""
    @State private var changeNewPass: String = ""
    @State private var changeNewPass2: String = ""

    // 反馈问题
    @State private var feedbackUser: String = ""
    @State private var feedbackPass: String = ""
    @State private var feedbackTitle: String = ""
    @State private var feedbackContact: String = ""
    @State private var feedbackTypeIndex: Int = 0
    @State private var feedbackContent: String = ""
    @State private var feedbackCode: String = ""

    private let feedbackTypes = ["建议反馈", "BUG", "使用问题"]

    private let regQuestions = [
        "你最喜欢的颜色？",
        "你母亲的名字？",
        "你父亲的名字？",
        "你的出生地？",
        "你最喜欢的食物？",
        "你的小学名称？",
        "自定义问题"
    ]

    var body: some View {
        VStack(spacing: 10) {
            noticeBox
            statusBar

            GroupBox {
                TabView(selection: $selectedTab) {
                    loginView
                        .tag(BSPTab.login)
                        .tabItem { Text("密码登录") }

                    smsLoginView
                        .tag(BSPTab.smsLogin)
                        .tabItem { Text("短信登录") }

                    emailLoginView
                        .tag(BSPTab.emailLogin)
                        .tabItem { Text("邮箱登录") }

                    registerView
                        .tag(BSPTab.register)
                        .tabItem { Text("账号注册") }

                    smsRegisterView
                        .tag(BSPTab.smsRegister)
                        .tabItem { Text("短信注册") }

                    emailRegisterView
                        .tag(BSPTab.emailRegister)
                        .tabItem { Text("邮箱注册") }

                    DemoBSphpUnbindView(
                        unbindUser: $unbindUser,
                        unbindPass: $unbindPass,
                        isBusy: $isBusy,
                        showInfoAlert: $showInfoAlert,
                        infoAlertCode: $infoAlertCode,
                        infoAlertText: $infoAlertText
                    )
                    .tag(BSPTab.unbind)
                    .tabItem { Text("解绑") }

                    rechargeView
                        .tag(BSPTab.recharge)
                        .tabItem { Text("充值") }

                    smsRecoverPasswordView
                        .tag(BSPTab.smsRecoverPassword)
                        .tabItem { Text("短信找回") }

                    emailRecoverPasswordView
                        .tag(BSPTab.emailRecoverPassword)
                        .tabItem { Text("邮箱找回") }

                    recoverPasswordView
                        .tag(BSPTab.recoverPassword)
                        .tabItem { Text("找回密码") }

                    changePasswordView
                        .tag(BSPTab.changePassword)
                        .tabItem { Text("修改密码") }

                    feedbackView
                        .tag(BSPTab.feedback)
                        .tabItem { Text("意见反馈") }
                }
                .padding(.top, 6)
                .tint(.accentColor)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
            )
        }
        .padding(14)
        .frame(minWidth: 760, minHeight: 820)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .task {
            await api.bootstrap()
            if api.isReady {
                noticeText = await api.fetchNotice()
            } else {
                noticeText = api.initFailedMessage ?? "初始化失败"
            }
        }
        .alert(infoAlertTitle, isPresented: $showInfoAlert) {
            Button("Yes") { }
        } message: {
            Text(infoAlertText)
        }
        .alert("初始化失败", isPresented: Binding(
            get: { api.initFailedMessage != nil },
            set: { if !$0 { api.initFailedMessage = nil } }
        )) {
            Button("确定") { api.initFailedMessage = nil }
        } message: {
            Text(api.initFailedMessage ?? "")
        }
    }

    /// 公告区域：从 gg.in 获取并展示
    private var noticeBox: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 10) {
                Text("公告：")
                    .frame(width: 50, alignment: .trailing)
                ScrollView {
                    Text(noticeText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 90)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(.vertical, 6)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Image(systemName: api.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(api.isReady ? .green : .orange)
            Text(api.isReady ? "服务已连接" : "服务未连接")
                .font(.subheadline.weight(.semibold))
            if isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer()
            if api.isLoggedIn {
                Label("已登录", systemImage: "person.crop.circle.badge.checkmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    // MARK: - 登录界面

    /// 登录页：账号密码、验证码（按 codeEnabled 动态显示）、Web 登录、登录按钮
    private var loginView: some View {
        DemoBSphpLoginView(
            loginUser: $loginUser,
            loginPass: $loginPass,
            loginCode: $loginCode,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 短信登录

    private var smsLoginView: some View {
        DemoBSphpSmsLoginView(
            mobile: $smsLoginMobile,
            area: $smsLoginArea,
            smsCode: $smsLoginSmsCode,
            key: $smsLoginKey,
            maxoror: $smsLoginMaxoror,
            coode: $smsLoginCoode,
            sent: $smsLoginSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 短信注册

    private var smsRegisterView: some View {
        DemoBSphpSmsRegisterView(
            mobile: $smsRegisterMobile,
            area: $smsRegisterArea,
            user: $smsRegisterUser,
            smsCode: $smsRegisterSmsCode,
            pwd: $smsRegisterPwd,
            pwdb: $smsRegisterPwdb,
            key: $smsRegisterKey,
            coode: $smsRegisterCoode,
            sent: $smsRegisterSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 短信找回

    private var smsRecoverPasswordView: some View {
        DemoBSphpSmsRecoverPasswordView(
            mobile: $smsRecoverMobile,
            area: $smsRecoverArea,
            smsCode: $smsRecoverSmsCode,
            pwd: $smsRecoverPwd,
            pwdb: $smsRecoverPwdb,
            coode: $smsRecoverCoode,
            sent: $smsRecoverSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 邮箱登录

    private var emailLoginView: some View {
        DemoBSphpEmailLoginView(
            email: $emailLoginEmail,
            emailCode: $emailLoginEmailCode,
            key: $emailLoginKey,
            maxoror: $emailLoginMaxoror,
            coode: $emailLoginCoode,
            sent: $emailLoginSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 邮箱注册

    private var emailRegisterView: some View {
        DemoBSphpEmailRegisterView(
            email: $emailRegisterEmail,
            user: $emailRegisterUser,
            emailCode: $emailRegisterEmailCode,
            pwd: $emailRegisterPwd,
            pwdb: $emailRegisterPwdb,
            key: $emailRegisterKey,
            coode: $emailRegisterCoode,
            sent: $emailRegisterSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 邮箱找回

    private var emailRecoverPasswordView: some View {
        DemoBSphpEmailRecoverPasswordView(
            email: $emailRecoverEmail,
            emailCode: $emailRecoverEmailCode,
            pwd: $emailRecoverPwd,
            pwdb: $emailRecoverPwdb,
            coode: $emailRecoverCoode,
            sent: $emailRecoverSent,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 注册界面

    /// 注册页：registration.lg，验证码按 INGES_RE 开关显示
    private var registerView: some View {
        DemoBSphpRegisterView(
            regQuestions: regQuestions,
            regUser: $regUser,
            regPass: $regPass,
            regPass2: $regPass2,
            regQQ: $regQQ,
            regMail: $regMail,
            regMobile: $regMobile,
            regQuestionIndex: $regQuestionIndex,
            regAnswer: $regAnswer,
            regCode: $regCode,
            regExtension: $regExtension,
            noticeText: $noticeText,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 解除绑定

    /// 解绑页：jiekey.lg
    private var unbindView: some View {
        formContainer {
            VStack(spacing: 12) {
                formRow(title: "登录账号：") {
                    TextField("", text: $unbindUser)
                        .textFieldStyle(.roundedBorder)
                }
                formRow(title: "登录密码：") {
                    SecureField("", text: $unbindPass)
                        .textFieldStyle(.roundedBorder)
                }
               

                HStack {
                    Spacer()
                    Button("解绑") {
                        Task {
                            isBusy = true
                            let r = await api.client.unbind(user: unbindUser, pwd: unbindPass)
                            infoAlertText = r.message.isEmpty ? "系统错误，解绑失败！" : r.message
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(width: 120)
                    .disabled(!api.isReady || isBusy)
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: - 充值

    /// 充值页：chong.lg
    private var rechargeView: some View {
        DemoBSphpRechargeView(
            rechargeUser: $rechargeUser,
            rechargePass: $rechargePass,
            rechargeCard: $rechargeCard,
            rechargeVerifyPassword: $rechargeVerifyPassword,
            rechargeCardPass: $rechargeCardPass,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 找回密码

    /// 找回密码页：backto.lg，验证码按 INGES_MACK 开关显示
    private var recoverPasswordView: some View {
        DemoBSphpRecoverPasswordView(
            regQuestions: regQuestions,
            recoverUser: $recoverUser,
            recoverQuestionIndex: $recoverQuestionIndex,
            recoverAnswer: $recoverAnswer,
            recoverNewPass: $recoverNewPass,
            recoverNewPass2: $recoverNewPass2,
            recoverCode: $recoverCode,
            noticeText: $noticeText,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 修改密码

    /// 修改密码页：password.lg
    private var changePasswordView: some View {
        DemoBSphpChangePasswordView(
            changeUser: $changeUser,
            changeOldPass: $changeOldPass,
            changeNewPass: $changeNewPass,
            changeNewPass2: $changeNewPass2,
            changeCode: $changeCode,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    // MARK: - 反馈问题

    /// 意见反馈页：liuyan.in，验证码按 INGES_SAY 开关显示
    private var feedbackView: some View {
        DemoBSphpFeedbackView(
            feedbackTypes: feedbackTypes,
            feedbackUser: $feedbackUser,
            feedbackPass: $feedbackPass,
            feedbackTitle: $feedbackTitle,
            feedbackContact: $feedbackContact,
            feedbackTypeIndex: $feedbackTypeIndex,
            feedbackContent: $feedbackContent,
            feedbackCode: $feedbackCode,
            isBusy: $isBusy,
            showInfoAlert: $showInfoAlert,
            infoAlertCode: $infoAlertCode,
            infoAlertText: $infoAlertText
        )
    }

    /// 表单容器：统一宽度 520，上下留白
    private func formContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack {
            Spacer(minLength: 24)
            content()
                .frame(width: 520)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 12)
    }

    /// 表单行：标题左对齐 120pt + 内容
    private func formRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 120, alignment: .trailing)
            content()
        }
    }
}

// MARK: - Web 登录窗口

/// Web 登录窗口：加载 kBSPHPWebLoginURL+BSphpSeSsL，监控 #login= 变动
/// 心跳包返回 5031 表示已登录，则关闭本窗口并打开控制台
struct WebLoginWindowView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @Environment(\.openWindow) private var openWindow

    private var webLoginURL: URL {
        let urlStr = kBSPHPWebLoginURL + api.client.bsPhpSeSsL
        return URL(string: urlStr) ?? URL(string: "about:blank")!
    }

    var body: some View {
        WebLoginWebView(url: webLoginURL) {
            Task { @MainActor in
                let r = await api.client.heartbeat()
                if r.code == 5031 {
                    api.isLoggedIn = true
                    openWindow(id: "console")
                    NSApp.windows.first { $0.title == "Web登录" }?.close()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 800)
    }
}

/// Web 登录页 WKWebView：注入 JS 监听 hashchange，当 hash 含 login= 时 postMessage
/// Coordinator 接收后触发 onLoginHashChanged，由父视图调用 heartbeat 判断 5031
struct WebLoginWebView: NSViewRepresentable {
    let url: URL
    var onLoginHashChanged: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoginHashChanged: onLoginHashChanged)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "loginHashChanged")
        let script = WKUserScript(
            source: """
            (function() {
                function checkHash() {
                    var h = window.location.hash || '';
                    if (h.indexOf('login=') !== -1) {
                        window.webkit.messageHandlers.loginHashChanged.postMessage(h);
                    }
                }
                window.addEventListener('hashchange', checkHash);
                if (document.readyState === 'complete') checkHash();
                else window.addEventListener('load', checkHash);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url?.absoluteString.hasPrefix(url.absoluteString) != true {
            nsView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onLoginHashChanged: () -> Void

        init(onLoginHashChanged: @escaping () -> Void) {
            self.onLoginHashChanged = onLoginHashChanged
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "loginHashChanged" else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onLoginHashChanged()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("var h=window.location.hash||'';if(h.indexOf('login=')!==-1){}else{window.webkit.messageHandlers.loginHashChanged.postMessage(h);}") { _, _ in }
        }
    }
}

/// 通用 WebView：用于续费购买等页面，仅加载 URL
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
}

// MARK: - 控制台独立窗口

/// 控制台：公用接口、自定义配置、通用接口、登录模式接口、续费订阅推广、注销登录
/// 登录成功后可打开，用于调试各类 API
struct ConsoleWindowView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @State private var isBusy: Bool = false
    @State private var showInfoAlert: Bool = false
    @State private var infoAlertText: String = ""

    private func run(_ block: @escaping () async -> String) {
        Task {
            isBusy = true
            let text = await block()
            infoAlertText = text
            showInfoAlert = true
            isBusy = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if api.isLoggedIn {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已登录")
                            .font(.headline)
                        Text("到期时间：\(api.loginEndTime)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                Group {
                    Text("公用接口")
                        .font(.headline)
                    flowButtons {
                        btn("服务器时间") { run { let r = await api.client.getServerDate(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("预设URL") { run { let r = await api.client.getPresetURL(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("Web地址") { run { let r = await api.client.getWebURL(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("全局配置") { run { let r = await api.client.getGlobalInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("验证码开关(全部)") { run { let r = await api.client.getCodeEnabled(types: Array(BSPHPCodeType.allCases)); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("登录验证码") { run { let r = await api.client.getCodeEnabled(type: .login); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("注册验证码") { run { let r = await api.client.getCodeEnabled(type: .reg); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("找回密码验证码") { run { let r = await api.client.getCodeEnabled(type: .backPwd); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("留言验证码") { run { let r = await api.client.getCodeEnabled(type: .say); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值A") { run { let r = await api.client.getLogicA(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值B") { run { let r = await api.client.getLogicB(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值A内容") { run { let r = await api.client.getLogicInfoA(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值B内容") { run { let r = await api.client.getLogicInfoB(); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

                Group {
                    Text("自定义配置模型")
                        .font(.headline)
                    flowButtons {
                        btn("软件配置") { run { let r = await api.client.getAppCustom(info: "myapp"); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("VIP配置") { run { let r = await api.client.getAppCustom(info: "myvip"); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("登录配置") { run { let r = await api.client.getAppCustom(info: "mylogin"); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

                Group {
                    Text("通用接口")
                        .font(.headline)
                    flowButtons {
                        btn("获取版本") { run { (await api.client.getVersion()).data as? String ?? "获取失败" } }
                        btn("获取软件描述") { run { let r = await api.client.getSoftInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

              
                    Group {
                        Text("登录模式接口")
                            .font(.headline)
                        flowButtons {
                            btn("注销登陆") {
                                run {
                                    let r = await api.client.logout()
                                    api.isLoggedIn = false
                                    api.loginEndTime = ""
                                    return r.message.isEmpty ? "注销成功" : r.message
                                }
                            }
                            btn("检测到期") {
                                run {
                                    await api.fetchLoginEndTime()
                                    return api.loginEndTime.isEmpty ? "系统错误，取到期时间失败！" : "到期时间：\(api.loginEndTime)"
                                }
                            }
                            btn("取用户信息(默认)") { run { let r = await api.client.getUserInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                            btn("心跳包更新") { run { let r = await api.client.heartbeat(); return r.message.isEmpty ? "获取失败" : r.message } }
                            btn("用户特征Key") { run { let r = await api.client.getUserKey(); return r.message.isEmpty ? "获取失败" : r.message } }
                        }

                        Text("取用户信息 info 字段")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        flowButtons {
                            ForEach(BSPHPUserInfoField.allCases, id: \.rawValue) { field in
                                btn(field.displayName) {
                                    run {
                                        let r = await api.client.getUserInfo(fields: [field])
                                        return r.message.isEmpty ? "获取失败" : r.message
                                    }
                                }
                            }
                        }
                    }

                    Group {
                        Text("续费订阅推广")
                            .font(.headline)
                        flowButtons {
                            btn("续费订阅(直接)") {
                                Task {
                                    isBusy = true
                                    var urlStr = kBSPHPRenewURL
                                    let r = await api.client.getUserInfo(fields: [.userName])
                                    if let dataStr = r.data as? String, !dataStr.isEmpty {
                                        let user = dataStr.contains("=") ? String(dataStr.split(separator: "=").last ?? "").trimmingCharacters(in: .whitespaces) : dataStr.trimmingCharacters(in: .whitespaces)
                                        if !user.isEmpty { urlStr += "&user=\(user.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? user)" }
                                    }
                                    if let url = URL(string: urlStr) { NSWorkspace.shared.open(url) }
                                    isBusy = false
                                }
                            }
                            btn("购买充值卡") {
                                if let url = URL(string: kBSPHPRenewCardURL) { NSWorkspace.shared.open(url) }
                            }
                            btn("购买库存卡") {
                                if let url = URL(string: kBSPHPRenewStockCardURL) { NSWorkspace.shared.open(url) }
                            }
                        }
                    }
               

                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .frame(minWidth: 800, minHeight: 430)
        .disabled(isBusy)
        .onAppear {
            if api.isLoggedIn {
                Task { await api.fetchLoginEndTime() }
            }
        }
        .overlay { if isBusy { ProgressView().scaleEffect(1.2) } }
        .alert("提示", isPresented: $showInfoAlert) {
            Button("确定") { }
        } message: {
            Text(infoAlertText)
        }
    }

    /// 控制台按钮流式布局
    @ViewBuilder
    private func flowButtons<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ConsoleFlowLayout(spacing: 8) { content() }
    }

    /// 控制台通用按钮：bordered 样式，未就绪或忙碌时禁用
    private func btn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) { action() }
            .buttonStyle(.bordered)
            .disabled(!api.isReady || isBusy)
    }
}

/// 流式布局：子视图按行排列，超出宽度自动换行（用于控制台按钮组）
struct ConsoleFlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (idx, pt) in result.positions.enumerated() {
            subviews[idx].place(at: CGPoint(x: bounds.minX + pt.x, y: bounds.minY + pt.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        var positions: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxW && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}

#Preview {
    ContentView()
        .environmentObject(BSPHPAPIViewModel())
}
