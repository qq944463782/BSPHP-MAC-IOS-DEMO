import SwiftUI

/// 购物车页：演示 **充值 `chong.lg` / 解绑 `jiekey.lg` / 反馈 `liuyan.in`**
struct CartPageView: View {
    let onGoHome: () -> Void

    private enum DemoTab: String, CaseIterable, Identifiable {
        case recharge = "充值"
        case unbind = "解绑"
        case feedback = "反馈"

        var id: String { rawValue }

        var apiHint: String {
            switch self {
            case .recharge: return "chong.lg"
            case .unbind: return "jiekey.lg"
            case .feedback: return "liuyan.in"
            }
        }

        var icon: String {
            switch self {
            case .recharge: return "creditcard.fill"
            // `link.badge.minus` 在部分 iOS/模拟器上可能不渲染，改用通用「断开链接」图标
            case .unbind: return "link.slash"
            case .feedback: return "bubble.left.and.bubble.right.fill"
            }
        }

        var tint: Color {
            switch self {
            case .recharge: return .orange
            case .unbind: return .red
            case .feedback: return .teal
            }
        }
    }

    @State private var tab: DemoTab = .recharge
    @State private var resultText = ""
    @State private var isBusy = false

    // chong.lg
    @State private var payUser = ""
    @State private var payUserPwd = ""
    @State private var payUserSet = false
    @State private var payKa = ""
    @State private var payKaPwd = ""

    // jiekey.lg
    @State private var unbindUser = ""
    @State private var unbindPwd = ""

    // liuyan.in
    @State private var fbUser = ""
    @State private var fbPwd = ""
    @State private var fbTable = "default"
    @State private var fbQQ = ""
    @State private var fbLeix = "建议"
    @State private var fbText = ""
    @State private var fbCoode = ""

    private let api = BSPHPMobileAPI.shared

    var body: some View {
        ZStack {
            cartPageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    heroHeader
                    tabPicker
                    tabContentCard
                    resultCard
                    goHomeButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay {
            if isBusy {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                    ProgressView("请求中…")
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    // MARK: - 视觉

    private var cartPageBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.95, blue: 1.0),
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color.white.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 120, y: -180)
            Circle()
                .fill(Color.indigo.opacity(0.07))
                .frame(width: 180, height: 180)
                .blur(radius: 35)
                .offset(x: -100, y: 120)
        }
    }

    private var heroHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .indigo.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: .blue.opacity(0.35), radius: 10, x: 0, y: 4)
                Image(systemName: "cart.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("购物车")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("充值 · 解绑 · 反馈  ·  BSPHP 接口演示")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var tabPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择功能")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 8) {
                ForEach(DemoTab.allCases) { t in
                    tabButton(t)
                }
            }
        }
    }

    private func tabButton(_ t: DemoTab) -> some View {
        let selected = tab == t
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                tab = t
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: t.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(t.rawValue)
                    .font(.caption.weight(.semibold))
                Text(t.apiHint)
                    .font(.caption2)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(selected ? Color.white : t.tint)
            .background(
                Group {
                    if selected {
                        LinearGradient(
                            colors: [t.tint, t.tint.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.white.opacity(0.92), Color.white.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : t.tint.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: selected ? t.tint.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var tabContentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .foregroundStyle(tab.tint)
                Text(tab.apiHint)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(tab.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            Group {
                switch tab {
                case .recharge:
                    rechargeSection
                case .unbind:
                    unbindSection
                case .feedback:
                    feedbackSection
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tab.tint.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 5)
    }

    private var resultCard: some View {
        Group {
            if !resultText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("接口返回", systemImage: "arrow.down.doc.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(resultText)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.primary.opacity(0.9))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var goHomeButton: some View {
        Button {
            onGoHome()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                Text("去首页逛逛")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.blue, .indigo.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .blue.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 充值 chong.lg

    private var rechargeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("填写充值参数（与后台约定一致）")
                .font(.caption)
                .foregroundStyle(.secondary)

            labeledField("账号 user", text: $payUser, icon: "person.fill")
            secureField("用户密码 userpwd", text: $payUserPwd, icon: "lock.fill")
            HStack {
                Image(systemName: "switch.2")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(width: 22)
                Toggle("userset", isOn: $payUserSet)
                    .tint(.orange)
            }
            .padding(10)
            .background(Color.orange.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            labeledField("卡串 ka", text: $payKa, icon: "barcode")
            secureField("卡密码 pwd", text: $payKaPwd, icon: "key.fill")

            submitButton(title: "提交充值", tint: .orange) {
                Task { await runPay() }
            }
        }
    }

    private func runPay() async {
        await MainActor.run {
            isBusy = true
            resultText = ""
        }
        let r = await api.pay(
            user: payUser.trimmingCharacters(in: .whitespacesAndNewlines),
            userpwd: payUserPwd,
            userset: payUserSet,
            ka: payKa.trimmingCharacters(in: .whitespacesAndNewlines),
            pwd: payKaPwd
        )
        let code = r.code.map { String($0) } ?? "nil"
        await MainActor.run {
            isBusy = false
            resultText = "code: \(code)\n\(r.message)"
        }
    }

    // MARK: - 解绑 jiekey.lg

    private var unbindSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解除当前账号与设备/特征绑定（谨慎操作）")
                .font(.caption)
                .foregroundStyle(.secondary)

            labeledField("账号 user", text: $unbindUser, icon: "person.fill")
            secureField("密码 pwd", text: $unbindPwd, icon: "lock.fill")

            submitButton(title: "提交解绑", tint: .red) {
                Task { await runUnbind() }
            }
        }
    }

    private func runUnbind() async {
        await MainActor.run {
            isBusy = true
            resultText = ""
        }
        let r = await api.unbind(
            user: unbindUser.trimmingCharacters(in: .whitespacesAndNewlines),
            pwd: unbindPwd
        )
        let code = r.code.map { String($0) } ?? "nil"
        await MainActor.run {
            isBusy = false
            resultText = "code: \(code)\n\(r.message)"
        }
    }

    // MARK: - 反馈 liuyan.in

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("留言反馈；若后台开启留言验证码请填写 coode")
                .font(.caption)
                .foregroundStyle(.secondary)

            labeledField("账号 user", text: $fbUser, icon: "person.fill")
            secureField("密码 pwd", text: $fbPwd, icon: "lock.fill")
            labeledField("table", text: $fbTable, icon: "tablecells")
            labeledField("QQ", text: $fbQQ, icon: "number")
            labeledField("类型 leix", text: $fbLeix, icon: "tag.fill")

            VStack(alignment: .leading, spacing: 6) {
                Label("反馈内容 txt", systemImage: "text.alignleft")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("输入反馈内容…", text: $fbText, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
            }

            Text("图片验证码 coode（可选）")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ImageCaptchaRow(captchaInput: $fbCoode)

            submitButton(title: "提交反馈", tint: .teal) {
                Task { await runFeedback() }
            }
        }
    }

    private func runFeedback() async {
        await MainActor.run {
            isBusy = true
            resultText = ""
        }
        let r = await api.feedback(
            user: fbUser.trimmingCharacters(in: .whitespacesAndNewlines),
            pwd: fbPwd,
            table: fbTable.trimmingCharacters(in: .whitespacesAndNewlines),
            qq: fbQQ.trimmingCharacters(in: .whitespacesAndNewlines),
            leix: fbLeix.trimmingCharacters(in: .whitespacesAndNewlines),
            text: fbText.trimmingCharacters(in: .whitespacesAndNewlines),
            coode: fbCoode.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let code = r.code.map { String($0) } ?? "nil"
        await MainActor.run {
            isBusy = false
            resultText = "code: \(code)\n\(r.message)"
        }
    }

    // MARK: - 小控件

    private func labeledField(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField("", text: text)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func secureField(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            SecureField("", text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func submitButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.78)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: tint.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
    }
}
