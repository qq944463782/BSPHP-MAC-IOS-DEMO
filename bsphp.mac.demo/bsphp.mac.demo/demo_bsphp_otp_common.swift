//
// 功能说明（简体中文）:
//   OTP 通用枚举与映射：把发送 scene（login/register/reset）映射到图片验证码开关类型。
// 功能说明（繁体中文）:
//   OTP 通用列舉與對應：把 scene（login/register/reset）對應到圖片驗證碼開關類型。
// Function (English):
//   OTP common mapping utilities (scene -> image captcha switch type).
//

import Foundation

enum DemoBSphpOTPScene: String {
    case login = "login"
    case register = "register"
    case reset = "reset"
}

func demoBSphpOTPCodeType(for scene: DemoBSphpOTPScene) -> BSPHPCodeType {
    switch scene {
    case .login: return .login
    case .register: return .reg
    case .reset: return .backPwd
    }
}

