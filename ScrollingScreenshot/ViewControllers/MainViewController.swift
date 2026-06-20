import UIKit

final class MainViewController: UIViewController {

    // MARK: - Dependencies
    private let screenRecorder: ScreenRecorderProtocol
    private let frameExtractor: FrameExtractorProtocol
    private let imageStitcher: ImageStitcherProtocol
    private let notificationManager: NotificationManagerProtocol

    // MARK: - UI
    private let recordButton = RecordButton()
    private let timerLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    private let tableView = UITableView()
    private let settingsButton = UIButton(type: .system)

    // MARK: - State
    private var recordingTimer: Timer?
    private var elapsedSeconds: TimeInterval = 0
    private var sessions: [RecordingSession] = []
    private var currentVideoURL: URL?
    private var isProcessing = false

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSessions()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "ScrollShot"

        // Record button
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        view.addSubview(recordButton)

        // Timer label
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 32, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"
        timerLabel.isHidden = true
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // Status label
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.text = "Tap to start recording"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Progress
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        // Settings button
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)

        // Table view
        tableView.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Layout
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 16),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 4),

            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),

            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Actions
    @objc private func recordButtonTapped() {
        if screenRecorder.isRecording {
            stopRecording()
        } else {
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
        Task {
            do {
                try await screenRecorder.startRecording()
                await MainActor.run {
                    recordButton.isRecording = true
                    timerLabel.isHidden = false
                    statusLabel.text = "Recording... Switch to target app and scroll"
                    startTimer()
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Recording Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func stopRecording() {
        recordButton.isEnabled = false
        statusLabel.text = "Stopping..."
        stopTimer()

        Task {
            do {
                let videoURL = try await screenRecorder.stopRecording()
                self.currentVideoURL = videoURL
                await MainActor.run {
                    recordButton.isRecording = false
                    timerLabel.isHidden = true
                    startProcessing(videoURL: videoURL)
                }
            } catch {
                await MainActor.run {
                    recordButton.isRecording = false
                    timerLabel.isHidden = true
                    recordButton.isEnabled = true
                    showAlert(title: "Stop Failed", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Processing
    private func startProcessing(videoURL: URL) {
        isProcessing = true
        progressView.isHidden = false
        progressView.progress = 0
        statusLabel.text = "Processing..."

        let session = RecordingSession(
            id: UUID(),
            date: Date(),
            duration: elapsedSeconds,
            status: .processing,
            resultImageFilename: nil
        )
        sessions.insert(session, at: 0)
        tableView.reloadData()

        Task {
            do {
                progressView.progress = 0.2
                statusLabel.text = "Extracting frames..."

                let frames = try await frameExtractor.extractFrames(
                    from: videoURL,
                    interval: UserSettings.frameInterval
                )

                progressView.progress = 0.5
                statusLabel.text = "Stitching \(frames.count) frames..."

                let stitchedImage = try await imageStitcher.stitch(frames: frames)

                progressView.progress = 0.8
                statusLabel.text = "Saving to Photos..."

                try await saveToPhotos(image: stitchedImage)

                // Clean up temp video
                try? FileManager.default.removeItem(at: videoURL)

                // Save result image to documents for history
                let filename = "\(session.id.uuidString).png"
                if let data = stitchedImage.pngData(),
                   let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try data.write(to: docs.appendingPathComponent(filename))
                }

                // Update session
                if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
                    sessions[idx].status = .completed
                    sessions[idx].resultImageFilename = filename
                }

                await MainActor.run {
                    progressView.progress = 1.0

                    if UserSettings.previewBeforeSave {
                        // Show preview
                        let previewVC = PreviewViewController(image: stitchedImage, session: sessions.first(where: { $0.id == session.id })!)
                        navigationController?.pushViewController(previewVC, animated: true)
                        statusLabel.text = "Preview"
                    } else {
                        statusLabel.text = "Saved!"
                    }

                    isProcessing = false
                    recordButton.isEnabled = true
                    tableView.reloadData()

                    notificationManager.notifyProcessingComplete(
                        sessionId: session.id.uuidString,
                        success: true
                    )

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.progressView.isHidden = true
                        if !UserSettings.previewBeforeSave {
                            self?.statusLabel.text = "Tap to start recording"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
                        sessions[idx].status = .failed
                    }
                    isProcessing = false
                    recordButton.isEnabled = true
                    progressView.isHidden = true
                    statusLabel.text = "Tap to start recording"
                    tableView.reloadData()

                    notificationManager.notifyProcessingComplete(
                        sessionId: session.id.uuidString,
                        success: false
                    )

                    showAlert(title: "Processing Failed", message: error.localizedDescription)
                }
            }
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func requestPermissions() {
        Task {
            try? await notificationManager.requestAuthorization()
        }
    }

    // MARK: - Persistence
    private func loadSessions() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let sessionsURL = docs.appendingPathComponent("sessions.json")
        if let data = try? Data(contentsOf: sessionsURL),
           let loaded = try? JSONDecoder().decode([RecordingSession].self, from: data) {
            sessions = loaded
        }
    }

    private func saveSessions() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let sessionsURL = docs.appendingPathComponent("sessions.json")
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: sessionsURL)
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

        let previewVC = PreviewViewController(image: image, session: session)
        navigationController?.pushViewController(previewVC, animated: true)
    }
}
