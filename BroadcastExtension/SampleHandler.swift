import ReplayKit
import UIKit
import AVFoundation

/// 系统录屏扩展 —— 从控制中心触发录制，完成后自动处理
final class SampleHandler: RPBroadcastSampleHandler {

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var outputURL: URL?

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        // 在 App Group 共享目录创建视频文件
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.scrollshot.app"
        ) else {
            finishBroadcastWithError(NSError(
                domain: "ScrollShot",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法访问共享存储"]
            ))
            return
        }

        let url = containerURL
            .appendingPathComponent("pending_recordings")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // 确保目录存在
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: url)
        self.outputURL = url

        // 创建 AVAssetWriter
        do {
            let writer = try AVAssetWriter(url: url, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: UIScreen.main.bounds.width * UIScreen.main.scale,
                AVVideoHeightKey: UIScreen.main.bounds.height * UIScreen.main.scale,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 8_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]

            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true
            writer.add(input)

            self.assetWriter = writer
            self.videoInput = input
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

        } catch {
            finishBroadcastWithError(error)
        }
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with type: RPSampleBufferType) {
        guard type == .video,
              let writer = assetWriter,
              let input = videoInput,
              writer.status == .writing else { return }

        if input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }

    override func broadcastFinished() {
        guard let url = outputURL else {
            return
        }

        videoInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            // 通知主 App 有新录制完成
            // 通过 App Group UserDefaults 传递文件路径
            var pending: [String] = UserDefaults(suiteName: "group.com.scrollshot.app")?
                .stringArray(forKey: "pendingVideos") ?? []
            pending.append(url.path)
            UserDefaults(suiteName: "group.com.scrollshot.app")?
                .set(pending, forKey: "pendingVideos")
            UserDefaults(suiteName: "group.com.scrollshot.app")?
                .synchronize()

            self?.finishBroadcast()
        }
    }
}
