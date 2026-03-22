//
// 功能说明（简体中文）:
//   邮箱登录 Tab：发送邮箱验证码、输入 OTP（6位）、可选图片验证码与登录提交。
// 功能说明（繁体中文）:
//   信箱登入 Tab：發送信箱驗證碼、輸入 OTP（6 位）、可選圖片驗證碼與登入提交。
// Function (English):
//   Email login tab: send email OTP, enter 6-digit OTP, optional image captcha, then submit login.
//

import SwiftUI

struct DemoBSphpEmailLoginView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @Environment(\.openWindow) private var openWindow

    @Binding var email: String
    @Binding var emailCode: String

    @Binding var key: String
    @Binding var maxoror: String
    @Binding var coode: String

    @Binding var sent: Bool

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "邮箱地址：") {
                    TextField("", text: $email)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "验  证  码：") {
                    HStack(spacing: 10) {
                        TextField("", text: $coode)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                        CodeImageView(url: URL(string: api.client.codeImageURL), sessionToken: api.client.bsPhpSeSsL, refreshTrigger: api.codeRefreshTrigger)
                        Button("刷新") {
                            api.codeRefreshTrigger = Int(Date().timeIntervalSince1970)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!api.isReady)

                        Button("发送验证码") {
                            Task {
                                isBusy = true
                                let r = await api.client.sendEmailCode(
                                    scene: DemoBSphpOTPScene.login.rawValue,
                                    email: email,
                                    coode: coode
                                )
                                infoAlertCode = r.code
                                sent = (r.code == 200)
                                infoAlertText = r.message.isEmpty ? "系统错误，发送邮箱验证码失败！" : r.message
                                showInfoAlert = true
                                isBusy = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            !api.isReady ||
                            isBusy ||
                            email.isEmpty ||
                            coode.isEmpty
                        )
                    }
                }

                demoBSphpFormRow(title: "邮箱验证码：") {
                    TextField("6位数字", text: $emailCode)
                        .textFieldStyle(.roundedBorder)
                }
                Text("OTP有效期：300秒").font(.caption).foregroundColor(.secondary)

                demoBSphpFormRow(title: "绑定特征key：") {
                    TextField("", text: $key)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "maxoror：") {
                    TextField("", text: $maxoror)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    Button("邮箱登录") {
                        Task {
                            isBusy = true
                            let coodeVal = coode
                            let r = await api.client.loginEmail(
                                email: email,
                                emailCode: emailCode,
                                key: key,
                                maxoror: maxoror,
                                coode: coodeVal
                            )
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
                                infoAlertText = r.message.isEmpty ? "系统错误，邮箱验证码登录失败！" : r.message
                                showInfoAlert = true
                            }
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !api.isReady ||
                        isBusy ||
                        !sent ||
                        emailCode.isEmpty ||
                        coode.isEmpty
                    )
                }
            }
        }
    }
}

