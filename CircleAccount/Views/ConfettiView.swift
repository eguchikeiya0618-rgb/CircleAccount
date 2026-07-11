import SwiftUI

struct ConfettiView: View {
    @State private var animate = false

    private let pieces = Array(0..<55)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces, id: \.self) { index in
                    ConfettiPiece(index: index)
                        .position(
                            x: confettiX(
                                index: index,
                                width: geometry.size.width
                            ),
                            y: animate
                                ? geometry.size.height + 100
                                : -100
                        )
                        .rotationEffect(
                            .degrees(
                                animate
                                ? Double(index * 65)
                                : 0
                            )
                        )
                        .animation(
                            .linear(
                                duration: confettiDuration(index: index)
                            )
                            .delay(confettiDelay(index: index)),
                            value: animate
                        )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animate = true
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    func confettiX(index: Int, width: CGFloat) -> CGFloat {
        let position = (index * 47 + 13) % 100
        return width * CGFloat(position) / 100
    }

    func confettiDuration(index: Int) -> Double {
        1.8 + Double(index % 8) * 0.18
    }

    func confettiDelay(index: Int) -> Double {
        Double(index % 15) * 0.06
    }
}

struct ConfettiPiece: View {
    let index: Int

    var body: some View {
        Group {
            if index % 3 == 0 {
                Circle()
                    .fill(confettiColor)
            } else if index % 3 == 1 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(confettiColor)
            } else {
                Capsule()
                    .fill(confettiColor)
            }
        }
        .frame(
            width: index % 2 == 0 ? 11 : 7,
            height: index % 2 == 0 ? 17 : 12
        )
    }

    var confettiColor: Color {
        switch index % 6 {
        case 0:
            return .yellow
        case 1:
            return .pink
        case 2:
            return .blue
        case 3:
            return .green
        case 4:
            return .orange
        default:
            return .purple
        }
    }
}

#Preview {
    ConfettiView()
        .background(Color.black)
}
