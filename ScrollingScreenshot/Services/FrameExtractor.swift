import AVFoundation
import UIKit

protocol FrameExtractorProtocol {
    func extractFrames(from url: URL, interval: TimeInterval) async throws -> [UIImage]
}

final class FrameExtractor: FrameExtractorProtocol {

    func extractFrames(from url: URL, interval: TimeInterval = 0.4) async throws -> [UIImage] {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds >= 1.0 else {
            throw FrameExtractorError.tooShort(durationSeconds)
        }

        let reader = try AVAssetReader(asset: asset)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw FrameExtractorError.noVideoTrack
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        reader.add(trackOutput)
        reader.startReading()

        var frames: [UIImage] = []
        var lastTimestamp: TimeInterval = -interval

        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            let timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))

            guard timestamp - lastTimestamp >= interval else { continue }

            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            guard !isBlurry(ciImage) else { continue }

            let uiImage = imageFromPixelBuffer(imageBuffer)
            frames.append(uiImage)
            lastTimestamp = timestamp
        }

        guard reader.status == .completed else {
            throw FrameExtractorError.readFailed(reader.error)
        }

        guard !frames.isEmpty else {
            throw FrameExtractorError.noFramesExtracted
        }

        return frames
    }

    // MARK: - Private

    private func isBlurry(_ image: CIImage) -> Bool {
        let context = CIContext()
        guard let laplacian = CIFilter(name: "CILaplacian") else { return false }
        laplacian.setValue(image, forKey: kCIInputImageKey)
        guard let output = laplacian.outputImage else { return false }

        let scale: CGFloat = 0.25
        let scaledExtent = CGRect(x: 0, y: 0,
                                  width: image.extent.width * scale,
                                  height: image.extent.height * scale)

        guard let cgImage = context.createCGImage(output, from: scaledExtent) else { return false }

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return false }

        let count = cgImage.width * cgImage.height
        var sum: Double = 0
        var sumSq: Double = 0

        for i in 0..<count {
            let v = Double(bytes[i])
            sum += v
            sumSq += v * v
        }

        let mean = sum / Double(count)
        let variance = sumSq / Double(count) - mean * mean

        return variance < 50
    }

    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage)
    }
}

enum FrameExtractorError: LocalizedError {
    case tooShort(TimeInterval)
    case noVideoTrack
    case readFailed(Error?)
    case noFramesExtracted

    var errorDescription: String? {
        switch self {
        case .tooShort(let d): return "Video too short (\(String(format: "%.1f", d))s). Minimum 1 second."
        case .noVideoTrack: return "No video track found in recording"
        case .readFailed(let e): return "Failed to read video: \(e?.localizedDescription ?? "unknown error")"
        case .noFramesExtracted: return "No usable frames extracted from recording"
        }
    }
}
