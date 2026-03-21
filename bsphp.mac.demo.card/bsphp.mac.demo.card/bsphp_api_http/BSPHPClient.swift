//
//  BSPHPClient.swift
//  bsphp_api_http
//
//  BSPHP API 客户端：AppEn 默认接口（卡模式 .ic / 公共 .in）
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

/// getsetimag.in 的 type 参数：指定验证码类型，开启返回 checked
enum BSPHPCodeType: String, CaseIterable {
    case login = "INGES_LOGIN"       // 登录验证码
    case reg = "INGES_RE"            // 用户注册验证码
    case backPwd = "INGES_MACK"      // 找回密码验证码
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



    /// 本机机器码（用于 login.ic 的 key、maxoror 参数）
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
        self.session = URLSession.shared
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
    ///   - api: 接口名，如 internet.in、gg.in、login.ic
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
        guard let http = response as? HTTPURLResponse else {
            print("[BSPHP] send 失败: 无 HTTPURLResponse")
            return nil
        }
        guard http.statusCode == 200 else {
            print("[BSPHP] send 失败: HTTP \(http.statusCode)，body 长度 \(data.count)")
            return nil
        }
        guard !data.isEmpty else {
            print("[BSPHP] send 失败: 响应体为空")
            return nil
        }

        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            print("[BSPHP] send 失败: 响应非 UTF-8 或空字符串")
            return nil
        }

        let raw = text.removingPercentEncoding ?? text

        print("[BSPHP] ========== 解密前(服务器原始响应) ==========")
        print("[BSPHP] raw 长度: \(raw.count)")
        print("[BSPHP] raw (完整，便于复制整段控制台):")
        print(raw)

        // 服务器可能返回 "OK|encrypted|rsa"  第一个防止多余字符干扰
        let body = raw
    
        let parts = body.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 3 else {
            print("[BSPHP] send 失败: 正文需至少 3 段 pipe 分隔密文（当前 \(parts.count) 段），常见于 PHP 报错/HTML 或非加密直出")
            return nil
        }

        let respEncB64 = String(parts[1]).trimmingCharacters(in: .whitespaces)
        let respRsaB64 = String(parts[2]).trimmingCharacters(in: .whitespaces)

        let sigDecrypted: String
        do {
            sigDecrypted = try BSPHPCrypto.rsaDecryptPKCS1Base64(ciphertextB64: respRsaB64, privateKeyBase64DER: config.serverPrivateKey)
        } catch {
            print("[BSPHP] send 失败: 响应 RSA 段解密异常（检查 serverPrivateKey 是否与后台「服务器私钥」一致）— \(error)")
            return nil
        }
        let sigParts = sigDecrypted.split(separator: "|")
        guard sigParts.count >= 4 else {
            print("[BSPHP] send 失败: 签名串分段不足 4 段: \(sigDecrypted.prefix(80))…")
            return nil
        }
        let respAesKeyFull = String(sigParts[2])
        let respAesKey = String(respAesKeyFull.prefix(16))

        let decrypted: String
        do {
            decrypted = try BSPHPCrypto.aes128CBCDecryptBase64ToString(ciphertextB64: respEncB64, key16: respAesKey)
        } catch {
            print("[BSPHP] send 失败: AES 解密异常 — \(error)")
            return nil
        }

        print("[BSPHP] ========== 解密后 ==========")
        print("[BSPHP] decrypted: \(decrypted)")

        guard let json = try? JSONSerialization.jsonObject(with: Data(decrypted.utf8)) as? [String: Any],
              let resp = json["response"] as? [String: Any] else {
            print("[BSPHP] send 失败: 解密结果不是含 response 的 JSON（若 raw 是 HTML/Notice 说明 URL 或 PHP 报错）")
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

    /// 注销登录（cancellation.ic），成功后清空会话并重新获取 SeSsL
    func logout() async -> BSPHPAPIResult {
        let r = (try? await send(api: "cancellation.ic")).map { BSPHPAPIResult(data: $0["data"], code: $0["code"] as? Int) } ?? BSPHPAPIResult(data: nil, code: nil)
        bsPhpSeSsL = ""
        _ = try? await getSeSsL()
        return r
    }

    // MARK: - AppEn 默认接口（与文档一致）

    /// 通用 API 调用封装，失败返回空结果
    private func apiResult(api: String, params: [String: String] = [:]) async -> BSPHPAPIResult {
        guard let r = try? await send(api: api, params: params) else {
            return BSPHPAPIResult(data: nil, code: nil)
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    /// AddCardFeatures.key.ic — carid / key / maxoror
    func addCardFeatures(carid: String, key: String, maxoror: String) async -> BSPHPAPIResult {
        await apiResult(api: "AddCardFeatures.key.ic", params: ["carid": carid, "key": key, "maxoror": maxoror])
    }

    /// CallRemote.in — datas：中转地址
    func callRemote(datas: String) async -> BSPHPAPIResult {
        await apiResult(api: "CallRemote.in", params: ["datas": datas])
    }

    /// GetMyData.in — keys：获取配置键值
    func getMyData(keys: String) async -> BSPHPAPIResult {
        await apiResult(api: "GetMyData.in", params: ["keys": keys])
    }

    /// SetAppRemarks.ic — icid / icpwd / remarks
    func setAppRemarks(icid: String, icpwd: String, remarks: String) async -> BSPHPAPIResult {
        await apiResult(api: "SetAppRemarks.ic", params: ["icid": icid, "icpwd": icpwd, "remarks": remarks])
    }

    /// SetMysData.in — keys / datas
    func setMyData(keys: String, datas: String) async -> BSPHPAPIResult {
        await apiResult(api: "SetMysData.in", params: ["keys": keys, "datas": datas])
    }

    /// appbadpush.in — table：日志内容
    func appBadPush(table: String) async -> BSPHPAPIResult {
        await apiResult(api: "appbadpush.in", params: ["table": table])
    }

    /// appcustom.in — 自定义配置（info 为 field_key，多个用 |）
    func getAppCustom(
        info: String,
        getType: String? = nil,
        user: String? = nil,
        pwd: String? = nil,
        icid: String? = nil,
        icpwd: String? = nil
    ) async -> BSPHPAPIResult {
        var p: [String: String] = ["info": info]
        if let v = getType { p["get_type"] = v }
        if let v = user { p["user"] = v }
        if let v = pwd { p["pwd"] = v }
        if let v = icid { p["icid"] = v }
        if let v = icpwd { p["icpwd"] = v }
        return await apiResult(api: "appcustom.in", params: p)
    }

    /// chong.ic — 卡模式充值：icid / ka / pwd
    func rechargeCard(icid: String, ka: String, pwd: String) async -> BSPHPAPIResult {
        await apiResult(api: "chong.ic", params: ["icid": icid, "ka": ka, "pwd": pwd])
    }

    /// date.in — m：时间格式，空默认 Y-m-d H:i:s
    func getServerDate(dateFormatM: String? = nil) async -> BSPHPAPIResult {
        var p: [String: String] = [:]
        if let m = dateFormatM { p["m"] = m }
        return await apiResult(api: "date.in", params: p)
    }

    /// getdata.ic — key：验证 key
    func getData(key: String) async -> BSPHPAPIResult {
        await apiResult(api: "getdata.ic", params: ["key": key])
    }

    /// getdate.ic — 取卡模式到期时间
    func getDateIC() async -> BSPHPAPIResult {
        await apiResult(api: "getdate.ic")
    }

    /// getinfo.ic — 取卡串用户信息
    func getCardInfo(ic_carid: String, ic_pwd: String, info: String, type: String? = nil) async -> BSPHPAPIResult {
        var p: [String: String] = ["ic_carid": ic_carid, "ic_pwd": ic_pwd, "info": info]
        if let t = type { p["type"] = t }
        return await apiResult(api: "getinfo.ic", params: p)
    }

    /// getlkinfo.ic — 验证登录状态
    func getLoginInfo() async -> BSPHPAPIResult {
        await apiResult(api: "getlkinfo.ic")
    }

    /// globalinfo.in — info：信息字段
    func getGlobalInfo(info: String? = nil) async -> BSPHPAPIResult {
        var p: [String: String] = [:]
        if let i = info, !i.isEmpty { p["info"] = i }
        return await apiResult(api: "globalinfo.in", params: p)
    }

    /// imga.in — 验证码
    func getCaptchaImage() async -> BSPHPAPIResult {
        await apiResult(api: "imga.in")
    }

    /// pushaddmoney.in — 文档标注作废，保留兼容
    func pushAddMoney(user: String, ka: String) async -> BSPHPAPIResult {
        await apiResult(api: "pushaddmoney.in", params: ["user": user, "ka": ka])
    }

    /// pushlog.in — user / log
    func pushLog(user: String, log: String) async -> BSPHPAPIResult {
        await apiResult(api: "pushlog.in", params: ["user": user, "log": log])
    }

    /// remotecancellation.ic
    func remoteCancellation(icid: String, icpwd: String, type: String, biaoji: String? = nil) async -> BSPHPAPIResult {
        var p: [String: String] = ["icid": icid, "icpwd": icpwd, "type": type]
        if let b = biaoji { p["biaoji"] = b }
        return await apiResult(api: "remotecancellation.ic", params: p)
    }

    /// setcarnot.ic — 解除绑定
    func unbindCard(icid: String, icpwd: String) async -> BSPHPAPIResult {
        await apiResult(api: "setcarnot.ic", params: ["icid": icid, "icpwd": icpwd])
    }

    /// setcaron.ic — 绑定新特征
    func bindCard(key: String, icid: String, icpwd: String) async -> BSPHPAPIResult {
        await apiResult(api: "setcaron.ic", params: ["key": key, "icid": icid, "icpwd": icpwd])
    }

    /// socard.in — 激活码查询
    func queryCard(cardid: String) async -> BSPHPAPIResult {
        await apiResult(api: "socard.in", params: ["cardid": cardid])
    }

    // MARK: - 公共 .in（无额外参数或已有）

    /// gg.in — 软件公告
    func getNotice() async -> BSPHPAPIResult { await apiResult(api: "gg.in") }

    /// v.in — 版本信息
    func getVersion() async -> BSPHPAPIResult { await apiResult(api: "v.in") }

    /// miao.in — 软件描述
    func getSoftInfo() async -> BSPHPAPIResult { await apiResult(api: "miao.in") }

    /// url.in — 预设 URL
    func getPresetURL() async -> BSPHPAPIResult { await apiResult(api: "url.in") }

    /// weburl.in — Web 浏览地址
    func getWebURL() async -> BSPHPAPIResult { await apiResult(api: "weburl.in") }

    /// getsetimag.in — type：验证码是否开启
    func getCodeEnabled(type: BSPHPCodeType? = nil) async -> BSPHPAPIResult {
        var params: [String: String] = [:]
        if let t = type { params["type"] = t.rawValue }
        return await apiResult(api: "getsetimag.in", params: params)
    }

    func getCodeEnabled(types: [BSPHPCodeType]) async -> BSPHPAPIResult {
        let params: [String: String] = types.isEmpty ? [:] : ["type": BSPHPCodeType.join(types)]
        return await apiResult(api: "getsetimag.in", params: params)
    }

    /// logica.in / logicb.in / logicinfoa.in / logicinfob.in
    func getLogicA() async -> BSPHPAPIResult { await apiResult(api: "logica.in") }
    func getLogicB() async -> BSPHPAPIResult { await apiResult(api: "logicb.in") }
    func getLogicInfoA() async -> BSPHPAPIResult { await apiResult(api: "logicinfoa.in") }
    func getLogicInfoB() async -> BSPHPAPIResult { await apiResult(api: "logicinfob.in") }

    /// timeout.ic — 心跳（需已登录/会话有效）
    func heartbeat() async -> BSPHPAPIResult { await apiResult(api: "timeout.ic") }

    /// login.ic — 卡模式登录；成功时更新 SeSsL
    func loginIC(icid: String, icpwd: String = "", key: String? = nil, maxoror: String? = nil) async -> BSPHPAPIResult {
        let k = key ?? BSPHPClient.machineCode
        let m = maxoror ?? k
        let params: [String: String] = [
            "icid": icid,
            "icpwd": icpwd,
            "key": k,
            "maxoror": m
        ]
        guard let r = try? await send(api: "login.ic", params: params) else {
            return BSPHPAPIResult(data: "系统错误，登录失败！", code: nil)
        }
        if let c = r["code"] as? Int, (c == 1011 || c == 9908 || c == 1081), let ssl = r["SeSsL"] as? String {
            bsPhpSeSsL = ssl
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    /// liuyan.in — table / leix / qq / txt / img / user / pwd
    func feedback(table: String, leix: String, qq: String, txt: String, img: String = "", user: String = "", pwd: String = "") async -> BSPHPAPIResult {
        var p: [String: String] = ["table": table, "leix": leix, "qq": qq, "txt": txt]
        if !img.isEmpty { p["img"] = img }
        if !user.isEmpty { p["user"] = user }
        if !pwd.isEmpty { p["pwd"] = pwd }
        return await apiResult(api: "liuyan.in", params: p)
    }
}

// MARK: - 错误

enum BSPHPClientError: Error {
    case initFailed(String)
}
