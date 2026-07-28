# Moosh Personal Free Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前 AltTab GPL-3.0 fork 改造成名为 Moosh、全部现有功能直接可用、仅构建 arm64，并由当前 GitHub 仓库自动发布和更新的个人版本。

**Architecture:** `master` 继续集成上游，`personal` 保存 Moosh 差异。产品代码删除许可证和 Pro 转换子系统，让功能直接走普通偏好与运行路径；发布代码使用固定自签名证书和独立 Sparkle EdDSA 密钥，在 GitHub Actions 中生成 DMG、ZIP、Release 与 Pages appcast。

**Tech Stack:** Swift 5.8、AppKit、XCTest、Swift Package Manager、Sparkle 2、Bash、GitHub Actions、GitHub Releases、GitHub Pages。

## Global Constraints

- 使用纯 Swift 5.8、AppKit，不使用 SwiftUI、Interface Builder 或直接打开 Xcode 开发。
- 应用显示名称固定为 `Moosh`。
- Bundle ID 固定为 `com.tyrival.moosh`。
- 只构建 Apple Silicon `arm64`。
- 项目继续使用 GPL-3.0，并保留 `LICENCE.md`。
- `master` 只负责合并上游；Moosh 的产品和发布改动只进入 `personal`。
- 不复用上游 Developer ID、Team ID、Sparkle 密钥、许可证服务或更新源。
- 没有付费 Apple Developer 账号；使用固定自签名证书，不做 Apple 公证。
- 除非用户再次明确授权，不运行编译、XCTest、GitHub Actions 发布，不提交、不推送、不创建 Release、不写 GitHub Secrets。
- 实施中的代码编辑遵循 TDD；在尚未授权编译时，先写测试并用静态契约证明测试与实现的连接，编译验证标为待用户授权执行。
- 每个任务结束只做 review checkpoint，不执行计划模板通常包含的 commit 步骤。

---

## File Structure

### 保留并修改

- `src/preferences/PreferenceDefinition.swift`：普通偏好定义和读取，不再承载授权门控。
- `src/preferences/settings-window/SettingsWindow.swift`：设置窗口主体，删除 Upgrade 页与升级按钮。
- `src/preferences/settings-window/SidebarList.swift`：普通侧边栏行，删除 Pro 徽标状态。
- `src/preferences/settings-window/tabs/appearance/AppearanceTab.swift`：所有外观选项直接可选。
- `src/preferences/settings-window/tabs/controls/ControlsTab.swift`：允许添加全部快捷键槽位。
- `src/preferences/settings-window/tabs/controls/ShortcutEditor.swift`：快捷键和搜索样式直接可选。
- `src/preferences/settings-window/tabs/controls/ShortcutsWhenActiveSheet.swift`：搜索动作不显示 Pro 徽标。
- `src/switcher/ShortcutAction.swift`：额外快捷键槽位直接执行。
- `src/switcher/main-window/TilesView.swift`：搜索模式直接进入。
- `src/switcher/state/SearchModeResolver.swift`：删除 Pro 拒绝分支，保留纯搜索状态机。
- `src/App.swift`：删除许可证启动、激活 URL 和转换 UI 连接。
- `src/Menubar.swift`：删除 Get Pro、My Account、授权状态和提示圆点。
- `src/events/PreferencesEvents.swift`：删除付费偏好写入拦截。
- `src/preferences/Preferences.swift`：删除 remembered Pro 偏好清理。
- `src/preferences/PreferencesMigrations.swift`：删除 Pro fresh-install 状态迁移。
- `src/preferences/PreferencesPersistenceCheck.swift`：只检查 Moosh 普通偏好域。
- `src/debug/QAMenu.swift`、`src/secondary-windows/DebugProfile.swift`：删除授权和转换模拟工具。
- `src/util/UsageStats.swift`：删除只用于 Pro 转换漏斗的统计项。
- `src/api/Endpoints.swift`：仅保留 Moosh 实际使用的支持/反馈或改为明确的仓库地址；更新 feed 不再依赖 `DOMAIN`。
- `src/vendors/SparkleDelegate.swift`：使用固定 Pages appcast，不发送授权层级。
- `Info.plist`、`config/base.xcconfig`、`config/release.xcconfig`：Moosh 身份、arm64、Sparkle 公钥和自签名配置。
- `alt-tab-macos.xcodeproj/project.pbxproj`：删除商业子系统文件引用，更新测试 Bundle ID。
- `README.md`、`docs/acknowledgments.md`：修改版与 GPL 归属说明。

### 删除

- `src/pro/ProConversionCopy.swift`
- `src/pro/ProFeature.swift`
- `src/pro/ProFeatureCopy.swift`
- `src/pro/license/`
- `src/pro/scheduling/`
- `src/pro/ui/`
- `src/preferences/settings-window/tabs/UpgradeTab.swift`

删除上述目录时同步删除 `project.pbxproj` 中对应 PBXFileReference、PBXBuildFile、group 和 Sources 条目。若某个非商业通用视图仍被其他界面使用，先移动到与使用方一起变化的目录并改名，再删除 `src/pro`。

### 新增

- `src/personal/MooshPersonalSpecs.md`：免费功能、品牌和更新不变量。
- `src/personal/MooshPersonalTests.swift`：可编译的核心免费路径测试。
- `scripts/tests/test_moosh_personal_static.sh`：无需编译的源码和配置契约。
- `scripts/release/package_moosh.sh`：生成 ZIP 与 DMG。
- `scripts/release/generate_appcast.sh`：签署 ZIP 并生成单版本 appcast。
- `scripts/release/verify_release.sh`：验证架构、Bundle ID、签名与 appcast。
- `.github/workflows/release-personal.yml`：构建、签名、Release 和 Pages 部署。
- `docs/personal-release.md`：一次性密钥生成、Secrets 设置、首次放行与升级演练。

---

### Task 1: 建立 Moosh 免费版静态契约

**Files:**
- Create: `src/personal/MooshPersonalSpecs.md`
- Create: `scripts/tests/test_moosh_personal_static.sh`

**Interfaces:**
- Consumes: 当前源码、`Info.plist`、xcconfig、workflow 和发布脚本。
- Produces: `bash scripts/tests/test_moosh_personal_static.sh`，供所有后续任务做无编译回归检查。

- [ ] **Step 1: 写功能与发行规格**

在 `src/personal/MooshPersonalSpecs.md` 固定以下可检验条件：

```markdown
# Moosh Personal

- Every shipped feature is available without a license, trial, grace period, free pass, or checkout.
- The app contains no activation, deactivation, license revalidation, account, pricing, or upgrade UI.
- Product name is Moosh and bundle identifier is com.tyrival.moosh.
- Release builds are arm64 and use a stable self-signed code-signing identity.
- Sparkle trusts only the Moosh EdDSA public key and reads:
  https://tyrival.github.io/alt-tab-macos/appcast.xml
- Release assets come only from:
  https://github.com/tyrival/alt-tab-macos/releases/
- The fork remains GPL-3.0 and visibly identifies itself as an unofficial modified version.
```

- [ ] **Step 2: 写预期失败的静态契约脚本**

`scripts/tests/test_moosh_personal_static.sh` 使用 `set -euo pipefail`，提供 `require_text` 与 `forbid_text` 两个函数，并检查：

```bash
require_text 'PRODUCT_NAME = Moosh' config/base.xcconfig
require_text 'PRODUCT_BUNDLE_IDENTIFIER = com.tyrival.moosh' config/base.xcconfig
require_text 'ARCHS = arm64' config/base.xcconfig
require_text 'https://tyrival.github.io/alt-tab-macos/appcast.xml' src/vendors/SparkleDelegate.swift
require_text 'github.com/tyrival/alt-tab-macos/releases/download' scripts/release/generate_appcast.sh
require_text 'GNU GENERAL PUBLIC LICENSE' LICENCE.md

forbid_text 'com.lwouis.alt-tab-macos' config Info.plist src scripts .github
forbid_text 'Developer ID Application: Louis Pontoise' config scripts .github
forbid_text '2e9SQOBoaKElchSa/4QDli/nvYkyuDNfynfzBF6vJK4=' Info.plist
forbid_text 'LicenseManager|ProTransitionManager|UpgradeTab|ProBadgeView|licenseApiBaseUrl|checkoutUrl|accountUrl' src
forbid_text 'github.com/lwouis/alt-tab-macos/releases/download' scripts .github src
```

`forbid_text` 必须用 `rg -n --glob '*.swift' --glob '*.xcconfig' --glob '*.sh' --glob '*.yml' --glob '*.yaml' --glob '*.plist'` 限定产品文件，避免设计文档中的历史名称造成误报。

- [ ] **Step 3: 运行静态契约并记录预期失败**

Run:

```bash
bash scripts/tests/test_moosh_personal_static.sh
```

Expected: FAIL，至少报告当前 `PRODUCT_NAME = AltTab`、原 Bundle ID、原 Sparkle 公钥和商业类型仍存在。

- [ ] **Step 4: 检查脚本自身**

Run:

```bash
bash -n scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: shell 语法通过；diff 无空白错误。

- [ ] **Step 5: Review checkpoint**

确认脚本失败原因均对应本设计尚未实现的条件，没有因扫描 `docs/`、`.git/`、第三方 vendor 或测试 fixture 产生误报。不提交。

---

### Task 2: 将偏好和运行时功能改为无门控路径

**Files:**
- Modify: `src/preferences/PreferenceDefinition.swift`
- Modify: `src/events/PreferencesEvents.swift`
- Modify: `src/preferences/Preferences.swift`
- Modify: `src/preferences/PreferencesMigrations.swift`
- Modify: `src/preferences/PreferencesMigrationsTests.swift`
- Modify: `src/switcher/ShortcutAction.swift`
- Modify: `src/switcher/main-window/TilesView.swift`
- Modify: `src/switcher/state/SearchModeResolver.swift`
- Modify existing search resolver tests returned by `rg -l 'SearchModeResolver' src unit-tests`
- Create: `src/personal/MooshPersonalTests.swift`

**Interfaces:**
- Consumes: `CachedUserDefaults.macroPref`, `Preferences.set`, `SearchModeResolver`.
- Produces: `PreferenceDefinition<T>.read() -> T` 无授权分支；`SearchModeResolver.enableEditing(mode:) -> SearchModeDecision` 无拒绝结果；额外快捷键直接执行。

- [ ] **Step 1: 写偏好直接读取测试**

在 `MooshPersonalTests.swift` 中用隔离的 UserDefaults fixture 构造包含 `.appIcons`、`.auto`、`.searchOnRelease` 的偏好值，断言 `PreferenceDefinition.read()` 返回原值，不降级为免费等价值。

核心断言：

```swift
XCTAssertEqual(ProGatedPreferences.appearanceStyle.read(), .appIcons)
XCTAssertEqual(ProGatedPreferences.appearanceSize.read(), .auto)
XCTAssertEqual(ProGatedPreferences.shortcutStyle.read(), .searchOnRelease)
```

实施时将 `ProGatedPreferences` 同步改名为 `PersonalPreferences` 或并入现有普通定义；测试必须使用最终名称，不能保留 `Pro` 命名。

- [ ] **Step 2: 更新搜索状态机测试**

将原：

```swift
SearchModeResolver.enableEditing(mode: .off, canSearch: true)
```

改为：

```swift
XCTAssertEqual(SearchModeResolver.enableEditing(mode: .off), .enterEditing)
XCTAssertEqual(SearchModeResolver.enableEditing(mode: .editing), .placeCaretOnly)
```

删除 `.proGateBlocked` 的测试与枚举 case。

- [ ] **Step 3: 在未授权编译时做连接性静态检查**

Run:

```bash
rg -n 'enableEditing\\(mode:.*canSearch|proGateBlocked|attemptUse\\(\\)' src
```

Expected before implementation: 命中现有门控调用，证明测试针对真实路径。

- [ ] **Step 4: 简化偏好定义**

将 `PreferenceDefinition<T>` 收敛为：

```swift
struct PreferenceDefinition<T: MacroPreference & CaseIterable & Equatable> {
    let key: String
    let `default`: T

    func read() -> T {
        CachedUserDefaults.macroPref(key, Array(T.allCases))
    }
}
```

删除 `PreferenceGate`、`AnyProGatedPreference`、snapshot/downgrade/restore/isStoredValuePro，以及 remembered key。将三项定义改成普通 `PreferenceDefinition`，并使用能表达功能而非商业属性的名称。

- [ ] **Step 5: 删除偏好写入和迁移门控**

从 `PreferencesEvents.preferenceChanged(_:)` 删除跳转 Upgrade 的分支。从 `Preferences.swift` 删除 remembered Pro index 清理。从 `PreferencesMigrations.swift` 删除 `markFreshInstallIfUnknown`，相应更新迁移测试，使旧偏好值继续保留而不是被降级。

- [ ] **Step 6: 删除运行时门控**

`ShortcutActions.execute(_:)` 删除 extra shortcut 的 `attemptUse()` 分支；`TilesView.enableSearchEditing()` 调用：

```swift
switch SearchModeResolver.enableEditing(mode: searchMode) {
```

`SearchModeResolver` 删除 `canSearch` 参数和 `.proGateBlocked`。

- [ ] **Step 7: 执行无编译静态检查**

Run:

```bash
rg -n 'PreferenceGate|AnyProGatedPreference|rememberedAppearance|rememberedShortcut|attemptUse\\(\\)|proGateBlocked|canSearch:' src
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: 本任务相关词为零；整体契约仍因品牌、UI 和发布任务未完成而失败。

- [ ] **Step 8: 用户授权后运行定向 XCTest**

Run:

```bash
xcodebuild test -project alt-tab-macos.xcodeproj -scheme Test -configuration Release \
  -only-testing:unit-tests/MooshPersonalTests \
  -only-testing:unit-tests/SearchModeResolverTests | scripts/xcbeautify
```

Expected: PASS。未获授权时不运行并明确记录“测试已写，未编译验证”。

- [ ] **Step 9: Review checkpoint**

确认功能是直接路径，不存在固定 `.pro`、伪造许可证或新的 Personal bypass 开关。不提交。

---

### Task 3: 删除许可证、试用和 Pro 转换子系统

**Files:**
- Modify: `src/App.swift`
- Modify: `src/Menubar.swift`
- Modify: `src/debug/QAMenu.swift`
- Modify: `src/secondary-windows/DebugProfile.swift`
- Modify: `src/preferences/PreferencesPersistenceCheck.swift`
- Modify: `src/util/UsageStats.swift`
- Delete: `src/pro/ProConversionCopy.swift`
- Delete: `src/pro/ProFeature.swift`
- Delete: `src/pro/ProFeatureCopy.swift`
- Delete: `src/pro/license/*`
- Delete: `src/pro/scheduling/*`
- Modify: `alt-tab-macos.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Task 2 已无门控的偏好和运行路径。
- Produces: App 启动不创建许可证状态、不访问授权 API、不调度商业弹窗；工程不再编译商业子系统。

- [ ] **Step 1: 扩充静态契约**

增加 App 启动和工程引用检查：

```bash
forbid_text 'activate|mock-pro|syncLicenseCookie|onBeforeProUnlock|onStateChanged' src/App.swift
forbid_text 'src/pro|ProFeature.swift|LicenseManager.swift|UpgradeTab.swift' alt-tab-macos.xcodeproj/project.pbxproj
```

对 `activate` 使用更精确的 Swift 模式，例如 `url\\.host == "activate"|LicenseManager\\.shared\\.activate`，避免普通英文文本误报。

- [ ] **Step 2: 移除 App 生命周期授权连接**

从 `applicationDidFinishLaunching` 删除：

- `LicenseManager` callbacks。
- `syncLicenseCookie`。
- `--mock-pro`。
- `LicenseManager.shared.initialize()`。

从启动完成路径删除 `ProTransitionManager` 与 `ProPromptHost` 连接。删除 `handleCustomUrl` 的许可证激活实现；若没有其他 URL action，则同步删除 Info.plist 的 URL scheme 注册和 `application(_:open:)`。

- [ ] **Step 3: 简化 Menubar**

删除 `upgradeToProMenuItem`、`myAccountMenuItem`、`refreshLicenseMenuItems()`、`toggleUpgradeMenuItem`、`UpgradeMenuItemView` 和徽标圆点。保留普通的 Show、Settings、Check for updates、Permissions、About、Debug、Feedback、Support、Quit。

`loadPreferredIcon()` 不再调用 `updateBadgeDotOverlay()`。

- [ ] **Step 4: 清理调试、持久化与统计**

删除 QAMenu 的授权清空、试用日、Pro 状态和转换弹窗模拟。`PreferencesPersistenceCheck` 只返回：

```swift
[App.bundleIdentifier, "\(App.bundleIdentifier).usage"]
```

删除 `UsageStats.usedProFeaturesSessionCount` 及只服务于转换漏斗的写入和展示。更新 `DebugProfile`，只展示实际调试信息。

- [ ] **Step 5: 删除商业源码与测试**

删除 `src/pro` 下所有文件。删除 `LicenseManagerTests`、`ProTransitionTests`、`ProBadgeViewSegmentTests` 等商业测试，因为对应生产单元已不存在，不把它们改成“永远 Pro”测试。

- [ ] **Step 6: 清理工程文件**

从 `project.pbxproj` 删除被删文件的：

- `PBXFileReference`
- `PBXBuildFile`
- `PBXGroup`
- app/test target 的 `PBXSourcesBuildPhase`

使用精确 ID 删除，不重写整个 pbxproj。确认未触碰 vendor/Sparkle 引用。

- [ ] **Step 7: 静态验证**

Run:

```bash
test ! -d src/pro
rg -n 'LicenseManager|LicenseState|LicenseAPI|RemoteLicenseClient|ProTransition|ProPrompt|ProFeature|syncLicenseCookie|mock-pro' src alt-tab-macos.xcodeproj
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: 商业子系统搜索为零；整体契约可能仍因设置 UI、品牌和发布任务失败。

- [ ] **Step 8: 用户授权后运行完整 XCTest**

Run:

```bash
scripts/run_tests.sh
```

Expected: PASS。未获授权时不运行。

- [ ] **Step 9: Review checkpoint**

检查删除列表与 `git diff --name-status`，确认没有误删 Sparkle、普通更新设置、普通使用统计或功能实现。不提交。

---

### Task 4: 删除设置窗口中的商业 UI，保留全部选项

**Files:**
- Modify: `src/preferences/settings-window/SettingsWindow.swift`
- Modify: `src/preferences/settings-window/LabelAndControl.swift`
- Modify: `src/preferences/settings-window/SidebarList.swift`
- Modify: `src/preferences/settings-window/SidebarListTests.swift`
- Modify: `src/preferences/settings-window/tabs/appearance/AppearanceTab.swift`
- Modify: `src/preferences/settings-window/tabs/controls/ControlsTab.swift`
- Modify: `src/preferences/settings-window/tabs/controls/ShortcutEditor.swift`
- Modify: `src/preferences/settings-window/tabs/controls/ShortcutsWhenActiveSheet.swift`
- Modify: `src/preferences/settings-window/tabs/controls/ShortcutEditor` related tests returned by `rg -l 'proGatedIndices|setProBadge' src unit-tests`
- Delete: `src/preferences/settings-window/tabs/UpgradeTab.swift`
- Modify: `alt-tab-macos.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Task 2 普通偏好，Task 3 已删除的商业类型。
- Produces: 设置窗口没有 Upgrade 导航和 Pro 徽标；所有现有值、快捷键槽位和搜索动作均可直接选择。

- [ ] **Step 1: 写设置 UI 的失败测试**

更新 `SidebarListTests`，不再测试 Pro badge wrapper；新增普通行稳定性测试：

```swift
func testRepeatedContentRefreshDoesNotAccumulateTitleViews() {
    let row = SidebarListRow()
    row.setContent("Shortcut 2", "")
    let count = descendantViews(row).count
    row.setContent("Shortcut 2", "")
    row.setContent("Shortcut 2", "")
    XCTAssertEqual(descendantViews(row).count, count)
}
```

在 `MooshPersonalTests` 添加：

```swift
XCTAssertEqual(Preferences.maxShortcutCount, expectedExistingMaximum)
```

其中 `expectedExistingMaximum` 从当前源码常量读取并写为确切数值，防止删除门控时误删槽位能力。

- [ ] **Step 2: 删除 SettingsWindow Upgrade chassis**

删除 `UpgradeButton`、`upgradeButton`、`upgradeContentView`、`isShowingUpgradeView`、`upgradeViewBottomConstraint`、setup/click/show/hide/refresh/shine/cleanup 逻辑。让 sidebar scroll view 直接约束到 Quit 按钮上方，保持现有边距。

设置搜索索引不再特殊识别 `ProBadgeView` 或索引 “Pro”。

- [ ] **Step 3: 删除外观选项门控和徽标**

从 `AppearanceTab` 删除：

- `ProTransitionManager` observer。
- `ProBadgeView.SegmentOverlay` refs。
- `addProBadge*` 与 refresh badge 方法。
- 点击 Pro index 后跳转 Upgrade 的分支。

控件仍写入用户选择的 `appearanceStyle`、`appearanceSize`、`shortcutStyle`，不改变枚举或选项顺序。

- [ ] **Step 4: 删除快捷键门控和徽标**

`ControlsTab.addShortcutSlot()` 不再检查 `currentCount >= 1`，只保留原最大数量限制。`ShortcutEditor` 删除 `proGatedIndices` 的跳转分支与 badge overlay 参数。`ShortcutsWhenActiveSheet` 直接显示搜索动作，不附加 Pro badge。

- [ ] **Step 5: 简化 SidebarListRow**

删除 `proBadge` 属性和 `setProBadge(_:)`。标题行仅包含 `titleLabel`，行复用仍保持幂等。

- [ ] **Step 6: 删除 UpgradeTab 和工程引用**

删除 Swift 文件，并从 `project.pbxproj` 精确删除引用和 build phase 条目。

- [ ] **Step 7: 静态验证**

Run:

```bash
rg -n 'Upgrade|Get Pro|ProBadge|proGated|isProLocked|proLockState' \
  src/preferences src/switcher src/Menubar.swift src/App.swift
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: 商业 UI 和门控搜索为零；功能枚举与最大快捷键数仍存在。

- [ ] **Step 8: 用户授权后运行 UI 相关 XCTest**

Run:

```bash
xcodebuild test -project alt-tab-macos.xcodeproj -scheme Test -configuration Release \
  -only-testing:unit-tests/SidebarListTests \
  -only-testing:unit-tests/MooshPersonalTests | scripts/xcbeautify
```

Expected: PASS。未获授权时不运行。

- [ ] **Step 9: Review checkpoint**

通过 diff 检查每项功能的 setter 和 runtime action 仍在，只删除门控与营销 UI。不提交。

---

### Task 5: 切换 Moosh 品牌、Bundle ID 与 GPL 修改版说明

**Files:**
- Modify: `config/base.xcconfig`
- Modify: `config/debug.xcconfig`
- Modify: `config/release.xcconfig`
- Modify: `Info.plist`
- Modify: `alt-tab-macos.xcodeproj/project.pbxproj`
- Modify: `src/_test-support/Mocks.swift`
- Modify: `src/App.swift`
- Modify: `README.md`
- Modify: `docs/acknowledgments.md`
- Verify/restore: `LICENCE.md`
- Modify localized resources returned by `rg -l 'AltTab|Get Pro|Pro activated|Trial|license|upgrade' resources src --glob '*.strings'`

**Interfaces:**
- Consumes: Task 3/4 已无商业文案和授权 URL。
- Produces: App、测试 target、日志、菜单和产物统一使用 Moosh 身份。

- [ ] **Step 1: 扩展品牌静态契约**

增加：

```bash
require_text 'PRODUCT_NAME = Moosh' config/base.xcconfig
require_text 'PRODUCT_BUNDLE_IDENTIFIER = com.tyrival.moosh' config/base.xcconfig
require_text 'ARCHS = arm64' config/base.xcconfig
forbid_text 'QXD7GW8FHY|Louis Pontoise' config alt-tab-macos.xcodeproj scripts .github
```

原 Bundle ID 的禁止扫描允许 GPL 归属文档和迁移说明出现，但产品配置、Swift 与 workflow 不得出现。

- [ ] **Step 2: 修改基础构建身份**

`config/base.xcconfig`：

```xcconfig
PRODUCT_NAME = Moosh
PRODUCT_BUNDLE_IDENTIFIER = com.tyrival.moosh
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
```

保留 Swift 5.8 与 macOS 10.13 deployment target，除非实际 arm64 依赖验证证明需要提高；不得顺便调整版本下限。

- [ ] **Step 3: 修改签名配置**

`config/release.xcconfig` 删除原 Developer ID identity，改为从 CI 注入：

```xcconfig
CODE_SIGN_IDENTITY = $(MOOSH_CODE_SIGN_IDENTITY)
CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO
OTHER_CODE_SIGN_FLAGS = --timestamp=none --deep
```

删除 release 配置中的 Apple 公证注释和要求。Debug 可继续使用本机 `Local Self-Signed`，但不得与 CI release identity 混为一个 secret。

- [ ] **Step 4: 修改测试和 mock Bundle ID**

将 unit-test Bundle ID 改为 `com.tyrival.moosh.unit-tests`，`Mocks.swift` 改为：

```swift
static let bundleIdentifier = "com.tyrival.moosh"
```

更新静态 fixture 的确切期望。

- [ ] **Step 5: 清理产品可见品牌**

将硬编码日志 “Launching AltTab”/“Finished launching AltTab” 改为使用 `App.name`。本地化 comment 中仅作为翻译上下文出现的 AltTab 可改成 Moosh；上游归属说明保留 AltTab。

- [ ] **Step 6: 更新 README 与致谢**

README 顶部加入：

```markdown
# Moosh

Moosh is an unofficial modified version of AltTab, maintained for personal use.
The source remains available under GPL-3.0. See [LICENCE.md](LICENCE.md).

Upstream project: https://github.com/lwouis/alt-tab-macos
Modified source: https://github.com/tyrival/alt-tab-macos
```

保留上游作者和贡献者归属，不使用会误导为官方发行的下载徽章或网站主视觉。

- [ ] **Step 7: 静态验证**

Run:

```bash
plutil -lint Info.plist
rg -n 'com\\.lwouis\\.alt-tab-macos|PRODUCT_NAME = AltTab|QXD7GW8FHY|Louis Pontoise' \
  config Info.plist src alt-tab-macos.xcodeproj scripts .github
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: 产品配置无旧身份；静态契约只剩 Sparkle/发布任务相关失败。

- [ ] **Step 8: 用户授权后检查 build settings**

Run:

```bash
xcodebuild -project alt-tab-macos.xcodeproj -scheme Release -configuration Release \
  -showBuildSettings | rg 'PRODUCT_NAME|PRODUCT_BUNDLE_IDENTIFIER|ARCHS|SWIFT_VERSION|CODE_SIGN_IDENTITY'
```

Expected: `Moosh`、`com.tyrival.moosh`、`arm64`、Swift 5.8、自签名 identity。未获授权时不运行，因为项目规则将 xcodebuild 视为编译流程的一部分。

- [ ] **Step 9: Review checkpoint**

确认 GPL 文件和上游归属未被删除，产品身份已完全隔离。不提交。

---

### Task 6: 将 Sparkle 更新源切到当前仓库

**Files:**
- Modify: `Info.plist`
- Modify: `src/api/Endpoints.swift`
- Modify: `src/vendors/SparkleDelegate.swift`
- Modify: `src/vendors/SparkleDelegate` related tests returned by `rg -l 'SparkleDelegate|appcastUrl|feedURLString' src unit-tests`
- Delete if unused: `src/pro/license/LicenseCookie.swift`（应已在 Task 3 删除）
- Create/Modify: `src/personal/MooshPersonalTests.swift`

**Interfaces:**
- Produces: `MooshUpdate.feedURL: URL` 或等价常量；`SparkleDelegate.feedURLString(for:)` 返回唯一 Pages feed。

- [ ] **Step 1: 写 feed URL 测试**

新增纯值测试：

```swift
func testUpdateFeedUsesMooshGitHubPages() {
    XCTAssertEqual(MooshUpdate.feedURL.absoluteString,
        "https://tyrival.github.io/alt-tab-macos/appcast.xml")
}
```

在 `src/vendors/SparkleDelegate.swift` 或同目录新增小型 `MooshUpdate` enum，避免更新地址继续借用网站 `DOMAIN`。

- [ ] **Step 2: 实现独立更新常量**

```swift
enum MooshUpdate {
    static let feedURL = URL(string: "https://tyrival.github.io/alt-tab-macos/appcast.xml")!
}
```

`feedURLString(for:)` 返回 `MooshUpdate.feedURL.absoluteString`。

- [ ] **Step 3: 收缩 Endpoints**

删除 `checkoutUrl`、`accountUrl`、`licenseApiBaseUrl`。若 `supportUrl`、`feedbackUrl` 仍被调用，分别改为明确可用的 GitHub Issues 地址或保留现有服务前先确认上游服务允许修改版使用。推荐：

```swift
static let supportUrl = "https://github.com/tyrival/alt-tab-macos/issues"
```

反馈网络 POST 若依赖上游 `API_DOMAIN`，本次改为打开 Issues，而不是继续向上游 API 上传修改版数据。

- [ ] **Step 4: 注入新的 Sparkle 公钥占位接口**

`Info.plist` 的 `SUPublicEDKey` 改为 build setting：

```xml
<key>SUPublicEDKey</key>
<string>$(MOOSH_SPARKLE_PUBLIC_KEY)</string>
```

`config/local.xcconfig` 由 Actions 生成并注入真实公钥；仓库可在 `config/base.xcconfig` 保存公钥，因为公钥不是 secret：

```xcconfig
MOOSH_SPARKLE_PUBLIC_KEY = $(inherited)
```

首次执行 `vendor/Sparkle/bin/generate_keys` 后，将命令输出的公钥作为 GitHub Repository Variable `MOOSH_SPARKLE_PUBLIC_KEY` 保存；workflow 生成 `config/local.xcconfig` 时写入该变量。构建前用 `test -n "$MOOSH_SPARKLE_PUBLIC_KEY"` 拒绝空值，并用静态契约拒绝上游公钥。

- [ ] **Step 5: 清理 feed 参数**

保留 version、macOS、arch、lang 等非授权参数；确认没有 license、variant、customer 或 trial 参数，也没有 Cookie 注入。

- [ ] **Step 6: 静态验证**

Run:

```bash
plutil -lint Info.plist
rg -n 'alt-tab\\.app/appcast|license|variant|customer|trial|LicenseCookie' \
  src/vendors/SparkleDelegate.swift src/api/Endpoints.swift Info.plist
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: 只使用 Moosh Pages feed；无授权信息。

- [ ] **Step 7: 用户授权后运行定向测试**

Run:

```bash
xcodebuild test -project alt-tab-macos.xcodeproj -scheme Test -configuration Release \
  -only-testing:unit-tests/MooshPersonalTests | scripts/xcbeautify
```

Expected: PASS。未获授权时不运行。

- [ ] **Step 8: Review checkpoint**

确认 App 的更新检查不依赖 Pages 之外的网站服务；公钥可以公开，私钥未进入 diff。不提交。

---

### Task 7: 实现可重复的 arm64 ZIP、DMG 与 appcast 脚本

**Files:**
- Create: `scripts/release/package_moosh.sh`
- Create: `scripts/release/generate_appcast.sh`
- Create: `scripts/release/verify_release.sh`
- Modify or retire: `scripts/package_and_notarize_release.sh`
- Modify or retire: `scripts/update_appcast.sh`
- Modify: `scripts/build_app.sh`
- Create: shell fixtures under `scripts/tests/fixtures/release/` only if needed
- Modify: `scripts/tests/test_moosh_personal_static.sh`

**Interfaces:**
- Consumes:
  - `MOOSH_APP_PATH`
  - `MOOSH_VERSION`
  - `MOOSH_TAG`
  - `MOOSH_OUTPUT_DIR`
  - `MOOSH_SPARKLE_ED_PRIVATE_KEY`
- Produces:
  - `$MOOSH_OUTPUT_DIR/Moosh-$MOOSH_VERSION-arm64.zip`
  - `$MOOSH_OUTPUT_DIR/Moosh-$MOOSH_VERSION-arm64.dmg`
  - `$MOOSH_OUTPUT_DIR/appcast.xml`

- [ ] **Step 1: 写 shell 参数失败测试**

在静态脚本中执行发布脚本的 `--help` 或缺参路径，断言缺少变量时非零退出并打印确切变量名。脚本统一：

```bash
set -euo pipefail
: "${MOOSH_VERSION:?MOOSH_VERSION is required}"
```

- [ ] **Step 2: 实现 package_moosh.sh**

流程：

```bash
ditto -c -k --keepParent --sequesterRsrc \
  "$MOOSH_APP_PATH" "$MOOSH_OUTPUT_DIR/Moosh-$MOOSH_VERSION-arm64.zip"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
ditto "$MOOSH_APP_PATH" "$staging/Moosh.app"
hdiutil create -volname "Moosh" -srcfolder "$staging" \
  -ov -format UDZO "$MOOSH_OUTPUT_DIR/Moosh-$MOOSH_VERSION-arm64.dmg"
```

不得调用 `notarytool`、`stapler` 或原作者凭据。

- [ ] **Step 3: 实现 generate_appcast.sh**

先检查 ZIP 已存在，再调用：

```bash
signature_and_length="$(
  vendor/Sparkle/bin/sign_update -s "$MOOSH_SPARKLE_ED_PRIVATE_KEY" "$zip_path"
)"
```

生成完整、单版本、可独立解析的 appcast，enclosure URL 固定为：

```text
https://github.com/tyrival/alt-tab-macos/releases/download/$MOOSH_TAG/Moosh-$MOOSH_VERSION-arm64.zip
```

XML 必须包含 `sparkle:version`、`sparkle:shortVersionString`、`sparkle:minimumSystemVersion`、签名、length 与 pubDate。版本值来自已验证 tag，不从不可信 PR 输入拼接 shell。

- [ ] **Step 4: 实现 verify_release.sh**

验证：

```bash
test "$(uname -m)" = "arm64"
lipo -archs "$MOOSH_APP_PATH/Contents/MacOS/Moosh" | rg -x 'arm64'
test "$(defaults read "$MOOSH_APP_PATH/Contents/Info" CFBundleIdentifier)" = "com.tyrival.moosh"
codesign --verify --deep --strict --verbose=2 "$MOOSH_APP_PATH"
hdiutil verify "$dmg_path"
unzip -t "$zip_path"
plutil -lint "$MOOSH_APP_PATH/Contents/Info.plist"
xmllint --noout "$appcast_path"
```

另外提取 appcast enclosure URL、length，分别与当前 tag、`stat -f%z "$zip_path"` 比较。

- [ ] **Step 5: 退役上游公证脚本**

若新 workflow 不再调用 `scripts/package_and_notarize_release.sh` 和 `scripts/update_appcast.sh`，删除它们并清理 pbxproj 文件引用；不要留下可误触发的原作者发布路径。`scripts/build_app.sh` 输出路径改为 Moosh，并显式传 `ARCHS=arm64`。

- [ ] **Step 6: 无编译验证**

Run:

```bash
bash -n scripts/release/package_moosh.sh
bash -n scripts/release/generate_appcast.sh
bash -n scripts/release/verify_release.sh
bash scripts/tests/test_moosh_personal_static.sh
git diff --check
```

Expected: shell 语法与静态契约通过发布脚本部分；没有生成真实产物。

- [ ] **Step 7: 用户授权后用真实产物验证**

Run after an authorized build:

```bash
version="$(defaults read DerivedData/Build/Products/Release/Moosh.app/Contents/Info CFBundleShortVersionString)"
tag="personal-v${version}-1"
output_dir="$(mktemp -d)"
MOOSH_APP_PATH='DerivedData/Build/Products/Release/Moosh.app' \
MOOSH_VERSION="$version" \
MOOSH_TAG="$tag" \
MOOSH_OUTPUT_DIR="$output_dir" \
scripts/release/package_moosh.sh

scripts/release/verify_release.sh
```

Expected: ZIP、DMG、appcast 全部验证通过。使用明确临时目录，不覆盖工作区根目录。

- [ ] **Step 8: Review checkpoint**

检查脚本无 `set -x`，避免输出 secrets；所有临时目录有 trap；没有公证命令。不提交。

---

### Task 8: 创建安全的 GitHub Actions 发布与 Pages 工作流

**Files:**
- Create: `.github/workflows/release-personal.yml`
- Modify: `.github/workflows/sync-upstream.yml` only if permission declarations conflict; otherwise leave unchanged
- Create: `docs/personal-release.md`
- Modify: `scripts/tests/test_moosh_personal_static.sh`

**Interfaces:**
- Consumes Secrets:
  - `MOOSH_CODESIGN_P12_BASE64`
  - `MOOSH_CODESIGN_P12_PASSWORD`
  - `MOOSH_KEYCHAIN_PASSWORD`
  - `MOOSH_SPARKLE_ED_PRIVATE_KEY`
- Consumes repository variable or checked-in public value:
  - `MOOSH_CODE_SIGN_IDENTITY`
  - `MOOSH_SPARKLE_PUBLIC_KEY`
- Produces: GitHub Release assets and Pages `appcast.xml`。

- [ ] **Step 1: 写 workflow 静态失败检查**

静态契约要求：

```bash
require_text 'release-personal' .github/workflows/release-personal.yml
require_text 'contents: write' .github/workflows/release-personal.yml
require_text 'pages: write' .github/workflows/release-personal.yml
require_text 'id-token: write' .github/workflows/release-personal.yml
require_text 'personal-v' .github/workflows/release-personal.yml
forbid_text 'pull_request:' .github/workflows/release-personal.yml
forbid_text 'APPLE_ID|APPLE_PASSWORD|APPLE_TEAM_ID|notarytool|stapler' .github/workflows/release-personal.yml
```

- [ ] **Step 2: 定义安全触发器**

Workflow 顶层：

```yaml
name: release-personal

on:
  workflow_dispatch:
    inputs:
      tag:
        description: Existing personal-v* tag to release
        required: true
        type: string
  push:
    tags:
      - "personal-v*"

permissions:
  contents: write
  pages: write
  id-token: write

concurrency:
  group: release-personal
  cancel-in-progress: false
```

手动输入必须先匹配 `^personal-v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$`，再用 Git 命令确认标签存在且 commit 是 `origin/personal` 的 ancestor。

- [ ] **Step 3: 配置 arm64 runner 与 checkout**

使用 GitHub 官方当前列出的标准 Apple Silicon runner：

```yaml
runs-on: macos-15
```

不使用可漂移的 `macos-latest`。Checkout 使用：

```yaml
with:
  ref: ${{ steps.ref.outputs.tag }}
  fetch-depth: 0
  submodules: recursive
```

禁止在 PR 环境使用 secrets。

- [ ] **Step 4: 导入固定自签名证书**

Workflow：

```bash
keychain_path="$RUNNER_TEMP/moosh-signing.keychain-db"
security create-keychain -p "$MOOSH_KEYCHAIN_PASSWORD" "$keychain_path"
security set-keychain-settings -lut 21600 "$keychain_path"
security unlock-keychain -p "$MOOSH_KEYCHAIN_PASSWORD" "$keychain_path"
printf '%s' "$MOOSH_CODESIGN_P12_BASE64" | base64 --decode > "$RUNNER_TEMP/moosh.p12"
security import "$RUNNER_TEMP/moosh.p12" -k "$keychain_path" \
  -P "$MOOSH_CODESIGN_P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -s \
  -k "$MOOSH_KEYCHAIN_PASSWORD" "$keychain_path"
```

环境变量来自 `${{ secrets.* }}`，step 不使用 `set -x`。Cleanup 使用 `if: always()` 删除 p12 和临时 Keychain。

- [ ] **Step 5: 注入非秘密配置并构建**

生成 `config/local.xcconfig`：

```bash
printf '%s\n' \
  'MOOSH_CODE_SIGN_IDENTITY = Moosh Personal Code Signing' \
  "MOOSH_SPARKLE_PUBLIC_KEY = $MOOSH_SPARKLE_PUBLIC_KEY" \
  "CURRENT_PROJECT_VERSION = $version" \
  > config/local.xcconfig
```

`version` 必须由已经通过正则校验的 tag 截取，证书 common name 固定为 `Moosh Personal Code Signing`。随后运行仓库 `ai/build.sh` 中等价的 xcodebuild 命令，但 scheme/configuration 为 Release，增加 `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`。此步骤只在 Actions 内执行。

- [ ] **Step 6: 打包、签名 appcast 并验证**

调用 Task 7 三个脚本。`MOOSH_SPARKLE_ED_PRIVATE_KEY` 只作为环境变量传给签名 step，不写入文件，不作为 artifact 上传。

- [ ] **Step 7: 创建 Release 后再部署 appcast**

先用 `gh release create "$tag" "$dmg" "$zip" --title "Moosh $version" --notes-file ...` 创建 Release。随后用 `curl -fL` 或 GitHub API 验证两个 asset URL 返回成功，再上传只包含 `appcast.xml` 的 Pages artifact 并调用官方 Pages deploy action。

如果 Release 或 asset 验证失败，Pages job 不运行，旧 feed 保持不变。

- [ ] **Step 8: 编写个人发布文档**

`docs/personal-release.md` 必须包含：

1. 在本机生成一次自签名 Code Signing certificate 的 Keychain Access 操作或等价 `security` 命令。
2. 导出 `.p12`、Base64 编码和设置三个证书 secrets。
3. 使用 `vendor/Sparkle/bin/generate_keys` 生成 EdDSA key，保存私钥 secret 和公开公钥。
4. 将证书、p12、密码与 Sparkle 私钥离线备份。
5. GitHub Pages 选择 GitHub Actions 作为 source。
6. 创建 `personal-v*` 标签前先将 `master` 合入 `personal`。
7. 首次下载安装、系统设置手动放行和信任证书。
8. 发布第二版完成 Sparkle 更新闭环。

文档不得包含真实 secret 值。

- [ ] **Step 9: 静态验证 workflow**

Run:

```bash
bash scripts/tests/test_moosh_personal_static.sh
rg -n 'pull_request:|notarytool|stapler|APPLE_ID|APPLE_PASSWORD|APPLE_TEAM_ID|lwouis/.+releases' \
  .github/workflows/release-personal.yml
git diff --check
```

Expected: 静态契约通过，禁止项为零。

- [ ] **Step 10: Review checkpoint**

确认发布 job 只对受信任 tag/manual dispatch 使用 secrets；同步 workflow 未被发布逻辑污染；未实际创建 Secrets 或运行 Actions。不提交。

---

### Task 9: 全量静态复核与待授权构建清单

**Files:**
- Modify as needed: all files changed in Tasks 1–8
- Modify: `docs/personal-release.md`
- Modify: `src/personal/MooshPersonalSpecs.md`

**Interfaces:**
- Consumes: 所有实现任务。
- Produces: 可供用户批准编译/发布的干净源码状态与证据报告。

- [ ] **Step 1: 运行完整静态契约**

Run:

```bash
bash scripts/tests/test_moosh_personal_static.sh
bash -n scripts/release/package_moosh.sh
bash -n scripts/release/generate_appcast.sh
bash -n scripts/release/verify_release.sh
plutil -lint Info.plist
xmllint --noout appcast.xml
git diff --check
```

Expected: 全部 PASS。若仓库根 `appcast.xml` 已退役，改为验证生成脚本 fixture，不保留双重 source of truth。

- [ ] **Step 2: 搜索残留商业路径**

Run:

```bash
rg -n -i '\\bpro\\b|license|trial|checkout|pricing|upgrade|account|QXD7GW8FHY|com\\.lwouis' \
  src config Info.plist scripts .github alt-tab-macos.xcodeproj
```

逐条分类。允许项仅限：

- GPL `LICENCE.md` 文件名引用。
- 与系统通用概念相同但非商业授权的第三方 license 文档。
- 明确的上游归属文档。

产品 Swift、构建配置和发布 workflow 不得保留商业路径。

- [ ] **Step 3: 检查工作区边界**

Run:

```bash
git status --short
git diff --stat
git diff --name-status
```

确认只包含 Moosh 设计范围内的文件；不覆盖用户原有改动。

- [ ] **Step 4: 输出未验证项**

在交付说明中明确列出尚未执行：

- Swift/XCTest 编译。
- Release arm64 构建。
- 自签名代码签名验证。
- DMG/ZIP 真实产物验证。
- GitHub Release 与 Pages 部署。
- Sparkle 第二版本自动升级。

- [ ] **Step 5: 请求一次明确的编译授权**

用户授权后才进入 Task 10。授权应明确覆盖本地编译还是仅 GitHub Actions 构建；不得自动扩展为发布授权。

- [ ] **Step 6: Review checkpoint**

在无编译状态下交付静态证据与未验证边界。不提交。

---

### Task 10: 经用户授权后的构建、首次发布与升级闭环

**Files:**
- No product source changes expected
- Modify only on discovered defect: exact owning file plus matching test

**Interfaces:**
- Consumes: GitHub Secrets、固定自签名证书、Sparkle key、`personal-v*` 标签。
- Produces: 可安装 DMG、可更新 ZIP、GitHub Release、Pages appcast 和升级验证记录。

- [ ] **Step 1: 运行完整 XCTest**

Run:

```bash
scripts/run_tests.sh
```

Expected: PASS。

- [ ] **Step 2: 按 `ai/build.sh` 的命令结构构建 Release arm64**

Run:

```bash
xcodebuild \
  -project alt-tab-macos.xcodeproj \
  -scheme Release \
  -configuration Release \
  -derivedDataPath DerivedData \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES
```

Expected: BUILD SUCCEEDED；不得使用 Xcode GUI。

- [ ] **Step 3: 本地验证 App 身份**

Run:

```bash
file DerivedData/Build/Products/Release/Moosh.app/Contents/MacOS/Moosh
defaults read DerivedData/Build/Products/Release/Moosh.app/Contents/Info CFBundleIdentifier
codesign -dv --verbose=4 DerivedData/Build/Products/Release/Moosh.app
```

Expected: arm64、`com.tyrival.moosh`、固定自签名 identity。

- [ ] **Step 4: 只在用户明确授权外部发布后创建首个标签**

Tag format:

```text
personal-v11.4.3-1
```

示例中的 `11.4.3` 取自当前上游版本；若实施时上游已经变化，则从 `CFBundleShortVersionString` 读取当时的确切版本并按同一规则生成。创建前确认 tag commit 属于 `personal` 且工作树内容已经过用户复核。提交、推送和标签均需单独明确授权。

- [ ] **Step 5: 观察 GitHub Actions**

确认：

- build/test job 通过。
- Release 含 DMG 与 ZIP。
- Pages appcast enclosure 指向实际 asset。
- workflow 日志未泄露 secrets。

- [ ] **Step 6: 首次安装**

从 Release 下载 DMG，拖入 `/Applications`，通过系统设置手动放行并信任自签名证书。验证 Moosh 与官方 AltTab 可并存，权限和设置使用 `com.tyrival.moosh`。

- [ ] **Step 7: 功能验收**

逐项验证原 Pro 功能：

- App icons / titles appearance style。
- Auto size。
- Search-on-release shortcut style。
- 第二个及更多快捷键槽位。
- Switcher 内搜索。

预期：无试用、授权、购买、Upgrade UI 或网络授权请求。

- [ ] **Step 8: 发布第二个修订版**

仅改变可见版本/测试标记；若首版为 `personal-v11.4.3-1`，第二版使用 `personal-v11.4.3-2`，让 Actions 生成第二个 Release 和 appcast。若首版使用其他上游版本，保持前三段版本相同并只将个人修订号从 `1` 增加到 `2`。

- [ ] **Step 9: 验证 Sparkle 闭环**

从第一版 Moosh 执行 Check for updates，确认：

- 检测到第二版。
- 从当前仓库 Release 下载 ZIP。
- EdDSA 验证通过。
- 代码签名验证通过。
- 更新、重启成功。
- 设置与登录项保持不变。

- [ ] **Step 10: 最终报告**

报告确切 tag、Release URL、Pages appcast URL、产物名称、验证结果和任何仍未验证项。只有全部成功后才声称自动升级已完成。
