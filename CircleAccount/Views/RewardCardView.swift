import SwiftUI

struct RewardCardView: View {
    let isVisible: Bool
    let symbols: [String]
    let title: String
    let subtitle: String
    let isPremium: Bool

    @State private var scale: CGFloat = 0.42
    @State private var rotationX = 78.0
    @State private var opacity = 0.0
    @State private var glow = false
    @State private var badgePulse = false
    @State private var holoOffset: CGFloat = -1.3
    @State private var starRotation = 0.0

    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    Color.black.opacity(0.28).ignoresSafeArea()

                    VStack(spacing: 12) {
                        badge

                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [.white,.yellow,.orange,.pink,.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            hologram

                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    AngularGradient(
                                        colors:[.white,.yellow,.cyan,.pink,.white],
                                        center:.center
                                    ),
                                    lineWidth:4
                                )

                            VStack(spacing:16){
                                Text(title)
                                    .font(.system(size:32,weight:.black,design:.rounded))

                                HStack(spacing:10){
                                    ForEach(symbols,id:\.self){ s in
                                        Text(s)
                                            .font(.system(size:42))
                                            .frame(width:70,height:70)
                                            .background(.white)
                                            .clipShape(RoundedRectangle(cornerRadius:16))
                                    }
                                }

                                Text(subtitle)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding()

                            cornerStars
                        }
                        .frame(width:330,height:300)
                        .shadow(color:.yellow.opacity(glow ? 0.9:0.45),radius: glow ? 28:14)
                    }
                    .scaleEffect(scale)
                    .rotation3DEffect(.degrees(rotationX), axis:(x:1,y:0,z:0))
                    .opacity(opacity)
                }
                .onAppear { animateIn() }
            }
        }
        .onChange(of:isVisible){_,v in if v { animateIn() } }
    }

    var badge: some View {
        Text(isPremium ? "SSR PREMIUM":"SR BONUS")
            .font(.caption.bold())
            .padding(.horizontal,14)
            .padding(.vertical,7)
            .background(.black.opacity(0.5),in:Capsule())
            .overlay(Capsule().stroke(.yellow,lineWidth:1.5))
            .foregroundStyle(.yellow)
            .scaleEffect(badgePulse ? 1.08:0.96)
    }

    var hologram: some View {
        GeometryReader{g in
            LinearGradient(
                colors:[.clear,.white.opacity(0.1),.cyan.opacity(0.3),.pink.opacity(0.3),.yellow.opacity(0.3),.clear],
                startPoint:.top,endPoint:.bottom
            )
            .frame(width:g.size.width*0.35,height:g.size.height*1.5)
            .rotationEffect(.degrees(18))
            .offset(x:g.size.width*holoOffset)
            .blendMode(.screen)
        }
        .clipShape(RoundedRectangle(cornerRadius:28))
    }

    var cornerStars: some View {
        GeometryReader{g in
            ForEach(0..<8,id:\.self){i in
                Image(systemName:i.isMultiple(of:2) ? "sparkle":"star.fill")
                    .foregroundStyle(.yellow)
                    .rotationEffect(.degrees(starRotation+Double(i*35)))
                    .position(
                        x:i<4 ? CGFloat(20+i*24):g.size.width-CGFloat(20+(i-4)*24),
                        y:i.isMultiple(of:2) ? 20:g.size.height-20
                    )
            }
        }
    }

    func animateIn(){
        scale=0.42
        rotationX=78
        opacity=0
        holoOffset = -1.3

        withAnimation(.spring(response:0.55,dampingFraction:0.62)){
            scale=1
            rotationX=0
            opacity=1
        }

        withAnimation(.linear(duration:1.8).repeatForever(autoreverses:false)){
            holoOffset=1.4
        }

        withAnimation(.easeInOut(duration:0.5).repeatForever(autoreverses:true)){
            badgePulse=true
        }

        withAnimation(.linear(duration:5).repeatForever(autoreverses:false)){
            starRotation=360
        }

        withAnimation(.easeInOut(duration:1.2).repeatForever(autoreverses:true)){
            glow=true
        }
    }
}

#Preview{
    RewardCardView(
        isVisible:true,
        symbols:["7","7","7"],
        title:"JACKPOT",
        subtitle:"PREMIUM GET!",
        isPremium:true
    )
}
