import XCTest
import AVFoundation
@testable import ScrollingScreenshot

final class FrameExtractorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertTrue(FrameExtractorError.tooShort(0.5).errorDescription?.contains("0.5") ?? false)
        XCTAssertEqual(FrameExtractorError.noVideoTrack.errorDescription,
                       "No video track found in recording")
        XCTAssertEqual(FrameExtractorError.noFramesExtracted.errorDescription,
                       "No usable frames extracted from recording")
    }

    func testExtractFramesFromNonexistentFile() async throws {
        let nonexistentURL = URL(fileURLWithPath: "/tmp/nonexistent_test_video.mp4")
        do {
            _ = try await FrameExtractor().extractFrames(from: nonexistentURL)
            XCTFail("Expected error for nonexistent file")
        } catch {
            XCTAssertTrue(error is FrameExtractorError)
        }
    }

    func testTooShortVideoErrorFormatting() {
        let error = FrameExtractorError.tooShort(0.3)
        XCTAssertTrue(error.errorDescription?.contains("0.3") ?? false)
    }
}
