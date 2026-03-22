# bsphp_api_http 模块

> BSPHP 后台管理系统 - Swift/macOS 客户端 API 封装模块  
> 参考：BSPHP-Python案例Aes加密

---

## 模块说明

本模块封装与 BSPHP 服务端通信的 HTTP 接口，包含：

1. **加密/解密**：AES-128-CBC + RSA 非对称加密，与 Python 示例 `bsphp/http.py` 协议一致
2. **HTTP 请求**：POST 表单、参数加密、响应解密
3. **业务接口**：公告、登录、注册、解绑、充值、找回密码、修改密码、意见反馈等

---

## 文件结构

```
bsphp_api_http/
├── README.md           # 本说明文档
├── BSPHPCrypto.swift   # 加密工具：MD5、AES-CBC、RSA
├── BSPHPClient.swift   # API 客户端：连接、公告、登录等
└── BSPHPModels.swift   # 响应模型、错误类型（可选）
```

---

## 使用方式

```swift
// 1. 初始化（需先获取服务端配置）
let client = BSPHPClient(
    url: "http://192.168.3.44:8000/AppEn.php?appid=8888888&m=xxx",
    mutualKey: "6600cfcd5ac01b9bb3f2460eb416daa8",
    serverPrivateKey: "MIICdwIBADANBgk...",  // 服务器私钥 Base64
    clientPublicKey: "MIGfMA0GCSqGSIb3..."   // 客户端公钥 Base64
)

// 2. 启动流程
try await client.bootstrap()  // connect + getSeSsL

// 3. 获取公告（返回 BSPHPAPIResult，含 data 与 code）
let noticeResult = await client.getNotice()
let notice = noticeResult.message  // 或 (noticeResult.data as? String)

// 4. 登录（key、maxoror 为空时自动传入本机机器码）
let result = await client.login(user: "xxx", password: "xxx", code: "xxx")
// 或手动传入机器码：login(user:password:code:key:maxoror:)
```

---

## API 接口对照表

> 来源：https://www.bsphp.com/chm.html  
> 请求地址：`{baseUrl}`（如 `http://192.168.3.44:8000/AppEn.php?appid=xxx&m=xxx`），`api` 作为 POST 参数传入

### API 地址速查

| api 参数 | 接口名 |
|----------|--------|
| `internet.in` | 网络验证 |
| `BSphpSeSsL.in` | 取 BSphpSeSsL |
| `gg.in` | 取软件的公告 |
| `v.in` | 取软件版本信息 |
| `miao.in` | 取软件描述 |
| `date.in` | 取服务器系统时间 |
| `url.in` | 取预设URL地址 |
| `weburl.in` | 取Web浏览地址 |
| `globalinfo.in` | 取软件配置信息段 |
| `getsetimag.in` | 取验证码是否开启 |
| `logica.in` | 取布尔逻辑值A |
| `logicb.in` | 取布尔逻辑值B |
| `logicinfoa.in` | 取布尔逻辑值A内容 |
| `logicinfob.in` | 取布尔逻辑值B内容 |
| `liuyan.in` | 用户留言 |
| `pushlog.in` | 反破解冻结日志提交 |
| `login.lg` | 用户登录 |
| `registration.lg` | 注册账号 |
| `registrationaska.lg` | 关联卡账号注册 |
| `GetPleaseregister.lg` | 检测账号是否存在 |
| `chong.lg` | 软件充值vip续期 |
| `backto.lg` | 找回密码 |
| `BackMailPwd.lg` | 通过邮箱找回密码 |
| `vipdate.lg` | 取用户到期时间 |
| `getuserinfo.lg` | 取用户信息 |
| `userkey.lg` | 取用户绑定特征key |
| `jiekey.lg` | 解绑 |
| `password.lg` | 修改密码 |
| `setthesecuritycode.lg` | 设置密保信息 |
| `timeout.lg` | 状态心跳包更新 |
| `tuichu.lg` | 注销登录 |
| `balancededuction.lg` | 账号余额扣除 |

### API 公用接口（详情）

| api 参数 | 接口名 | 说明 |
|----------|--------|------|
| `internet.in` | 网络验证 | 连接测试 |
| `BSphpSeSsL.in` | 取 BSphpSeSsL | 获取会话令牌 |
| `gg.in` | 取软件的公告 | 公告内容 |
| `v.in` | 取软件版本信息 | 软件版本号 |
| `miao.in` | 取软件描述 | 软件描述 |
| `date.in` | 取服务器系统时间 | 服务器时间 |
| `url.in` | 取预设URL地址 | 预设 URL |
| `weburl.in` | 取Web浏览地址 | Web 浏览地址 |
| `globalinfo.in` | 取软件配置信息段 | 全局配置 |
| `getsetimag.in` | 取验证码是否开启 | 验证码开关，可选 `type` 指定类型 |
| `logica.in` | 取布尔逻辑值A | 逻辑值 A |
| `logicb.in` | 取布尔逻辑值B | 逻辑值 B |
| `logicinfoa.in` | 取布尔逻辑值A内容 | 逻辑值 A 内容 |
| `logicinfob.in` | 取布尔逻辑值B内容 | 逻辑值 B 内容 |
| `liuyan.in` | 用户留言 | 意见反馈 |
| `pushlog.in` | 反破解冻结日志提交 | 日志提交 |

### API 登录模式接口（详情）

| api 参数 | 接口名 | 说明 |
|----------|--------|------|
| `login.lg` | 用户登录 | user, pwd, coode, key(机器码), maxoror(机器码) |
| `registration.lg` | 注册账号 | user, pwd, pwdb, qq, mail, coode, mobile, mibao_wenti, mibao_daan |
| `registrationaska.lg` | 关联卡账号注册 | 卡密关联注册 |
| `GetPleaseregister.lg` | 检测账号是否存在 | 注册前检测 |
| `chong.lg` | 软件充值vip续期 | user, userpwd, userset, ka, pwd |
| `backto.lg` | 找回密码 | user, pwd, pwdb, wenti, daan, coode |
| `BackMailPwd.lg` | 通过邮箱找回密码 | 邮箱找回 |
| `vipdate.lg` | 取用户到期时间 | 到期时间 |
| `getuserinfo.lg` | 取用户信息 | 用户详情，可选 `info` 指定返回字段 |
| `userkey.lg` | 取用户绑定特征key | 绑定 key |
| `jiekey.lg` | 解绑 | user, pwd |
| `password.lg` | 修改密码 | user, pwd, pwda, pwdb, img |
| `setthesecuritycode.lg` | 设置密保信息 | 密保设置 |
| `timeout.lg` | 状态心跳包更新 | 心跳保活 |
| `tuichu.lg` | 注销登录 | 退出登录 |
| `balancededuction.lg` | 账号余额扣除 | 余额扣减 |

### getsetimag.in 的 type 参数

可选参数 `type` 指定验证码类型，开启返回 `checked`。可组合如 `INGES_LOGIN|INGES_RE|INGES_MACK|INGES_SAY`。

| type 值 | 说明 | 对应接口 |
|---------|------|----------|
| `INGES_LOGIN` | 登录验证码 | login.lg |
| `INGES_RE` | 用户注册验证码 | registration.lg |
| `INGES_MACK` | 找回密码验证码 | backto.lg |
| `INGES_SAY` | 用户留言验证码 | liuyan.in |

### getuserinfo.lg 的 info 参数

可选参数 `info` 指定返回字段，逗号分隔。不传则返回默认字段（激活时间、激活时Ip、用户状态、登录时间）。

| info 字段 | 说明 |
|-----------|------|
| `UserName` | 用户名称 |
| `UserUID` | 用户UID |
| `UserReDate` | 激活时间 |
| `UserReIp` | 激活时Ip |
| `UserIsLock` | 用户状态 |
| `UserLogInDate` | 登录时间 |
| `UserLogInIp` | 登录Ip |
| `UserVipDate` | 到期时/VIP到期时间 |
| `UserKey` | 绑定特征 |
| `Class_Nane` | 用户分组名称 |
| `Class_Mark` | 用户分组别名 |
| `UserQQ` | 用户QQ |
| `UserMAIL` | 用户邮箱 |
| `UserPayZhe` | 购卡折扣 |
| `UserTreasury` | 是否代理(1=代理) |
| `UserMobile` | 电话 |
| `UserRMB` | 帐号金额 |
| `UserPoint` | 帐号积分 |
| `Usermibao_wenti` | 密保问题 |
| `UserVipWhether` | vip是否到期(1=未到期,2=到期) |
| `UserVipDateSurplus_DAY` | 到期倒计时-天 |
| `UserVipDateSurplus_H` | 到期倒计时-时 |
| `UserVipDateSurplus_I` | 到期倒计时-分 |
| `UserVipDateSurplus_S` | 到期倒计时-秒 |

---

## 加密协议说明

1. **请求加密**  
   - `appsafecode` = MD5(当前时间 "YYYY-MM-DD HH:mm:ss")  
   - `aes_key` = MD5(服务器私钥 + appsafecode) 前 16 字符  
   - 请求体用 AES-128-CBC 加密后 Base64  
   - 签名 = `0|AES-128-CBC|{aes_key}|{MD5(加密数据)}|json`  
   - 签名用 RSA 公钥加密，与加密数据用 `|` 拼接，URL 编码后作为 `parameter` 提交  

2. **响应解密**  
   - 响应格式：`加密数据|RSA签名`  
   - RSA 解密签名得到 aes_key，再 AES 解密得到 JSON  
   - JSON 中 `response` 为业务数据  

---

## 依赖

- `CommonCrypto`（Bridging Header）
- `Foundation`、`Security`

---

## 备注

- 验证码图片地址：`{code_url}{bs_php_se_ssl}`，需在 `bootstrap` 后使用
- 登录成功会更新内部 `bs_php_se_ssl`，后续请求自动携带
- 所有接口均为异步 `async`，建议在 `Task` 中调用
- **login.lg**：`key`、`maxoror` 需传入机器码；不传时自动使用本机硬件 UUID（macOS IOKit）
