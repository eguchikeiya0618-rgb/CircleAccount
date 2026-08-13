import QuartzCore
import UIKit

@MainActor
final class SiriUSV2ReelRenderer {
    private let configuration: SiriUSV2ReelConfiguration
    private let substrateLayer = CAGradientLayer()
    private let substrateTextureLayer = CAGradientLayer()
    // CATransformLayer keeps every symbol face in one genuine 3D hierarchy.
    // The drum is projected once at the parent, never as independent 2D cards.
    private let perspectiveLayer = CATransformLayer()
    private let symbolPool: SiriUSV2ReelSymbolPool
    private let topFadeLayer = CAGradientLayer()
    private let bottomFadeLayer = CAGradientLayer()
    private let leftShadeLayer = CAGradientLayer()
    private let rightShadeLayer = CAGradientLayer()
    private let resolver = SiriUSV2ReelSymbolResolver.shared

    private var bounds: CGRect = .zero
    private var viewportBounds: CGRect = .zero
    private var renderedSymbols: [String?]

    init(configuration: SiriUSV2ReelConfiguration) {
        self.configuration = configuration
        symbolPool = SiriUSV2ReelSymbolPool(count: configuration.visibleFaceCount)
        renderedSymbols = Array(repeating: nil, count: configuration.visibleFaceCount)

        perspectiveLayer.masksToBounds = false
        perspectiveLayer.actions = disabledActions

        symbolPool.install(in: perspectiveLayer)

        configureEdgeLayers()
    }

    func install(in hostLayer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hostLayer.addSublayer(substrateLayer)
        hostLayer.addSublayer(substrateTextureLayer)
        hostLayer.addSublayer(perspectiveLayer)
        hostLayer.addSublayer(leftShadeLayer)
        hostLayer.addSublayer(rightShadeLayer)
        hostLayer.addSublayer(topFadeLayer)
        hostLayer.addSublayer(bottomFadeLayer)
        CATransaction.commit()
    }

    func layout(in newBounds: CGRect, scale: CGFloat) {
        guard newBounds.width > 0, newBounds.height > 0 else { return }
        viewportBounds = newBounds
        let guardHeight = newBounds.height * configuration.guardHeightRatio
        bounds = CGRect(
            x: 0,
            y: 0,
            width: newBounds.width,
            height: newBounds.height + guardHeight * 2
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        perspectiveLayer.frame = CGRect(
            x: 0,
            y: -guardHeight,
            width: newBounds.width,
            height: bounds.height
        )
        perspectiveLayer.sublayerTransform = perspectiveTransform
        substrateLayer.frame = newBounds
        substrateTextureLayer.frame = newBounds

        let drumGeometryHeight = max(
            newBounds.height,
            configuration.minimumDrumGeometryHeight
        )
        let faceSize = CGSize(
            width: newBounds.width,
            height: drumGeometryHeight * 0.32
        )
        for face in symbolPool.faces {
            face.bounds = CGRect(origin: .zero, size: faceSize)
            face.contentsScale = scale
            face.setNeedsLayout()
            face.layoutIfNeeded()
        }

        for seam in symbolPool.seams {
            seam.bounds = CGRect(
                x: 0,
                y: 0,
                width: newBounds.width * 0.86,
                height: 1.15
            )
        }

        // Darken only the partial edge symbols; the central three remain
        // readable while the offscreen guards wrap behind the aperture.
        let verticalFadeHeight = newBounds.height * 0.17
        topFadeLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: newBounds.width,
            height: verticalFadeHeight
        )
        bottomFadeLayer.frame = CGRect(
            x: 0,
            y: newBounds.height - verticalFadeHeight,
            width: newBounds.width,
            height: verticalFadeHeight
        )
        leftShadeLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: newBounds.width * 0.18,
            height: newBounds.height
        )
        rightShadeLayer.frame = CGRect(
            x: newBounds.width * 0.82,
            y: 0,
            width: newBounds.width * 0.18,
            height: newBounds.height
        )
        CATransaction.commit()
    }

    func render(_ snapshot: SiriUSV2ReelRenderSnapshot, scale: CGFloat) {
        guard !bounds.isEmpty else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Radius is intentionally independent from the aperture height. The
        // housing masks a full-size drum instead of scaling the drum to fit.
        let drumGeometryHeight = max(
            viewportBounds.height,
            configuration.minimumDrumGeometryHeight
        )
        let radius = drumGeometryHeight * configuration.drumRadiusRatio
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        for index in symbolPool.faces.indices {
            let faceLayer = symbolPool.faces[index]
            guard snapshot.faces.indices.contains(index) else {
                faceLayer.isHidden = true
                symbolPool.seams[index].isHidden = true
                continue
            }

            let face = snapshot.faces[index]
            let angle = face.localAngle
            let cosine = cos(angle)
            let depth = max(0, cosine)

            guard depth > 0.012 else {
                faceLayer.isHidden = true
                symbolPool.seams[index].isHidden = true
                continue
            }

            faceLayer.isHidden = false
            if renderedSymbols[index] != face.symbol {
                faceLayer.setImage(resolver.image(for: face.symbol, scale: scale))
                renderedSymbols[index] = face.symbol
            }

            let y = center.y + radius * CGFloat(sin(angle))
            let z = radius * CGFloat(depth)
            let centrality = CGFloat(pow(depth, 3.45))
            let horizontalScale = 0.08 + CGFloat(pow(depth, 5.15)) * 0.92
            let verticalScale = 0.10 + CGFloat(pow(depth, 4.25)) * 0.90
            let visibility = pow(depth, 1.32)
            let darkness = CGFloat(pow(1 - depth, 0.68)) * 1.30
            let isSeven = face.symbol == "7"
                || face.symbol == "7️⃣"
                || face.symbol == "🌈7"
                || face.symbol == "🌈7️⃣"
            let stoppedAtCenter = snapshot.state == .stopped
                || snapshot.state == .idle
            let centerScale: CGFloat = 1 + centrality
                * (stoppedAtCenter ? (isSeven ? 0.112 : 0.058) : 0.032)

            faceLayer.position = CGPoint(x: center.x, y: y)
            faceLayer.zPosition = z
            faceLayer.opacity = Float(visibility)
            faceLayer.setAppearance(
                darkness: darkness,
                velocity: CGFloat(snapshot.normalizedVelocity),
                impact: CGFloat(snapshot.impactIntensity),
                centrality: centrality,
                isStopped: stoppedAtCenter,
                isSeven: isSeven
            )

            var transform = CATransform3DMakeTranslation(
                0,
                0,
                -radius * CGFloat(1 - depth) * 0.64
            )
            transform = CATransform3DRotate(transform, CGFloat(angle), 1, 0, 0)
            transform = CATransform3DScale(
                transform,
                horizontalScale * centerScale,
                verticalScale * centerScale,
                1
            )
            faceLayer.transform = transform

            let seam = symbolPool.seams[index]
            let boundaryAngle = angle - configuration.symbolAngle / 2
            let boundaryDepth = max(0, cos(boundaryAngle))
            if boundaryDepth > 0.012 {
                seam.isHidden = false
                seam.position = CGPoint(
                    x: center.x,
                    y: center.y + radius * CGFloat(sin(boundaryAngle))
                )
                seam.zPosition = radius * CGFloat(boundaryDepth) + 0.5
                seam.opacity = Float(
                    pow(boundaryDepth, 0.35)
                        * (0.30 + snapshot.normalizedVelocity * 0.24)
                )
                var seamTransform = CATransform3DMakeRotation(
                    CGFloat(boundaryAngle),
                    1,
                    0,
                    0
                )
                seamTransform = CATransform3DScale(
                    seamTransform,
                    0.46 + CGFloat(boundaryDepth) * 0.54,
                    1,
                    1
                )
                seam.transform = seamTransform
            } else {
                seam.isHidden = true
            }
        }

        let impact = CGFloat(snapshot.impactIntensity)
        perspectiveLayer.setAffineTransform(
            CGAffineTransform(
                translationX: sin(impact * .pi * 5) * impact * 1.5,
                y: cos(impact * .pi * 4) * impact * 2.2
            )
            .scaledBy(x: 1 + impact * 0.008, y: 1 - impact * 0.018)
        )
        CATransaction.commit()
    }

    private var perspectiveTransform: CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = -1 / configuration.perspectiveDistance
        return transform
    }

    private func configureEdgeLayers() {
        substrateLayer.colors = [
            UIColor(red: 0.48, green: 0.49, blue: 0.47, alpha: 1).cgColor,
            UIColor(red: 0.91, green: 0.90, blue: 0.84, alpha: 1).cgColor,
            UIColor(red: 1.00, green: 0.985, blue: 0.91, alpha: 1).cgColor,
            UIColor(red: 0.91, green: 0.90, blue: 0.84, alpha: 1).cgColor,
            UIColor(red: 0.46, green: 0.47, blue: 0.45, alpha: 1).cgColor
        ]
        substrateLayer.locations = [0, 0.14, 0.5, 0.86, 1]
        substrateLayer.startPoint = CGPoint(x: 0, y: 0.5)
        substrateLayer.endPoint = CGPoint(x: 1, y: 0.5)

        substrateTextureLayer.colors = [
            UIColor.black.withAlphaComponent(0.34).cgColor,
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.055).cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.39).cgColor
        ]
        substrateTextureLayer.locations = [0, 0.22, 0.5, 0.76, 1]
        substrateTextureLayer.startPoint = CGPoint(x: 0.5, y: 0)
        substrateTextureLayer.endPoint = CGPoint(x: 0.5, y: 1)

        topFadeLayer.colors = [
            UIColor.black.withAlphaComponent(0.62).cgColor,
            UIColor.black.withAlphaComponent(0.12).cgColor,
            UIColor.clear.cgColor
        ]
        topFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)

        bottomFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.13).cgColor,
            UIColor.black.withAlphaComponent(0.66).cgColor
        ]
        bottomFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)

        leftShadeLayer.colors = [
            UIColor.black.withAlphaComponent(0.72).cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.clear.cgColor
        ]
        leftShadeLayer.startPoint = CGPoint(x: 0, y: 0.5)
        leftShadeLayer.endPoint = CGPoint(x: 1, y: 0.5)

        rightShadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        rightShadeLayer.startPoint = CGPoint(x: 0, y: 0.5)
        rightShadeLayer.endPoint = CGPoint(x: 1, y: 0.5)

        for layer in [
            substrateLayer,
            substrateTextureLayer,
            topFadeLayer,
            bottomFadeLayer,
            leftShadeLayer,
            rightShadeLayer
        ] {
            layer.actions = disabledActions
        }
    }

    private var disabledActions: [String: CAAction] {
        [
            "bounds": NSNull(),
            "position": NSNull(),
            "transform": NSNull(),
            "opacity": NSNull(),
            "contents": NSNull(),
            "sublayerTransform": NSNull()
        ]
    }
}

@MainActor
final class SiriUSV2ReelSymbolResolver {
    static let shared = SiriUSV2ReelSymbolResolver()
    private static let artworkContentScale: CGFloat = 0.76

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 48
    }

    func image(for symbol: String, scale: CGFloat) -> UIImage {
        let key = "premium-artwork-v10-sirius-metal|\(symbol)|\(scale)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Legacy PNGs contain photographic backgrounds. Transparent runtime
        // artwork guarantees that a reel face can never become a white card.
        let image = renderArtwork(symbol, scale: scale)
        cache.setObject(image, forKey: key)
        return image
    }

    private func renderArtwork(_ symbol: String, scale: CGFloat) -> UIImage {
        let size = CGSize(width: 180, height: 112)
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(scale, 1)
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rawArtwork = renderer.image { rendererContext in
            switch symbol {
            case "7", "7️⃣":
                drawSeven(in: rendererContext.cgContext, size: size, rainbow: false)
            case "🌈7", "🌈7️⃣":
                drawSeven(in: rendererContext.cgContext, size: size, rainbow: true)
            case "BAR":
                drawBar(in: rendererContext.cgContext, size: size)
            default:
                drawTransparentText(symbol, size: size)
            }
        }
        let paddedRenderer = UIGraphicsImageRenderer(size: size, format: format)
        return paddedRenderer.image { _ in
            let contentSize = CGSize(
                width: size.width * Self.artworkContentScale,
                height: size.height * Self.artworkContentScale
            )
            rawArtwork.draw(
                in: CGRect(
                    x: (size.width - contentSize.width) * 0.5,
                    y: (size.height - contentSize.height) * 0.5,
                    width: contentSize.width,
                    height: contentSize.height
                ),
                blendMode: .normal,
                alpha: 1
            )
        }
    }

    private func drawTransparentText(_ text: String, size: CGSize) {
        let isEmoji = text.unicodeScalars.contains { $0.properties.isEmojiPresentation }
        let font = isEmoji
            ? UIFont.systemFont(ofSize: 76)
            : UIFont.systemFont(ofSize: 58, weight: .heavy)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let string = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.label,
                .strokeColor: UIColor.black.withAlphaComponent(isEmoji ? 0 : 0.30),
                .strokeWidth: isEmoji ? 0 : -2.0
            ]
        )
        string.draw(
            in: CGRect(
                x: 0,
                y: (size.height - font.lineHeight) * 0.5 - 3,
                width: size.width,
                height: font.lineHeight + 8
            )
        )
    }

    private func drawSeven(in context: CGContext, size: CGSize, rainbow: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let font = UIFont.italicSystemFont(ofSize: 94)
        let rect = CGRect(x: -5, y: -7, width: size.width + 10, height: size.height + 10)
        let silhouette = NSAttributedString(
            string: "7",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -7.0
            ]
        )
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 5),
            blur: 5,
            color: UIColor.black.withAlphaComponent(0.48).cgColor
        )
        silhouette.draw(in: rect)
        context.restoreGState()

        if rainbow {
            drawRainbowSeven(in: context, size: size, font: font, rect: rect)
        } else {
            drawPremiumSeven(in: context, size: size, font: font, rect: rect)
        }

        NSAttributedString(
            string: "7",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.clear,
                .strokeColor: UIColor.white.withAlphaComponent(0.55),
                .strokeWidth: -0.7
            ]
        ).draw(in: rect.offsetBy(dx: -1.2, dy: -1.2))
    }

    private func drawPremiumSeven(
        in context: CGContext,
        size: CGSize,
        font: UIFont,
        rect: CGRect
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        NSAttributedString(
            string: "7",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor(red: 0.28, green: 0.07, blue: 0.42, alpha: 1),
                .strokeColor: UIColor(red: 0.90, green: 0.70, blue: 0.24, alpha: 1),
                .strokeWidth: -4.2
            ]
        ).draw(in: rect)

        let maskFormat = UIGraphicsImageRendererFormat()
        maskFormat.opaque = false
        maskFormat.scale = 1
        let mask = UIGraphicsImageRenderer(size: size, format: maskFormat).image { _ in
            NSAttributedString(
                string: "7",
                attributes: [
                    .font: font,
                    .paragraphStyle: paragraph,
                    .foregroundColor: UIColor.white
                ]
            ).draw(in: rect)
        }
        guard let cgMask = mask.cgImage else { return }

        context.saveGState()
        context.clip(to: CGRect(origin: .zero, size: size), mask: cgMask)
        let colors = [
            UIColor(red: 0.16, green: 0.012, blue: 0.018, alpha: 1).cgColor,
            UIColor(red: 0.92, green: 0.10, blue: 0.14, alpha: 1).cgColor,
            UIColor(red: 0.48, green: 0.018, blue: 0.035, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.006, blue: 0.012, alpha: 1).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 0.24, 0.58, 1]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width * 0.24, y: 0),
                end: CGPoint(x: size.width * 0.76, y: size.height),
                options: []
            )
        }
        context.restoreGState()

        NSAttributedString(
            string: "7",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.clear,
                .strokeColor: UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 0.92),
                .strokeWidth: -1.15
            ]
        ).draw(in: rect.offsetBy(dx: -0.7, dy: -0.8))
    }

    private func drawRainbowSeven(
        in context: CGContext,
        size: CGSize,
        font: UIFont,
        rect: CGRect
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let maskFormat = UIGraphicsImageRendererFormat()
        maskFormat.opaque = false
        maskFormat.scale = 1
        let mask = UIGraphicsImageRenderer(size: size, format: maskFormat).image { _ in
            NSAttributedString(
                string: "7",
                attributes: [
                    .font: font,
                    .paragraphStyle: paragraph,
                    .foregroundColor: UIColor.white
                ]
            ).draw(in: rect)
        }
        guard let cgMask = mask.cgImage else { return }

        context.saveGState()
        context.clip(to: CGRect(origin: .zero, size: size), mask: cgMask)
        let metalColors = [
            UIColor(red: 0.03, green: 0.035, blue: 0.05, alpha: 1).cgColor,
            UIColor(red: 0.34, green: 0.37, blue: 0.43, alpha: 1).cgColor,
            UIColor(red: 0.055, green: 0.06, blue: 0.085, alpha: 1).cgColor,
            UIColor(red: 0.52, green: 0.55, blue: 0.61, alpha: 1).cgColor,
            UIColor(red: 0.018, green: 0.022, blue: 0.035, alpha: 1).cgColor
        ] as CFArray
        let metalLocations: [CGFloat] = [0, 0.20, 0.45, 0.62, 1]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: metalColors,
            locations: metalLocations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width * 0.18, y: 0),
                end: CGPoint(x: size.width * 0.82, y: size.height),
                options: []
            )
        }

        let rainbowColors = [
            UIColor.systemRed.cgColor,
            UIColor.systemYellow.cgColor,
            UIColor.systemGreen.cgColor,
            UIColor.systemCyan.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemPurple.cgColor
        ] as CFArray
        let rainbowLocations: [CGFloat] = [0, 0.20, 0.40, 0.60, 0.80, 1]
        context.saveGState()
        context.clip(to: CGRect(x: 19, y: size.height * 0.48, width: size.width - 38, height: 9))
        if let rainbow = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: rainbowColors,
            locations: rainbowLocations
        ) {
            context.drawLinearGradient(
                rainbow,
                start: CGPoint(x: 18, y: size.height * 0.5),
                end: CGPoint(x: size.width - 18, y: size.height * 0.5),
                options: []
            )
        }
        context.restoreGState()
        context.restoreGState()

        NSAttributedString(
            string: "7",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.clear,
                .strokeColor: UIColor(red: 0.86, green: 0.90, blue: 0.98, alpha: 0.96),
                .strokeWidth: -1.35
            ]
        ).draw(in: rect.offsetBy(dx: -0.9, dy: -1.0))
    }

    private func drawBar(in context: CGContext, size: CGSize) {
        let outer = CGRect(x: 16, y: 25, width: size.width - 32, height: 64)
        let path = UIBezierPath(roundedRect: outer, cornerRadius: 13)
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 4),
            blur: 5,
            color: UIColor.black.withAlphaComponent(0.46).cgColor
        )
        UIColor(red: 0.045, green: 0.045, blue: 0.055, alpha: 1).setFill()
        path.fill()
        context.restoreGState()
        UIColor(red: 0.86, green: 0.67, blue: 0.20, alpha: 1).setStroke()
        path.lineWidth = 4
        path.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        NSAttributedString(
            string: "BAR",
            attributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .black),
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0,
                .kern: 1.5
            ]
        ).draw(in: CGRect(x: 18, y: 33, width: size.width - 36, height: 50))
    }
}
