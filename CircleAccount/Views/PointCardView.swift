import SwiftUI
import FirebaseFirestore

struct PointCardView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var memberNo = 1
    @State private var totalPoint = 0
    @State private var availablePoint = 0

    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0

    @State private var legendCount = 0
    @State private var isLegend = false

    @State private var myRank = 0
    @State private var totalMembersCount = 0

    @State private var isFlipped = false
    @State private var rankingMembers: [Member] = []

    
    
    var rankName: String {
        if totalPoint >= 700 { return "👑 Legend Player" }
        if totalPoint >= 400 { return "💎 Platinum Player" }
        if totalPoint >= 200 { return "🥇 Gold Player" }
        if totalPoint >= 100 { return "🥈 Silver Player" }
        return "🥉 Bronze Player"
    }

    var rankBadge: String {
        if totalPoint >= 700 { return "LEGEND" }
        if totalPoint >= 400 { return "PLATINUM" }
        if totalPoint >= 200 { return "GOLD" }
        if totalPoint >= 100 { return "SILVER" }
        return "BRONZE"
    }

    var cardBackground: String {
        if totalPoint >= 700 { return "legend_card_bg" }
        if totalPoint >= 400 { return "platinum_card_bg" }
        if totalPoint >= 200 { return "gold_card_bg" }
        if totalPoint >= 100 { return "silver_card_bg" }
        return "bronze_card_bg"
    }

    var nextReward: (title: String, point: Int, icon: String) {
        if totalPoint >= 700 {
            return ("最高ランク達成！", 700, "👑")
        }

        if availablePoint < 100 {
            return ("片付け免除", 100, "🧹")
        } else if availablePoint < 200 {
            return ("100円引き", 200, "💴")
        } else if availablePoint < 400 {
            return ("参加費無料", 400, "🎁")
        } else {
            return ("参加費無料交換できます", 400, "🎁")
        }
    }

    var remainingPoint: Int {
        if totalPoint >= 700 { return 0 }
        return max(nextReward.point - availablePoint, 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                flippingCard

                Text("カードをタップするとランキングが見れます")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ticketsSection
                exchangeSection

                NavigationLink {
                    PointHistoryView()
                } label: {
                    Label("ポイント履歴を見る", systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
               
                pointRuleSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ポイントカード")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMember()
            loadRanking()
        }
    }

    var flippingCard: some View {
        ZStack {
            memberCard
                .opacity(isFlipped ? 0 : 1)

            rankingCard
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }

    var memberCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(rankName)
                        .font(.title2)
                        .bold()

                    Text(totalPoint >= 700 ? "SiRiUS Legend Card" : "SiRiUS Digital Member Card")
                        .font(.caption)
                        .opacity(0.75)
                }

                Spacer()

                Text(rankBadge)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                    .offset(y: -4)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("累計ポイント")
                    .font(.caption)
                    .opacity(0.75)

                Text("\(totalPoint) pt")
                    .font(.system(size: 48, weight: .black))

                if totalPoint >= 700 {
                    Text("👑 LEGEND達成")
                        .font(.headline)
                        .bold()
                }

                Divider()
                    .background(.white.opacity(0.12))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("利用可能")
                            .font(.caption)
                            .opacity(0.75)

                        Text("\(availablePoint) pt")
                            .font(.title2)
                            .bold()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(totalPoint >= 700 ? "LEGEND MAX" : "NEXT REWARD")
                            .font(.caption2)
                            .bold()
                            .opacity(0.75)

                        Text("\(nextReward.icon) \(nextReward.title)")
                            .font(.headline)

                        if totalPoint >= 700 {
                            Text("最高ランク")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.yellow)
                        } else {
                            Text("あと\(remainingPoint)pt")
                                .font(.caption)
                                .opacity(0.85)
                        }
                    }
                    .offset(x: -20, y: 8)
                }
            }

            ProgressView(
                value: Double(min(availablePoint, nextReward.point)),
                total: Double(nextReward.point)
            )
            .tint(.white)
            .scaleEffect(y: 1.5)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Member No.")
                        .font(.caption2)
                        .opacity(0.65)

                    Text(String(format: "%06d", memberNo))
                        .font(.caption)
                        .bold()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Since")
                        .font(.caption2)
                        .opacity(0.65)

                    Text("2023.07")
                        .font(.caption)
                        .bold()
                }
            }
        }
        .cardStyle(imageName: cardBackground)
    }

    var rankingCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🏆 Point Ranking")
                        .font(.title2)
                        .bold()

                    Text("Top 3 Members")
                        .font(.caption)
                        .opacity(0.75)
                }

                Spacer()

                Text("RANKING")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
            }

            Spacer()

            if rankingMembers.isEmpty {
                Text("ランキングを読み込み中...")
                    .font(.headline)
                    .opacity(0.8)
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(rankingMembers.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack {
                            Text(rankIcon(index))
                                .font(.title)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.headline)
                                    .bold()

                                Text("\(member.totalPoint) pt")
                                    .font(.caption)
                                    .opacity(0.8)
                            }

                            Spacer()

                            Text("#\(index + 1)")
                                .font(.headline)
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }

                    Divider()
                        .background(.white.opacity(0.12))

                    HStack {
                        Text("あなたの順位")
                            .font(.caption)
                            .opacity(0.75)

                        Spacer()

                        Text(myRank == 0 ? "-" : "\(myRank)位 / \(totalMembersCount)人")
                            .font(.headline)
                            .bold()
                    }
                }
            }

            Spacer()

            Text("もう一度タップでカードに戻ります")
                .font(.caption)
                .opacity(0.7)
        }
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .cardStyle(imageName: cardBackground)
    }

    var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎫 My Tickets")
                .font(.title2)
                .bold()

            ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets)
            Divider()
            ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets)
            Divider()
            ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets)
            Divider()
            ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets)
            Divider()
            ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets)
            Divider()
            ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    var exchangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎁 ポイント交換")
                .font(.title2)
                .bold()

            exchangeButton(
                title: "片付けパス",
                point: 100,
                icon: "🧹",
                ticketField: "cleanupTickets"
            )

            exchangeButton(
                title: "参加費500円券",
                point: 200,
                icon: "💰",
                ticketField: "discountTickets"
            )

            exchangeButton(
                title: "参加費半額券",
                point: 400,
                icon: "🏸",
                ticketField: "halfPriceTickets"
            )

            exchangeButton(
                title: "参加費無料券",
                point: 700,
                icon: "🎁",
                ticketField: "freeTickets"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    func ticketRow(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.title2)

            Text(title)
                .font(.headline)

            Spacer()

            Text("\(count)枚")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    func exchangeButton(
        title: String,
        point: Int,
        icon: String,
        ticketField: String
    ) -> some View {
        Button {
            PointService.shared.exchangeTicket(
                memberId: currentUserId,
                requiredPoint: point,
                ticketField: ticketField,
                title: title,
                icon: icon
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                loadMember()
                loadRanking()
            }
        } label: {
            HStack {
                Text(icon)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)

                    Text("\(point)ptで交換")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                availablePoint >= point
                ? Color.blue.opacity(0.12)
                : Color.gray.opacity(0.12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(availablePoint < point)
    }

    var pointRuleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ポイントルール")
                .font(.headline)

            ruleRow("🏸 練習参加", "+5pt")
            ruleRow("⏰ 前日の18:00までに参加回答", "+2pt")
            ruleRow("🔧 設営参加", "+5pt")
            ruleRow("👥 Bクラス入賞者レベル以上の方を新規で連れてくる", "+20pt")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }

    func ruleRow(_ title: String, _ point: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)

            Spacer()

            Text(point)
                .font(.caption)
                .bold()
                .foregroundStyle(.blue)
        }
    }

    func rankIcon(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "🏸"
        }
    }

    func loadMember() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }

                totalPoint = data["totalPoint"] as? Int ?? 0
                availablePoint = data["availablePoint"] as? Int ?? 0
                cleanupTickets = data["cleanupTickets"] as? Int ?? 0
                discountTickets = data["discountTickets"] as? Int ?? 0
                freeTickets = data["freeTickets"] as? Int ?? 0
                halfPriceTickets = data["halfPriceTickets"] as? Int ?? 0
                challengeTickets = data["challengeTickets"] as? Int ?? 0
                memberNo = data["memberNo"] as? Int ?? 999999
                legendCount = data["legendCount"] as? Int ?? 0
                isLegend = data["isLegend"] as? Bool ?? false
            }
    }

    func loadRanking() {
        db.collection("members")
            .order(by: "totalPoint", descending: true)
            .getDocuments { snapshot, _ in

                let members = snapshot?.documents.compactMap { document -> Member? in
                    let data = document.data()

                    return Member(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        role: MemberRole(rawValue: data["role"] as? String ?? "メンバー") ?? .member,
                        isAdmin: data["isAdmin"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,
                        gender: Gender(rawValue: data["gender"] as? String ?? "男性") ?? .male,
                        level: MemberLevel(rawValue: data["level"] as? String ?? "初心者") ?? .beginner,
                        totalPoint: data["totalPoint"] as? Int ?? 0,
                        availablePoint: data["availablePoint"] as? Int ?? 0,
                        cleanupTickets: data["cleanupTickets"] as? Int ?? 0,
                        discountTickets: data["discountTickets"] as? Int ?? 0,
                        freeTickets: data["freeTickets"] as? Int ?? 0,
                        attendanceCount: data["attendanceCount"] as? Int ?? 0,
                        setupCount: data["setupCount"] as? Int ?? 0
                    )
                } ?? []

                rankingMembers = Array(members.prefix(3))
                totalMembersCount = members.count

                if let index = members.firstIndex(where: { $0.id == currentUserId }) {
                    myRank = index + 1
                } else {
                    myRank = 0
                }
            }
    }
}

extension View {
    func cardStyle(imageName: String) -> some View {
        self
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 320)
            .background {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.00)
                        .offset(x: -75, y: 0)

                    Color.black.opacity(0.04)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.45), radius: 25, x: 0, y: 18)
    }
}

#Preview {
    NavigationStack {
        PointCardView()
    }
}
