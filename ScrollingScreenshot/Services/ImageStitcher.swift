import UIKit
import Vision

protocol ImageStitcherProtocol {
    func stitch(frames: [UIImage]) async throws -> UIImage
}

final class ImageStitcher: ImageStitcherProtocol {

    private let minimumOverlapRatio: CGFloat = 0.05

    func stitch(frames: [UIImage]) async throws -> UIImage {
        guard frames.count >= 2 else {
            if let single = frames.first {
                return single
            }
            throw ImageStitcherError.noFrames
        }

        // Step 1: Compute Y-offsets between adjacent frames
        var offsets: [CGFloat] = [0]
        var effectiveHeights: [CGFloat] = []

        for i in 0..<(frames.count - 1) {
            let frameA = frames[i]
            let frameB = frames[i + 1]

            let offsetY = try await computeVerticalOffset(imageA: frameA, imageB: frameB)
            let frameAHeight = frameA.size.height
            let overlapRatio = (frameAHeight - abs(offsetY)) / frameAHeight

            if overlapRatio >= minimumOverlapRatio {
                offsets.append(offsets[i] + offsetY)
                effectiveHeights.append(offsetY)
            } else {
                offsets.append(offsets[i] + frameAHeight)
                effectiveHeights.append(frameAHeight)
            }
        }
        effectiveHeights.append(frames.last!.size.height)

        // Step 2: Calculate total canvas size
        let totalHeight = offsets.last! + effectiveHeights.last!
        let width = frames.first!.size.width
        let canvasSize = CGSize(width: width, height: totalHeight)

        // Step 3: Render all frames onto canvas
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let result = renderer.image { ctx in
            for i in 0..<frames.count {
                let frame = frames[i]
                let y = offsets[i]
                let height = effectiveHeights[i]

                let sourceRect = CGRect(
                    x: 0,
                    y: frame.size.height - height,
                    width: frame.size.width,
                    height: height
                )
                let destRect = CGRect(
                    x: 0,
                    y: y,
                    width: width,
                    height: height
                )

                frame.draw(in: destRect)
            }
        }

        return result
    }

    // MARK: - Private: Vision-based image registration

    private func computeVerticalOffset(
        imageA: UIImage,
        imageB: UIImage
    ) async throws -> CGFloat {
        guard let cgImageA = imageA.cgImage, let cgImageB = imageB.cgImage else {
            throw ImageStitcherError.invalidImage
        }

        let request = VNTranslationalImageRegistrationRequest(
            targetedCGImage: cgImageB,
            orientation: .up
        )

        let handler = VNImageRequestHandler(cgImage: cgImageA, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                if let result = request.results?.first {
                    let offsetY = abs(CGFloat(result.alignmentTransform.ty))
                    continuation.resume(returning: offsetY)
                } else {
                    continuation.resume(returning: imageA.size.height)
                }
            } catch {
                continuation.resume(returning: imageA.size.height)
            }
        }
    }
}

enum ImageStitcherError: LocalizedError {
    case noFrames
    case invalidImage
    case stitchingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noFrames: return "No frames to stitch"
        case .invalidImage: return "Invalid image data in frame"
        case .stitchingFailed(let msg): return "Stitching failed: \(msg)"
        }
    }
}
