import XCTest
@testable import ScrollingScreenshot

final class RecordingSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "frameInterval")
        UserDefaults.standard.removeObject(forKey: "previewBeforeSave")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "frameInterval")
        UserDefaults.standard.removeObject(forKey: "previewBeforeSave")
        super.tearDown()
    }

    func testSessionInitialization() {
        let session = RecordingSession(
            id: UUID(),
            date: Date(),
            duration: 5.0,
            status: .recording,
            resultImageFilename: nil
        )
        XCTAssertEqual(session.status, .recording)
        XCTAssertEqual(session.duration, 5.0)
        XCTAssertNil(session.resultImageFilename)
    }

    func testSessionCoding() throws {
        let session = RecordingSession(
            id: UUID(),
            date: Date(),
            duration: 3.0,
            status: .completed,
            resultImageFilename: "test.png"
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(RecordingSession.self, from: data)
        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.status, .completed)
    }

}
