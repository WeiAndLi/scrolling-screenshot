import UIKit

final class RecordButton: UIControl {

    private let outerCircle = CALayer()
    private let innerCircle = CALayer()
    private var pulseAnimation: CABasicAnimation?

    var isRecording: Bool = false {
        didSet { updateAppearance(animated: true) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Outer circle (white ring)
        outerCircle.frame = bounds
        outerCircle.cornerRadius = bounds.width / 2
        outerCircle.borderWidth = 6
        outerCircle.borderColor = UIColor.white.cgColor
        outerCircle.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(outerCircle)

        // Inner circle (red fill)
        let inset: CGFloat = 12
        innerCircle.frame = bounds.insetBy(dx: inset, dy: inset)
        innerCircle.cornerRadius = innerCircle.frame.width / 2
        innerCircle.backgroundColor = UIColor.systemRed.cgColor
        layer.addSublayer(innerCircle)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        outerCircle.frame = bounds
        outerCircle.cornerRadius = bounds.width / 2
        let inset: CGFloat = isRecording ? 20 : 12
        innerCircle.frame = bounds.insetBy(dx: inset, dy: inset)
        innerCircle.cornerRadius = innerCircle.frame.width / 2
    }

    private func updateAppearance(animated: Bool) {
        let inset: CGFloat = isRecording ? 20 : 12
        let cornerRadius: CGFloat = isRecording ? 6 : innerCircle.frame.width / 2

        let animations = {
            self.innerCircle.frame = self.bounds.insetBy(dx: inset, dy: inset)
            self.innerCircle.cornerRadius = cornerRadius
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: animations)
        } else {
            animations()
        }

        if isRecording {
            startPulse()
        } else {
            stopPulse()
        }
    }

    private func startPulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.05
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        outerCircle.add(pulse, forKey: "pulse")
        pulseAnimation = pulse
    }

    private func stopPulse() {
        outerCircle.removeAnimation(forKey: "pulse")
        pulseAnimation = nil
    }

    @objc private func handleTap() {
        sendActions(for: .touchUpInside)
    }
}
