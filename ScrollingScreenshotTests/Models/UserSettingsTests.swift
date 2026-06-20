import XCTest
@testable import ScrollingScreenshot

final class UserSettingsTests: XCTestCase {

    private var defaultsSnapshot: [String: Any] = [:]

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        let keys = ["frameInterval", "previewBeforeSave"]
        for key in keys {
            if let value = defaults.object(forKey: key) {
                defaultsSnapshot[key] = value
            }
            defaults.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "frameInterval")
        defaults.removeObject(forKey: "previewBeforeSave")
        for (key, value) in defaultsSnapshot {
            defaults.set(value, forKey: key)
        }
        defaultsSnapshot.removeAll()
        super.tearDown()
    }

    func testUserSettingsDefaults() {
        XCTAssertEqual(UserSettings.frameInterval, 0.4)
        XCTAssertFalse(UserSettings.previewBeforeSave)
    }

    func testUserSettingsCustomValues() {
        UserSettings.frameInterval = 0.3
        UserSettings.previewBeforeSave = true
        XCTAssertEqual(UserSettings.frameInterval, 0.3)
        XCTAssertTrue(UserSettings.previewBeforeSave)
    }
}
