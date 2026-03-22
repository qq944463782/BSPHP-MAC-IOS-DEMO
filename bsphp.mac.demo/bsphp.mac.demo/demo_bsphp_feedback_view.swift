//
// 功能说明（简体中文）:
//   意见反馈页：账号/密码/标题/联系方式/类型/内容 + 留言验证码（按开关显示）。
// 功能说明（繁体中文）:
//   意見回饋頁：帳號/密碼/標題/聯絡方式/類型/內容 + 留言驗證碼（依開關顯示）。
// Function (English):
//   Feedback page with credentials, title/contact/type/content, and optional captcha.
//

import SwiftUI
import AppKit

struct DemoBSphpFeedbackView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel

    let feedbackTypes: [String]

    @Binding var feedbackUser: String
    @Binding var feedbackPass: String
    @Binding var feedbackTitle: String
    @Binding var feedbackContact: String

    @Binding var feedbackTypeIndex: Int
    @Binding var feedbackContent: String
    @Binding var feedbackCode: String

    @Binding var isBusy: Bool
    @Binding var showInfoAlert: Bool
    @Binding var infoAlertCode: Int?
    @Binding var infoAlertText: String

    var body: some View {
        demoBSphpFormContainer {
            VStack(spacing: 12) {
                demoBSphpFormRow(title: "账号：") {
                    TextField("", text: $feedbackUser)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "密码：") {
                    SecureField("", text: $feedbackPass)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "标题：") {
                    TextField("", text: $feedbackTitle)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "联系：") {
                    TextField("", text: $feedbackContact)
                        .textFieldStyle(.roundedBorder)
                }

                demoBSphpFormRow(title: "类型：") {
                    Picker("", selection: $feedbackTypeIndex) {
                        ForEach(feedbackTypes.indices, id: \.self) { idx in
                            Text(feedbackTypes[idx]).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160, alignment: .leading)
                }

                demoBSphpFormRow(title: "内容：") {
                    TextEditor(text: $feedbackContent)
                        .font(.body)
                        .frame(height: 60)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                }

                if api.isCodeEnabled(for: .say) {
                    demoBSphpFormRow(title: "验  证  码：") {
                        HStack(spacing: 10) {
                            TextField("", text: $feedbackCode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)

                            CodeImageView(
                                url: URL(string: api.client.codeImageURL),
                                sessionToken: api.client.bsPhpSeSsL,
                                refreshTrigger: api.codeRefreshTrigger
                            )

                            Button("刷新") {
                                api.codeRefreshTrigger = Int(Date().timeIntervalSince1970)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!api.isReady)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("提交") {
                        Task {
                            isBusy = true
                            let feedbackCodeVal = api.isCodeEnabled(for: .say) ? feedbackCode : ""
                            let r = await api.client.feedback(
                                user: feedbackUser,
                                pwd: feedbackPass,
                                table: feedbackTitle,
                                qq: feedbackContact,
                                leix: feedbackTypes[feedbackTypeIndex],
                                text: feedbackContent,
                                coode: feedbackCodeVal
                            )
                            infoAlertCode = r.code
                            infoAlertText = r.message.isEmpty ? "系统错误，意见反馈失败！" : r.message
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

