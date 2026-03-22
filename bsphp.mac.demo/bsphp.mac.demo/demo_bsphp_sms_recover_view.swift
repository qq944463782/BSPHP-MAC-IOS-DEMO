//
// 功能说明（简体中文）:
//   短信找回 Tab：发送短信验证码、输入 OTP、新密码（两次）并提交找回。
// 功能说明（繁体中文）:
//   簡訊找回 Tab：發送簡訊驗證碼、輸入 OTP、新密碼（兩次）並提交找回。
// Function (English):
//   SMS password recovery tab: send SMS OTP, enter OTP, set new password twice, submit recovery.
//

import SwiftUI

struct DemoBSphpSmsRecoverPasswordView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    @Binding var mobile: String
    @Binding var area: String
    @Binding var smsCode: String

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
                demoBSphpFormRow(title: "手机号码：") {
                    TextField("", text: $mobile)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "区  号：") {
                    TextField("", text: $area)
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

                demoBSphpFormRow(title: "短信验证码：") {
                    TextField("4位数字", text: $smsCode)
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
                            let r = await api.client.sendSmsCode(
                                scene: DemoBSphpOTPScene.reset.rawValue,
                                mobile: mobile,
                                area: area.isEmpty ? "86" : area,
                                coode: coodeVal
                            )
                            infoAlertCode = r.code
                            sent = (r.code == 200)
                            infoAlertText = r.message.isEmpty ? "系统错误，发送短信验证码失败！" : r.message
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        !api.isReady ||
                        isBusy ||
                        mobile.isEmpty ||
                        coode.isEmpty
                    )

                    Button("短信找回") {
                        Task {
                            isBusy = true
                            let coodeVal = coode
                            let r = await api.client.resetSmsPwd(
                                mobile: mobile,
                                area: area.isEmpty ? "86" : area,
                                smsCode: smsCode,
                                pwd: pwd,
                                pwdb: pwdb,
                                coode: coodeVal
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，短信验证码找回失败！" : r.message
                            showInfoAlert = true
                            isBusy = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !api.isReady ||
                        isBusy ||
                        !sent ||
                        smsCode.isEmpty ||
                        pwd.isEmpty ||
                        pwdb.isEmpty ||
                        coode.isEmpty
                    )
                }
            }
        }
    }
}

