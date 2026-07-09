import SwiftUI
import FirebaseFirestore

struct PointCardView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var memberNo = 1
    @State private var memberName = ""

    @State private var totalPoint = 0
    @State private var availablePoint = 0
    @State private var monthlyPoint = 0

    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var stringingFreeTickets = 0

    @State private var monthlyChampionCount = 0
    @State private var monthlySecondCount = 0
    @State private var monthlyThirdCount = 0
    @State private var mvpCount = 0

    @State private var myRank = 0
    @State private var myRankingPoint = 0
    @State private var pointToNextRank = 0
    @State private var targetRank = 0
    @State private var rankingMembers: [Member] = []

    @State private var isFlipped = false
    @State private var hasLoadedMember = false

    @State private var showRankUpAlert = false
    @State private var rankUpMessage = ""

    @State private var showUseTicketAlert = false
    @State private var selectedTicketTitle = ""
    @State private var selectedTicketField = ""
    @State private var selectedTicketIcon = ""

    @State private var showActivityTicketAlert = false
    @State private var showAlreadyAwardedAlert = false
    @State private var showMonthlyAwardAlert = false
    @State private var showMonthlyAwardDoneAlert = false

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
        if availablePoint < 100 {
            return ("片付けパス", 100, "🧹")
        } else if availablePoint < 200 {
            return ("参加費500円券", 200, "💰")
        } else if availablePoint < 400 {
            return ("参加費半額券", 400, "🏸")
        } else {
            return ("参加費無料券", 700, "🎁")
        }
    }

    var remainingPoint: Int {
        max(nextReward.point - availablePoint, 0)
    }

    var progressToNextRank: Double {
        guard pointToNextRank > 0 else { return 1.0 }
        let goal = myRankingPoint + pointToNextRank
        guard goal > 0 else { return 0.0 }
        return min(Double(myRankingPoint) / Double(goal), 1.0)
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

                if currentUserIsAdmin {
                    monthlyAwardButton
                }
                

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

                if currentUserIsAdmin {
                    NavigationLink {
                        TicketUsageHistoryView()
                    } label: {
                        Label("🎫 チケット使用履歴", systemImage: "clock.badge.checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }

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
        .alert("🎉 RANK UP!", isPresented: $showRankUpAlert) {
            Button("OK") { }
        } message: {
            Text(rankUpMessage)
        }
        .alert("チケットを使用しますか？", isPresented: $showUseTicketAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("使用する", role: .destructive) {
                useTicket()
            }
        } message: {
            Text("使用すると元に戻せません。")
        }
        .alert("活動詳細から使用してください", isPresented: $showActivityTicketAlert) {
            Button("OK") { }
        } message: {
            Text("このチケットは活動に紐づけて使用するため、近日の活動詳細画面から使用してください。")
        }
        .alert("🏆 月間表彰", isPresented: $showMonthlyAwardAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("確定する") {
                grantMonthlyAwards()
            }
        } message: {
            Text("今月の表彰を確定しますか？\n\n🥇1位\n🎾 ガット張り工賃無料券 ×1\n\n🥈2位\n⭐ 対戦指名券 ×1\n\n🥉3位\n🚀 優先ゲーム券 ×1\n\n今月は一度だけ実行できます。")
        }
        .alert("🎉 月間表彰完了", isPresented: $showMonthlyAwardDoneAlert) {
            Button("OK") { }
        } message: {
            Text("受賞回数と特典チケットを反映しました。")
        }
        .alert("今月は表彰済みです", isPresented: $showAlreadyAwardedAlert) {
            Button("OK") { }
        } message: {
            Text("月間表彰は月に1回だけ実行できます。")
        }
    }

    var flippingCard: some View {
        ZStack {
            memberCard.opacity(isFlipped ? 0 : 1)
            rankingCard.opacity(isFlipped ? 1 : 0)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                   
                    Text("SiRiUS MEMBER CARD")
                        .offset(x: 0, y: 35)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .opacity(0.7)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(memberName.isEmpty ? "MEMBER" : memberName)
                        .offset(x: -12, y: 5)
                        .font(.system(size: 17, weight: .black))
                        .lineLimit(1)

                    Text("No. \(String(format: "%06d", memberNo))")
                        .offset(x: -3, y: 5)
                        .font(.system(size: 9, weight: .bold))
                        .opacity(0.7)
                    
                    Text(rankBadge)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.1)
                        .padding(.horizontal, 8)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                        .offset(x: 0, y: 3)
                }
            }

            Spacer()

            VStack(spacing: 0) {
                Text("TOTAL POINT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .opacity(0.7)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(totalPoint)")
                        .font(.system(size: 52, weight: .black))

                    Text("pt")
                        .font(.system(size: 18, weight: .black))
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            HStack(spacing: 7) {
                walletBox(title: "今月", value: "\(monthlyPoint)pt")
                walletBox(title: "利用可能", value: "\(availablePoint)pt")

                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                        .opacity(0.7)

                    Text("\(nextReward.icon) \(nextReward.title)")
                        .font(.system(size: 10, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("あと\(remainingPoint)pt")
                        .font(.system(size: 9, weight: .medium))
                        .opacity(0.7)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer(minLength: 6)

            HStack {
                Text("OFFICIAL MEMBER")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .opacity(0.6)

                Spacer()

                Image(systemName: "qrcode")
                    .font(.system(size: 18))
                    .opacity(0.2)
            }
        }
        .padding(14)
        .cardStyle(imageName: cardBackground)
    }
    func walletBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .opacity(0.7)

            Text(value)
                .font(.system(size: 13, weight: .black))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 72, alignment: .leading)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    var rankingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("今月ランキング")
                    .font(.system(size: 18, weight: .black))

                Spacer()

                
            }

            Spacer(minLength: 8)

            if rankingMembers.isEmpty {
                Spacer()
                Text("ランキングを読み込み中...")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(rankingMembers.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: 7) {
                            Text(rankIcon(index))
                                .frame(width: 22)

                            Text("\(index + 1)位")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 30, alignment: .leading)

                            Text(member.name)
                                .font(.system(size: 14, weight: .black))
                                .lineLimit(1)

                            Spacer()

                            Text("\(member.monthlyPoint)pt")
                                .offset(x: -90)
                                .font(.system(size: 14, weight: .black))
                        }
                    }
                }

                Spacer(minLength: 8)

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 1)

                Spacer(minLength: 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("あなた")
                            .font(.system(size: 10, weight: .bold))
                            .opacity(0.7)

                        Text(myRank == 0 ? "-位" : "\(myRank)位")
                            .font(.system(size: 34, weight: .black))

                        Text("現在の順位")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.65)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(myRankingPoint)pt")
                            .font(.system(size: 30, weight: .black))

                        Text("今月ポイント")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.65)

                        if myRank == 1 {
                            Text("👑 現在トップ！")
                                .font(.system(size: 11, weight: .black))
                        } else if pointToNextRank > 0 {
                            Text("あと\(pointToNextRank)pt")
                                .font(.system(size: 10, weight: .black))
                        }
                    }
                }
            }
        }
        .padding(14)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .cardStyle(imageName: cardBackground)
    }
    var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎫 My Tickets")
                .font(.title2)
                .bold()

            ticketRow(icon: "🎾", title: "ガット張り工賃無料券", count: stringingFreeTickets, ticketField: "stringingFreeTickets")
            Divider()
            ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets, ticketField: "challengeTickets")
            Divider()
            ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets, ticketField: "priorityTickets")
            Divider()
            ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets, ticketField: "cleanupTickets")
            Divider()
            ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets, ticketField: "discountTickets")
            Divider()
            ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets, ticketField: "halfPriceTickets")
            Divider()
            ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets, ticketField: "freeTickets")
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

            exchangeButton(title: "片付けパス", point: 100, icon: "🧹", ticketField: "cleanupTickets")
            exchangeButton(title: "参加費500円券", point: 200, icon: "💰", ticketField: "discountTickets")
            exchangeButton(title: "参加費半額券", point: 400, icon: "🏸", ticketField: "halfPriceTickets")
            exchangeButton(title: "参加費無料券", point: 700, icon: "🎁", ticketField: "freeTickets")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    var monthlyAwardButton: some View {
        Button {
            checkMonthlyAward()
        } label: {
            HStack {
                Text("🏆")
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("月間表彰を確定する")
                        .font(.headline)

                    Text("1位〜3位に特典を付与して今月ポイントをリセット")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
   
    func ticketRow(icon: String, title: String, count: Int, ticketField: String) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                Text("残り \(count)枚")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard count > 0 else { return }

            if ticketField == "priorityTickets" || ticketField == "challengeTickets" {
                showActivityTicketAlert = true
                return
            }

            selectedTicketTitle = title
            selectedTicketField = ticketField
            selectedTicketIcon = icon
            showUseTicketAlert = true
        }
    }

    func exchangeButton(title: String, point: Int, icon: String, ticketField: String) -> some View {
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

                let oldPoint = totalPoint
                let newPoint = data["totalPoint"] as? Int ?? 0

                totalPoint = newPoint
                availablePoint = data["availablePoint"] as? Int ?? 0
                monthlyPoint = data["monthlyPoint"] as? Int ?? 0

                cleanupTickets = data["cleanupTickets"] as? Int ?? 0
                discountTickets = data["discountTickets"] as? Int ?? 0
                halfPriceTickets = data["halfPriceTickets"] as? Int ?? 0
                freeTickets = data["freeTickets"] as? Int ?? 0
                stringingFreeTickets = data["stringingFreeTickets"] as? Int ?? 0
                challengeTickets = data["challengeTickets"] as? Int ?? 0
                priorityTickets = data["priorityTickets"] as? Int ?? 0

                memberNo = data["memberNo"] as? Int ?? 999999
                memberName = data["name"] as? String ?? "MEMBER"

                monthlyChampionCount = data["monthlyChampionCount"] as? Int ?? 0
                monthlySecondCount = data["monthlySecondCount"] as? Int ?? 0
                monthlyThirdCount = data["monthlyThirdCount"] as? Int ?? 0
                mvpCount = data["mvpCount"] as? Int ?? 0

                if hasLoadedMember {
                    checkRankUp(oldPoint: oldPoint, newPoint: newPoint)
                } else {
                    hasLoadedMember = true
                }
            }
    }

    func useTicket() {
        PointService.shared.useTicket(
            memberId: currentUserId,
            ticketField: selectedTicketField,
            title: selectedTicketTitle,
            icon: selectedTicketIcon
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loadMember()
        }
    }

    func checkRankUp(oldPoint: Int, newPoint: Int) {
        if oldPoint < 700 && newPoint >= 700 {
            rankUpMessage = "👑 Legend Player\n\n⭐ 対戦指名券 ×2\n🚀 優先ゲーム券 ×2 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 400 && newPoint >= 400 {
            rankUpMessage = "💎 Platinum Player\n\n⭐ 対戦指名券 ×1\n🚀 優先ゲーム券 ×1 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 200 && newPoint >= 200 {
            rankUpMessage = "🥇 Gold Player\n\n⭐ 対戦指名券 ×2 を獲得しました！"
            showRankUpAlert = true
        } else if oldPoint < 100 && newPoint >= 100 {
            rankUpMessage = "🥈 Silver Player\n\n⭐ 対戦指名券 ×1 を獲得しました！"
            showRankUpAlert = true
        }
    }

    func loadRanking() {
        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
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
                        halfPriceTickets: data["halfPriceTickets"] as? Int ?? 0,
                        freeTickets: data["freeTickets"] as? Int ?? 0,
                        challengeTickets: data["challengeTickets"] as? Int ?? 0,
                        priorityTickets: data["priorityTickets"] as? Int ?? 0,
                        attendanceCount: data["attendanceCount"] as? Int ?? 0,
                        setupCount: data["setupCount"] as? Int ?? 0,
                        monthlyChampionCount: data["monthlyChampionCount"] as? Int ?? 0,
                        monthlySecondCount: data["monthlySecondCount"] as? Int ?? 0,
                        monthlyThirdCount: data["monthlyThirdCount"] as? Int ?? 0,
                        mvpCount: data["mvpCount"] as? Int ?? 0,
                        monthlyPoint: data["monthlyPoint"] as? Int ?? 0,
                        legendCount: data["legendCount"] as? Int ?? 0,
                        isLegend: data["isLegend"] as? Bool ?? false,
                        profileImageBase64: data["profileImageBase64"] as? String ?? ""
                    )
                } ?? []

                rankingMembers = Array(members.prefix(5))

                if let index = members.firstIndex(where: { $0.id == currentUserId }) {
                    myRank = index + 1
                    myRankingPoint = members[index].monthlyPoint

                    if index == 0 {
                        pointToNextRank = 0
                        targetRank = 0
                    } else if index >= 5, members.count >= 5 {
                        let targetPoint = members[4].monthlyPoint
                        pointToNextRank = max(targetPoint - myRankingPoint + 1, 0)
                        targetRank = 5
                    } else {
                        let targetPoint = members[index - 1].monthlyPoint
                        pointToNextRank = max(targetPoint - myRankingPoint + 1, 0)
                        targetRank = index
                    }
                } else {
                    myRank = 0
                    myRankingPoint = 0
                    pointToNextRank = 0
                    targetRank = 0
                }
            }
    }

    func grantMonthlyAwards() {
        guard rankingMembers.count >= 3 else { return }

        PointService.shared.addMonthlyAward(
            memberId: rankingMembers[0].id,
            field: "monthlyChampionCount"
        )

        PointService.shared.addMonthlyAward(
            memberId: rankingMembers[1].id,
            field: "monthlySecondCount"
        )

        PointService.shared.addMonthlyAward(
            memberId: rankingMembers[2].id,
            field: "monthlyThirdCount"
        )

        PointService.shared.resetAllMonthlyPoints()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())

        db.collection("settings")
            .document("monthlyAward")
            .setData([
                "lastAwardMonth": currentMonth
            ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loadMember()
            loadRanking()
            showMonthlyAwardDoneAlert = true
        }
    }

    func checkMonthlyAward() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())

        db.collection("settings")
            .document("monthlyAward")
            .getDocument { snapshot, _ in
                let lastMonth = snapshot?.data()?["lastAwardMonth"] as? String ?? ""

                if lastMonth == currentMonth {
                    showAlreadyAwardedAlert = true
                } else {
                    showMonthlyAwardAlert = true
                }
            }
    }
}

extension View {
    func cardStyle(imageName: String) -> some View {
        self
            .foregroundStyle(.white)
            .frame(width: 340, height: 214)
            .background {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 340, height: 214)
                        .clipped()

                    LinearGradient(
                        colors: [
                            .black.opacity(0.32),
                            .black.opacity(0.05),
                            .black.opacity(0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.42), radius: 22, x: 0, y: 14)
    }
}
