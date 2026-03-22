//
// 功能说明（简体中文）:
//   控制台独立窗口：在登录后打开，用于调试/查看公用接口、登录模式接口、续费订阅与注销等功能。
// 功能说明（繁体中文）:
//   控制台獨立視窗：登入後開啟，用於除錯/查看公用介面、登入模式介面、續費訂閱與登出等功能。
// Function (English):
//   Console window shown after login for debugging common APIs and operations.
//

import SwiftUI
import AppKit

// MARK: - 控制台独立窗口

// 续费订阅推广（与 ContentView.swift 保持一致）
private let kBSPHPRenewURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=index&daihao=8888888"
private let kBSPHPRenewCardURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=index&daihao=8888888"
private let kBSPHPRenewStockCardURL = "https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=index&daihao=8888888"

/// 控制台：公用接口、自定义配置、通用接口、登录模式接口、续费订阅推广、注销登录
/// 登录成功后可打开，用于调试各类 API
struct DemoBSphpConsoleWindowView: View {
    @EnvironmentObject private var api: BSPHPAPIViewModel
    @State private var isBusy: Bool = false
    @State private var showInfoAlert: Bool = false
    @State private var infoAlertText: String = ""

    private func run(_ block: @escaping () async -> String) {
        Task {
            isBusy = true
            let text = await block()
            infoAlertText = text
            showInfoAlert = true
            isBusy = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if api.isLoggedIn {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已登录")
                            .font(.headline)
                        Text("到期时间：\(api.loginEndTime)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                Group {
                    Text("公用接口")
                        .font(.headline)
                    flowButtons {
                        btn("服务器时间") { run { let r = await api.client.getServerDate(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("预设URL") { run { let r = await api.client.getPresetURL(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("Web地址") { run { let r = await api.client.getWebURL(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("全局配置") { run { let r = await api.client.getGlobalInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("验证码开关(全部)") { run { let r = await api.client.getCodeEnabled(types: Array(BSPHPCodeType.allCases)); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("登录验证码") { run { let r = await api.client.getCodeEnabled(type: .login); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("注册验证码") { run { let r = await api.client.getCodeEnabled(type: .reg); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("找回密码验证码") { run { let r = await api.client.getCodeEnabled(type: .backPwd); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("留言验证码") { run { let r = await api.client.getCodeEnabled(type: .say); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值A") { run { let r = await api.client.getLogicA(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值B") { run { let r = await api.client.getLogicB(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值A内容") { run { let r = await api.client.getLogicInfoA(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("逻辑值B内容") { run { let r = await api.client.getLogicInfoB(); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

                Group {
                    Text("自定义配置模型")
                        .font(.headline)
                    flowButtons {
                        btn("软件配置") { run { let r = await api.client.getAppCustom(info: "myapp"); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("VIP配置") { run { let r = await api.client.getAppCustom(info: "myvip"); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("登录配置") { run { let r = await api.client.getAppCustom(info: "mylogin"); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

                Group {
                    Text("通用接口")
                        .font(.headline)
                    flowButtons {
                        btn("获取版本") { run { (await api.client.getVersion()).data as? String ?? "获取失败" } }
                        btn("获取软件描述") { run { let r = await api.client.getSoftInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                    }
                }

                Group {
                    Text("登录模式接口")
                        .font(.headline)
                    flowButtons {
                        btn("注销登陆") {
                            run {
                                let r = await api.client.logout()
                                api.isLoggedIn = false
                                api.loginEndTime = ""
                                return r.message.isEmpty ? "注销成功" : r.message
                            }
                        }
                        btn("检测到期") {
                            run {
                                await api.fetchLoginEndTime()
                                return api.loginEndTime.isEmpty ? "系统错误，取到期时间失败！" : "到期时间：\(api.loginEndTime)"
                            }
                        }
                        btn("取用户信息(默认)") { run { let r = await api.client.getUserInfo(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("心跳包更新") { run { let r = await api.client.heartbeat(); return r.message.isEmpty ? "获取失败" : r.message } }
                        btn("用户特征Key") { run { let r = await api.client.getUserKey(); return r.message.isEmpty ? "获取失败" : r.message } }
                    }

                    Text("取用户信息 info 字段")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    flowButtons {
                        ForEach(BSPHPUserInfoField.allCases, id: \.rawValue) { field in
                            btn(field.displayName) { run { let r = await api.client.getUserInfo(fields: [field]); return r.message.isEmpty ? "获取失败" : r.message } }
                        }
                    }
                }

                Group {
                    Text("续费订阅推广")
                        .font(.headline)
                    flowButtons {
                        btn("续费订阅(直接)") {
                            Task {
                                isBusy = true
                                var urlStr = kBSPHPRenewURL
                                let r = await api.client.getUserInfo(fields: [.userName])
                                if let dataStr = r.data as? String, !dataStr.isEmpty {
                                    let user = dataStr.contains("=") ? String(dataStr.split(separator: "=").last ?? "").trimmingCharacters(in: .whitespaces) : dataStr.trimmingCharacters(in: .whitespaces)
                                    if !user.isEmpty {
                                        urlStr += "&user=\(user.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? user)"
                                    }
                                }
                                if let url = URL(string: urlStr) { NSWorkspace.shared.open(url) }
                                isBusy = false
                            }
                        }
                        btn("购买充值卡") {
                            if let url = URL(string: kBSPHPRenewCardURL) { NSWorkspace.shared.open(url) }
                        }
                        btn("购买库存卡") {
                            if let url = URL(string: kBSPHPRenewStockCardURL) { NSWorkspace.shared.open(url) }
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .frame(minWidth: 800, minHeight: 430)
        .allDisabled(isBusy)
        .onAppear {
            if api.isLoggedIn {
                Task { await api.fetchLoginEndTime() }
            }
        }
        .overlay { if isBusy { ProgressView().scaleEffect(1.2) } }
        .alert("提示", isPresented: $showInfoAlert) {
            Button("确定") { }
        } message: {
            Text(infoAlertText)
        }
    }

    /// 控制台按钮流式布局
    @ViewBuilder
    private func flowButtons<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        FlowLayout(spacing: 8) { content() }
    }

    /// 控制台通用按钮：bordered 样式，未就绪或忙碌时禁用
    private func btn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) { action() }
            .buttonStyle(.bordered)
            .disabled(!api.isReady || isBusy)
    }
}

/// 流式布局：子视图按行排列，超出宽度自动换行（用于控制台按钮组）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (idx, pt) in result.positions.enumerated() {
            subviews[idx].place(at: CGPoint(x: bounds.minX + pt.x, y: bounds.minY + pt.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxW && x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}

/// 批量禁用修饰符：控制台请求中时禁用所有按钮
extension View {
    func allDisabled(_ disabled: Bool) -> some View {
        self.disabled(disabled)
    }
}

