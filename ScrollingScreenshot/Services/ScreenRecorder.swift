import ReplayKit
import AVFoundation
import UIKit

protocol ScreenRecorderProtocol {
    func startRecording() async throws
    func stopRecording() async throws -> URL
    var isRecording: Bool { get }
}

final class ScreenRecorder: ScreenRecorderProtocol {

    private let recorder = RPScreenRecorder.shared()
    private var outputURL: URL?

    var isRecording: Bool {
        recorder.isRecording
    }

    func startRecording() async throws {
        guard recorder.isAvailable else {
            throw ScreenRecorderError.unavailable
        }
        guard !recorder.isRecording else {
            throw ScreenRecorderError.alreadyRecording
        }

        recorder.isMicrophoneEnabled = false

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        self.outputURL = url

        try? FileManager.default.removeItem(at: url)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            recorder.startRecording(withOutput: url) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func stopRecording() async throws -> URL {
        guard let url = outputURL else {
            throw ScreenRecorderError.noOutputURL
        }
        guard recorder.isRecording else {
            throw ScreenRecorderError.notRecording
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            recorder.stopRecording { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ScreenRecorderError.outputFileMissing
        }

        return url
    }
}

enum ScreenRecorderError: LocalizedError {
    case unavailable
    case alreadyRecording
    case notRecording
    case noOutputURL
    case outputFileMissing

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Screen recording is not available on this device"
        case .alreadyRecording: return "Recording is already in progress"
        case .notRecording: return "No active recording to stop"
        case .noOutputURL: return "Output URL not configured"
        case .outputFileMissing: return "Recording output file not found"
        }
    }
}
