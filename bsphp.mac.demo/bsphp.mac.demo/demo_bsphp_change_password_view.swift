//
// 功能说明（简体中文）:
//   修改密码页：输入账号/旧密码/新密码（两次），调用修改密码接口（`password.lg`）。
// 功能说明（繁体中文）:
//   修改密碼頁：輸入帳號/舊密碼/新密碼（兩次），呼叫修改密碼介面（`password.lg`）。
// Function (English):
//   Change password page with account, old/new passwords; calls `password.lg`.
//

import SwiftUI

struct DemoBSphpChangePasswordView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    @Binding var changeUser: String
    @Binding var changeOldPass: String
    @Binding var changeNewPass: String
    @Binding var changeNewPass2: String
    @Binding var changeCode: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "登录账号：") {
                    TextField("", text: $changeUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "旧密码：") {
                    SecureField("", text: $changeOldPass)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "新密码：") {
                    HStack(spacing: 10) {
                        SecureField("新密码", text: $changeNewPass)
                            .textFieldStyle(.roundedBorder)
                        SecureField("确认新密码", text: $changeNewPass2)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack {
                    Spacer()
                    Button("修改密码") {
                        Task {
                            isBusy = true
                            let r = await api.client.editPass(
                                user: changeUser,
                                pwd: changeOldPass,
                                pwda: changeNewPass,
                                pwdb: changeNewPass2,
                                img: changeCode
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，修改密码失败！" : r.message
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

