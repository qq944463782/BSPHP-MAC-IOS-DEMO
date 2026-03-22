# dylib.mac.card 说明

macOS 动态库：BSPHP 卡密验证（Swift 实现，网络与加解密在 `bsphp_api_http`）。加载后由 constructor 排队等待 AppKit 就绪，再执行与 `dylib.verify.macos` 类似的公告（gg.in）与卡密（login.ic）流程。

## 产物名称

- 动态库：**`libdylib.mac.card.dylib`**（工程里设置了 `EXECUTABLE_PREFIX = lib`）

## 编译产物在哪里

Xcode 默认把产物放在 **DerivedData**，不在工程目录内：

- 路径形如：`~/Library/Developer/Xcode/DerivedData/dylib.mac.card-<哈希>/Build/Products/Debug/` 或 `.../Release/`
- 其中可找到 **`libdylib.mac.card.dylib`**（以及 `dylib_mac_card.swiftmodule` 等）

**在 Xcode 里打开该目录：**

- 菜单 **Product → Show Build Folder in Finder**；或
- **Xcode → Settings → Locations**，点 **Derived Data** 右侧箭头，再进入对应工程下的 `Build/Products/Debug`（或 `Release`）；或
- 左侧 **Products** 中选中 **`libdylib.mac.card.dylib`**，右键 **Show in Finder**。

**终端查询本机准确路径：**

在仓库中先进入本目录 `dylib.mac.card`，再执行：

```bash
xcodebuild -project dylib.mac.card.xcodeproj -scheme dylib.mac.card -configuration Debug -showBuildSettings 2>/dev/null | grep BUILT_PRODUCTS_DIR
```

## VerifyHost（调试用宿主 App）

**VerifyHost** 是测试用小应用：启动后在 `applicationDidFinishLaunching` 里对 **`VerifyHost.app/Contents/MacOS/libdylib.mac.card.dylib`** 执行 **`dlopen`**，无需第三方注入即可调试 constructor、网络请求与 `NSAlert` 流程。

1. 打开 **`dylib.mac.card.xcodeproj`**
2. Scheme 选 **VerifyHost**（不要只选 dylib 目标若需要界面与完整启动流程）
3. **⌘R** 运行
4. 控制台成功时会出现：`[VerifyHost] 已 dlopen ...`；随后由 dylib 拉起验证 UI

工程已配置：**VerifyHost** 依赖 **dylib.mac.card**，构建时用 **Copy Files** 将 `libdylib.mac.card.dylib` 复制到 App 的 **MacOS** 目录。若 `dlopen` 失败，宿主会弹出说明对话框。

## 若提示 “Please select an available device or choose a simulated device…”

本工程是 **macOS** 目标，没有 iOS / 模拟器运行目的地。出现该提示通常是 **运行目的地** 仍停留在 iPhone / iPad 模拟器（或其它不可用设备）。

**在 Xcode 里：**

1. 点窗口顶部 **运行目标** 下拉菜单（Scheme 右侧）。
2. 在 **macOS** 下选择 **My Mac** 或 **Any Mac**（不要选任何 **iOS Simulator**）。
3. 再按 **⌘R** 运行。

调试带界面的验证流程时，Scheme 选 **VerifyHost**，目的地选 **My Mac**。

**用命令行编译时** 请显式指定 macOS，避免工具默认去选 iOS 模拟器：

```bash
xcodebuild -project dylib.mac.card.xcodeproj -scheme VerifyHost -configuration Debug -destination 'platform=macOS' build
```

只编动态库时：

```bash
xcodebuild -project dylib.mac.card.xcodeproj -scheme dylib.mac.card -configuration Debug -destination 'platform=macOS' build
```

## 修改后台地址 / 密钥

编辑 **`dylib.mac.card/MacCardVerifyEntry.swift`** 中的私有枚举 **`MacCardBSPHPConfig`**（`host`、`mutualKey`、`serverPrivateKey`、`clientPublicKey`）。

## 工程结构（简要）

| 路径 | 说明 |
| --- | --- |
| `dylib.mac.card/` | 动态库源码（Swift + ObjC 桥接、`dylib_mac_card.m` constructor） |
| `VerifyHost/` | 宿主：`main.m`、`AppDelegate`（`dlopen`） |
| `dylib.mac.card.xcodeproj` | Xcode 工程；共享 Scheme：**dylib.mac.card**、**VerifyHost** |
