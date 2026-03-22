//
// 功能说明（简体中文）:
//   登录页：账号密码登录、验证码（按开关显示）、Web 登录入口与网络/到期/版本检测按钮。
// 功能说明（繁体中文）:
//   登入頁：帳號密碼登入、驗證碼（依開關顯示）、Web 登入入口與網路/到期/版本檢測按鈕。
// Function (English):
//   Login page with username/password, optional image captcha, Web login shortcut, and basic checks.
//

import SwiftUI

struct DemoBSphpLoginView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @Environment(\.openWindow) private var openWindow

    @Binding var loginUser: String
    @Binding var loginPass: String
    @Binding var loginCode: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "登录账号：") {
                    TextField("", text: $loginUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "登录密码：") {
                    SecureField("", text: $loginPass)
                        .textFieldStyle(.roundedBorder)
                }

                if api.isCodeEnabled(for: .login) {
                    demoBSphpFormRow(title: "验  证  码：") {
                        HStack(spacing: 10) {
                            TextField("", text: $loginCode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)

                            CodeImageView(
                                url: URL(string: api.client.codeImageURL),
                                sessionToken: api.client.bsPhpSeSsL,
                                refreshTrigger: api.codeRefreshTrigger
                            )

                            Button("刷新") {
                                Task {
                                    api.codeRefreshTrigger = Int(Date().timeIntervalSince1970)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(!api.isReady)
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button("测试网络") {
                        Task {
                            isBusy = true
                            let ok = await api.client.connect()
                            infoAlertCode = nil
                            infoAlertText = ok ? "测试连接成功!" : "测试连接失败!"
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!api.isReady || isBusy)

                    Button("检测到期") {
                        Task {
                            isBusy = true
                            let r = await api.client.getEndTime()
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，取到期时间失败！" : r.message
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!api.isReady || isBusy)

                    Button("获取版本") {
                        Task {
                            isBusy = true
                            let r = await api.client.getVersion()
                            infoAlertCode = r.code
                            infoAlertText = (r.data as? String) ?? "获取版本失败"
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!api.isReady || isBusy)

                    Spacer()

                    Button("Web方式登陆") {
                        openWindow(id: "webLogin")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!api.isReady)

                    Button("登录") {
                        Task {
                            isBusy = true
                            let code = api.isCodeEnabled(for: .login) ? loginCode : ""
                            let r = await api.client.login(user: loginUser, password: loginPass, code: code)
                            infoAlertCode = r.code
                            if r.code == 1011 {
                                infoAlertText = "登录成功！"
                                showInfoAlert = true
                                api.isLoggedIn = true
                                openWindow(id: "console")
                            } else if r.code == 9908 {
                                infoAlertText = "使用已经到期！"
                                showInfoAlert = true
                                api.isLoggedIn = true
                                openWindow(id: "console")
                            } else {
                                infoAlertText = r.message
                                showInfoAlert = true
                            }
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
}

