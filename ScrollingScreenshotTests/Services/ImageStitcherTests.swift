import XCTest
@testable import ScrollingScreenshot

final class ImageStitcherTests: XCTestCase {

    func testSingleFrameReturnsAsIs() async throws {
        let stitcher = ImageStitcher()
        let singleFrame = makeSolidImage(color: .red, size: CGSize(width: 300, height: 400))
        let result = try await stitcher.stitch(frames: [singleFrame])
        XCTAssertEqual(result.size.width, 300)
        XCTAssertEqual(result.size.height, 400)
    }

    func testEmptyFramesThrows() async {
        let stitcher = ImageStitcher()
        do {
            _ = try await stitcher.stitch(frames: [])
            XCTFail("Expected error for empty frames")
        } catch {
            XCTAssertTrue(error is ImageStitcherError)
        }
    }

    func testTwoDifferentFramesProduceTallerImage() async throws {
        let stitcher = ImageStitcher()
        let frameSize = CGSize(width: 300, height: 400)
        let frame1 = makeSolidImage(color: .red, size: frameSize)
        let frame2 = makeSolidImage(color: .blue, size: frameSize)

        let result = try await stitcher.stitch(frames: [frame1, frame2])
        XCTAssertGreaterThanOrEqual(result.size.width, 300)
        XCTAssertGreaterThan(result.size.height, frameSize.height)
        XCTAssertLessThanOrEqual(result.size.height, frameSize.height * 2)
    }

    func testErrorDescriptions() {
        XCTAssertEqual(ImageStitcherError.noFrames.errorDescription, "No frames to stitch")
        XCTAssertEqual(ImageStitcherError.invalidImage.errorDescription, "Invalid image data in frame")
    }

    // MARK: - Helper

    private func makeSolidImage(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
