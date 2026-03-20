//
//  ContentView.swift
//  bsphp.app.demo.user
//
//  Created by enzu zhou on 2026/3/20.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("is_logged_in") private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView(onLogout: { isLoggedIn = false })
            } else {
                AuthContainerView(onLoginSuccess: { isLoggedIn = true })
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

private struct AuthContainerView: View {
    @State private var currentPage: AuthPage = .login
    let onLoginSuccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("用户中心")
                .font(.largeTitle.bold())
                .padding(.top, 28)

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

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct LoginView: View {
    @State private var mode: AuthMode = .password
    @State private var account = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var smsCode = ""
    @State private var email = ""
    @State private var emailCode = ""
    @State private var hintText = ""

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
                case .sms:
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(code: $smsCode, buttonTitle: "获取短信", onSend: sendSmsCode)
                case .emailCode:
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(code: $emailCode, buttonTitle: "获取邮箱码", onSend: sendEmailCode)
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
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
    }

    private var canSubmit: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        switch mode {
        case .password:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入账号" }
            if password.count < 6 { return "密码至少 6 位" }
        case .sms:
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        case .emailCode:
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doLogin() {
        if let message = validationMessage {
            hintText = message
            return
        }
        hintText = ""
        onLoginSuccess()
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        hintText = "短信验证码已发送（演示）"
        return true
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        hintText = "邮箱验证码已发送（演示）"
        return true
    }
}

private struct RegisterView: View {
    @State private var mode: AuthMode = .password
    @State private var account = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var smsCode = ""
    @State private var email = ""
    @State private var emailCode = ""
    @State private var hintText = ""

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
                    TextField("账号", text: $account)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                case .sms:
                    TextField("手机号", text: $phone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(code: $smsCode, buttonTitle: "获取短信", onSend: sendSmsCode)
                case .emailCode:
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(code: $emailCode, buttonTitle: "获取邮箱码", onSend: sendEmailCode)
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
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    private var canSubmit: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        switch mode {
        case .password:
            if account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "请输入账号" }
            if password.count < 6 { return "密码至少 6 位" }
            if confirmPassword != password { return "两次密码不一致" }
        case .sms:
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        case .emailCode:
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doRegister() {
        if let message = validationMessage {
            hintText = message
            return
        }
        hintText = "注册成功（演示）"
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        hintText = "短信验证码已发送（演示）"
        return true
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        hintText = "邮箱验证码已发送（演示）"
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
                    VerifyCodeRow(code: $smsCode, buttonTitle: "获取短信", onSend: sendSmsCode)
                } else {
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    VerifyCodeRow(code: $emailCode, buttonTitle: "获取邮箱码", onSend: sendEmailCode)
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
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    private var canSubmit: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        if newPassword.count < 6 { return "新密码至少 6 位" }
        if mode == .sms {
            if !Validation.isPhone(phone) { return "手机号格式不正确" }
            if smsCode.count < 4 { return "请输入短信验证码" }
        } else {
            if !Validation.isEmail(email) { return "邮箱格式不正确" }
            if emailCode.count < 4 { return "请输入邮箱验证码" }
        }
        return nil
    }

    private func doResetPassword() {
        if let message = validationMessage {
            hintText = message
            return
        }
        hintText = "密码重置成功（演示）"
    }

    private func sendSmsCode() -> Bool {
        guard Validation.isPhone(phone) else {
            hintText = "请先输入正确手机号"
            return false
        }
        hintText = "短信验证码已发送（演示）"
        return true
    }

    private func sendEmailCode() -> Bool {
        guard Validation.isEmail(email) else {
            hintText = "请先输入正确邮箱"
            return false
        }
        hintText = "邮箱验证码已发送（演示）"
        return true
    }
}

private struct AuthCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())

            content
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}

private struct VerifyCodeRow: View {
    @Binding var code: String
    var buttonTitle: String
    var onSend: () -> Bool
    @State private var countDown = 0

    var body: some View {
        HStack(spacing: 8) {
            TextField("验证码", text: $code)
                .textFieldStyle(.roundedBorder)
            Button(buttonText) {
                if onSend() {
                    startCountdown()
                }
            }
            .disabled(countDown > 0)
                .buttonStyle(.bordered)
        }
    }

    private var buttonText: String {
        countDown > 0 ? "\(countDown)s" : buttonTitle
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
}

private struct MainTabView: View {
    let onLogout: () -> Void

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("首页内容")
                        .font(.title2.bold())
                    Text("这里可放 Banner、推荐商品、活动模块")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("首页")
            }
            .tabItem {
                Label("首页", systemImage: "house")
            }

            NavigationStack {
                VStack(spacing: 16) {
                    Text("购物车为空")
                        .font(.title2.bold())
                    Text("这里展示购物车商品列表与结算按钮")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("购物车")
            }
            .tabItem {
                Label("购物车", systemImage: "cart")
            }

            NavigationStack {
                VStack(spacing: 16) {
                    Text("我的")
                        .font(.title2.bold())
                    Text("这里展示用户资料、订单、设置等")
                        .foregroundStyle(.secondary)
                    Button("退出登录", role: .destructive) {
                        onLogout()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("我的")
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
        }
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
