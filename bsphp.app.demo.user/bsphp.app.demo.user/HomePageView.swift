import SwiftUI

struct HomePageView: View {
    @State private var isBusy = false
    @State private var statusMessage = ""

    private let api = BSPHPMobileAPI.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HeroCard(
                    title: "今日推荐",
                    subtitle: "精选好物限时折扣",
                    icon: "sparkles"
                )
                FeatureCard(title: "新人福利", desc: "首单立减，领券下单", tint: .orange, icon: "gift")
                FeatureCard(title: "会员专享", desc: "专属价格和加速发货", tint: .purple, icon: "crown")

                publicInfoSection
            }
            .padding()
        }
    }

    private var publicInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("公共信息（.in 接口）")
                .font(.headline)

            Button("公告 gg.in") { run("公告") { await api.getNotice() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("服务器时间 date.in") { run("服务器时间") { await api.getServerDate() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("预设URL url.in") { run("预设URL") { await api.getPresetURL() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("Web地址 weburl.in") { run("Web地址") { await api.getWebURL() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("全局配置 globalinfo.in") { run("全局配置") { await api.getGlobalInfo() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("版本 v.in") { run("版本") { await api.getVersion() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            Button("软件描述 miao.in") { run("软件描述") { await api.getSoftInfo() } }
                .buttonStyle(.bordered)
                .disabled(isBusy)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }

    private func run(_ title: String, _ action: @escaping () async -> DemoAPIResult) {
        Task {
            isBusy = true
            defer { isBusy = false }
            let r = await action()
            statusMessage = "\(title)：\(r.message)"
        }
    }
}

private struct HeroCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.bold()).foregroundStyle(.white)
                Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: icon).font(.system(size: 26)).foregroundStyle(.white)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct FeatureCard: View {
    let title: String
    let desc: String
    let tint: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

