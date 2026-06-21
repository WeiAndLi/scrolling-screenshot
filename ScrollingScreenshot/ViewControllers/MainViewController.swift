import UIKit

final class MainViewController: UIViewController {

    // MARK: - Dependencies
    private let screenRecorder: ScreenRecorderProtocol
    private let frameExtractor: FrameExtractorProtocol
    private let imageStitcher: ImageStitcherProtocol
    private let notificationManager: NotificationManagerProtocol

    // MARK: - UI
    private let headerLabel = UILabel()
    private let recordButton = RecordButton()
    private let timerLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    private let tipLabel = UILabel()
    private let tableView = UITableView()
    private let settingsButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()

    // MARK: - State
    private var recordingTimer: Timer?
    private var elapsedSeconds: TimeInterval = 0
    private var sessions: [RecordingSession] = []
    private var currentVideoURL: URL?
    private var isProcessing = false
    private var pendingCheckTimer: Timer?

    // MARK: - Init
    init(
        screenRecorder: ScreenRecorderProtocol = ScreenRecorder(),
        frameExtractor: FrameExtractorProtocol = FrameExtractor(),
        imageStitcher: ImageStitcherProtocol = ImageStitcher(),
        notificationManager: NotificationManagerProtocol = NotificationManager()
    ) {
        self.screenRecorder = screenRecorder
        self.frameExtractor = frameExtractor
        self.imageStitcher = imageStitcher
        self.notificationManager = notificationManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.screenRecorder = ScreenRecorder()
        self.frameExtractor = FrameExtractor()
        self.imageStitcher = ImageStitcher()
        self.notificationManager = NotificationManager()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSessions()
        requestPermissions()
        startPendingCheck()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPendingRecordings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSessions()
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "滚动长截图"

        headerLabel.text = "滚动长截图"
        headerLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"
        timerLabel.isHidden = true
        timerLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "点击红色按钮开始录制"
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        tipLabel.font = .systemFont(ofSize: 12)
        tipLabel.textColor = .tertiaryLabel
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        tipLabel.text = "💡 也可以用控制中心长按录屏按钮 → 选「ScrollShot 录屏」"
        tipLabel.translatesAutoresizingMaskIntoConstraints = false

        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = "暂无录制记录\n点击红色按钮或在控制中心开始录制"
        emptyStateLabel.font = .systemFont(ofSize: 14)
        emptyStateLabel.textColor = .tertiaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let historyLabel = UILabel()
        historyLabel.text = "历史记录"
        historyLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        historyLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerLabel)
        view.addSubview(settingsButton)
        view.addSubview(recordButton)
        view.addSubview(timerLabel)
        view.addSubview(statusLabel)
        view.addSubview(tipLabel)
        view.addSubview(progressView)
        view.addSubview(historyLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 32),
            recordButton.widthAnchor.constraint(equalToConstant: 72),
            recordButton.heightAnchor.constraint(equalToConstant: 72),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 12),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),

            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),

            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            tipLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            tipLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),

            historyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            historyLabel.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 24),

            tableView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])

        updateEmptyState()
    }

    // MARK: - Actions
    @objc private func recordButtonTapped() {
        if screenRecorder.isRecording {
            stopRecording()
        } else if !isProcessing {
            startRecording()
        }
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        let nav = UINavigationController(rootViewController: settingsVC)
        present(nav, animated: true)
    }

    // MARK: - Recording
    private func startRecording() {
        // 立即显示"请求中"状态，不阻塞 UI
        recordButton.isEnabled = false
        statusLabel.text = "正在请求屏幕录制..."

        // 异步发起录制，不等待回调
        Task {
            do {
                try await screenRecorder.startRecording()
                // 录制已获授权，开始录制
                await MainActor.run {
                    recordButton.isRecording = true
                    recordButton.isEnabled = true
                    timerLabel.isHidden = false
                    statusLabel.text = "正在录制... 切换到目标 App 滚动内容"
                    tipLabel.isHidden = true
                    startTimer()
                }
            } catch {
                // 用户取消或录制失败
                await MainActor.run {
                    recordButton.isRecording = false
                    recordButton.isEnabled = true
                    statusLabel.text = "点击红色按钮开始录制"
                }
            }
        }
    }

    private func stopRecording() {
        recordButton.isEnabled = false
        statusLabel.text = "正在停止录制..."
        stopTimer()

        Task {
            do {
                let videoURL = try await screenRecorder.stopRecording()
                await MainActor.run {
                    recordButton.isRecording = false
                    timerLabel.isHidden = true
                    tipLabel.isHidden = false
                    recordButton.isEnabled = true
                    startProcessing(videoURL: videoURL)
                }
            } catch {
                await MainActor.run {
                    recordButton.isRecording = false
                    timerLabel.isHidden = true
                    tipLabel.isHidden = false
                    recordButton.isEnabled = true
                    statusLabel.text = "点击红色按钮开始录制"
                    showAlert(title: "停止失败", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Processing
    private func startProcessing(videoURL: URL) {
        isProcessing = true
        progressView.isHidden = false
        progressView.progress = 0
        statusLabel.text = "处理中..."

        let session = RecordingSession(
            id: UUID(),
            date: Date(),
            duration: elapsedSeconds,
            status: .processing,
            resultImageFilename: nil
        )
        sessions.insert(session, at: 0)
        updateEmptyState()
        tableView.reloadData()

        Task {
            do {
                progressView.progress = 0.15
                statusLabel.text = "正在提取帧..."

                let frames = try await frameExtractor.extractFrames(
                    from: videoURL,
                    interval: UserSettings.frameInterval
                )

                progressView.progress = 0.45
                statusLabel.text = "正在拼接 \(frames.count) 帧..."

                let stitchedImage = try await imageStitcher.stitch(frames: frames)

                progressView.progress = 0.75
                statusLabel.text = "正在保存到相册..."

                try await saveToPhotos(image: stitchedImage)

                try? FileManager.default.removeItem(at: videoURL)

                let filename = "\(session.id.uuidString).png"
                if let data = stitchedImage.pngData(),
                   let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try data.write(to: docs.appendingPathComponent(filename))
                }

                if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
                    sessions[idx].status = .completed
                    sessions[idx].resultImageFilename = filename
                }

                await MainActor.run {
                    progressView.progress = 1.0
                    if UserSettings.previewBeforeSave {
                        if let updatedSession = sessions.first(where: { $0.id == session.id }) {
                            navigationController?.pushViewController(
                                PreviewViewController(image: stitchedImage, session: updatedSession),
                                animated: true
                            )
                        }
                        statusLabel.text = "预览"
                    } else {
                        statusLabel.text = "✅ 已保存到相册"
                    }
                    isProcessing = false
                    updateEmptyState()
                    tableView.reloadData()
                    notificationManager.notifyProcessingComplete(sessionId: session.id.uuidString, success: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.progressView.isHidden = true
                        if !UserSettings.previewBeforeSave {
                            self?.statusLabel.text = "点击红色按钮开始录制"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
                        sessions[idx].status = .failed
                    }
                    isProcessing = false
                    progressView.isHidden = true
                    statusLabel.text = "点击红色按钮开始录制"
                    updateEmptyState()
                    tableView.reloadData()
                    notificationManager.notifyProcessingComplete(sessionId: session.id.uuidString, success: false)
                    showAlert(title: "处理失败", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Pending check
    private func startPendingCheck() {
        pendingCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkPendingRecordings()
        }
    }

    private func checkPendingRecordings() {
        guard !isProcessing else { return }
        guard let pending = UserDefaults(suiteName: "group.com.scrollshot.app")?
            .stringArray(forKey: "pendingVideos"), !pending.isEmpty else { return }
        var list = pending
        let videoPath = list.removeFirst()
        UserDefaults(suiteName: "group.com.scrollshot.app")?.set(list, forKey: "pendingVideos")
        let videoURL = URL(fileURLWithPath: videoPath)
        guard FileManager.default.fileExists(atPath: videoPath) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.startProcessing(videoURL: videoURL)
        }
    }

    // MARK: - Helpers
    private func startTimer() {
        elapsedSeconds = 0
        updateTimerLabel()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
            self?.updateTimerLabel()
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func updateTimerLabel() {
        let mins = Int(elapsedSeconds) / 60
        let secs = Int(elapsedSeconds) % 60
        timerLabel.text = String(format: "%02d:%02d", mins, secs)
    }

    private func saveToPhotos(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(Self.imageSaveComplete(_:didFinishSavingWithError:contextInfo:)), nil)
            Self.pendingSaveContinuation = continuation
        }
    }

    private static var pendingSaveContinuation: CheckedContinuation<Void, Error>?

    @objc private func imageSaveComplete(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer?
    ) {
        if let error = error {
            Self.pendingSaveContinuation?.resume(throwing: error)
        } else {
            Self.pendingSaveContinuation?.resume()
        }
        Self.pendingSaveContinuation = nil
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func requestPermissions() {
        Task { try? await notificationManager.requestAuthorization() }
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !sessions.isEmpty
    }

    // MARK: - Persistence
    private func loadSessions() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = docs.appendingPathComponent("sessions.json")
        if let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode([RecordingSession].self, from: data) {
            sessions = loaded
        }
    }

    private func saveSessions() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = docs.appendingPathComponent("sessions.json")
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: url)
        }
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SessionCell.reuseIdentifier, for: indexPath) as? SessionCell else {
            return UITableViewCell()
        }
        let session = sessions[indexPath.row]
        var thumbnail: UIImage?
        if let filename = session.resultImageFilename,
           let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let data = try? Data(contentsOf: docs.appendingPathComponent(filename)) {
                thumbnail = UIImage(data: data)
            }
        }
        cell.configure(with: session, thumbnail: thumbnail)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = sessions[indexPath.row]
        guard session.status == .completed, let filename = session.resultImageFilename else { return }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = docs.appendingPathComponent(filename)
        guard let image = UIImage(contentsOfFile: url.path) else { return }
        navigationController?.pushViewController(
            PreviewViewController(image: image, session: session),
            animated: true
        )
    }
}
