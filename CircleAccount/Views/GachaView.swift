import SwiftUI
import FirebaseFirestore
struct GachaView: View {
    private let db = Firestore.firestore()
    @AppStorage("currentUserId") private var currentUserId = ""
    
    @State private var result: GachaPrize?
    @State private var showResult = false
    @State private var isLoading = false
    @State private var availablePoint = 0
    @State private var isRolling = false
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)
                
                Text("🎰")
                    .font(.system(size: 90))
                    .rotationEffect(
                        .degrees(isRolling ? 720 : 0)
                    )
                    .animation(
                        .easeInOut(duration: 2),
                        value: isRolling
                    )
                
                Text("SiRiUS GACHA")
                    .font(.largeTitle)
                    .bold()
                
                Text("100ptでガチャを回せます")
                    .foregroundStyle(.secondary)
                
                Text("現在のポイント：\(availablePoint)pt")
                    .font(.headline)
                    .foregroundStyle(
                        availablePoint >= 100 ? .green : .red
                    )
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("排出アイテム")
                        .font(.headline)
                    
                    prizeRow(
                        icon: "🎾",
                        title: "ガット張り工賃無料券",
                        rate: "1%"
                    )
                    
                    prizeRow(
                        icon: "🎁",
                        title: "参加費無料券",
                        rate: "3%"
                    )
                    
                    prizeRow(
                        icon: "🏸",
                        title: "参加費半額券",
                        rate: "8%"
                    )
                    
                    prizeRow(
                        icon: "💰",
                        title: "参加費500円券",
                        rate: "18%"
                    )
                    
                    prizeRow(
                        icon: "⭐",
                        title: "対戦指名券",
                        rate: "20%"
                    )
                    
                    prizeRow(
                        icon: "🚀",
                        title: "優先ゲーム券",
                        rate: "20%"
                    )
                    
                    prizeRow(
                        icon: "🧹",
                        title: "片付けパス",
                        rate: "30%"
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button {
                    runGacha()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        
                        Text(
                            isLoading
                            ? "抽選中..."
                            : "100ptでガチャを回す"
                        )
                        .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        availablePoint >= 100
                        ? (isLoading ? Color.gray : Color.orange)
                        : Color.gray
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .disabled(availablePoint < 100)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ガチャ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResult) {
            if let result {
                GachaResultView(
                    prize: result,
                    showResult: $showResult
                )
            }
        }
        .alert(
            "ガチャを回せませんでした",
            isPresented: $showError
        ) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadPoint()
        }
    }
    
    func runGacha() {
        guard !currentUserId.isEmpty else {
            errorMessage = "ユーザー情報を確認できませんでした。"
            showError = true
            return
        }
        
        guard !isLoading else {
            return
        }
        
        isLoading = true
        isRolling = true
        
        PointService.shared.runGacha(
            memberId: currentUserId
        ) { result in

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

                isLoading = false
                isRolling = false

                switch result {

                case .success(let prize):
                    self.result = prize
                    availablePoint = max(availablePoint - 100, 0)
                    showResult = true

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

func loadPoint() {
    guard !currentUserId.isEmpty else { return }

    db.collection("members")
        .document(currentUserId)
        .getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }

            availablePoint = data["availablePoint"] as? Int ?? 0
        }
}
    func prizeRow(
        icon: String,
        title: String,
        rate: String
    ) -> some View {
        HStack {
            Text(icon)
                .font(.title2)
            
            Text(title)
            
            Spacer()
            
            Text(rate)
                .bold()
                .foregroundStyle(.orange)
        }
    }
}
struct GachaResultView: View {
    let prize: GachaPrize

    @Binding var showResult: Bool

    var stars: String {
        String(
            repeating: "⭐",
            count: max(prize.rarity, 1)
        )
    }

    var resultColor: Color {
        switch prize.rarity {
        case 5:
            return .yellow

        case 4:
            return .purple

        case 3:
            return .orange

        default:
            return .blue
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    resultColor.opacity(0.35),
                    Color(.systemBackground),
                    resultColor.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ConfettiView()

            VStack(spacing: 28) {
                Spacer()

                Text("🎉 GET!!")
                    .font(.headline)
                    .bold()
                    .tracking(1.2)
                    .foregroundStyle(resultColor)

                Text(stars)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .fill(resultColor.opacity(0.18))
                        .frame(width: 190, height: 190)

                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 145, height: 145)
                        .shadow(
                            color: resultColor.opacity(0.35),
                            radius: 22
                        )

                    Text(prize.icon)
                        .font(.system(size: 76))
                }

                Text(prize.title)
                    .font(.system(size: 30, weight: .black))
                    .multilineTextAlignment(.center)

                Text("チケットを1枚獲得しました")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showResult = false
                } label: {
                    Text("受け取る")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(resultColor)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(28)
        }
    }
}

#Preview {
    NavigationStack {
        GachaView()
    }
}
