import UIKit

final class SessionCell: UITableViewCell {

    static let reuseIdentifier = "SessionCell"

    private let thumbnailView = UIImageView()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    private let statusBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        accessoryType = .disclosureIndicator

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 8
        thumbnailView.backgroundColor = .systemGray6
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        statusBadge.font = .systemFont(ofSize: 11, weight: .semibold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 4
        statusBadge.clipsToBounds = true
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(statusBadge)

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 48),
            thumbnailView.heightAnchor.constraint(equalToConstant: 64),

            dateLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            dateLabel.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: -8),

            durationLabel.leadingAnchor.constraint(equalTo: dateLabel.leadingAnchor),
            durationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),

            statusBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusBadge.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
            statusBadge.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    func configure(with session: RecordingSession, thumbnail: UIImage?) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: session.date)

        let mins = Int(session.duration) / 60
        let secs = Int(session.duration) % 60
        durationLabel.text = "Duration: \(mins)m \(secs)s"

        switch session.status {
        case .completed:
            statusBadge.text = " Done "
            statusBadge.backgroundColor = .systemGreen.withAlphaComponent(0.15)
            statusBadge.textColor = .systemGreen
        case .processing:
            statusBadge.text = " Processing "
            statusBadge.backgroundColor = .systemOrange.withAlphaComponent(0.15)
            statusBadge.textColor = .systemOrange
        case .failed:
            statusBadge.text = " Failed "
            statusBadge.backgroundColor = .systemRed.withAlphaComponent(0.15)
            statusBadge.textColor = .systemRed
        case .recording:
            statusBadge.text = " Recording "
            statusBadge.backgroundColor = .systemBlue.withAlphaComponent(0.15)
            statusBadge.textColor = .systemBlue
        }

        thumbnailView.image = thumbnail
    }
}
