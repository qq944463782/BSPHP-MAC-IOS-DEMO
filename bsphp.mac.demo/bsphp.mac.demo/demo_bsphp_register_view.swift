//
// 功能说明（简体中文）:
//   注册页：账号密码 + QQ/邮箱/手机号 + 密保问题，验证码按开关显示。
// 功能说明（繁体中文）:
//   註冊頁：帳號密碼 + QQ/信箱/手機號 + 密保問題，驗證碼依開關顯示。
// Function (English):
//   Registration page with username/password, optional QQ/email/mobile, security questions, and optional image captcha.
//

import SwiftUI

struct DemoBSphpRegisterView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    let regQuestions: [String]

    @Binding var regUser: String
    @Binding var regPass: String
    @Binding var regPass2: String
    @Binding var regQQ: String
    @Binding var regMail: String
    @Binding var regMobile: String

    @Binding var regQuestionIndex: Int
    @Binding var regAnswer: String
    @Binding var regCode: String
    @Binding var regExtension: String

    @Binding var noticeText: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 10) {
                demoBSphpFormRow(title: "注册账号：") {
                    TextField("", text: $regUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "注册密码：") {
                    HStack(spacing: 10) {
                        SecureField("登录密码", text: $regPass)
                            .textFieldStyle(.roundedBorder)
                        SecureField("确认密码", text: $regPass2)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                demoBSphpFormRow(title: "QQ / 邮箱：") {
                    HStack(spacing: 10) {
                        TextField("QQ(可选)", text: $regQQ)
                            .textFieldStyle(.roundedBorder)
                        TextField("邮箱(可选)", text: $regMail)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                demoBSphpFormRow(title: "手机号码：") {
                    TextField("", text: $regMobile)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "密保问题：") {
                    HStack(spacing: 10) {
                        Picker("", selection: $regQuestionIndex) {
                            ForEach(regQuestions.indices, id: \.self) { idx in
                                Text(regQuestions[idx]).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)

                        TextField("答案", text: $regAnswer)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if api.isCodeEnabled(for: .reg) {
                    demoBSphpFormRow(title: "验  证  码：") {
                        HStack(spacing: 10) {
                            TextField("", text: $regCode)
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

                demoBSphpFormRow(title: "推  广  码：") {
                    TextField("可选", text: $regExtension)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button("注册") {
                        Task {
                            isBusy = true
                            let regCodeVal = api.isCodeEnabled(for: .reg) ? regCode : ""
                            let r = await api.client.reg(
                                user: regUser,
                                pwd: regPass,
                                pwdb: regPass2,
                                coode: regCodeVal,
                                mobile: regMobile,
                                mibaoWenti: regQuestions[regQuestionIndex],
                                mibaoDaan: regAnswer,
                                qq: regQQ,
                                mail: regMail,
                                extensionCode: regExtension
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，注册失败！" : r.message
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

