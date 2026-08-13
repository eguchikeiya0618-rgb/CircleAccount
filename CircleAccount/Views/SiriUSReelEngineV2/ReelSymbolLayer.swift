import QuartzCore
import UIKit

@MainActor
final class SiriUSV2ReelSymbolLayer: CALayer {
    private static let proofArtworkScale: CGFloat = 1.0
    private var didLogFinalGeometry = false
    private let upperPersistence = CALayer()
    private let lowerPersistence = CALayer()
    private let upperNearPersistence = CALayer()
    private let lowerNearPersistence = CALayer()
    private let bevelShadowLayer = CALayer()
    private let artworkLayer = CALayer()
    private let contrastPickupLayer = CALayer()
    private let metalHighlightLayer = CAGradientLayer()
    private let metalHighlightMask = CALayer()
    private let cylindricalShade = CAGradientLayer()
    private let glassPickup = CAGradientLayer()

    override init() {
        super.init()
        masksToBounds = false
        actions = disabledActions

        for layer in [
            upperPersistence,
            lowerPersistence,
            upperNearPersistence,
            lowerNearPersistence,
            bevelShadowLayer,
            artworkLayer,
            contrastPickupLayer
        ] {
            layer.contentsGravity = .resizeAspect
            layer.magnificationFilter = .linear
            layer.minificationFilter = .trilinear
            layer.actions = disabledActions
            addSublayer(layer)
        }

        metalHighlightLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.80).cgColor,
            UIColor.white.withAlphaComponent(0.12).cgColor,
            UIColor.clear.cgColor
        ]
        metalHighlightLayer.locations = [0, 0.38, 0.51, 1]
        metalHighlightLayer.startPoint = CGPoint(x: 0.05, y: 0.08)
        metalHighlightLayer.endPoint = CGPoint(x: 0.95, y: 0.92)
        metalHighlightLayer.mask = metalHighlightMask
        metalHighlightLayer.actions = disabledActions
        metalHighlightMask.contentsGravity = .resizeAspect
        metalHighlightMask.actions = disabledActions
        addSublayer(metalHighlightLayer)

        cylindricalShade.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        cylindricalShade.locations = [0, 0.48, 1]
        cylindricalShade.startPoint = CGPoint(x: 0.5, y: 0)
        cylindricalShade.endPoint = CGPoint(x: 0.5, y: 1)
        cylindricalShade.actions = disabledActions
        addSublayer(cylindricalShade)

        glassPickup.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.08).cgColor
        ]
        glassPickup.startPoint = CGPoint(x: 0.5, y: 0)
        glassPickup.endPoint = CGPoint(x: 0.5, y: 1)
        glassPickup.actions = disabledActions
        addSublayer(glassPickup)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSublayers() {
        super.layoutSublayers()
        // The resolved CGImage already contains its physical transparent
        // margins. Keep every presentation layer at full-cell geometry so the
        // parent drum transform can never cancel the artwork reduction.
        let artworkBounds = bounds
        let artworkCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        for layer in [
            upperPersistence,
            lowerPersistence,
            upperNearPersistence,
            lowerNearPersistence,
            artworkLayer,
            contrastPickupLayer,
            metalHighlightLayer
        ] {
            layer.bounds = artworkBounds
            layer.position = artworkCenter
            layer.transform = CATransform3DMakeScale(
                Self.proofArtworkScale,
                Self.proofArtworkScale,
                1
            )
        }
        bevelShadowLayer.bounds = artworkBounds
        bevelShadowLayer.position = CGPoint(
            x: artworkCenter.x,
            y: artworkCenter.y + 1.4
        )
        bevelShadowLayer.transform = CATransform3DMakeScale(
            Self.proofArtworkScale,
            Self.proofArtworkScale,
            1
        )
        metalHighlightMask.frame = metalHighlightLayer.bounds
        cylindricalShade.frame = bounds
        glassPickup.frame = bounds
    }

    func setImage(_ image: UIImage) {
        let contents = image.cgImage
        upperPersistence.contents = contents
        lowerPersistence.contents = contents
        upperNearPersistence.contents = contents
        lowerNearPersistence.contents = contents
        bevelShadowLayer.contents = contents
        artworkLayer.contents = contents
        contrastPickupLayer.contents = contents
        metalHighlightMask.contents = contents
    }

    func setAppearance(
        darkness: CGFloat,
        velocity: CGFloat,
        impact: CGFloat,
        centrality: CGFloat,
        isStopped: Bool,
        isSeven: Bool
    ) {
        // Two low-opacity persistence samples bridge the temporal gap between
        // presented frames. They follow the rotating face, so this reads as
        // optical persistence on a drum rather than a detached scrolling blur.
        let persistenceDistance = velocity * 6.2
        let nearPersistenceDistance = persistenceDistance * 0.46
        upperPersistence.position = CGPoint(
            x: bounds.midX,
            y: bounds.midY - persistenceDistance
        )
        lowerPersistence.position = CGPoint(
            x: bounds.midX,
            y: bounds.midY + persistenceDistance
        )
        upperNearPersistence.position = CGPoint(
            x: bounds.midX,
            y: bounds.midY - nearPersistenceDistance
        )
        lowerNearPersistence.position = CGPoint(
            x: bounds.midX,
            y: bounds.midY + nearPersistenceDistance
        )
        upperPersistence.opacity = Float(velocity * 0.10)
        lowerPersistence.opacity = Float(velocity * 0.10)
        upperNearPersistence.opacity = Float(velocity * 0.12)
        lowerNearPersistence.opacity = Float(velocity * 0.12)
        artworkLayer.opacity = Float(1 - velocity * 0.075)
        bevelShadowLayer.opacity = Float(
            centrality * (isSeven ? (isStopped ? 0.43 : 0.25) : 0.10)
        )
        bevelShadowLayer.shadowColor = isSeven
            ? UIColor(red: 1.0, green: 0.82, blue: 0.46, alpha: 1).cgColor
            : UIColor.clear.cgColor
        bevelShadowLayer.shadowOffset = .zero
        bevelShadowLayer.shadowRadius = isSeven && isStopped ? 5.5 : 2.0
        bevelShadowLayer.shadowOpacity = isSeven
            ? Float(centrality * (isStopped ? 0.42 : 0.10))
            : 0
        contrastPickupLayer.opacity = Float(
            centrality * (isStopped ? (isSeven ? 0.18 : 0.095) : 0.045)
        )
        metalHighlightLayer.opacity = Float(
            centrality * (isStopped ? (isSeven ? 0.46 : 0.16) : 0.085)
        )
        artworkLayer.shadowColor = UIColor.black.cgColor
        artworkLayer.shadowOffset = CGSize(width: 0, height: isSeven ? 1.5 : 0.7)
        artworkLayer.shadowRadius = isSeven ? 2.2 : 1.1
        artworkLayer.shadowOpacity = Float(
            (isStopped ? (isSeven ? 0.50 : 0.22) : 0.14) * centrality
        )
        cylindricalShade.opacity = Float(min(0.84, darkness + velocity * 0.05))
        glassPickup.opacity = Float(min(1, 0.42 + impact * 0.58))

#if DEBUG
        if !didLogFinalGeometry {
            layoutIfNeeded()
            didLogFinalGeometry = true
            print(
                "[SiriUSV2][SymbolGeometry] "
                    + "faceFrame=\(frame) faceBounds=\(bounds) "
                    + "artworkFrame=\(artworkLayer.frame) "
                    + "artworkBounds=\(artworkLayer.bounds) "
                    + "artworkTransform=\(artworkLayer.transform) "
                    + "contentsGravity=\(artworkLayer.contentsGravity.rawValue)"
            )
        }
#endif
    }

    private var disabledActions: [String: CAAction] {
        [
            "bounds": NSNull(),
            "position": NSNull(),
            "transform": NSNull(),
            "opacity": NSNull(),
            "contents": NSNull()
        ]
    }
}
