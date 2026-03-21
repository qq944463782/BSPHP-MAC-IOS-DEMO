import SwiftUI

struct LoginPageView: View {
    let onLoginSuccess: () -> Void

    var body: some View {
        AuthContainerView(onLoginSuccess: onLoginSuccess)
    }
}

