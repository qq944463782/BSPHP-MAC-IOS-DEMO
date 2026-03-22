//
// 功能说明（简体中文）:
//   充值页：账号/登录密码/充值卡号/充值卡密码 + 是否验证密码（防充错）。
// 功能说明（繁体中文）:
//   充值頁：帳號/登入密碼/充值卡號/充值卡密碼 + 是否驗證密碼（防止充錯）。
// Function (English):
//   Recharge page with account/password, card info, and an optional "verify login password" toggle.
//

import SwiftUI

struct DemoBSphpRechargeView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    @Binding var rechargeUser: String
    @Binding var rechargePass: String
    @Binding var rechargeCard: String
    @Binding var rechargeVerifyPassword: Bool
    @Binding var rechargeCardPass: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "充值账号：") {
                    TextField("", text: $rechargeUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "登录密码：") {
                    SecureField("", text: $rechargePass)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "充值卡号：") {
                    TextField("", text: $rechargeCard)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "充值密码：") {
                    SecureField("", text: $rechargeCardPass)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "是否需要验证密码：") {
                    HStack(spacing: 10) {
                        Toggle("", isOn: $rechargeVerifyPassword)
                            .toggleStyle(.switch)
                            .labelsHidden()
                        Text(rechargeVerifyPassword ? "是(1) 验证登录密码，防止充值错误给了别人" : "否(0) 不验证登录密码即可充值")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Spacer()
                    Button("充值") {
                        Task {
                            isBusy = true
                            let r = await api.client.pay(
                                user: rechargeUser,
                                userpwd: rechargePass,
                                userset: rechargeVerifyPassword,
                                ka: rechargeCard,
                                pwd: rechargeCardPass
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，充值失败！" : r.message
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
}

