import SwiftUI
import UIKit

@MainActor
final class SiriUSV2ReelDrumUIView: UIView {
    private let renderer: SiriUSV2ReelRenderer
    private let apertureMaskLayer = CAShapeLayer()
    private var latestSnapshot: SiriUSV2ReelRenderSnapshot?

    init(configuration: SiriUSV2ReelConfiguration) {
        renderer = SiriUSV2ReelRenderer(configuration: configuration)
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = true
        layer.masksToBounds = true
        apertureMaskLayer.fillColor = UIColor.black.cgColor
        apertureMaskLayer.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "path": NSNull()
        ]
        layer.mask = apertureMaskLayer
        renderer.install(in: layer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The aperture consumes the entire UIView. An inset here exposed the
        // housing surface as a false lower drum edge.
        let aperture = bounds
        apertureMaskLayer.frame = bounds
        apertureMaskLayer.path = UIBezierPath(
            roundedRect: aperture,
            cornerRadius: 9
        ).cgPath
        renderer.layout(in: bounds, scale: currentDisplayScale)
        if let latestSnapshot {
            renderer.render(latestSnapshot, scale: currentDisplayScale)
        }
    }

    func render(_ snapshot: SiriUSV2ReelRenderSnapshot) {
        latestSnapshot = snapshot
        renderer.render(snapshot, scale: currentDisplayScale)
    }

    private var currentDisplayScale: CGFloat {
        window?.windowScene?.screen.scale ?? traitCollection.displayScale
    }
}

struct SiriUSV2ReelDrumView: UIViewRepresentable {
    let inputs: SiriUSV2ReelInputs

    func makeCoordinator() -> Coordinator {
        Coordinator(inputs: inputs)
    }

    func makeUIView(context: Context) -> SiriUSV2ReelDrumUIView {
        let view = SiriUSV2ReelDrumUIView(
            configuration: SiriUSV2ReelConfiguration(reelIndex: inputs.reelIndex)
        )
        context.coordinator.attach(view)
        return view
    }

    func updateUIView(_ uiView: SiriUSV2ReelDrumUIView, context: Context) {
        context.coordinator.update(inputs)
    }

    static func dismantleUIView(_ uiView: SiriUSV2ReelDrumUIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator: NSObject, SiriUSV2ReelFrameObserver {
        private let controller: SiriUSV2ReelController
        private weak var view: SiriUSV2ReelDrumUIView?
        private var lastTimestamp: CFTimeInterval?
        private var accumulator: TimeInterval = 0
        private var isRegistered = false

        // Four physics samples per 120 Hz presentation frame leave enough
        // temporal resolution for the brake and locking recoil without making
        // SwiftUI participate in frame-by-frame rendering.
        private let fixedStep: TimeInterval = 1.0 / 480.0
        private let maximumCatchUp: TimeInterval = 1.0 / 20.0

        init(inputs: SiriUSV2ReelInputs) {
            controller = SiriUSV2ReelController(inputs: inputs)
        }

        func attach(_ view: SiriUSV2ReelDrumUIView) {
            self.view = view
            view.render(controller.makeSnapshot())
            registerClock()
        }

        func detach() {
            if isRegistered {
                SiriUSV2ReelFrameClock.shared.remove(self)
                isRegistered = false
            }
            view = nil
            lastTimestamp = nil
        }

        func update(_ inputs: SiriUSV2ReelInputs) {
            controller.apply(inputs)
            view?.render(controller.makeSnapshot())
            if inputs.isSpinning || !inputs.isStopped {
                registerClock()
            } else if controller.state != .stopped {
                registerClock()
            }
        }

        func reelFrameClockDidTick(timestamp: CFTimeInterval) {
            guard let view else {
                detach()
                return
            }

            guard let previous = lastTimestamp else {
                lastTimestamp = timestamp
                view.render(controller.makeSnapshot())
                return
            }

            let elapsed = min(max(timestamp - previous, 0), maximumCatchUp)
            lastTimestamp = timestamp
            accumulator += elapsed

            var steps = 0
            while accumulator >= fixedStep, steps < 32 {
                controller.fixedStep(fixedStep)
                accumulator -= fixedStep
                steps += 1
            }

            view.render(controller.makeSnapshot(predictionTime: accumulator))

            if controller.state == .stopped || controller.state == .idle {
                SiriUSV2ReelFrameClock.shared.remove(self)
                isRegistered = false
                lastTimestamp = nil
                accumulator = 0
            }
        }

        private func registerClock() {
            guard !isRegistered else { return }
            SiriUSV2ReelFrameClock.shared.add(self)
            isRegistered = true
            lastTimestamp = nil
        }
    }
}
