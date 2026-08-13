import QuartzCore
import UIKit

@MainActor
final class SiriUSV2ReelSymbolPool {
    let faces: [SiriUSV2ReelSymbolLayer]
    let seams: [CAGradientLayer]

    init(count: Int) {
        faces = (0..<count).map { _ in SiriUSV2ReelSymbolLayer() }
        seams = (0..<count).map { _ in
            let layer = CAGradientLayer()
            layer.colors = [
                UIColor.clear.cgColor,
                UIColor.white.withAlphaComponent(0.34).cgColor,
                UIColor.black.withAlphaComponent(0.12).cgColor,
                UIColor.clear.cgColor
            ]
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
            layer.actions = [
                "bounds": NSNull(),
                "position": NSNull(),
                "transform": NSNull(),
                "opacity": NSNull()
            ]
            return layer
        }
    }

    func install(in transformLayer: CATransformLayer) {
        for face in faces {
            transformLayer.addSublayer(face)
        }
        for seam in seams {
            transformLayer.addSublayer(seam)
        }
    }
}
