//
//  BSPHPClient.swift
//  bsphp_api_http
//
//  BSPHP API 客户端：封装公告、登录、注册、解绑、充值、找回密码、修改密码、意见反馈等接口
//  参考：BSPHP-Python案例Aes加密 / bsphp/main.py
//

import Foundation
#if canImport(IOKit)
import IOKit
#endif

// MARK: - 配置

/// BSPHP 客户端配置
struct BSPHPClientConfig {
    /// 接口地址，如：http://192.168.3.44:8000/AppEn.php?appid=8888888&m=xxx
    let url: String
    /// 通信 KEY（mutualkey）
    let mutualKey: String
    /// 服务器私钥 Base64（用于 AES 密钥派生、响应解密）
    let serverPrivateKey: String
    /// 客户端公钥 Base64（用于请求签名加密）
    let clientPublicKey: String
    /// 验证码图片地址前缀，如：http://192.168.3.44:8000/index.php?m=coode&sessl=
    var codeURLPrefix: String = ""
}

// MARK: - 响应模型

/// 通用 API 响应（解析后的字典）
typealias BSPHPResponse = [String: Any]

/// API 返回结果：data 与 code 一起返回，便于根据 code 判断
struct BSPHPAPIResult {
    /// data 可能是 String 或 [Any] 等
    let data: Any?
    /// 状态码，如 1011 表示成功
    let code: Int?

    /// 用于显示的消息：data 为 String 时直接返回，数组时拼接
    var message: String {
        if let s = data as? String { return s }
        if let arr = data as? [Any] { return arr.map { "\($0)" }.joined(separator: "\n") }
        return ""
    }
}

/// getuserinfo.lg 的 info 参数可选字段
enum BSPHPUserInfoField: String, CaseIterable {
    case userName = "UserName"           // 用户名称
    case userUID = "UserUID"             // 用户UID
    case userReDate = "UserReDate"       // 激活时间
    case userReIp = "UserReIp"           // 激活时Ip
    case userIsLock = "UserIsLock"       // 用户状态
    case userLogInDate = "UserLogInDate" // 登录时间
    case userLogInIp = "UserLogInIp"     // 登录Ip
    case userVipDate = "UserVipDate"    // 到期时/VIP到期时间
    case userKey = "UserKey"             // 绑定特征
    case classNane = "Class_Nane"        // 用户分组名称
    case classMark = "Class_Mark"        // 用户分组别名
    case userQQ = "UserQQ"               // 用户QQ
    case userMAIL = "UserMAIL"            // 用户邮箱
    case userPayZhe = "UserPayZhe"       // 购卡折扣
    case userTreasury = "UserTreasury"   // 是否代理(1=代理)
    case userMobile = "UserMobile"       // 电话
    case userRMB = "UserRMB"             // 帐号金额
    case userPoint = "UserPoint"         // 帐号积分
    case usermibaoWenti = "Usermibao_wenti" // 密保问题
    case userVipWhether = "UserVipWhether"   // vip是否到期(1=未到期,2=到期)
    case userVipDateSurplusDAY = "UserVipDateSurplus_DAY" // 到期倒计时-天
    case userVipDateSurplusH = "UserVipDateSurplus_H"    // 到期倒计时-时
    case userVipDateSurplusI = "UserVipDateSurplus_I"    // 到期倒计时-分
    case userVipDateSurplusS = "UserVipDateSurplus_S"    // 到期倒计时-秒

    /// 逗号拼接多个字段，如 "UserName,UserUID,UserReDate"
    static func join(_ fields: [BSPHPUserInfoField]) -> String {
        fields.map(\.rawValue).joined(separator: ",")
    }

    /// 中文显示名（用于控制台按钮等）
    var displayName: String {
        switch self {
        case .userName: return "用户名称"
        case .userUID: return "用户UID"
        case .userReDate: return "激活时间"
        case .userReIp: return "激活时Ip"
        case .userIsLock: return "用户状态"
        case .userLogInDate: return "登录时间"
        case .userLogInIp: return "登录Ip"
        case .userVipDate: return "到期时"
        case .userKey: return "绑定特征"
        case .classNane: return "用户分组名称"
        case .classMark: return "用户分组别名"
        case .userQQ: return "用户QQ"
        case .userMAIL: return "用户邮箱"
        case .userPayZhe: return "购卡折扣"
        case .userTreasury: return "是否代理"
        case .userMobile: return "电话"
        case .userRMB: return "帐号金额"
        case .userPoint: return "帐号积分"
        case .usermibaoWenti: return "密保问题"
        case .userVipWhether: return "vip是否到期"
        case .userVipDateSurplusDAY: return "到期倒计时-天"
        case .userVipDateSurplusH: return "到期倒计时-时"
        case .userVipDateSurplusI: return "到期倒计时-分"
        case .userVipDateSurplusS: return "到期倒计时-秒"
        }
    }
}

/// getsetimag.in 的 type 参数：指定验证码类型，开启返回 checked
enum BSPHPCodeType: String, CaseIterable {
    case login = "INGES_LOGIN"       // 登录验证码 login.lg
    case reg = "INGES_RE"            // 用户注册验证码 registration.lg
    case backPwd = "INGES_MACK"      // 找回密码验证码 backto.lg
    case say = "INGES_SAY"           // 用户留言验证码 liuyan.in

    var displayName: String {
        switch self {
        case .login: return "登录验证码"
        case .reg: return "用户注册验证码"
        case .backPwd: return "找回密码验证码"
        case .say: return "用户留言验证码"
        }
    }

    static func join(_ types: [BSPHPCodeType]) -> String {
        types.map(\.rawValue).joined(separator: "|")
    }
}

// MARK: - 客户端

/// BSPHP API 客户端
final class BSPHPClient {

    private let config: BSPHPClientConfig
    // Exposed to SwiftUI views for constructing URLs (e.g.验证码图片 session token).
    // Keep write access internal to avoid accidental mutation from the UI layer.
    private(set) var bsPhpSeSsL: String = ""
    private let session: URLSession
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    private let dateFormatterHash: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd#HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()



    /// 本机机器码（用于 login.lg 的 key、maxoror 参数）
    static var machineCode: String {
        #if canImport(IOKit)
        if let uuid = BSPHPClient.hardwareUUID() { return uuid }
        #endif
        return fallbackMachineCode
    }

    #if canImport(IOKit)
    private static func hardwareUUID() -> String? {
        let service = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, service)
        guard platformExpert != 0 else { return nil }
        defer { IOObjectRelease(platformExpert) }
        let uuid = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        return uuid?.takeRetainedValue() as? String
    }
    #endif

    private static var fallbackMachineCode: String {
        let key = "com.bsphp.machineCode"
        if let cached = UserDefaults.standard.string(forKey: key), !cached.isEmpty { return cached }
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(uuid, forKey: key)
        return uuid
    }

    /// 验证码图片完整 URL（bootstrap 后有效）
    var codeImageURL: String {
        config.codeURLPrefix.isEmpty ? "" : config.codeURLPrefix + bsPhpSeSsL
    }

    init(config: BSPHPClientConfig) {
        self.config = config
        // Avoid using system proxy (some environments set a local proxy on lo0:8000).
        // If a local proxy is not running, requests fail with "Connection refused".
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.connectionProxyDictionary = [:]
        self.session = URLSession(configuration: sessionConfig)
    }

    convenience init(url: String, mutualKey: String, serverPrivateKey: String, clientPublicKey: String, codeURLPrefix: String = "") {
        self.init(config: BSPHPClientConfig(
            url: url,
            mutualKey: mutualKey,
            serverPrivateKey: serverPrivateKey,
            clientPublicKey: clientPublicKey,
            codeURLPrefix: codeURLPrefix
        ))
    }

    // MARK: - 核心请求

    /// 发送加密请求
    /// - Parameters:
    ///   - api: 接口名，如 internet.in、gg.in、login.lg
    ///   - params: 附加参数
    /// - Returns: 解析后的 response 字典，失败返回 nil
    func send(api: String, params: [String: String] = [:]) async throws -> BSPHPResponse? {
        let appsafecode = BSPHPCrypto.md5Hex(dateFormatter.string(from: Date()))
        var param: [String: String] = [
            "api": api,
            "BSphpSeSsL": bsPhpSeSsL,
            "date": dateFormatterHash.string(from: Date()),
            "md5": "",
            "mutualkey": config.mutualKey,
            "appsafecode": appsafecode
        ]
        param.merge(params) { _, new in new }

        let dataStr = param.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")

        print("[BSPHP] ========== 加密前 ==========")
        print("[BSPHP] api: \(api)")
        print("[BSPHP] request_data: \(dataStr)")

        let timeMd5 = appsafecode
        let aesKeyFull = BSPHPCrypto.md5Hex(config.serverPrivateKey + timeMd5)
        let aesKey = String(aesKeyFull.prefix(16))

        let encryptedB64: String
        let rsaB64: String
        do {
            encryptedB64 = try BSPHPCrypto.aes128CBCEncryptBase64(plaintext: dataStr, key16: aesKey)
            let sigMd5 = BSPHPCrypto.md5Hex(encryptedB64)
            let signatureContent = "0|AES-128-CBC|\(aesKey)|\(sigMd5)|json"
            rsaB64 = try BSPHPCrypto.rsaEncryptPKCS1Base64(message: signatureContent, publicKeyBase64DER: config.clientPublicKey)
        } catch {
            print("[BSPHP] ========== 请求加密失败（故无「加密后」「解密前」）==========")
            print("[BSPHP] api: \(api) 错误: \(error)")
            print("[BSPHP] 常见原因：clientPublicKey 须为后台「客户端公钥」；勿与 serverPrivateKey 对调；须与 mutualkey 对应应用一致")
            throw error
        }

        let payload = "\(encryptedB64)|\(rsaB64)"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = payload.addingPercentEncoding(withAllowedCharacters: allowed) ?? payload

        print("[BSPHP] ========== 加密后 ==========")
        print("[BSPHP] encrypted_b64: \(encryptedB64.count > 120 ? String(encryptedB64.prefix(120)) + "..." : encryptedB64)")
        print("[BSPHP] rsa_b64: \(rsaB64.count > 120 ? String(rsaB64.prefix(120)) + "..." : rsaB64)")
        print("[BSPHP] payload 总长度: \(payload.count), encoded 总长度: \(encoded.count)")

        var request = URLRequest(url: URL(string: config.url)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "parameter=\(encoded)".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            return nil
        }

        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return nil }

        let raw = text.removingPercentEncoding ?? text

        print("[BSPHP] ========== 解密前(服务器原始响应) ==========")
        print("[BSPHP] raw 长度: \(raw.count)")
        print("[BSPHP] raw: \(raw.count > 300 ? String(raw.prefix(300)) + "..." : raw)")

        // 服务器可能返回 "OK|encrypted|rsa"  第一个防止多余字符干扰
        let body = raw
    
        let parts = body.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 3 else { return nil }

        let respEncB64 = String(parts[1]).trimmingCharacters(in: .whitespaces)
        let respRsaB64 = String(parts[2]).trimmingCharacters(in: .whitespaces)

        let sigDecrypted = try BSPHPCrypto.rsaDecryptPKCS1Base64(ciphertextB64: respRsaB64, privateKeyBase64DER: config.serverPrivateKey)
        let sigParts = sigDecrypted.split(separator: "|")
        guard sigParts.count >= 4 else { return nil }
        let respAesKeyFull = String(sigParts[2])
        let respAesKey = String(respAesKeyFull.prefix(16))

        let decrypted = try BSPHPCrypto.aes128CBCDecryptBase64ToString(ciphertextB64: respEncB64, key16: respAesKey)

        print("[BSPHP] ========== 解密后 ==========")
        print("[BSPHP] decrypted: \(decrypted)")

        guard let json = try? JSONSerialization.jsonObject(with: Data(decrypted.utf8)) as? [String: Any],
              let resp = json["response"] as? [String: Any] else {
            return nil
        }

        if resp["appsafecode"] as? String != appsafecode {
            var mutable = resp
            mutable["data"] = "appsafecode 安全参数验证不通过"
            return mutable
        }
        return resp
    }

    // MARK: - 初始化流程

    /// 连接测试
    func connect() async -> Bool {
        guard let r = try? await send(api: "internet.in") else { return false }
        return (r["data"] as? String) == "1"
    }

    /// 获取 BSphpSeSsL 会话令牌（必须先调用，否则后续请求无效）
    func getSeSsL() async throws -> Bool {
        guard let r = try await send(api: "BSphpSeSsL.in"),
              let data = r["data"] as? String, !data.isEmpty else {
            return false
        }
        bsPhpSeSsL = data
        return true
    }

    /// 启动流程：connect + getSeSsL
    func bootstrap() async throws {
        guard await connect() else { throw BSPHPClientError.initFailed("连接失败") }
        guard try await getSeSsL() else { throw BSPHPClientError.initFailed("获取 BSphpSeSsL 失败") }
    }

    /// 注销登录（cancellation.lg），成功后清空会话并重新获取 SeSsL
    func logout() async -> BSPHPAPIResult {
        let r = (try? await send(api: "cancellation.lg")).map { BSPHPAPIResult(data: $0["data"], code: $0["code"] as? Int) } ?? BSPHPAPIResult(data: nil, code: nil)
        bsPhpSeSsL = ""
        _ = try? await getSeSsL()
        return r
    }

    // MARK: - 业务接口

    /// 通用 API 调用封装，失败返回空结果
    private func apiResult(api: String, params: [String: String] = [:]) async -> BSPHPAPIResult {
        guard let r = try? await send(api: api, params: params) else {
            return BSPHPAPIResult(data: nil, code: nil)
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    /// 获取公告
    func getNotice() async -> BSPHPAPIResult { await apiResult(api: "gg.in") }

    /// 获取版本号
    func getVersion() async -> BSPHPAPIResult { await apiResult(api: "v.in") }

    /// 获取软件描述
    func getSoftInfo() async -> BSPHPAPIResult { await apiResult(api: "miao.in") }

    /// 取服务器系统时间
    func getServerDate() async -> BSPHPAPIResult { await apiResult(api: "date.in") }

    /// 取预设URL地址
    func getPresetURL() async -> BSPHPAPIResult { await apiResult(api: "url.in") }

    /// 取Web浏览地址
    func getWebURL() async -> BSPHPAPIResult { await apiResult(api: "weburl.in") }

    /// 取软件配置信息段
    func getGlobalInfo() async -> BSPHPAPIResult { await apiResult(api: "globalinfo.in") }

    /// 取自定义配置模型（软件配置->自定义配置模型）
    /// - Parameter info: myapp=软件配置, myvip=VIP配置, mylogin=登录配置
    func getAppCustom(info: String) async -> BSPHPAPIResult {
        await apiResult(api: "appcustom.in", params: ["info": info])
    }

    /// 取验证码是否开启
    /// - Parameter type: 可选，指定验证码类型，如 .login 或 [.login, .reg]。不传则按服务端默认
    func getCodeEnabled(type: BSPHPCodeType? = nil) async -> BSPHPAPIResult {
        var params: [String: String] = [:]
        if let t = type { params["type"] = t.rawValue }
        return await apiResult(api: "getsetimag.in", params: params)
    }

    /// 取验证码是否开启（多类型组合）
    func getCodeEnabled(types: [BSPHPCodeType]) async -> BSPHPAPIResult {
        let params: [String: String] = types.isEmpty ? [:] : ["type": BSPHPCodeType.join(types)]
        return await apiResult(api: "getsetimag.in", params: params)
    }

    /// 取布尔逻辑值A
    func getLogicA() async -> BSPHPAPIResult { await apiResult(api: "logica.in") }

    /// 取布尔逻辑值B
    func getLogicB() async -> BSPHPAPIResult { await apiResult(api: "logicb.in") }

    /// 取布尔逻辑值A内容
    func getLogicInfoA() async -> BSPHPAPIResult { await apiResult(api: "logicinfoa.in") }

    /// 取布尔逻辑值B内容
    func getLogicInfoB() async -> BSPHPAPIResult { await apiResult(api: "logicinfob.in") }

    /// 获取到期时间（需已登录）
    func getEndTime() async -> BSPHPAPIResult { await apiResult(api: "vipdate.lg") }

    /// 取用户信息（需已登录）
    /// - Parameter info: 可选，指定返回字段，逗号分隔，如 "UserName,UserUID,UserReDate"
    ///   可选字段见 BSPHPUserInfoField
    func getUserInfo(info: String? = nil) async -> BSPHPAPIResult {
        var params: [String: String] = [:]
        if let info = info, !info.isEmpty { params["info"] = info }
        return await apiResult(api: "getuserinfo.lg", params: params)
    }

    /// 取用户信息（需已登录），按指定字段返回
    /// - Parameter fields: 要获取的字段，如 [.userName, .userUID, .userReDate]
    func getUserInfo(fields: [BSPHPUserInfoField]) async -> BSPHPAPIResult {
        await getUserInfo(info: BSPHPUserInfoField.join(fields))
    }

    /// 完善 / 修改用户资料（需已登录）
    /// 参考官方说明：https://www.bsphp.com/chm-38.html
    /// 参数名取决于后台「用户资料 / 自定义字段」配置，常见如 qq、mail、mobile；若开启图片验证码可传 coode。
    func perfectUserInfo(params: [String: String]) async -> BSPHPAPIResult {
        await apiResult(api: "Perfect.lg", params: params)
    }

    /// 取用户绑定特征key（需已登录）
    func getUserKey() async -> BSPHPAPIResult { await apiResult(api: "userkey.lg") }

    /// 状态心跳包更新（需已登录）
    func heartbeat() async -> BSPHPAPIResult { await apiResult(api: "timeout.lg") }

    /// 账号登录，返回 data/code 与其他接口一致；成功时需更新 SeSsL
    func login(user: String, password: String, code: String, key: String = "", maxoror: String = "") async -> BSPHPAPIResult {
        let machineCode = key.isEmpty ? BSPHPClient.machineCode : key
        let maxororVal = maxoror.isEmpty ? machineCode : maxoror
        let params: [String: String] = [
            "user": user, "pwd": password, "coode": code,
            "key": machineCode, "maxoror": maxororVal
        ]
        guard let r = try? await send(api: "login.lg", params: params) else {
            return BSPHPAPIResult(data: "系统错误，登录失败！", code: nil)
        }
        if let c = r["code"] as? Int, (c == 1011 || c == 9908), let ssl = r["SeSsL"] as? String {
            bsPhpSeSsL = ssl
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    // MARK: - 短信/邮箱 OTP 登录注册找回

    /// 发送邮箱验证码（send_email.in）
    func sendEmailCode(scene: String, email: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "scene": scene,
            "email": email,
            "coode": coode
        ]
        return await apiResult(api: "send_email.lg", params: params)
    }

    /// 邮箱验证码注册（register_email.lg）
    func registerEmail(user: String, email: String, emailCode: String, pwd: String, pwdb: String, key: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user,
            "email": email,
            "email_code": emailCode,
            "pwd": pwd,
            "pwdb": pwdb,
            "key": key,
            "coode": coode
        ]
        return await apiResult(api: "register_email.lg", params: params)
    }

    /// 邮箱验证码登录（login_email.lg），成功时需更新 SeSsL
    func loginEmail(email: String, emailCode: String, key: String, maxoror: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "email": email,
            "email_code": emailCode,
            "key": key,
            "maxoror": maxoror,
            "coode": coode
        ]
        guard let r = try? await send(api: "login_email.lg", params: params) else {
            return BSPHPAPIResult(data: "系统错误，邮箱验证码登录失败！", code: nil)
        }
       
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    /// 邮箱验证码找回密码（resetpwd_email.lg）
    func resetEmailPwd(email: String, emailCode: String, pwd: String, pwdb: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "email": email,
            "email_code": emailCode,
            "pwd": pwd,
            "pwdb": pwdb,
            "coode": coode
        ]
        return await apiResult(api: "resetpwd_email.lg", params: params)
    }

    /// 发送手机短信验证码（send_sms.in）
    func sendSmsCode(scene: String, mobile: String, area: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "scene": scene,
            "mobile": mobile,
            "area": area,
            "coode": coode
        ]
        return await apiResult(api: "send_sms.lg", params: params)
    }

    /// 手机短信验证码注册（register_sms.lg）
    func registerSms(user: String, mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, key: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user,
            "mobile": mobile,
            "area": area,
            "sms_code": smsCode,
            "pwd": pwd,
            "pwdb": pwdb,
            "key": key,
            "coode": coode
        ]
        return await apiResult(api: "register_sms.lg", params: params)
    }

    /// 手机短信验证码登录（login_sms.lg），成功时需更新 SeSsL
    func loginSms(mobile: String, area: String, smsCode: String, key: String, maxoror: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "mobile": mobile,
            "area": area,
            "sms_code": smsCode,
            "key": key,
            "maxoror": maxoror,
            "coode": coode
        ]
        guard let r = try? await send(api: "login_sms.lg", params: params) else {
            return BSPHPAPIResult(data: "系统错误，短信验证码登录失败！", code: nil)
        }
        if let c = r["code"] as? Int, (c == 1011 || c == 9908), let ssl = r["SeSsL"] as? String {
            bsPhpSeSsL = ssl
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    /// 手机短信验证码找回密码（resetpwd_sms.lg）
    func resetSmsPwd(mobile: String, area: String, smsCode: String, pwd: String, pwdb: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "mobile": mobile,
            "area": area,
            "sms_code": smsCode,
            "pwd": pwd,
            "pwdb": pwdb,
            "coode": coode
        ]
        return await apiResult(api: "resetpwd_sms.lg", params: params)
    }

    /// 用户注册
    func reg(user: String, pwd: String, pwdb: String, coode: String, mobile: String, mibaoWenti: String, mibaoDaan: String, qq: String = "", mail: String = "", extensionCode: String = "") async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user, "pwd": pwd, "pwdb": pwdb, "coode": coode,
            "mobile": mobile, "mibao_wenti": mibaoWenti, "mibao_daan": mibaoDaan,
            "qq": qq, "mail": mail, "extension": extensionCode
        ]
        return await apiResult(api: "registration.lg", params: params)
    }

    /// 解绑
    func unbind(user: String, pwd: String) async -> BSPHPAPIResult {
        await apiResult(api: "jiekey.lg", params: ["user": user, "pwd": pwd])
    }

    /// 充值
    func pay(user: String, userpwd: String, userset: Bool, ka: String, pwd: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user, "userpwd": userpwd,
            "userset": userset ? "1" : "0",
            "ka": ka, "pwd": pwd
        ]
        return await apiResult(api: "chong.lg", params: params)
    }

    /// 找回密码
    func backPass(user: String, pwd: String, pwdb: String, wenti: String, daan: String, coode: String = "") async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user, "pwd": pwd, "pwdb": pwdb,
            "wenti": wenti, "daan": daan, "coode": coode
        ]
        return await apiResult(api: "backto.lg", params: params)
    }

    /// 修改密码
    func editPass(user: String, pwd: String, pwda: String, pwdb: String, img: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user, "pwd": pwd, "pwda": pwda, "pwdb": pwdb, "img": img
        ]
        return await apiResult(api: "password.lg", params: params)
    }

    /// 意见反馈
    func feedback(user: String, pwd: String, table: String, qq: String, leix: String, text: String, coode: String) async -> BSPHPAPIResult {
        let params: [String: String] = [
            "user": user, "pwd": pwd, "table": table,
            "qq": qq, "leix": leix, "txt": text, "coode": coode
        ]
        return await apiResult(api: "liuyan.in", params: params)
    }
}

// MARK: - 错误

enum BSPHPClientError: Error {
    case initFailed(String)
}
