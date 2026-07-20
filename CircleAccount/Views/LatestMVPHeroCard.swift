import SwiftUI
import UIKit

struct LatestMVPHeroCard: View {
    let mvpName: String
    let mvpPoint: Int
    let imageBase64: String

    @State private var glowAnimation = false
    @State private var crownAnimation = false
    @State private var shimmerOffset: CGFloat = -1.5

    private var hasMVP: Bool {
        !mvpName.isEmpty
    }

    private var displayName: String {
        hasMVP
            ? mvpName
            : "Coming Soon"
    }

    private var decodedImage: UIImage? {
        var base64Text = imageBase64
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let commaIndex = base64Text.firstIndex(of: ","),
           base64Text.contains("base64") {
            base64Text = String(
                base64Text[
                    base64Text.index(
                        after: commaIndex
                    )...
                ]
            )
        }

        guard
            !base64Text.isEmpty,
            let imageData = Data(
                base64Encoded: base64Text,
                options: .ignoreUnknownCharacters
            )
        else {
            return nil
        }

        return UIImage(data: imageData)
    }

    var body: some View {
        VStack(spacing: 9) {
            headerSection

            profileSection

            informationSection
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background {
            cardBackground
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 27)
        )
        .overlay {
            overallGlowLayer
        }
        .overlay {
            cardBorder
        }
        .overlay {
            shimmerLayer
                .clipShape(
                    RoundedRectangle(cornerRadius: 27)
                )
                .allowsHitTesting(false)
        }
        .shadow(
            color: Color.yellow.opacity(
                glowAnimation ? 0.34 : 0.15
            ),
            radius: glowAnimation ? 20 : 11,
            x: 0,
            y: 8
        )
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 3) {
            Text("👑")
                .font(.system(size: 28))
                .scaleEffect(
                    crownAnimation ? 1.09 : 0.96
                )
                .rotationEffect(
                    .degrees(
                        crownAnimation ? 3 : -3
                    )
                )
                .shadow(
                    color: Color.yellow.opacity(0.60),
                    radius: 7
                )

            Text("MONTHLY MVP")
                .font(
                    .system(
                        size: 11,
                        weight: .black
                    )
                )
                .tracking(2.1)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.yellow,
                            Color.white,
                            Color.orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("SiRiUS HONOR PLAYER")
                .font(
                    .system(
                        size: 7,
                        weight: .bold
                    )
                )
                .tracking(1.4)
                .foregroundStyle(
                    .white.opacity(0.56)
                )
        }
    }

    // MARK: - プロフィール画像

    private var profileSection: some View {
        ZStack {
            Circle()
                .fill(
                    Color.yellow.opacity(
                        glowAnimation ? 0.23 : 0.11
                    )
                )
                .frame(
                    width: 96,
                    height: 96
                )
                .blur(radius: 7)
                .scaleEffect(
                    glowAnimation ? 1.08 : 0.96
                )

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow,
                            Color.white,
                            Color.orange,
                            Color.yellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(
                    width: 84,
                    height: 84
                )

            Circle()
                .fill(
                    Color.black.opacity(0.28)
                )
                .frame(
                    width: 77,
                    height: 77
                )

            if let decodedImage {
                Image(uiImage: decodedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 77,
                        height: 77
                    )
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.23),
                                    Color.orange.opacity(0.16),
                                    Color.black.opacity(0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: 77,
                            height: 77
                        )

                    Image(
                        systemName: "person.fill"
                    )
                    .font(
                        .system(
                            size: 31,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.80)
                    )
                }
            }

            if hasMVP {
                Text("MVP")
                    .font(
                        .system(
                            size: 7,
                            weight: .black
                        )
                    )
                    .tracking(0.8)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.yellow,
                                Color.white,
                                Color.orange
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.white.opacity(0.65),
                                lineWidth: 1
                            )
                    }
                    .offset(
                        x: 31,
                        y: 32
                    )
            }
        }
    }

    // MARK: - MVP情報

    private var informationSection: some View {
        VStack(spacing: 4) {
            Text(displayName)
                .font(
                    .system(
                        size: hasMVP ? 23 : 20,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            if hasMVP {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)

                    Text("\(mvpPoint)pt")
                        .font(
                            .system(
                                size: 17,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.yellow)

                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }

                Text("MONTHLY HONOR")
                    .font(
                        .system(
                            size: 8,
                            weight: .bold
                        )
                    )
                    .tracking(1.1)
                    .foregroundStyle(
                        .white.opacity(0.70)
                    )
            } else {
                Text("次の月間MVPをお楽しみに")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        .white.opacity(0.68)
                    )
            }
        }
    }

    // MARK: - 背景

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 27)
                .fill(
                    Color.yellow.opacity(glowAnimation ? 0.12 : 0.03)
                )
                .blur(radius: glowAnimation ? 45 : 18)
                .scaleEffect(glowAnimation ? 1.08 : 0.94)
            RoundedRectangle(cornerRadius: 27)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 0.06,
                                green: 0.045,
                                blue: 0.015
                            ),
                            Color(
                                red: 0.22,
                                green: 0.13,
                                blue: 0.018
                            ),
                            Color(
                                red: 0.46,
                                green: 0.31,
                                blue: 0.035
                            ),
                            Color(
                                red: 0.13,
                                green: 0.07,
                                blue: 0.01
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    Color.yellow.opacity(
                        glowAnimation ? 0.20 : 0.08
                    )
                )
                .frame(
                    width: 180,
                    height: 180
                )
                .blur(radius: 18)
                .offset(
                    x: 140,
                    y: -90
                )

            Circle()
                .fill(
                    Color.orange.opacity(0.11)
                )
                .frame(
                    width: 145,
                    height: 145
                )
                .blur(radius: 16)
                .offset(
                    x: -140,
                    y: 105
                )

            MVPSparkleLayer()
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 27)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.95),
                        Color.white.opacity(0.74),
                        Color.orange.opacity(0.66),
                        Color.yellow.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.7
            )
    }
    private var overallGlowLayer: some View {
        RoundedRectangle(cornerRadius: 27)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.yellow.opacity(0.14),
                        Color.orange.opacity(0.10),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(glowAnimation ? 1.18 : 0.92)
            .blur(radius: glowAnimation ? 55 : 18)
            .opacity(glowAnimation ? 0.9 : 0.22)
            .blendMode(.screen)
    }

    private var shimmerLayer: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.yellow.opacity(0.12),
                    Color.white.opacity(0.22),
                    Color.yellow.opacity(0.18),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 700)      // ←ここ超重要
            .blur(radius: 26)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.10),
                    Color.yellow.opacity(0.35),
                    Color.white.opacity(0.50),
                    Color.yellow.opacity(0.30),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 520)      // ←ここも大きく
            .blur(radius: 6)
        }
        .rotationEffect(.degrees(-18))
        .offset(x: shimmerOffset * 650)
        .blendMode(.screen)
        .opacity(0.95)
    }
    // MARK: - アニメーション

    private func startAnimations() {
        withAnimation(
            .easeInOut(duration: 2.8)
                .repeatForever(
                    autoreverses: true
                )
        ) {
            glowAnimation = true
            crownAnimation = true
        }

        withAnimation(
            .linear(duration: 3.1)
                .repeatForever(
                    autoreverses: false
                )
        ) {
            shimmerOffset = 1.5
        }
    }
}

// MARK: - MVPカード粒子

private struct MVPSparkleLayer: View {
    private let particles: [
        (
            x: CGFloat,
            y: CGFloat,
            size: CGFloat,
            speed: Double
        )
    ] = [
        (-145, -95, 3, 0.42),
        (-95, -45, 5, 0.50),
        (-35, -105, 3, 0.57),
        (55, -85, 4, 0.46),
        (130, -55, 3, 0.54),
        (145, 15, 5, 0.44),
        (110, 88, 3, 0.58),
        (40, 108, 4, 0.49),
        (-45, 102, 3, 0.55),
        (-125, 70, 5, 0.47),
        (-150, 5, 3, 0.61)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                ForEach(
                    particles.indices,
                    id: \.self
                ) { index in
                    let particle = particles[index]

                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? Color.white.opacity(0.65)
                                : Color.yellow.opacity(0.72)
                        )
                        .frame(
                            width: particle.size,
                            height: particle.size
                        )
                        .offset(
                            x:
                                particle.x
                                + CGFloat(
                                    sin(
                                        time
                                        * particle.speed
                                        + Double(index)
                                    )
                                ) * 7,
                            y:
                                particle.y
                                + CGFloat(
                                    cos(
                                        time
                                        * particle.speed
                                        + Double(index)
                                    )
                                ) * 6
                        )
                        .shadow(
                            color:
                                Color.yellow.opacity(0.75),
                            radius: 4
                        )
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        LatestMVPHeroCard(
            mvpName: "江口 圭哉",
            mvpPoint: 650,
            imageBase64: ""
        )
        .padding()
    }
}
