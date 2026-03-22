//
// 功能说明（简体中文）:
//   UI 公共布局组件：统一表单宽度与标题行布局（给各 Tab 页面复用）。
// 功能说明（繁体中文）:
//   UI 公共佈局元件：統一表單寬度與標題列佈局（提供各分頁重用）。
// Function (English):
//   Shared UI helpers for consistent form layout across tabs.
//

import SwiftUI

@ViewBuilder
func demoBSphpFormContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack {
        Spacer(minLength: 24)
        content()
            .frame(maxWidth: 620)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        Spacer(minLength: 24)
    }
    .padding(.horizontal, 12)
    .controlSize(.large)
    .font(.system(size: 14))
}

@ViewBuilder
func demoBSphpFormRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    HStack(alignment: .center, spacing: 14) {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 124, alignment: .trailing)
        content()
    }
}

