import SwiftUI

struct ProfilePageView: View {
    let onLogout: () -> Void

    @Environment(\.openURL) private var openURL

    @State private var isLoading = true
    @State private var accountName = "-"
    @State private var vipEndTime = "-"
    @State private var userInfoText = ""
    @State private var statusMessage = ""

    /// 资料修改演示：`Perfect.lg`（字段名以后台配置为准）
    @State private var editQQ = ""
    @State private var editMail = ""
    @State private var editMobile = ""
    @State private var editCoode = ""
    @State private var isSubmitting = false

    /// getuserinfo.lg 单字段调试：点击后在 Alert 中展示返回结构
    @State private var isFetchingInfoField = false
    @State private var showInfoFieldAlert = false
    @State private var infoFieldAlertTitle = ""
    @State private var infoFieldAlertMessage = ""

    private let api = BSPHPMobileAPI.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的")
                            .font(.title3.bold())
                         Button("退出登录", role: .destructive) {
                    onLogout()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                    }
                }
                .padding(.bottom, 6)

                Group {
                    if isLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("账号名称")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(accountName)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("到期时间")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(vipEndTime)
                                    .multilineTextAlignment(.trailing)
                            }
                            Divider()
                            Text("用户信息")
                                .font(.headline)
                            Text(userInfoText.isEmpty ? "-" : userInfoText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                Text("getuserinfo.lg · info 字段")
                    .font(.headline)
                Text("与 BSPHPUserInfoField 一一对应；点击按钮单独请求该字段，Alert 中展示 code 与 data（message）。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isFetchingInfoField {
                    ProgressView("请求中…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(BSPHPUserInfoField.allCases, id: \.rawValue) { field in
                    Button {
                        Task { await fetchSingleUserInfoField(field) }
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(field.displayName)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Text(field.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || isFetchingInfoField)
                }

                Divider()
                Text("修改资料（Perfect.lg）")
                    .font(.headline)
                Text("参数名需与后台「用户资料」一致，演示使用 qq / mail / mobile；若接口要求图片验证码请填写 coode。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("QQ（qq）", text: $editQQ)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                TextField("邮箱（mail）", text: $editMail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                TextField("手机（mobile）", text: $editMobile)
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)
                TextField("图片验证码（coode，可选）", text: $editCoode)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await submitPerfectProfile() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("提交资料（Perfect.lg）")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)

                Button("接口更多查阅bsphp.com官网文档") {
                    openURL(URL(string: "https://www.bsphp.com/chm-38.html")!)
                 
                }
                .buttonStyle(.bordered)

               
            }
            .padding(16)
        }
        .alert(infoFieldAlertTitle, isPresented: $showInfoFieldAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(infoFieldAlertMessage)
        }
        .onAppear {
            if isLoading {
                Task { await loadUserInfo(showFullLoading: true) }
            }
        }
    }

    /// 单独拉取 `getuserinfo.lg` 的某一个 `info` 字段，Alert 展示返回结构（code + message）
    private func fetchSingleUserInfoField(_ field: BSPHPUserInfoField) async {
        await MainActor.run {
            isFetchingInfoField = true
        }
        let r = await api.getUserInfo(fields: [field])
        let codeStr = r.code.map { String($0) } ?? "nil"
        let body = r.message.isEmpty ? "(空)" : r.message
        await MainActor.run {
            isFetchingInfoField = false
            infoFieldAlertTitle = field.displayName
            infoFieldAlertMessage = """
            info: \(field.rawValue)
            code: \(codeStr)
            data: \(body)
            """
            showInfoFieldAlert = true
        }
    }

    private func parseValue(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = t.split(separator: "=").last else { return t }
        let v = String(last).trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? t : v
    }

    private func loadUserInfo(showFullLoading: Bool = true) async {
        if showFullLoading {
            isLoading = true
        }
        statusMessage = ""

        let nameRes = await api.getUserInfo(fields: [.userName])
        if nameRes.code != nil && nameRes.code != 200 {
            statusMessage = nameRes.message
        } else {
            accountName = parseValue(nameRes.message)
        }

        let vipRes = await api.getUserInfo(fields: [.userVipDate])
        if !vipRes.message.isEmpty {
            vipEndTime = parseValue(vipRes.message)
        } else {
            let endRes = await api.getEndTime()
            vipEndTime = parseValue(endRes.message)
        }

        let infoRes = await api.getUserInfo()
        userInfoText = infoRes.message

        // If everything fails, show at least one error.
        if userInfoText.isEmpty && statusMessage.isEmpty {
            statusMessage = "获取用户信息失败"
        }

        if showFullLoading {
            isLoading = false
        }
    }

    private func submitPerfectProfile() async {
        isSubmitting = true
        statusMessage = ""

        var params: [String: String] = [:]
        let qq = editQQ.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = editMail.trimmingCharacters(in: .whitespacesAndNewlines)
        let mobile = editMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        let coode = editCoode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !qq.isEmpty { params["qq"] = qq }
        if !mail.isEmpty { params["mail"] = mail }
        if !mobile.isEmpty { params["mobile"] = mobile }
        if !coode.isEmpty { params["coode"] = coode }

        if params.isEmpty {
            statusMessage = "请至少填写一项资料或验证码"
            isSubmitting = false
            return
        }

        let r = await api.perfectUserInfo(params: params)
        if r.code == 200 || r.code == 1011 {
            statusMessage = r.message.isEmpty ? "提交成功" : r.message
            await loadUserInfo(showFullLoading: false)
        } else {
            statusMessage = r.message.isEmpty ? "提交失败" : r.message
        }
        isSubmitting = false
    }
}

