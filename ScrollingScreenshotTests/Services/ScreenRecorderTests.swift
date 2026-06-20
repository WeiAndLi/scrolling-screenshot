import XCTest
@testable import ScrollingScreenshot

final class ScreenRecorderTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(ScreenRecorderError.unavailable.errorDescription,
                       "Screen recording is not available on this device")
        XCTAssertEqual(ScreenRecorderError.alreadyRecording.errorDescription,
                       "Recording is already in progress")
        XCTAssertEqual(ScreenRecorderError.notRecording.errorDescription,
                       "No active recording to stop")
        XCTAssertEqual(ScreenRecorderError.noOutputURL.errorDescription,
                       "Output URL not configured")
        XCTAssertEqual(ScreenRecorderError.outputFileMissing.errorDescription,
                       "Recording output file not found")
    }

    func testRecorderAvailability() {
        let recorder = ScreenRecorder()
        XCTAssertFalse(recorder.isRecording)
    }
}
