import SwiftUI
import AVFoundation
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(
        _ uiViewController: QRScannerViewController,
        context: Context
    ) {}
}

final class QRScannerViewController:
    UIViewController,
    AVCaptureMetadataOutputObjectsDelegate {

    var onCodeScanned: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(
        label: "com.sirius.qrscanner.session",
        qos: .userInitiated
    )

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScannedCode = false
    private var isConfigured = false

    private let overlayView = UIView()
    private let scanFrameView = UIView()
    private let scanLineView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statusLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let permissionButton = UIButton(type: .system)

    private var scanLineTopConstraint: NSLayoutConstraint?
    private var scanLineBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupOverlay()
        setupCloseButton()
        setupPermissionButton()
        checkCameraPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlayMask()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hasScannedCode = false

        if isConfigured {
            startSession()
            startScanLineAnimation()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
        scanLineView.layer.removeAllAnimations()
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureCamera()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }

        case .denied, .restricted:
            showPermissionDenied()

        @unknown default:
            showPermissionDenied()
        }
    }

    private func configureCamera() {
        guard !isConfigured else {
            startSession()
            return
        }

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showStatus(
                text: "カメラを利用できません",
                systemImage: "camera.fill",
                isError: true
            )
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            session.beginConfiguration()
            session.sessionPreset = .high

            guard session.canAddInput(videoInput) else {
                session.commitConfiguration()
                showStatus(
                    text: "カメラ入力を開始できません",
                    systemImage: "exclamationmark.triangle.fill",
                    isError: true
                )
                return
            }

            session.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()

            guard session.canAddOutput(metadataOutput) else {
                session.commitConfiguration()
                showStatus(
                    text: "QRコード読み取りを開始できません",
                    systemImage: "qrcode.viewfinder",
                    isError: true
                )
                return
            }

            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(
                self,
                queue: .main
            )
            metadataOutput.metadataObjectTypes = [.qr]

            session.commitConfiguration()

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer

            isConfigured = true
            permissionButton.isHidden = true

            showStatus(
                text: "QRコードを探しています",
                systemImage: "viewfinder",
                isError: false
            )

            startSession()
            startScanLineAnimation()
        } catch {
            showStatus(
                text: "カメラの起動に失敗しました",
                systemImage: "exclamationmark.triangle.fill",
                isError: true
            )
        }
    }

    private func startSession() {
        guard isConfigured, !session.isRunning else {
            return
        }

        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func stopSession() {
        guard session.isRunning else {
            return
        }

        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func setupOverlay() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)

        scanFrameView.translatesAutoresizingMaskIntoConstraints = false
        scanFrameView.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        scanFrameView.layer.cornerRadius = 28
        scanFrameView.layer.borderWidth = 2
        scanFrameView.layer.borderColor = UIColor.systemCyan.cgColor
        scanFrameView.layer.shadowColor = UIColor.systemCyan.cgColor
        scanFrameView.layer.shadowOpacity = 0.55
        scanFrameView.layer.shadowRadius = 18
        scanFrameView.layer.shadowOffset = .zero
        overlayView.addSubview(scanFrameView)

        scanLineView.translatesAutoresizingMaskIntoConstraints = false
        scanLineView.backgroundColor = UIColor.systemCyan
        scanLineView.layer.cornerRadius = 2
        scanLineView.layer.shadowColor = UIColor.systemCyan.cgColor
        scanLineView.layer.shadowOpacity = 0.9
        scanLineView.layer.shadowRadius = 8
        scanFrameView.addSubview(scanLineView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "QR CHECK-IN"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(
            ofSize: 28,
            weight: .black
        )
        titleLabel.textAlignment = .center
        overlayView.addSubview(titleLabel)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "QRコードを枠内に合わせてください"
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        descriptionLabel.font = .systemFont(
            ofSize: 15,
            weight: .semibold
        )
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        overlayView.addSubview(descriptionLabel)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(
            ofSize: 13,
            weight: .bold
        )
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        statusLabel.layer.cornerRadius = 16
        statusLabel.clipsToBounds = true
        overlayView.addSubview(statusLabel)

        let topCornerLeft = makeCornerView()
        let topCornerRight = makeCornerView()
        let bottomCornerLeft = makeCornerView()
        let bottomCornerRight = makeCornerView()

        scanFrameView.addSubview(topCornerLeft)
        scanFrameView.addSubview(topCornerRight)
        scanFrameView.addSubview(bottomCornerLeft)
        scanFrameView.addSubview(bottomCornerRight)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 42
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: overlayView.leadingAnchor,
                constant: 24
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: overlayView.trailingAnchor,
                constant: -24
            ),

            scanFrameView.centerXAnchor.constraint(
                equalTo: overlayView.centerXAnchor
            ),
            scanFrameView.centerYAnchor.constraint(
                equalTo: overlayView.centerYAnchor,
                constant: -12
            ),
            scanFrameView.widthAnchor.constraint(
                equalToConstant: 274
            ),
            scanFrameView.heightAnchor.constraint(
                equalToConstant: 274
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: scanFrameView.bottomAnchor,
                constant: 28
            ),
            descriptionLabel.leadingAnchor.constraint(
                equalTo: overlayView.leadingAnchor,
                constant: 30
            ),
            descriptionLabel.trailingAnchor.constraint(
                equalTo: overlayView.trailingAnchor,
                constant: -30
            ),

            statusLabel.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 16
            ),
            statusLabel.centerXAnchor.constraint(
                equalTo: overlayView.centerXAnchor
            ),
            statusLabel.widthAnchor.constraint(
                lessThanOrEqualToConstant: 260
            ),
            statusLabel.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 34
            ),

            scanLineView.leadingAnchor.constraint(
                equalTo: scanFrameView.leadingAnchor,
                constant: 20
            ),
            scanLineView.trailingAnchor.constraint(
                equalTo: scanFrameView.trailingAnchor,
                constant: -20
            ),
            scanLineView.heightAnchor.constraint(
                equalToConstant: 3
            )
        ])

        scanLineTopConstraint = scanLineView.topAnchor.constraint(
            equalTo: scanFrameView.topAnchor,
            constant: 22
        )
        scanLineTopConstraint?.isActive = true

        setupCornerConstraints(
            view: topCornerLeft,
            horizontalAnchor: topCornerLeft.leadingAnchor,
            horizontalTarget: scanFrameView.leadingAnchor,
            horizontalConstant: 14,
            verticalAnchor: topCornerLeft.topAnchor,
            verticalTarget: scanFrameView.topAnchor,
            verticalConstant: 14
        )

        setupCornerConstraints(
            view: topCornerRight,
            horizontalAnchor: topCornerRight.trailingAnchor,
            horizontalTarget: scanFrameView.trailingAnchor,
            horizontalConstant: -14,
            verticalAnchor: topCornerRight.topAnchor,
            verticalTarget: scanFrameView.topAnchor,
            verticalConstant: 14
        )

        setupCornerConstraints(
            view: bottomCornerLeft,
            horizontalAnchor: bottomCornerLeft.leadingAnchor,
            horizontalTarget: scanFrameView.leadingAnchor,
            horizontalConstant: 14,
            verticalAnchor: bottomCornerLeft.bottomAnchor,
            verticalTarget: scanFrameView.bottomAnchor,
            verticalConstant: -14
        )

        setupCornerConstraints(
            view: bottomCornerRight,
            horizontalAnchor: bottomCornerRight.trailingAnchor,
            horizontalTarget: scanFrameView.trailingAnchor,
            horizontalConstant: -14,
            verticalAnchor: bottomCornerRight.bottomAnchor,
            verticalTarget: scanFrameView.bottomAnchor,
            verticalConstant: -14
        )
    }

    private func makeCornerView() -> UIView {
        let corner = UIView()
        corner.translatesAutoresizingMaskIntoConstraints = false
        corner.backgroundColor = .white
        corner.layer.cornerRadius = 3
        corner.layer.shadowColor = UIColor.systemCyan.cgColor
        corner.layer.shadowOpacity = 0.9
        corner.layer.shadowRadius = 7
        return corner
    }

    private func setupCornerConstraints(
        view: UIView,
        horizontalAnchor: NSLayoutXAxisAnchor,
        horizontalTarget: NSLayoutXAxisAnchor,
        horizontalConstant: CGFloat,
        verticalAnchor: NSLayoutYAxisAnchor,
        verticalTarget: NSLayoutYAxisAnchor,
        verticalConstant: CGFloat
    ) {
        NSLayoutConstraint.activate([
            horizontalAnchor.constraint(
                equalTo: horizontalTarget,
                constant: horizontalConstant
            ),
            verticalAnchor.constraint(
                equalTo: verticalTarget,
                constant: verticalConstant
            ),
            view.widthAnchor.constraint(equalToConstant: 26),
            view.heightAnchor.constraint(equalToConstant: 5)
        ])
    }

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        var configuration = UIButton.Configuration.filled()
        configuration.title = "閉じる"
        configuration.image = UIImage(systemName: "xmark")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = UIColor.black.withAlphaComponent(0.45)
        configuration.cornerStyle = .capsule
        closeButton.configuration = configuration

        closeButton.addTarget(
            self,
            action: #selector(closeTapped),
            for: .touchUpInside
        )

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 14
            ),
            closeButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -18
            ),
            closeButton.heightAnchor.constraint(
                equalToConstant: 44
            )
        ])
    }

    private func setupPermissionButton() {
        permissionButton.translatesAutoresizingMaskIntoConstraints = false
        permissionButton.isHidden = true

        var configuration = UIButton.Configuration.filled()
        configuration.title = "設定を開く"
        configuration.image = UIImage(systemName: "gearshape.fill")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .systemBlue
        configuration.cornerStyle = .large
        permissionButton.configuration = configuration

        permissionButton.addTarget(
            self,
            action: #selector(openSettings),
            for: .touchUpInside
        )

        view.addSubview(permissionButton)

        NSLayoutConstraint.activate([
            permissionButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            permissionButton.topAnchor.constraint(
                equalTo: statusLabel.bottomAnchor,
                constant: 18
            ),
            permissionButton.heightAnchor.constraint(
                equalToConstant: 48
            )
        ])
    }

    private func updateOverlayMask() {
        let maskLayer = CAShapeLayer()
        let fullPath = UIBezierPath(rect: overlayView.bounds)

        let scanFrame = overlayView.convert(
            scanFrameView.bounds,
            from: scanFrameView
        )

        let transparentPath = UIBezierPath(
            roundedRect: scanFrame,
            cornerRadius: 28
        )

        fullPath.append(transparentPath)
        fullPath.usesEvenOddFillRule = true

        maskLayer.path = fullPath.cgPath
        maskLayer.fillRule = .evenOdd

        let dimLayer = CAShapeLayer()
        dimLayer.path = fullPath.cgPath
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.56).cgColor

        overlayView.layer.sublayers?
            .filter { $0.name == "scannerDimLayer" }
            .forEach { $0.removeFromSuperlayer() }

        dimLayer.name = "scannerDimLayer"
        overlayView.layer.insertSublayer(dimLayer, at: 0)
    }

    private func startScanLineAnimation() {
        scanLineView.layer.removeAllAnimations()

        let animation = CABasicAnimation(
            keyPath: "transform.translation.y"
        )
        animation.fromValue = 0
        animation.toValue = 226
        animation.duration = 2.1
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )

        scanLineView.layer.add(
            animation,
            forKey: "scanLine"
        )
    }

    private func showPermissionDenied() {
        permissionButton.isHidden = false

        showStatus(
            text: "カメラへのアクセスを許可してください",
            systemImage: "camera.fill",
            isError: true
        )
    }

    private func showStatus(
        text: String,
        systemImage: String,
        isError: Bool
    ) {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemImage)?
            .withTintColor(
                isError ? .systemRed : .systemCyan,
                renderingMode: .alwaysOriginal
            )

        let attributedText = NSMutableAttributedString(
            attachment: attachment
        )
        attributedText.append(
            NSAttributedString(
                string: "  \(text)",
                attributes: [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(
                        ofSize: 13,
                        weight: .bold
                    )
                ]
            )
        )

        statusLabel.attributedText = attributedText
        statusLabel.layer.borderWidth = 1
        statusLabel.layer.borderColor = (
            isError
                ? UIColor.systemRed.withAlphaComponent(0.45)
                : UIColor.systemCyan.withAlphaComponent(0.35)
        ).cgColor
    }

    @objc
    private func closeTapped() {
        stopSession()
        onCancel?()
    }

    @objc
    private func openSettings() {
        guard let settingsURL = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScannedCode,
              let metadataObject =
                metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        hasScannedCode = true
        stopSession()

        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        feedback.notificationOccurred(.success)

        showStatus(
            text: "QRコードを読み取りました",
            systemImage: "checkmark.circle.fill",
            isError: false
        )

        UIView.animate(
            withDuration: 0.16,
            animations: {
                self.scanFrameView.transform =
                    CGAffineTransform(scaleX: 1.04, y: 1.04)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.16,
                    animations: {
                        self.scanFrameView.transform = .identity
                    },
                    completion: { _ in
                        self.onCodeScanned?(code)
                    }
                )
            }
        )
    }
}

#Preview {
    QRScannerView(
        onCodeScanned: { code in
            print(code)
        },
        onCancel: {}
    )
}
