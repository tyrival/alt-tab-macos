import Foundation

struct PreferenceDefinition<T: MacroPreference & CaseIterable & Equatable> {
    let key: String
    let `default`: T

    func read() -> T {
        CachedUserDefaults.macroPref(key, Array(T.allCases))
    }
}

enum FeaturePreferences {
    static let appearanceStyle = PreferenceDefinition<AppearanceStylePreference>(
        key: "appearanceStyle",
        default: .thumbnails)
    static let appearanceSize = PreferenceDefinition<AppearanceSizePreference>(
        key: "appearanceSize",
        default: .auto)
    static let shortcutStyle = PreferenceDefinition<ShortcutStylePreference>(
        key: "shortcutStyle",
        default: .focusOnRelease)
    static let appearanceStyleOverride0 = PreferenceDefinition<AppearanceStylePreference>(
        key: "appearanceStyleOverride",
        default: .thumbnails)
    static let appearanceSizeOverride0 = PreferenceDefinition<AppearanceSizePreference>(
        key: "appearanceSizeOverride",
        default: .medium)
    static let shortcutStyleOverride0 = PreferenceDefinition<ShortcutStylePreference>(
        key: "shortcutStyleOverride",
        default: .doNothingOnRelease)
}
