//
//  ContentView.swift
//  bsphp.app.demo.user
//
//  Created by enzu zhou on 2026/3/20.
//

import SwiftUI

private enum BSPHPMobileConfig {
    // 本地开发配置（你当前这组 localhost 参数是正确可用的）
    // 切换环境时：只改这里，不需要改页面逻辑。
//-------------------------------------------------------------------必须配置--------------------------------------------------------------------------------------------------
//服务器地址
// MARK: - API 配置（可改为你的服务端地址）
// 本地开发：本机跑 BSPHP 时 `http://localhost:8000/...` 是对的（模拟器访问本机服务）。
private static let kBSPHPURL = "https://demo.bsphp.com/AppEn.php?appid=8888888&m=95e87faf2f6e41babddaef60273489e1&lang=0"
//通信 KEY（mutualkey）
private static let kBSPHPMutualKey = "6600cfcd5ac01b9bb3f2460eb416daa8"
//服务器私钥 Base64（用于 AES 密钥派生、响应解密）
// 服务器私钥 长-接收服务器数据时候进行解密
private static let kBSPHPServerPrivateKey = "MIIEqAIBADANBgkqhkiG9w0BAQEFAASCBJIwggSOAgEAAoH+DEr7H5BhMwRA9ZWXVftcCWHznBdl0gQBu5617qSe9in+uloF1sC64Ybdc8Q0JwQkGQANC5PnMqPLgXXIfnl7/LpnQ/BvghQI5cr/4DEezRKrmQaXgYfXHL3woVw7JIsLpPTGa7Ar9S6SEH8RcPIbZjlPVRZPwV3RgWgox2/4lkXsmopqD+mEtOI/ntvti147nEpK2c7cdtCU5M2hQSlIXsTWvri88RTYJ/CtopBOXarUkNBfpWGImiYGsmbZI+YZ6uU0wSYlq8huu+pkTseUUiymzmv8Rpg3coi7YU+pszvB9wnQ1Rz6Z/B6Z3WN7d6OP7f9w0Q0WvgrsKcEJhMCAwEAAQKB/gHa5t6yiRiL0cm902K0VgVMdNjfZww0cpZ/svDaguqfF8PDhhIMb6dNFOo9d6lTpKbpLQ7MOR2ZPkLBJYqAhsdy0dac2BcHMviKk+afQwirgp3LMt3nQ/0gZMnVA0/Wc+Fm1vK1WUzcxEodAuLKhnv8tg4fGdYSdGVU9KJ0MU1bKQZXv0CAIhJYWsiCa5y5bFO7K+ia+UIVBHcvITQLzlgEm+Z/X6ye5cws4pWbk8+spsBDvweb5jpelbkCYs5C5TRNIWXk7+QxTXTg1vrcsmZRcmpRJq7sOd3faZltNHTIlB3HhWnsf47Bz334j9RtU8iqonbuBmcnYbD3+bvBAn891RGdAl+rVU/sJ2kPXmV4eqJOwJfbi8o1WYDp4GcK0ThjrZ1pmaZMj2WTjb3QX1VUoi+7l3389KzzDn0VXLKXZvGxmLikA1FWuuLUmwfNTxyxtGTBVeZCEaQ2lEJuaDGsK0oLi4Bo8ELfQw6JFK7jlgtTlflcYcul99P9BThDAn8y5TpSQy8/07LCgMMZOgJomYzQUmd14Zn2VQLH1u1Z4v2CPlOzGanDt7mmGZCew7iMSO1P0TrwDIreKzYyERuVvZti/IFHH1+J1hAbvk9SJGmdt46W5lyIp3xjdR2QmiK+hSsc8HF9R+zPaSe9yGA8+FwxLRfo0snGP3MC3aXxAn4n2iyABgejZlkc3EnanfzIqkHygC9gUbkCqa1tEDVZw3+Uv1G1vlJxBftyHuk4ZDmbUu1w+zM41nqiLbRxEE4LR06AKO7Yx0qlm86XOVTN/y9/WcWW1saRzs0IYIZwordhQIV463DYMgLn41B7Cdmu1gZ22TLfWCjpz9HSQosCfwMJu9l9OSzOLjV+CidPVyV3RPiKcrKOrOoPWQMkyTY8XnWP0t82APQ121cW35Mai8GT+NZy3tnFZeStH6cNbmAZ2VSnTfA45zMLHBsL2SBGHCfV9ST8yzk9BifJreIb0UceG9y2XY/k4zXeSQkDFPuOt7IXxv2W14SF9Q+Ou4ECfzfRP1hXPwq2w4YJ8sLmqWJT+3aMDucei5MJEAJNifZWhdW0GIrlKRSbhIgLAunxq+KK+mAPqqWw7Prsa21JbXSe3gugusu5d6ESURvLENRKI+Pp9TgRESsydeLy8VcPKRJ5/Ct7/p6QB3A+7F/iPNE2GagGffG9i7e+OdcToYQ="
// 客户端公钥-短-客户端加密用-发送请求时候进行加密
private static let kBSPHPClientPublicKey = "MIIBHjANBgkqhkiG9w0BAQEFAAOCAQsAMIIBBgKB/g26m2hYtESqcKW+95Lr+PfCd4bwHW2Z+mM0/vcKQ5j/ZGMigqkgl3QXCEcsCaw0KFSmqAPtLbrl6p5Sp+ZUSYEYQhSxAajE5qRCd3k0r/MIQQanBaOALkP71/u6U2SZhrTXd05n1wQo6ojMH/xVunBOFOa/Eon/Y5FVh6GiJpwwDkFzTlnecmff7Y+VDqRhZ7vu2CQjApOx23N6DiFEmVZYEb/efyASngoZ+3A/DSB5cwbaYVZ21EhPe/GNcwtUleFHn+d4vb0cvolO3Gyw6ObceOT/Q7E3k8ejIml6vPKzmRdtw0FXGOJTclx1CjShRDfXoUjFGyXHy3sZs9VLAgMBAAE="

//---------------------------------------------------------------------必须配置结束------------------------------------------------------------------------------------------------



//图片验证码地址,修改自己地址就可以
private static let kBSPHPCodeURL = "https://demo.bsphp.com/index.php?m=coode&sessl="

    // 统一对外读取字段，业务层仍使用 BSPHPMobileConfig.xxx
    static let url = kBSPHPURL
    static let mutualKey = kBSPHPMutualKey
    static let serverPrivateKey = kBSPHPServerPrivateKey
    static let clientPublicKey = kBSPHPClientPublicKey
    static let codeURLPrefix = kBSPHPCodeURL
}

actor BSPHPMobileAPI {
    static let shared = BSPHPMobileAPI()

    private let client = BSPHPClient(config: BSPHPClientConfig(
        url: BSPHPMobileConfig.url,
        mutualKey: BSPHPMobileConfig.mutualKey,
        serverPrivateKey: BSPHPMobileConfig.serverPrivateKey,
        clientPublicKey: BSPHPMobileConfig.clientPublicKey,
        codeURLPrefix: BSPHPMobileConfig.codeURLPrefix
    ))
    private var isReady = false
    private var codeEnabledCache: [DemoOTPScene: Bool] = [:]

    private func ensureReady() async -> DemoAPIResult? {
        if isReady { return nil }
        guard await client.connect() else { return DemoAPIResult(code: nil, message: "服务器连接失败") }
        do {
            guard try await client.getSeSsL() else { return DemoAPIResult(code: nil, message: "获取会话失败") }
            isReady = true
            return nil
        } catch {
            return DemoAPIResult(code: nil, message: "初始化失败：\(error.localizedDescription)")
        }
    }

    private func convert(_ r: BSPHPAPIResult, fallback: String) -> DemoAPIResult {
        DemoAPIResult(code: r.code, message: r.message.isEmpty ? fallback : r.message)
    }

    func captchaImageURL() async -> (url: URL?, message: String) {
        if let e = await ensureReady(), e.code == nil {
            return (nil, e.message)
        }
        let url = URL(string: client.codeImageURL)
        return (url, url == nil ? "验证码地址无效" : "验证码")
    }

    func sendSmsCode(scene: DemoOTPScene, mobile: String, area: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.sendSmsCode(scene: scene.rawValue, mobile: mobile, area: area, coode: coode)
        return convert(r, fallback: "发送短信验证码失败")
    }

    func isCodeEnabled(scene: DemoOTPScene) async -> Bool {
        if let cached = codeEnabledCache[scene] { return cached }
        // If we cannot reach the server (no session / connect failure),
        // do NOT force "captcha required" because that would disable the login button.
        // Instead allow submit so user can see the concrete connection error message.
        if let e = await ensureReady(), e.code == nil { return false }

        let codeType: BSPHPCodeType
        switch scene {
        case .login: codeType = .login
        case .register: codeType = .reg
        case .reset: codeType = .backPwd
        }

        let r = await client.getCodeEnabled(type: codeType)
        let enabled = (r.message.lowercased() == "checked")
        codeEnabledCache[scene] = enabled
        return enabled
    }

    func sendEmailCode(scene: DemoOTPScene, email: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.sendEmailCode(scene: scene.rawValue, email: email, coode: coode)
        return convert(r, fallback: "发送邮箱验证码失败")
    }

    func loginPassword(user: String, password: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.login(user: user, password: password, code: coode)
        return convert(r, fallback: "账号密码登录失败")
    }

    func loginSms(mobile: String, area: String, smsCode: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let machine = BSPHPClient.machineCode
        let r = await client.loginSms(mobile: mobile, area: area, smsCode: smsCode, key: machine, maxoror: machine, coode: coode)
        return convert(r, fallback: "短信登录失败")
    }

    func loginEmail(email: String, emailCode: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let machine = BSPHPClient.machineCode
        let r = await client.loginEmail(email: email, emailCode: emailCode, key: machine, maxoror: machine, coode: coode)
        return convert(r, fallback: "邮箱登录失败")
    }

    /// 账号密码注册（registration.lg），与 Mac 演示一致：可选 QQ/邮箱、手机、密保、图片验证码、推广码
    func registerPassword(
        user: String,
        pwd: String,
        pwdb: String,
        coode: String,
        mobile: String,
        mibaoWenti: String,
        mibaoDaan: String,
        qq: String,
        mail: String,
        extensionCode: String
    ) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.reg(
            user: user,
            pwd: pwd,
            pwdb: pwdb,
            coode: coode,
            mobile: mobile,
            mibaoWenti: mibaoWenti,
            mibaoDaan: mibaoDaan,
            qq: qq,
            mail: mail,
            extensionCode: extensionCode
        )
        return convert(r, fallback: "账号注册失败")
    }

    func registerSms(user: String, mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.registerSms(user: user, mobile: mobile, area: area, smsCode: smsCode, pwd: pwd, pwdb: pwdb, key: BSPHPClient.machineCode, coode: coode)
        return convert(r, fallback: "短信注册失败")
    }

    func registerEmail(user: String, email: String, emailCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.registerEmail(user: user, email: email, emailCode: emailCode, pwd: pwd, pwdb: pwdb, key: BSPHPClient.machineCode, coode: coode)
        return convert(r, fallback: "邮箱注册失败")
    }

    func resetSmsPwd(mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.resetSmsPwd(mobile: mobile, area: area, smsCode: smsCode, pwd: pwd, pwdb: pwdb, coode: coode)
        return convert(r, fallback: "短信找回失败")
    }

    func resetEmailPwd(email: String, emailCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.resetEmailPwd(email: email, emailCode: emailCode, pwd: pwd, pwdb: pwdb, coode: coode)
        return convert(r, fallback: "邮箱找回失败")
    }

    // MARK: - 公共信息（首页 .in 接口）

    func getNotice() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getNotice()
        return convert(r, fallback: "公告获取失败")
    }

    func getServerDate() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getServerDate()
        return convert(r, fallback: "服务器时间获取失败")
    }

    func getPresetURL() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getPresetURL()
        return convert(r, fallback: "预设URL获取失败")
    }

    func getWebURL() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getWebURL()
        return convert(r, fallback: "Web地址获取失败")
    }

    func getGlobalInfo() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getGlobalInfo()
        return convert(r, fallback: "全局配置获取失败")
    }

    func getVersion() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getVersion()
        return convert(r, fallback: "版本获取失败")
    }

    func getSoftInfo() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getSoftInfo()
        return convert(r, fallback: "软件描述获取失败")
    }

    // MARK: - 用户信息（我的页）

    func getUserInfo() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getUserInfo()
        return convert(r, fallback: "获取用户信息失败")
    }

    func getUserInfo(fields: [BSPHPUserInfoField]) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getUserInfo(fields: fields)
        return convert(r, fallback: "获取用户信息失败")
    }

    func getEndTime() async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.getEndTime()
        return convert(r, fallback: "获取到期时间失败")
    }

    /// 完善资料：`Perfect.lg`（需已登录，参数见 chm-38）
    func perfectUserInfo(params: [String: String]) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.perfectUserInfo(params: params)
        return convert(r, fallback: "资料修改失败")
    }

    // MARK: - 购物车演示（chong.lg / jiekey.lg / liuyan.in）

    /// 充值：`chong.lg`
    func pay(user: String, userpwd: String, userset: Bool, ka: String, pwd: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.pay(user: user, userpwd: userpwd, userset: userset, ka: ka, pwd: pwd)
        return convert(r, fallback: "充值请求失败")
    }

    /// 解除绑定：`jiekey.lg`
    func unbind(user: String, pwd: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.unbind(user: user, pwd: pwd)
        return convert(r, fallback: "解绑请求失败")
    }

    /// 意见反馈：`liuyan.in`
    func feedback(user: String, pwd: String, table: String, qq: String, leix: String, text: String, coode: String) async -> DemoAPIResult {
        if let e = await ensureReady() { return e }
        let r = await client.feedback(user: user, pwd: pwd, table: table, qq: qq, leix: leix, text: text, coode: coode)
        return convert(r, fallback: "反馈提交失败")
    }
}

struct ContentView: View {
    // Do not persist login state across launches.
    // Start in login page by default, switch to tabs after successful login.
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView(onLogout: { isLoggedIn = false })
            } else {
                LoginPageView(onLoginSuccess: { isLoggedIn = true })
            }
        }
    }
}

#Preview {
    ContentView()
}

private enum AuthMode: String, CaseIterable, Identifiable {
    case password = "账号密码"
    case sms = "短信验证码"
    case emailCode = "邮箱验证码"

    var id: String { rawValue }
}

private enum AuthPage: String, CaseIterable, Identifiable {
    case login = "登录"
    case register = "注册"
    case forgotPassword = "找回密码"

    var id: String { rawValue }
}

struct AuthContainerView: View {
    @State private var currentPage: AuthPage = .login
    let onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            WaterRippleBackground()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text("BSPHP演示")
                        .font(.largeTitle.bold())
                    Text("安全登录与账号管理")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                Picker("页面", selection: $currentPage) {
                    ForEach(AuthPage.allCases) { page in
                        Text(page.rawValue).tag(page)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch currentPage {
                case .login:
                    LoginView(onLoginSuccess: onLoginSuccess)
                case .register:
                    RegisterView()
                case .forgotPassword:
                    ForgotPasswordView()
                }

                Spacer(minLength: 8)
            }
        }
    }
}

private struct WaterRippleBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.96, blue: 1.00),
                        Color(red: 0.95, green: 0.98, blue: 1.00),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 240
                            )
                        )
                        .frame(width: 380, height: 380)
                        .position(
                            x: w * 0.25 + CGFloat(sin(t * 0.8) * 28),
                            y: h * 0.22 + CGFloat(cos(t * 0.7) * 24)
                        )
                        .blur(radius: 6)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.30), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 260
                            )
                        )
                        .frame(width: 420, height: 420)
                        .position(
                            x: w * 0.78 + CGFloat(cos(t * 0.65) * 24),
                            y: h * 0.30 + CGFloat(sin(t * 0.9) * 20)
                        )
                        .blur(radius: 8)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.indigo.opacity(0.22), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 230
                            )
                        )
                        .frame(width: 340, height: 340)
                        .position(
                            x: w * 0.52 + CGFloat(sin(t * 1.0) * 30),
                            y: h * 0.78 + CGFloat(cos(t * 0.6) * 26)
                        )
                        .blur(radius: 10)
                }

                // Subtle glossy wash to mimic Apple-like fluid depth.
                LinearGradient(
                    colors: [Color.white.opacity(0.34), Color.white.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

private struct LoginView: View {
    @State private var mode: AuthMode = .password
    /// 演示默认账号密码（可在发布前清空或改由配置读取）
    @State private var account = "admin"
    @State private var password = "admin"
    @State private var phone = ""
    @State private var smsCode = ""
    @State private var email = ""
    @State private var emailCode = ""
    @State private var hintText = ""
    @State private var passwordCaptcha = ""
    @State private var passwordCodeEnabled = true
    @State private var hasSentOtp = false
    @State private var currentCaptcha = ""

    let onLoginSuccess: () -> Void

    var body: some View {
        AuthCard(title: "登录") {
            Picker("登录方式", selection: $mode) {
                ForEach(AuthMode.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch mode {
                case .password:
                    TextField("账号", text: $account)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    if passwordCodeEnabled {
                        ImageCaptchaRow(captchaInput: $passwordCaptcha)
                    }
                case .sms:
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $smsCode,
                        buttonTitle: "获取短信",
                        onSend: sendSmsCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                case .emailCode:
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $emailCode,
                        buttonTitle: "获取邮箱码",
                        onSend: sendEmailCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                }
            }

            if !hintText.isEmpty {
                Text(hintText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("登录") {
                doLogin()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
        .task {
            passwordCodeEnabled = await DemoAuthMockAPI.isCodeEnabled(scene: .login)
        }
    }

    private var validationMessage: String? {
        switch mode {
        case .password:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入账号" }
            if password.isEmpty { return "请输入密码" }
            if passwordCodeEnabled && passwordCaptcha.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入图片验证码" }
        case .sms:
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if !hasSentOtp { return "请先发送短信验证码" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        case .emailCode:
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if !hasSentOtp { return "请先发送邮箱验证码" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doLogin() {
        Task {
            print("[Auth] doLogin tapped. mode=\(mode.rawValue) account=\(account.count) pwd=\(password.count) hasCaptcha=\(passwordCaptcha.count)")
            if let message = validationMessage {
                print("[Auth] validation failed: \(message)")
                await MainActor.run { hintText = message }
                return
            }

            switch mode {
            case .password:
                print("[Auth] loginPassword start")
                let result = await DemoAuthMockAPI.loginPassword(
                    user: account,
                    password: password,
                    coode: passwordCodeEnabled ? passwordCaptcha : ""
                )
                await MainActor.run {
                    print("[Auth] loginPassword done code=\(result.code ?? -1) message=\(result.message)")
                    hintText = result.message
                    if result.code == 1011 || result.code == 9908 { onLoginSuccess() }
                }
            case .sms:
                print("[Auth] loginSms start")
                let result = await DemoAuthMockAPI.loginSms(
                    mobile: phone,
                    area: "86",
                    smsCode: smsCode,
                    coode: currentCaptcha
                )
                await MainActor.run {
                    print("[Auth] loginSms done code=\(result.code ?? -1) message=\(result.message)")
                    hintText = result.message
                    if result.code == 1011 || result.code == 9908 { onLoginSuccess() }
                }
            case .emailCode:
                print("[Auth] loginEmail start")
                let result = await DemoAuthMockAPI.loginEmail(
                    email: email,
                    emailCode: emailCode,
                    coode: currentCaptcha
                )
                await MainActor.run {
                    print("[Auth] loginEmail done code=\(result.code ?? -1) message=\(result.message)")
                    hintText = result.message
                    if result.code == 1011 || result.code == 9908 { onLoginSuccess() }
                }
            }
        }
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendSmsCode(scene: .login, mobile: phone, area: "86", coode: currentCaptcha)
        }
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendEmailCode(scene: .login, email: email, coode: currentCaptcha)
        }
    }

    private func sendOtp(_ action: @escaping () async -> DemoAPIResult) -> Bool {
        Task {
            let result = await action()
            await MainActor.run {
                print("[Auth] sendOtp done code=\(result.code ?? -1) message=\(result.message)")
                hintText = result.message
                hasSentOtp = (result.code == 200)
            }
        }
        return true
    }
}

private struct RegisterView: View {
    private let regQuestions = [
        "你最喜欢的颜色？",
        "你母亲的名字？",
        "你父亲的名字？",
        "你的出生地？",
        "你最喜欢的食物？",
        "你的小学名称？",
        "自定义问题"
    ]

    @State private var mode: AuthMode = .password
    @State private var account = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var regQQ = ""
    @State private var regMail = ""
    @State private var regMobile = ""
    @State private var regQuestionIndex = 0
    @State private var regAnswer = ""
    @State private var regCaptcha = ""
    @State private var regExtension = ""
    @State private var registerCodeEnabled = false

    @State private var phone = ""
    @State private var smsCode = ""
    @State private var email = ""
    @State private var emailCode = ""
    @State private var hintText = ""
    @State private var hasSentOtp = false
    @State private var currentCaptcha = ""

    var body: some View {
        AuthCard(title: "注册") {
            Picker("注册方式", selection: $mode) {
                ForEach(AuthMode.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch mode {
                case .password:
                    TextField("注册账号", text: $account)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    SecureField("登录密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        TextField("QQ（可选）", text: $regQQ)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                        TextField("邮箱（可选）", text: $regMail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .textFieldStyle(.roundedBorder)
                    }

                    TextField("手机号（可选，按后台要求填写）", text: $regMobile)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("密保问题")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Picker("密保", selection: $regQuestionIndex) {
                                ForEach(regQuestions.indices, id: \.self) { idx in
                                    Text(regQuestions[idx]).tag(idx)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            TextField("答案", text: $regAnswer)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if registerCodeEnabled {
                        ImageCaptchaRow(captchaInput: $regCaptcha)
                    }

                    TextField("推广码（可选）", text: $regExtension)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)

                case .sms:
                    TextField("注册账号", text: $account)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    SecureField("登录密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $smsCode,
                        buttonTitle: "获取短信",
                        onSend: sendSmsCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                case .emailCode:
                    TextField("注册账号", text: $account)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    SecureField("登录密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $emailCode,
                        buttonTitle: "获取邮箱码",
                        onSend: sendEmailCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                }
            }

            if !hintText.isEmpty {
                Text(hintText)
                    .font(.footnote)
                    .foregroundStyle(hintText.contains("成功") ? .green : .red)
            }

            Button("注册") {
                doRegister()
            }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .task {
            registerCodeEnabled = await DemoAuthMockAPI.isCodeEnabled(scene: .register)
        }
    }

    private var validationMessage: String? {
        switch mode {
        case .password:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入账号" }
            if confirmPassword != password { return "两次密码不一致" }
            if regAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请填写密保答案" }
            if registerCodeEnabled && regCaptcha.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "请输入图片验证码"
            }
        case .sms:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入注册账号" }
            if confirmPassword != password { return "两次密码不一致" }
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if !hasSentOtp { return "请先发送短信验证码" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        case .emailCode:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入注册账号" }
            if confirmPassword != password { return "两次密码不一致" }
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if !hasSentOtp { return "请先发送邮箱验证码" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doRegister() {
        Task {
            if let message = validationMessage {
                hintText = message
                return
            }
            let result: DemoAPIResult
            switch mode {
            case .password:
                result = await DemoAuthMockAPI.registerPassword(
                    user: account,
                    pwd: password,
                    pwdb: confirmPassword,
                    coode: registerCodeEnabled ? regCaptcha : "",
                    mobile: regMobile.trimmingCharacters(in: .whitespacesAndNewlines),
                    mibaoWenti: regQuestions[regQuestionIndex],
                    mibaoDaan: regAnswer.trimmingCharacters(in: .whitespacesAndNewlines),
                    qq: regQQ.trimmingCharacters(in: .whitespacesAndNewlines),
                    mail: regMail.trimmingCharacters(in: .whitespacesAndNewlines),
                    extensionCode: regExtension.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            case .sms:
                result = await DemoAuthMockAPI.registerSms(
                    user: account,
                    mobile: phone,
                    area: "86",
                    smsCode: smsCode,
                    pwd: password,
                    pwdb: confirmPassword,
                    coode: currentCaptcha
                )
            case .emailCode:
                result = await DemoAuthMockAPI.registerEmail(
                    user: account,
                    email: email,
                    emailCode: emailCode,
                    pwd: password,
                    pwdb: confirmPassword,
                    coode: currentCaptcha
                )
            }
            hintText = result.message
        }
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendSmsCode(scene: .register, mobile: phone, area: "86", coode: currentCaptcha)
        }
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendEmailCode(scene: .register, email: email, coode: currentCaptcha)
        }
    }

    private func sendOtp(_ action: @escaping () async -> DemoAPIResult) -> Bool {
        Task {
            let result = await action()
            hintText = result.message
            hasSentOtp = (result.code == 200)
        }
        return true
    }
}

private struct ForgotPasswordView: View {
    @State private var mode: AuthMode = .sms
    @State private var phone = ""
    @State private var smsCode = ""
    @State private var email = ""
    @State private var emailCode = ""
    @State private var newPassword = ""
    @State private var hintText = ""
    @State private var hasSentOtp = false
    @State private var currentCaptcha = ""

    var body: some View {
        AuthCard(title: "找回密码") {
            Picker("找回方式", selection: $mode) {
                Text(AuthMode.sms.rawValue).tag(AuthMode.sms)
                Text(AuthMode.emailCode.rawValue).tag(AuthMode.emailCode)
            }
            .pickerStyle(.segmented)

            Group {
                if mode == .sms {
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $smsCode,
                        buttonTitle: "获取短信",
                        onSend: sendSmsCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                } else {
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(
                        code: $emailCode,
                        buttonTitle: "获取邮箱码",
                        onSend: sendEmailCode,
                        onHint: { hintText = $0 },
                        onCaptchaChanged: { currentCaptcha = $0 }
                    )
                }
            }

            SecureField("新密码", text: $newPassword)
                .textFieldStyle(.roundedBorder)

            if !hintText.isEmpty {
                Text(hintText)
                    .font(.footnote)
                    .foregroundStyle(hintText.contains("成功") ? .green : .red)
            }

            Button("重置密码") {
                doResetPassword()
            }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    private var validationMessage: String? {
        
        if mode == .sms {
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if !hasSentOtp { return "请先发送短信验证码" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        } else {
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if !hasSentOtp { return "请先发送邮箱验证码" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doResetPassword() {
        Task {
            if let message = validationMessage {
                hintText = message
                return
            }
            let result: DemoAPIResult
            if mode == .sms {
                result = await DemoAuthMockAPI.resetSmsPwd(
                    mobile: phone,
                    area: "86",
                    smsCode: smsCode,
                    pwd: newPassword,
                    pwdb: newPassword,
                    coode: currentCaptcha
                )
            } else {
                result = await DemoAuthMockAPI.resetEmailPwd(
                    email: email,
                    emailCode: emailCode,
                    pwd: newPassword,
                    pwdb: newPassword,
                    coode: currentCaptcha
                )
            }
            hintText = result.message
        }
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendSmsCode(scene: .reset, mobile: phone, area: "86", coode: currentCaptcha)
        }
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        return sendOtp {
            await DemoAuthMockAPI.sendEmailCode(scene: .reset, email: email, coode: currentCaptcha)
        }
    }

    private func sendOtp(_ action: @escaping () async -> DemoAPIResult) -> Bool {
        Task {
            let result = await action()
            hintText = result.message
            hasSentOtp = (result.code == 200)
        }
        return true
    }
}

private struct AuthCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: titleIcon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.title3.bold())
            }

            content
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
        .padding(.horizontal)
    }

    private var titleIcon: String {
        switch title {
        case "登录": return "lock.shield"
        case "注册": return "person.badge.plus"
        case "找回密码": return "key.viewfinder"
        default: return "square.text.square"
        }
    }
}

private struct VerifyCodeRow: View {
    @Binding var code: String
    var buttonTitle: String
    var onSend: () -> Bool
    var onHint: (String) -> Void
    var onCaptchaChanged: (String) -> Void = { _ in }
    @State private var countDown = 0
    @State private var imageCaptchaInput = ""
    @State private var refreshTrigger = Int(Date().timeIntervalSince1970)
    @State private var captchaImageURL: URL?
    @State private var captchaHint = "加载中..."

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("图片验证码", text: $imageCaptchaInput)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)

                Group {
                    if let url = loadURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            case .empty:
                                ProgressView()
                            case .failure:
                                Text("加载失败").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text(captchaHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 36)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )

                Button {
                    refreshCaptcha()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }

            HStack(spacing: 8) {
                TextField("短信/邮箱验证码", text: $code)
                    .textFieldStyle(.roundedBorder)
                Button(buttonText) {
                    guard !imageCaptchaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        onHint("请输入图片验证码")
                        return
                    }

                    if onSend() {
                        startCountdown()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            onCaptchaChanged(imageCaptchaInput)
            Task { await loadCaptchaImageURL() }
        }
        .onChange(of: imageCaptchaInput) { _, newValue in
            onCaptchaChanged(newValue)
        }
    }

    private var buttonText: String {
        countDown > 0 ? "\(countDown)s" : buttonTitle
    }

    private var loadURL: URL? {
        guard let base = captchaImageURL else { return nil }
        guard var comp = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        comp.queryItems = (comp.queryItems ?? []) + [URLQueryItem(name: "_", value: "\(refreshTrigger)")]
        return comp.url
    }

    private func startCountdown() {
        countDown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countDown <= 0 {
                timer.invalidate()
            } else {
                countDown -= 1
            }
        }
    }

    private func refreshCaptcha() {
        imageCaptchaInput = ""
        refreshTrigger = Int(Date().timeIntervalSince1970)
        Task { await loadCaptchaImageURL() }
    }

    private func loadCaptchaImageURL() async {
        let result = await BSPHPMobileAPI.shared.captchaImageURL()
        captchaImageURL = result.url
        captchaHint = result.message
    }
}

struct ImageCaptchaRow: View {
    @Binding var captchaInput: String
    @State private var refreshTrigger = Int(Date().timeIntervalSince1970)
    @State private var captchaImageURL: URL?
    @State private var captchaHint = "加载中..."

    var body: some View {
        HStack(spacing: 8) {
            TextField("图片验证码", text: $captchaInput)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)

            Group {
                if let url = loadURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .empty:
                            ProgressView()
                        case .failure:
                            Text("加载失败").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(captchaHint).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 36)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.blue.opacity(0.25), lineWidth: 1)
            )

            Button {
                refreshTrigger = Int(Date().timeIntervalSince1970)
                Task { await loadCaptchaImageURL() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .onAppear {
            Task { await loadCaptchaImageURL() }
        }
    }

    private var loadURL: URL? {
        guard let base = captchaImageURL else { return nil }
        guard var comp = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        comp.queryItems = (comp.queryItems ?? []) + [URLQueryItem(name: "_", value: "\(refreshTrigger)")]
        return comp.url
    }

    private func loadCaptchaImageURL() async {
        let result = await BSPHPMobileAPI.shared.captchaImageURL()
        captchaImageURL = result.url
        captchaHint = result.message
    }
}

private struct MainTabView: View {
    private enum TabKey: Hashable {
        case home
        case cart
        case profile
    }

    let onLogout: () -> Void
    @State private var selectedTab: TabKey = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomePageView()
                .navigationTitle("首页")
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(TabKey.home)

            NavigationStack {
                CartPageView(onGoHome: { selectedTab = .home })
                .navigationTitle("购物车")
            }
            .tabItem {
                Label("购物车", systemImage: "cart.fill")
            }
            .tag(TabKey.cart)

            NavigationStack {
                ProfilePageView(onLogout: onLogout)
                .navigationTitle("我的")
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(TabKey.profile)
        }
        .tint(.blue)
    }
}

private struct HeroCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.bold()).foregroundStyle(.white)
                Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: icon).font(.system(size: 26)).foregroundStyle(.white)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct FeatureCard: View {
    let title: String
    let desc: String
    let tint: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: configuration.isPressed ? [.indigo, .blue] : [.blue, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private enum Validation {
    static func isPhone(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = #"^1[3-9]\d{9}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    static func isEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

}

struct DemoAPIResult {
    let code: Int?
    let message: String
}

enum DemoOTPScene: String {
    case login
    case register
    case reset
}

private enum DemoAuthMockAPI {
    private static let api = BSPHPMobileAPI.shared

    static func sendSmsCode(scene: DemoOTPScene, mobile: String, area: String, coode: String) async -> DemoAPIResult {
        await api.sendSmsCode(scene: scene, mobile: mobile, area: area, coode: coode)
    }

    static func sendEmailCode(scene: DemoOTPScene, email: String, coode: String) async -> DemoAPIResult {
        await api.sendEmailCode(scene: scene, email: email, coode: coode)
    }

    static func isCodeEnabled(scene: DemoOTPScene) async -> Bool {
        await api.isCodeEnabled(scene: scene)
    }

    static func loginPassword(user: String, password: String, coode: String) async -> DemoAPIResult {
        await api.loginPassword(user: user, password: password, coode: coode)
    }

    static func loginSms(mobile: String, area: String, smsCode: String, coode: String) async -> DemoAPIResult {
        await api.loginSms(mobile: mobile, area: area, smsCode: smsCode, coode: coode)
    }

    static func loginEmail(email: String, emailCode: String, coode: String) async -> DemoAPIResult {
        await api.loginEmail(email: email, emailCode: emailCode, coode: coode)
    }

    static func registerPassword(
        user: String,
        pwd: String,
        pwdb: String,
        coode: String,
        mobile: String,
        mibaoWenti: String,
        mibaoDaan: String,
        qq: String,
        mail: String,
        extensionCode: String
    ) async -> DemoAPIResult {
        await api.registerPassword(
            user: user,
            pwd: pwd,
            pwdb: pwdb,
            coode: coode,
            mobile: mobile,
            mibaoWenti: mibaoWenti,
            mibaoDaan: mibaoDaan,
            qq: qq,
            mail: mail,
            extensionCode: extensionCode
        )
    }

    static func registerSms(user: String, mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        await api.registerSms(user: user, mobile: mobile, area: area, smsCode: smsCode, pwd: pwd, pwdb: pwdb, coode: coode)
    }

    static func registerEmail(user: String, email: String, emailCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        await api.registerEmail(user: user, email: email, emailCode: emailCode, pwd: pwd, pwdb: pwdb, coode: coode)
    }

    static func resetSmsPwd(mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        await api.resetSmsPwd(mobile: mobile, area: area, smsCode: smsCode, pwd: pwd, pwdb: pwdb, coode: coode)
    }

    static func resetEmailPwd(email: String, emailCode: String, pwd: String, pwdb: String, coode: String) async -> DemoAPIResult {
        await api.resetEmailPwd(email: email, emailCode: emailCode, pwd: pwd, pwdb: pwdb, coode: coode)
    }
}
