import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupCloseButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if session.isRunning {
            session.stopRunning()
        }
    }

    func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        let guideView = UIView()
        guideView.layer.borderColor = UIColor.white.cgColor
        guideView.layer.borderWidth = 3
        guideView.layer.cornerRadius = 18
        guideView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideView)

        NSLayoutConstraint.activate([
            guideView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            guideView.widthAnchor.constraint(equalToConstant: 240),
            guideView.heightAnchor.constraint(equalToConstant: 240)
        ])

        let label = UILabel()
        label.text = "QRコードを枠内に合わせてください"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: guideView.bottomAnchor, constant: 24),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func setupCloseButton() {
        let button = UIButton(type: .system)
        button.setTitle("閉じる", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 18
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc func closeTapped() {
        onCancel?()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        session.stopRunning()
        onCodeScanned?(code)
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
