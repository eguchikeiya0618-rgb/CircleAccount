import SwiftUI

struct LevelUpView: View {

    let oldLevel: Int
    let newLevel: Int

    @Environment(\.dismiss) private var dismiss

    @State private var animate = false

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    .blue.opacity(0.35),
                    .purple.opacity(0.20),
                    .white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ConfettiView()

            VStack(spacing: 28) {

                Spacer()

                Text("⬆️ LEVEL UP!")
                    .font(.headline)
                    .bold()

                ZStack {

                    Circle()
                        .fill(.white)
                        .frame(width: 180,height:180)

                    Text("Lv.\(newLevel)")
                        .font(.system(size: 55,weight: .black))
                        .scaleEffect(animate ? 1.15 : 0.7)
                        .animation(
                            .spring(response: 0.6,dampingFraction: 0.55),
                            value: animate
                        )
                }

                Text("Lv.\(oldLevel) → Lv.\(newLevel)")
                    .font(.title)
                    .bold()

                Text("おめでとうございます！")
                    .font(.title3)

                Spacer()

                Button {

                    dismiss()

                } label: {

                    Text("OK")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

            }
            .padding(28)

        }
        .onAppear {

            animate = true

        }

    }
}

#Preview {

    LevelUpView(
        oldLevel: 8,
        newLevel: 9
    )

}
