# Moosh 个人免费版与自动更新设计

## 1. 目标

在现有 AltTab GPL-3.0 fork 中维护一个仅供仓库所有者个人使用的免费版本：

- 保留当前全部功能，包括上游标记为 Pro 的功能。
- 将这些功能转为普通功能，而不是伪造或持久化 Pro 授权状态。
- 移除许可证、试用、购买、升级提示及其远程服务依赖。
- 应用名称改为 `Moosh`，Bundle ID 改为 `com.tyrival.moosh`。
- 仅构建 Apple Silicon `arm64` 版本。
- 通过当前公开 GitHub 仓库的 Actions、Releases 和 Pages 完成构建与 Sparkle 自动更新。
- 保持从原作者仓库同步后可继续合并到 `personal` 分支。

本设计不包含重新设计功能、增加新功能、兼容 Intel 或创建另一套服务端。

## 2. 许可与修改版标识

项目继续按 GPL-3.0 发布。仓库必须保留上游的 `LICENCE.md`，并在 README 中显著说明：

- Moosh 是基于 AltTab 修改的非官方版本。
- 修改版的维护者、修改日期和源码仓库地址。
- 软件不提供担保。
- 接收二进制文件的人可从同一公开仓库获得对应源码。

不得暗示这是原作者发布的官方构建，也不得复用原作者的 Developer ID、Sparkle 密钥、许可证服务或发布身份。

## 3. 分支结构与上游同步

使用当前单一公开仓库，不新建独立 Releases 仓库。

### 3.1 分支职责

- `upstream/master`：原作者的上游分支。
- `origin/master`：上游集成分支，仅保留同步工作流所需的 fork 提交。
- `origin/personal`：Moosh 产品代码、品牌、构建和发布配置的唯一来源。

现有 `.github/workflows/sync-upstream.yml` 每天获取 `upstream/master`，在需要时合并到 `origin/master`，并支持手动触发。该工作流不直接修改 `personal`。

### 3.2 同步流程

1. 自动工作流将上游变更合入 `master`。
2. 维护者检查上游 Pro、Sparkle、构建配置和品牌相关变更。
3. 将 `master` 合入 `personal`。
4. 解决冲突并完成静态检查。
5. 明确触发发布工作流或创建符合规则的版本标签。

发布工作流必须拒绝从 `master` 发布，避免未包含 Moosh 修改的上游代码被误发。

## 4. 免费功能架构

### 4.1 采用方案

采用“功能普通化并删除商业流程”的方案，不采用以下替代方式：

- 不让 `LicenseManager` 永远返回 `.pro`。
- 不写入伪造许可证、实例 ID 或 Keychain 状态。
- 不保留个人构建专用的运行时授权旁路。

这样可以减少无效状态、远程请求、升级弹窗和后续同步时的隐式副作用。

### 4.2 保留内容

- 原 Pro 功能的实际实现。
- 对应的偏好设置、运行时动作和用户选择。
- 与功能本身有关的测试与规格。

### 4.3 移除内容

- 许可证激活、停用、重新验证和实例管理。
- 许可证 Keychain 与专用 UserDefaults。
- 14 天试用、过期、宽限或免费体验次数状态。
- Pro 功能写入拦截、运行时硬门控及自动降级/恢复。
- Pro 转换调度、购买窗口、升级页、Pro 徽标和付费文案。
- 许可证 Cookie、许可证 API 和定价/账户跳转。
- 仅服务于商业流程的 QA 模拟入口及测试。

删除应从调用链入口向下进行，不能只删除 UI 后留下后台请求，也不能只返回固定布尔值后保留无效状态机。

### 4.4 上游同步冲突策略

上游可能继续修改 `src/pro` 或在新功能中增加门控。每次合并上游时应检查：

- 新增的 `ProFeature` 枚举项。
- 新增的 `isProLocked`、`isProAvailable` 或 `attemptUse()` 调用。
- 新增的 Upgrade、Trial、License、Checkout 文案或窗口。
- `Endpoints` 中新增的许可证、定价或账户地址。
- Sparkle feed 参数中新增的授权信息。

发现新的功能门控时，将实际功能接入普通路径，同时移除新增的商业依赖。

## 5. 应用身份与本地数据

固定以下身份：

- 显示名称：`Moosh`
- Bundle ID：`com.tyrival.moosh`
- 架构：`arm64`

Bundle ID 的变化会自然隔离官方 AltTab 的：

- UserDefaults。
- 登录项和 LaunchAgent。
- URL Scheme。
- 使用统计。
- Keychain 服务。
- macOS 隐私权限记录。

由于许可证系统会被删除，不迁移官方 AltTab 的许可证 Keychain 数据。是否迁移官方 AltTab 的普通偏好设置不属于本次范围；Moosh 首次启动按新应用处理。

## 6. 签名与首次安装

用户没有付费 Apple Developer 账号，因此不进行 Developer ID 签名和 Apple 公证。

### 6.1 固定自签名证书

生成一次自签名代码签名证书，并长期保持不变：

- 证书的私钥导出为受密码保护的 PKCS#12 文件。
- PKCS#12 内容以 Base64 保存到 GitHub Actions Secret。
- 密码保存到另一个 GitHub Actions Secret。
- Workflow 在临时 Keychain 中导入证书，构建结束后删除临时 Keychain。
- 私钥、证书密码和临时 Keychain 密码不得提交到仓库或写入日志。

推荐的 Secrets 名称：

- `MOOSH_CODESIGN_P12_BASE64`
- `MOOSH_CODESIGN_P12_PASSWORD`
- `MOOSH_KEYCHAIN_PASSWORD`

### 6.2 安装体验

由于没有 Apple 公证：

- 首次安装需要用户在 macOS 中手动放行。
- 用户需要在本机信任固定自签名证书。
- 后续构建必须继续使用同一证书，否则 Sparkle 的代码签名要求可能阻止升级。

不得在工作流中每次重新生成证书。

## 7. Sparkle 自动更新

代码签名证书与 Sparkle EdDSA 更新签名是两套独立身份，两者都必须稳定。

### 7.1 Sparkle 密钥

生成一对新的 Sparkle EdDSA 密钥：

- 公钥写入 `Info.plist` 的 `SUPublicEDKey`。
- 私钥保存为 GitHub Actions Secret `MOOSH_SPARKLE_ED_PRIVATE_KEY`。
- 不复用上游公钥或私钥。

### 7.2 Appcast

Appcast 由同一仓库的 GitHub Pages 提供：

`https://tyrival.github.io/alt-tab-macos/appcast.xml`

发布工作流将新 appcast 部署到 Pages，不将自动生成的 appcast 提交回 `personal`，从而避免发布流程改变产品源码分支。

App 内的 Sparkle feed 直接指向该地址，不再依赖上游 `DOMAIN` 或许可证 Cookie。Feed 请求只保留 Sparkle 正常更新所需的信息，不发送许可证层级。

### 7.3 Release 资源

每个版本生成：

- `Moosh-<version>-arm64.dmg`：首次安装和手动安装。
- `Moosh-<version>-arm64.zip`：Sparkle 更新包。

Appcast 的 enclosure 指向同一仓库的 GitHub Release：

`https://github.com/tyrival/alt-tab-macos/releases/download/<tag>/Moosh-<version>-arm64.zip`

ZIP 必须由 Sparkle 私钥签名，appcast 中必须包含正确的文件长度和 EdDSA 签名。

## 8. GitHub Actions 发布流程

新增独立发布工作流，与现有上游同步工作流分离。

### 8.1 触发条件

支持两种触发方式：

- 从 Actions 页面手动触发，并校验目标 ref 属于 `personal`。
- 推送符合 `personal-v*` 规则的标签。

推荐标签格式：

`personal-v<上游版本>-<个人修订号>`

示例：

`personal-v11.4.3-1`

### 8.2 发布步骤

1. 检出标签或明确的 `personal` 提交。
2. 校验提交属于 `personal` 历史。
3. 创建临时 Keychain 并导入固定自签名证书。
4. 注入 Moosh 的构建配置和 Sparkle 公钥。
5. 仅构建 Release `arm64`。
6. 检查产物名称、Bundle ID、架构和代码签名。
7. 生成 ZIP。
8. 生成 DMG。
9. 使用 Sparkle 私钥签署 ZIP。
10. 生成只包含已验证 Release 地址的 appcast。
11. 创建 GitHub Release 并上传 DMG、ZIP。
12. 部署 appcast 到 GitHub Pages。
13. 删除临时 Keychain 和临时文件。

若 Release 创建或资源上传失败，不得发布指向缺失资源的 appcast。应先发布并验证资源，再将 appcast 作为最后一步部署。

### 8.3 权限

工作流使用最小权限：

- `contents: write`：创建 Release 和上传资源。
- `pages: write`、`id-token: write`：部署 GitHub Pages。

Secrets 只允许在受信任的 `personal` 标签或手动发布任务中使用，不在 Pull Request 工作流中暴露。

## 9. 错误处理与回滚

- 构建失败：不创建 Release，不更新 appcast。
- 签名检查失败：删除临时产物并终止。
- Release 上传部分失败：不部署 appcast；可删除草稿 Release 后重试。
- Pages 部署失败：Release 可保留，但旧 appcast 继续指向上一可用版本。
- 新版本运行异常：发布一个更高版本号的修复版；Sparkle 不依赖降低版本号回滚。
- 自签名证书丢失：旧安装可能无法平滑自动升级。必须备份证书、私钥和密码。
- Sparkle 私钥丢失：旧安装无法验证新更新。必须备份 Sparkle 私钥。

证书或 Bundle ID 如需轮换，必须先设计迁移版本，不能直接替换。

## 10. 验证方案

### 10.1 实施期间的本地静态检查

在未明确授权编译前，只进行：

- 搜索残留许可证、试用、升级、Checkout 和门控调用。
- 搜索原 Bundle ID、原 Developer ID、原 Sparkle 公钥及上游 Release 地址。
- 校验 plist 和 XML 语法。
- 检查 GitHub Actions YAML 和 shell 脚本。
- 运行仓库已有的相关静态测试脚本（如果不触发编译）。
- 运行 `git diff --check`。

### 10.2 首次 Actions 构建验证

只有在用户明确授权后才触发 Actions 构建。验证：

- 主可执行文件为 `arm64`。
- Bundle ID 为 `com.tyrival.moosh`。
- 显示名称和产物名称为 `Moosh`。
- App 与嵌入式 Sparkle 组件的签名有效且身份稳定。
- DMG 可挂载，ZIP 可解压。
- Release 中的文件与 appcast URL、长度和签名一致。
- App 不访问上游许可证 API。
- 全部原 Pro 功能可直接配置和使用。

### 10.3 自动更新闭环

首次版本手动安装并放行后，再发布更高版本：

1. Moosh 读取 GitHub Pages appcast。
2. Sparkle 检测到新版本。
3. 下载同仓库 Release 中的 ZIP。
4. 验证 EdDSA 与代码签名。
5. 完成替换并重新启动。
6. 用户设置和登录项保持不变。

只有完成第二个版本的升级测试，才能认为自动更新链路已验证。

## 11. 明确不做

- 不创建第二个 Releases 仓库。
- 不兼容 Intel。
- 不进行 Apple 公证。
- 不复用上游许可证或签名基础设施。
- 不向上游许可证 API 发送伪造请求。
- 不迁移官方 AltTab 的许可证信息。
- 不在本设计阶段编译、提交、推送、创建 Release 或修改 GitHub Secrets。
