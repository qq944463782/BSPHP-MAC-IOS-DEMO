//
// 功能说明（简体中文）:
//   找回密码页：账号/密保问题/新密码（两次）+ 验证码（按开关显示）。
// 功能说明（繁体中文）:
//   找回密碼頁：帳號/密保問題/新密碼（兩次）+ 驗證碼（依開關顯示）。
// Function (English):
//   Recover password page with account, security question, two-pass new password, and optional captcha.
//

import SwiftUI

struct DemoBSphpRecoverPasswordView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    let regQuestions: [String]

    @Binding var recoverUser: String
    @Binding var recoverQuestionIndex: Int
    @Binding var recoverAnswer: String
    @Binding var recoverNewPass: String
    @Binding var recoverNewPass2: String
    @Binding var recoverCode: String

    @Binding var noticeText: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "登录账号：") {
                    TextField("", text: $recoverUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "密保问题：") {
                    HStack(spacing: 10) {
                        Picker("", selection: $recoverQuestionIndex) {
                            ForEach(regQuestions.indices, id: \.self) { idx in
                                Text(regQuestions[idx]).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)

                        TextField("答案", text: $recoverAnswer)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                demoBSphpFormRow(title: "新密码：") {
                    HStack(spacing: 10) {
                        SecureField("新密码", text: $recoverNewPass)
                            .textFieldStyle(.roundedBorder)
                        SecureField("确认新密码", text: $recoverNewPass2)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if api.isCodeEnabled(for: .backPwd) {
                    demoBSphpFormRow(title: "验  证  码：") {
                        HStack(spacing: 10) {
                            TextField("", text: $recoverCode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)

                            CodeImageView(
                                url: URL(string: api.client.codeImageURL),
                                sessionToken: api.client.bsPhpSeSsL,
                                refreshTrigger: api.codeRefreshTrigger
                            )

                            Button("刷新") {
                                Task {
                                    await api.bootstrap()
                                    noticeText = await api.fetchNotice()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(!api.isReady)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("找回密码") {
                        Task {
                            isBusy = true
                            let recoverCodeVal = api.isCodeEnabled(for: .backPwd) ? recoverCode : ""
                            let r = await api.client.backPass(
                                user: recoverUser,
                                pwd: recoverNewPass,
                                pwdb: recoverNewPass2,
                                wenti: regQuestions[recoverQuestionIndex],
                                daan: recoverAnswer,
                                coode: recoverCodeVal
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，找回密码失败！" : r.message
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

