//
// 功能说明（简体中文）:
//   邮箱找回 Tab：发送邮箱验证码、输入 OTP（6位）、设置新密码并提交找回。
// 功能说明（繁体中文）:
//   信箱找回 Tab：發送信箱驗證碼、輸入 OTP（6 位）、設定新密碼並提交找回。
// Function (English):
//   Email password recovery tab: send email OTP, enter 6-digit OTP, set new password, submit recovery.
//

import SwiftUI

struct DemoBSphpEmailRecoverPasswordView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    @Binding var email: String
    @Binding var emailCode: String

    @Binding var pwd: String
    @Binding var pwdb: String

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
                    }
                }

                demoBSphpFormRow(title: "邮箱验证码：") {
                    TextField("6位数字", text: $emailCode)
                        .textFieldStyle(.roundedBorder)
                }
                Text("OTP有效期：300秒").font(.caption).foregroundColor(.secondary)

                demoBSphpFormRow(title: "新密码：") {
                    SecureField("", text: $pwd)
                        .textFieldStyle(.roundedBorder)
                }
                demoBSphpFormRow(title: "确认新密码：") {
                    SecureField("", text: $pwdb)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    Button("发送验证码") {
                        Task {
                            isBusy = true
                            let coodeVal = coode
                            let r = await api.client.sendEmailCode(
                                scene: DemoBSphpOTPScene.reset.rawValue,
                                email: email,
                                coode: coodeVal
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

                    Button("邮箱找回") {
                        Task {
                            isBusy = true
                            let coodeVal = coode
                            let r = await api.client.resetEmailPwd(
                                email: email,
                                emailCode: emailCode,
                                pwd: pwd,
                                pwdb: pwdb,
                                coode: coodeVal
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，邮箱验证码找回失败！" : r.message
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !api.isReady ||
                        isBusy ||
                        !sent ||
                        emailCode.isEmpty ||
                        pwd.isEmpty ||
                        pwdb.isEmpty ||
                        coode.isEmpty
                    )
                }
            }
        }
    }
}

