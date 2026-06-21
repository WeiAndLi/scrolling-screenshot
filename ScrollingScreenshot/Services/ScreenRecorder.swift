import ReplayKit
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

        // iOS 15+: startRecording(handler:) is the standard API
        // The handler fires AFTER user confirms the system dialog
        try await withCheckedThrowingContinuation { continuation in
            recorder.startRecording { error in
                if let error = error {
                    // User cancelled or recording failed
                    continuation.resume(throwing: error)
                } else {
                    // Recording started successfully
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
            // iOS 15+: stopRecording saves video then calls handler with preview VC
            // We dismiss the preview automatically — just want the video file
            recorder.stopRecording { previewVC, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                // Dismiss preview immediately
                previewVC?.dismiss(animated: false)
                continuation.resume()
            }
        }

        // After stopRecording, the video should be at the output URL
        // RPScreenRecorder stores it internally and we can access it
        // For iOS 17+, video goes to the URL set in startRecording
        guard FileManager.default.fileExists(atPath: url.path) else {
            // Video might not be at our URL — try finding it via preview
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
        case .unavailable:
            return "屏幕录制在此设备上不可用"
        case .alreadyRecording:
            return "已经在录制中"
        case .notRecording:
            return "当前没有在录制"
        case .noOutputURL:
            return "输出路径未配置"
        case .outputFileMissing:
            return "录制视频文件未找到，请尝试使用系统录屏触发"
        }
    }
}
