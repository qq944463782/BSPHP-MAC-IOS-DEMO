//
// 功能说明（简体中文）:
//   解绑页：输入账号/密码，调用解绑接口（`jiekey.lg`）。
// 功能说明（繁体中文）:
//   解除綁定頁：輸入帳號/密碼，呼叫解除綁定介面（`jiekey.lg`）。
// Function (English):
//   Unbind page with account and password; calls `jiekey.lg`.
//

import SwiftUI

struct DemoBSphpUnbindView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    @Binding var unbindUser: String
    @Binding var unbindPass: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "登录账号：") {
                    TextField("", text: $unbindUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "登录密码：") {
                    SecureField("", text: $unbindPass)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button("解绑") {
                        Task {
                            isBusy = true
                            let r = await api.client.unbind(user: unbindUser, pwd: unbindPass)
                            infoAlertCode = r.code
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
}

