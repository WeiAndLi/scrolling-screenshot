import Foundation

struct UserSettings {
    private enum Keys {
        static let previewBeforeSave = "previewBeforeSave"
        static let frameInterval = "frameInterval"
    }

    static var previewBeforeSave: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.previewBeforeSave) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.previewBeforeSave) }
    }

    static var frameInterval: TimeInterval {
        get {
            let value = UserDefaults.standard.double(forKey: Keys.frameInterval)
            return value > 0 ? value : 0.4
        }
        set {
            let clamped = min(2.0, max(0.1, newValue))
            UserDefaults.standard.set(clamped, forKey: Keys.frameInterval)
        }
    }
}
