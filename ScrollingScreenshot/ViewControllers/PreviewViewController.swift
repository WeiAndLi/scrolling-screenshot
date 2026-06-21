import UIKit
import Photos

final class PreviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let image: UIImage
    private let session: RecordingSession

    init(image: UIImage, session: RecordingSession) {
        self.image = image
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "预览"

        let discardButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(discardTapped)
        )
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        let saveButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.down"),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        toolbarItems = [discardButton, .flexibleSpace(), shareButton, .flexibleSpace(), saveButton]
        navigationController?.isToolbarHidden = false

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    @objc private func saveTapped() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized, let self = self else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: self.image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        let alert = UIAlertController(title: "已保存", message: "长截图已保存到系统相册", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "好的", style: .default) { [weak self] _ in
                            self?.navigationController?.popViewController(animated: true)
                        })
                        self.present(alert, animated: true)
                    } else {
                        let alert = UIAlertController(title: "保存失败", message: error?.localizedDescription ?? "未知错误", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "好的", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    @objc private func shareTapped() {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = toolbarItems?.last
        }
        present(activityVC, animated: true)
    }

    @objc private func discardTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension PreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
