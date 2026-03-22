# BSPHP · Apple iOS / macOS Demo

Official site: [www.bsphp.com](https://www.bsphp.com) · Sample projects for **BSPHP** license / verification on Apple platforms (apps and dylibs).

---

## 目录 · Table of contents

| Language | Section |
|----------|---------|
| 简体中文 | [简体中文](#简体中文) |
| 繁體中文 | [繁體中文](#繁體中文) |
| English | [English](#english) |

---

## 简体中文

### 简介

本仓库提供在 **iOS** 与 **macOS** 上对接 **BSPHP 验证系统** 的示例工程，涵盖独立 App 与 **动态库（dylib）** 弹窗激活等场景，便于集成到自有产品或给客户试用版加验证。

### 示例工程一览

| 目录 | 说明 |
|------|------|
| `bsphp.app.demo.card` | iOS：**卡密 / 充值卡** 模式演示 App |
| `bsphp.app.demo.user` | iOS：**账号登录** 模式演示 App |
| `bsphp.mac.demo` | macOS：**账号** 模式演示（SwiftUI 等，详见目录内说明） |
| `bsphp.mac.demo.card` | macOS：**卡密** 模式演示 |
| `dylib.verify.oc` | iOS **dylib**：Objective-C，弹窗输入激活码；含 **VerifyHost**，用于调试注入与调用动态库 |
| `dylib.verify.macos` | macOS **dylib**：同上思路，OC 版，VerifyHost 调试 |
| `dylib.mac.card` | macOS **dylib**：**Swift** 弹窗验证示例，适合在已写好的程序中嵌入验证逻辑，给客户测试版使用 |

### 构建与产物路径

- 使用 **Xcode** 打开对应 `.xcodeproj` / workspace 编译即可。
- 查看编译输出目录：**Product → Show Build Folder in Finder**（在 Finder 中打开构建文件夹）。

### 演示站 · 购卡与订单相关

购买、订单展示、领取充值卡等可在演示后台与接口中查看，例如：

- [续费/相关列表（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=list)
- [生成卡相关（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=list)
- [售卡相关（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=list)

具体字段与业务流程以 BSPHP 官方文档与后台配置为准。

---

## 繁體中文

### 簡介

本倉庫提供在 **iOS** 與 **macOS** 上對接 **BSPHP 驗證系統** 的範例專案，包含獨立 App 與 **動態庫（dylib）** 彈窗啟用等情境，方便整合進自有產品或為客戶試用版加上驗證。

### 範例專案一覽

| 目錄 | 說明 |
|------|------|
| `bsphp.app.demo.card` | iOS：**卡密／儲值卡** 模式示範 App |
| `bsphp.app.demo.user` | iOS：**帳號登入** 模式示範 App |
| `bsphp.mac.demo` | macOS：**帳號** 模式示範（SwiftUI 等，詳見目錄內說明） |
| `bsphp.mac.demo.card` | macOS：**卡密** 模式示範 |
| `dylib.verify.oc` | iOS **dylib**：Objective-C，彈窗輸入啟用碼；含 **VerifyHost**，用於除錯注入與呼叫動態庫 |
| `dylib.verify.macos` | macOS **dylib**：同上概念，OC 版，VerifyHost 除錯 |
| `dylib.mac.card` | macOS **dylib**：**Swift** 彈窗驗證範例，適合在既有程式中嵌入驗證，提供客戶測試版使用 |

### 建置與產出路徑

- 使用 **Xcode** 開啟對應 `.xcodeproj` / workspace 編譯即可。
- 檢視建置輸出：**Product → Show Build Folder in Finder**。

### 演示站 · 購卡與訂單相關

購買、訂單展示、領取儲值卡等可於演示後台與介面中參考，例如：

- [續費／相關列表（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=list)
- [產生卡相關（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=list)
- [售卡相關（演示）](https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=list)

實際欄位與流程以 BSPHP 官方文件與後台設定為準。

---

## English

### Overview

This repository contains **sample projects** for integrating the **BSPHP** licensing / verification backend on **iOS** and **macOS**, including standalone apps and **dylib**-based activation dialogs. Use them as references when embedding verification in your own apps or trial builds for customers.

### Project map

| Folder | Description |
|--------|-------------|
| `bsphp.app.demo.card` | iOS demo app: **card / prepaid key** flow |
| `bsphp.app.demo.user` | iOS demo app: **account login** flow |
| `bsphp.mac.demo` | macOS demo: **account** mode (SwiftUI, etc.; see in-folder docs) |
| `bsphp.mac.demo.card` | macOS demo: **card** mode |
| `dylib.verify.oc` | iOS **dylib** (Objective-C): modal activation code entry; includes **VerifyHost** for debugging injection and dylib loading |
| `dylib.verify.macos` | macOS **dylib**: same idea, Objective-C, VerifyHost for debugging |
| `dylib.mac.card` | macOS **dylib** (**Swift**): verification UI sample for integrating into existing apps / customer trial builds |

### Build output

- Open the matching `.xcodeproj` or workspace in **Xcode** and build.
- To locate build products: **Product → Show Build Folder in Finder**.

### Demo site · cards & orders

Demo web API entry points for renewals, card generation, and sales (illustrative):

- [salecard_renew list (demo)](https://demo.bsphp.com/index.php?m=webapi&c=salecard_renew&a=list)
- [salecard_gencard list (demo)](https://demo.bsphp.com/index.php?m=webapi&c=salecard_gencard&a=list)
- [salecard_salecard list (demo)](https://demo.bsphp.com/index.php?m=webapi&c=salecard_salecard&a=list)

Refer to BSPHP official documentation and your server configuration for fields and business rules.

---

*BSPHP is a third-party verification / licensing system; configure API endpoints, keys, and policies on your own BSPHP deployment.*
