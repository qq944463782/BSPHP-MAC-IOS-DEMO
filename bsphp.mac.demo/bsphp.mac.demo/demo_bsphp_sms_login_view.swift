//
// 功能说明（简体中文）:
//   短信登录 Tab：发送短信验证码、输入 OTP、可选图片验证码与登录提交。
// 功能说明（繁体中文）:
//   簡訊登入 Tab：發送簡訊驗證碼、輸入 OTP、可選圖片驗證碼與登入提交。
// Function (English):
//   SMS login tab: send SMS OTP, optional image captcha, enter OTP, then submit login.
//

import SwiftUI

struct DemoBSphpSmsLoginView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @Environment(\.openWindow) private var openWindow

    @Binding var mobile: String
    @Binding var area: String
    @Binding var smsCode: String

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

                        Button("发送验证码") {
                            Task {
                                isBusy = true
                                let r = await api.client.sendSmsCode(
                                    scene: DemoBSphpOTPScene.login.rawValue,
                                    mobile: mobile,
                                    area: area.isEmpty ? "86" : area,
                                    coode: coode
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
                    }
                }

                demoBSphpFormRow(title: "短信验证码：") {
                    TextField("4位数字", text: $smsCode)
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
                    Button("短信登录") {
                        Task {
                            isBusy = true
                            let coodeVal = coode
                            let r = await api.client.loginSms(
                                mobile: mobile,
                                area: area.isEmpty ? "86" : area,
                                smsCode: smsCode,
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
                                infoAlertText = r.message.isEmpty ? "系统错误，短信验证码登录失败！" : r.message
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
                        smsCode.isEmpty ||
                        coode.isEmpty
                    )
                }
            }
        }
    }
}

