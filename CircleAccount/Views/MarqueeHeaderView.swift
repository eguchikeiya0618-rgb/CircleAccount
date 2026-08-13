import SwiftUI

struct MarqueeHeaderView: View {
    let heatLevel: SlotHeatLevel
    let machineGlow: Color

    @State private var lampPulse = false
    @State private var chaseOffset: CGFloat = -1.2

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? heatLevel.lampColor
                                : machineGlow
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse ? machineGlow : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 1.0 : 0.48)
                }
            }

            VStack(spacing: -2) {
                Text("SiRiUS")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(Color.white.opacity(0.82))

                Text("LUCKY SLOT")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                heatLevel.lampColor,
                                machineGlow,
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: machineGlow, radius: 9)
            }

            HStack(spacing: 8) {
                ForEach(0..<11, id: \.self) { index in
                    Circle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? machineGlow
                                : heatLevel.lampColor
                        )
                        .frame(width: 9, height: 9)
                        .shadow(
                            color: lampPulse
                                ? heatLevel.lampColor
                                : Color.clear,
                            radius: 7
                        )
                        .opacity(lampPulse ? 0.82 : 0.42)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors:[Color.black,Color(red:0.08,green:0.08,blue:0.11)],
                        startPoint:.top,
                        endPoint:.bottom
                    )
                )
                .overlay{
                    RoundedRectangle(cornerRadius:18,style:.continuous)
                        .stroke(machineGlow.opacity(0.55),lineWidth:1.5)

                    GeometryReader{proxy in
                        LinearGradient(
                            colors:[
                                .clear,
                                .white.opacity(0.15),
                                .white.opacity(0.65),
                                .white.opacity(0.15),
                                .clear
                            ],
                            startPoint:.top,
                            endPoint:.bottom
                        )
                        .frame(width:32,height:proxy.size.height*1.5)
                        .rotationEffect(.degrees(18))
                        .offset(x:proxy.size.width*chaseOffset)
                        .blendMode(.screen)
                    }
                    .clipShape(RoundedRectangle(cornerRadius:18))
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration:0.62).repeatForever(autoreverses:true)){
                lampPulse=true
            }
            withAnimation(.linear(duration:3).repeatForever(autoreverses:false)){
                chaseOffset=1.2
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        MarqueeHeaderView(
            heatLevel: .premium,
            machineGlow: .purple
        )
        .padding()
    }
}
