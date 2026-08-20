import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import UIKit

struct MyPageView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var name = ""
    @State private var memberNo = 0
    @State private var gender = ""
    @State private var level = ""
    
    @State private var badmintonStartAge = 0
    @State private var badmintonYears = 0
    @State private var racket = ""
    @State private var stringName = ""
    @State private var tension = ""
    @State private var playStyle = ""
    @State private var comment = ""
    @State private var dominantHand = ""
    @State private var favoriteShot = ""
    @State private var favoriteEvent = ""
    @State private var courtPosition = ""
    
    @State private var showProfileEditor = false
    
    @State private var currentRank = 0

    @State private var referralCount = 0
    @State private var gachaCount = 0
    @State private var totalPoint = 0
    @State private var availablePoint = 0
    @State private var monthlyPoint = 0

    @State private var attendanceCount = 0
    @State private var setupCount = 0
    @State private var streakCount = 0
    @State private var mvpCount = 0
    @State private var monthlyChampionCount = 0
    @State private var monthlySecondCount = 0
    @State private var monthlyThirdCount = 0
    @State private var legendCount = 0
    @State private var tournamentCount = 0
    @State private var totalGames = 0
    @State private var totalWins = 0
    @State private var longestStreakCount = 0
    
    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var stringingFreeTickets = 0

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    @State private var selectedAchievement: Achievement?
    @State private var selectedBadgeTitle = ""
    @State private var showBadgeDescription = false
    @State private var unlockedAchievement: Achievement?
    
    @State private var showLevelUp = false
    @State private var previousLevel = 1
    
    @State private var recentActivities: [String] = []
    @State private var savedBadgeIds: [String] = []
    @State private var profileRingFlow = false
    var earnedBadges: [(icon: String, title: String)] {
        var badges: [(icon: String, title: String)] = []

        if totalPoint >= 700 {
            badges.append(("👑", "LEGEND"))
        }

        if monthlyChampionCount >= 1 {
            badges.append(("🏆", "月間王者"))
        }

        if mvpCount >= 1 {
            badges.append(("⭐", "MVP"))
        }

        if attendanceCount >= 10 {
            badges.append(("🔥", "常連"))
        }

        if attendanceCount >= 50 {
            badges.append(("💪", "ベテラン"))
        }

        if setupCount >= 10 {
            badges.append(("🧹", "設営王候補"))
        }

        if streakCount >= 5 {
            badges.append(("⚡", "\(streakCount)連続参加"))
        }

        if referralCount >= 1 {
            badges.append(("👥", "紹介者"))
        }
        for badgeId in savedBadgeIds {
            let savedBadge: (icon: String, title: String)

            switch badgeId {
            case "monthlyContributor":
                savedBadge = ("🏅", "今月の貢献者")
            case "monthlyChampion":
                savedBadge = ("🏆", "月間王者")

            case "setupKing":
                savedBadge = ("🧹", "設営王")

            case "perfectAttendance":
                savedBadge = ("🔥", "皆勤賞")

            case "mvp":
                savedBadge = ("⭐", "MVP")

            case "legend":
                savedBadge = ("👑", "LEGEND")

            default:
                savedBadge = ("🏅", badgeId)
            }

            let alreadyExists = badges.contains {
                $0.title == savedBadge.title
            }

            if !alreadyExists {
                badges.append(savedBadge)
            }
        }
        return badges
    }
    var rankBadge: String {
        if totalPoint >= 700 { return "LEGEND" }
        if totalPoint >= 400 { return "PLATINUM" }
        if totalPoint >= 200 { return "GOLD" }
        if totalPoint >= 100 { return "SILVER" }
        return "BRONZE"
    }

    var rankIcon: String {
        if totalPoint >= 700 { return "👑" }
        if totalPoint >= 400 { return "💎" }
        if totalPoint >= 200 { return "🥇" }
        if totalPoint >= 100 { return "🥈" }
        return "🥉"
    }
    var memberLevel: Int {
        max(1, totalPoint / 50 + 1)
    }

    var nextRankPoint: Int {
        if totalPoint < 100 { return 100 }
        if totalPoint < 200 { return 200 }
        if totalPoint < 400 { return 400 }
        if totalPoint < 700 { return 700 }
        return 700
    }

    var nextRankText: String {
        if totalPoint < 100 { return "あと\(100 - totalPoint)ptでSILVER" }
        if totalPoint < 200 { return "あと\(200 - totalPoint)ptでGOLD" }
        if totalPoint < 400 { return "あと\(400 - totalPoint)ptでPLATINUM" }
        if totalPoint < 700 { return "あと\(700 - totalPoint)ptでLEGEND" }
        return "LEGEND達成！"
    }

    var rankProgress: Double {
        if totalPoint >= 700 { return 1.0 }
        return min(Double(totalPoint) / Double(nextRankPoint), 1.0)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileCard.siriusScrollEntrance()
                    badmintonProfileCard.siriusScrollEntrance()
                    activityDataCard.siriusScrollEntrance()
                    achievementGrid.siriusScrollEntrance()
                    earnedBadgesCard.siriusScrollEntrance()
                    if currentUserIsAdmin {
                        adminSection.siriusScrollEntrance()
                    }
                    settingsSection.siriusScrollEntrance()
                    logoutButton.siriusScrollEntrance()
                }
                .padding()
            }
            .background(MyPagePremiumBackground(pulse: false).ignoresSafeArea())
            .navigationTitle("MY PAGE")
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedAchievement) { achievement in

                VStack(spacing: 24) {

                    Text(achievement.icon)
                        .font(.system(size: 70))

                    Text(achievement.title)
                        .font(.largeTitle)
                        .bold()

                    Text(achievement.description)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {

                        Label(
                            "報酬：\(achievement.reward)",
                            systemImage: "gift.fill"
                        )

                        Label(
                            achievement.isAchieved ? "達成済み" : "未達成",
                            systemImage: achievement.isAchieved
                            ? "checkmark.circle.fill"
                            : "lock.fill"
                        )
                    }
                    .font(.headline)

                    Spacer()
                }
                .padding()
            }
            .alert(selectedBadgeTitle, isPresented: $showBadgeDescription) {
                Button("OK") { }
            } message: {
                Text(badgeDescription(title: selectedBadgeTitle))
            }
           
            .fullScreenCover(isPresented: $showLevelUp) {
                LevelUpView(
                    oldLevel: previousLevel,
                    newLevel: memberLevel
                )
            }
            .onAppear {
                loadMember()
                loadMyRank()
                if !profileRingFlow {
                    withAnimation(.linear(duration: 52).repeatForever(autoreverses: false)) {
                        profileRingFlow = true
                    }
                }
               
            }
            .onChange(of: selectedPhoto) { _, newItem in
                if let newItem {
                    loadSelectedPhoto(newItem)
                }
            }
        }
    }

    var profileCard: some View {
        VStack(spacing: 6) {
            ZStack {
                if let profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 104, height: 104)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 104))
                        .foregroundStyle(.gray.opacity(0.45))
                }

            }
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.yellow.opacity(0.95), .orange.opacity(0.72), .yellow.opacity(0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 112, height: 112)

                Circle()
                    .trim(from: 0.05, to: 0.30)
                    .stroke(
                        AngularGradient(colors: [.cyan, .purple, .pink, .yellow, .cyan], center: .center),
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                    )
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(profileRingFlow ? 360 : 0))
                    .shadow(color: .purple.opacity(0.34), radius: 5)
            }
            .overlay(alignment: .top) {
                Text(rankIcon)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.24), radius: 4, y: 2)
                    .shadow(color: .yellow.opacity(0.22), radius: 6)
                    .offset(y: -28)
            }
            .shadow(color: .yellow.opacity(0.14), radius: 7)
            .padding(.top, 8)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("写真を変更")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            Text(name.isEmpty ? "メンバー" : name)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .padding(.horizontal, 16)

            HStack(spacing: 8) {
                Text(rankIcon)
                Text(rankBadge).tracking(1.2)
            }
            .font(.title3.bold())
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(rankColor.opacity(0.18))
            .foregroundStyle(rankColor)
            .clipShape(Capsule())

            Text("Lv.\(memberLevel)")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.38))
                    Capsule()
                        .fill(LinearGradient(colors: [.orange, .yellow.opacity(0.92)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * min(Double(totalPoint % 50) / 50, 1))
                        .shadow(color: .orange.opacity(0.30), radius: 3)
                }
            }
                .frame(width: 240, height: 4)
                .animation(.easeInOut(duration: 0.8), value: totalPoint)

            if streakCount > 0 {
                Text("🔥 現在\(streakCount)連続参加中")
                    .font(.headline.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("次の参加から連続記録スタート")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Member No. \(String(format: "%06d", memberNo))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.07), .purple.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 6)
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditView()
        }
    }

    var pointCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ポイント")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            HStack {
                profileStatBox(icon: "star.fill", title: "累計", value: "\(totalPoint)pt", color: .yellow)
                profileStatBox(icon: "gift.fill", title: "利用可能", value: "\(availablePoint)pt", color: .blue)
                profileStatBox(icon: "flame.fill", title: "今月", value: "\(monthlyPoint)pt", color: .orange)
                profileStatBox(icon: "trophy.fill", title: "順位", value: currentRank == 0 ? "-" : "\(currentRank)位", color: .yellow)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("次のランクまで")
                        .font(.headline)
                        .bold()

                    Spacer()

                    Text(nextRankText)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: rankProgress)
                    .tint(rankColor)
                    .scaleEffect(y: 1.4)

                Text("\(totalPoint) / \(nextRankPoint)pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .mypageCard()
    }

    var badmintonProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("バドプロフィール", icon: "figure.badminton")

                Spacer()

                Button {
                    showProfileEditor = true
                } label: {
                    Label("編集", systemImage: "pencil")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.16))
                        .clipShape(Capsule())
                }
            }

            badmintonProfileRow(icon: "hand.raised.fill", title: "利き手", value: dominantHand)
            badmintonProfileRow(icon: "sportscourt.fill", title: "得意種目", value: favoriteEvent.isEmpty ? favoriteShot : favoriteEvent)
            badmintonProfileRow(icon: "person.2.fill", title: "ポジション", value: courtPosition.isEmpty ? playStyle : courtPosition)
            badmintonProfileRow(icon: "figure.badminton", title: "使用ラケット", value: racket)
            badmintonProfileRow(icon: "circle.grid.cross.fill", title: "使用ガット", value: stringName)
            badmintonProfileRow(icon: "person.text.rectangle", title: "所属クラス", value: level)
            badmintonProfileRow(icon: "calendar", title: "バド歴", value: badmintonYears > 0 ? "\(badmintonYears)年" : "")

            if !comment.isEmpty {
                Divider().overlay(Color.white.opacity(0.12))
                Label(comment, systemImage: "quote.bubble.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .mypageCard()
    }

    var activityDataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("活動データ", icon: "chart.bar.xaxis")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                activityMetric(icon: "figure.badminton", title: "練習参加", value: "\(attendanceCount)回", color: .blue, emphasized: true)
                activityMetric(icon: "flag.checkered", title: "大会参加", value: "\(tournamentCount)回", color: .purple)
                activityMetric(icon: "trophy.fill", title: "優勝", value: "\(monthlyChampionCount)回", color: .yellow)
                activityMetric(icon: "medal.fill", title: "準優勝", value: "\(monthlySecondCount)回", color: .orange)
                activityMetric(icon: "star.fill", title: "MVP獲得", value: "\(mvpCount)回", color: .yellow)
                activityMetric(icon: "percent", title: "勝率", value: totalGames > 0 ? "\(Int((Double(totalWins) / Double(totalGames) * 100).rounded()))%" : "—", color: .mint)
                activityMetric(icon: "flame.fill", title: "最長連続参加", value: "\(max(longestStreakCount, streakCount))回", color: .orange)
                activityMetric(icon: "circle.grid.3x3.fill", title: "累計ゲーム", value: "\(totalGames)回", color: .indigo)
            }
        }
        .mypageCard()
    }

    var earnedBadgesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("獲得バッジ", icon: "medal.fill")

            if earnedBadges.isEmpty {
                Text("獲得済みのバッジはまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(earnedBadges.enumerated()), id: \.offset) { _, badge in
                        Button {
                            selectedBadgeTitle = badge.title
                            showBadgeDescription = true
                        } label: {
                            VStack(spacing: 8) {
                                Text(badge.icon).font(.title)
                                Text(badge.title)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Text(badgeShortDescription(title: badge.title))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.52))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.70)
                            }
                            .frame(maxWidth: .infinity, minHeight: 88)
                            .background(badgeColor(title: badge.title).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(badgeColor(title: badge.title).opacity(0.34), lineWidth: 1)
                            }
                        }
                        .buttonStyle(MyPageMenuButtonStyle())
                    }
                }
            }
        }
        .mypageCard()
    }

    var recentAchievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("最近獲得した実績", systemImage: "sparkles")
                    .font(.title2.bold())
                Spacer()
                Text("NEW")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.yellow)
            }
            .foregroundStyle(.white)

            if earnedBadges.isEmpty {
                Text("新しい実績はまだありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(earnedBadges.prefix(3).enumerated()), id: \.offset) { _, badge in
                    HStack(spacing: 12) {
                        Text(badge.icon).font(.title2)
                        Text(badge.title).font(.headline.bold())
                        Spacer()
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.yellow)
                    }
                    .padding(12)
                    .background(badgeColor(title: badge.title).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .mypageCard()
    }

    var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("最近の活動履歴", systemImage: "clock.arrow.circlepath")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if recentActivities.isEmpty {
                Text("まだ活動履歴はありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(recentActivities.enumerated()), id: \.offset) { index, activity in
                    HStack(spacing: 13) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.12))
                                .frame(width: 42, height: 42)
                            Image(systemName: "figure.badminton")
                                .foregroundStyle(.cyan)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.90))
                                .lineLimit(2)
                            Text(index == 0 ? "最新の活動" : "参加履歴")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.42))
                        }
                        Spacer(minLength: 8)
                        if !activity.contains("不参加") {
                            Text("+5pt")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 0.7)
                    }
                }
            }
        }
        .mypageCard()
    }

    var pointRuleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ポイントルール", systemImage: "list.bullet.rectangle.portrait.fill")
                .font(.title2.bold())
                .foregroundStyle(.white)

            pointRuleRow(icon: "figure.badminton", title: "練習参加", point: "+5pt")
            pointRuleRow(icon: "clock.badge.checkmark.fill", title: "前日回答", point: "+2pt")
            pointRuleRow(icon: "wrench.and.screwdriver.fill", title: "設営", point: "+5pt")
            pointRuleRow(icon: "person.badge.plus.fill", title: "新規紹介", point: "+20pt")
        }
        .mypageCard()
    }

    var recentTicketsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("最近獲得したチケット", systemImage: "ticket.fill")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if ownedTicketSummary.isEmpty {
                Text("獲得したチケットはまだありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(ownedTicketSummary.prefix(3).enumerated()), id: \.offset) { _, ticket in
                    HStack(spacing: 12) {
                        Text(ticket.icon).font(.title2)
                        Text(ticket.title).font(.headline)
                        Spacer()
                        Text("×\(ticket.count)")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .mypageCard()
    }

    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("設定", icon: "gearshape.fill")

            Button {
                showProfileEditor = true
            } label: {
                menuRow(icon: "person.crop.circle.fill", title: "プロフィール編集", color: .cyan)
            }

            NavigationLink { MyPageSettingDetailView(title: "通知設定", message: "通知は端末の設定から変更できます。") } label: {
                menuRow(icon: "bell.fill", title: "通知設定", color: .orange)
            }
            NavigationLink { MyPageSettingDetailView(title: "テーマ", message: "SIRIUS Premiumテーマを使用中です。") } label: {
                menuRow(icon: "paintpalette.fill", title: "テーマ", color: .purple)
            }
            NavigationLink { MyPageSettingDetailView(title: "アプリについて", message: "CircleAccount / SIRIUS Premium") } label: {
                menuRow(icon: "info.circle.fill", title: "アプリについて", color: .blue)
            }
            NavigationLink { MyPageSettingDetailView(title: "利用規約", message: "利用規約をご確認ください。") } label: {
                menuRow(icon: "doc.text.fill", title: "利用規約", color: .gray)
            }
            NavigationLink { MyPageSettingDetailView(title: "プライバシーポリシー", message: "プライバシーポリシーをご確認ください。") } label: {
                menuRow(icon: "hand.raised.fill", title: "プライバシーポリシー", color: .mint)
            }
            NavigationLink { MyPageSettingDetailView(title: "お問い合わせ", message: "管理者までお問い合わせください。") } label: {
                menuRow(icon: "envelope.fill", title: "お問い合わせ", color: .cyan)
            }
        }
        .mypageCard()
        .buttonStyle(MyPageMenuButtonStyle())
    }

    var achievementGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink {
                AchievementsView(achievements: achievements)
            } label: {
                HStack {
                    sectionHeader("実績", icon: "trophy.fill")

                    Spacer()

                    Text("\(achievedCount)/\(achievements.count) 達成")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(MyPageMenuButtonStyle())

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                ForEach(achievements.prefix(6)) { achievement in
                    achievementBadge(achievement)
                }
            }

            NavigationLink {
                AchievementsView(achievements: achievements)
            } label: {
                Text("すべての実績を見る")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(MyPageMenuButtonStyle())
        }
        .mypageCard()
    }
    
    
    var adminSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("管理メニュー", icon: "crown.fill")

            NavigationLink { MembersView() } label: {
                menuRow(icon: "person.3.fill", title: "メンバー管理", color: .blue)
            }

            NavigationLink { ActivitiesView() } label: {
                menuRow(icon: "calendar", title: "活動管理", color: .orange)
            }

            NavigationLink { AccountingView() } label: {
                menuRow(icon: "creditcard.fill", title: "会計管理", color: .green)
            }
            NavigationLink { NoticeView() } label: {
                menuRow(
                    icon: "megaphone.fill",
                    title: "お知らせ管理",
                    color: .red
                )
            }
            NavigationLink { CalendarView() } label: {
                menuRow(icon: "calendar.circle.fill", title: "カレンダー管理", color: .purple)
            }
        }
        .mypageCard()
        .buttonStyle(MyPageMenuButtonStyle())
    }

    var logoutButton: some View {
        Button(role: .destructive) {
            do {
                try Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                UserDefaults.standard.removeObject(forKey: "currentUserName")
                UserDefaults.standard.removeObject(forKey: "currentUserIsAdmin")
            } catch {
                print(error.localizedDescription)
            }
        } label: {
            HStack {
                Spacer()
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("ログアウト").bold()
                Spacer()
            }
            .padding()
            .foregroundStyle(.red)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.red.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(MyPageMenuButtonStyle())
    }

    var rankColor: Color {
        if totalPoint >= 700 { return .yellow }
        if totalPoint >= 400 { return .purple }
        if totalPoint >= 200 { return .orange }
        if totalPoint >= 100 { return .gray }
        return .brown
    }
    var achievements: [Achievement] {
        [
            Achievement(
                icon: "🥉",
                title: "BRONZE",
                subtitle: "登録完了",
                description: "SiRiUSメンバーとして登録",
                reward: "なし",
                isAchieved: true,
                color: .brown
            ),

            Achievement(
                icon: "🥈",
                title: "SILVER",
                subtitle: totalPoint >= 100 ? "達成" : "\(totalPoint)/100pt",
                description: "累計100ptを獲得する",
                reward: "⭐ 対戦指名券 ×1",
                isAchieved: totalPoint >= 100,
                color: .gray
            ),

            Achievement(
                icon: "🥇",
                title: "GOLD",
                subtitle: totalPoint >= 200 ? "達成" : "\(totalPoint)/200pt",
                description: "累計200ptを獲得する",
                reward: "⭐ 対戦指名券 ×2",
                isAchieved: totalPoint >= 200,
                color: .orange
            ),

            Achievement(
                icon: "💎",
                title: "PLATINUM",
                subtitle: totalPoint >= 400 ? "達成" : "\(totalPoint)/400pt",
                description: "累計400ptを獲得する",
                reward: "⭐対戦指名券×1・🚀優先ゲーム券×1",
                isAchieved: totalPoint >= 400,
                color: .purple
            ),

            Achievement(
                icon: "👑",
                title: "LEGEND",
                subtitle: totalPoint >= 700 ? "達成" : "\(totalPoint)/700pt",
                description: "累計700ptを獲得する",
                reward: "⭐対戦指名券×2・🚀優先ゲーム券×2",
                isAchieved: totalPoint >= 700,
                color: .yellow
            ),

            Achievement(
                icon: "🎉",
                title: "初参加",
                subtitle: "\(attendanceCount)/1回",
                description: "初めて活動に参加する",
                reward: "+5pt",
                isAchieved: attendanceCount >= 1,
                color: .blue
            ),

            Achievement(
                icon: "🔥",
                title: "常連",
                subtitle: "\(attendanceCount)/10回",
                description: "10回参加する",
                reward: "+10pt",
                isAchieved: attendanceCount >= 10,
                color: .orange
            ),

            Achievement(
                icon: "💪",
                title: "ベテラン",
                subtitle: "\(attendanceCount)/50回",
                description: "50回参加する",
                reward: "限定バッジ",
                isAchieved: attendanceCount >= 50,
                color: .green
            ),

            Achievement(
                icon: "⚡",
                title: "100回参加",
                subtitle: "\(attendanceCount)/100回",
                description: "100回参加する",
                reward: "LEGEND称号",
                isAchieved: attendanceCount >= 100,
                color: .red
            ),

            Achievement(
                icon: "🧹",
                title: "設営デビュー",
                subtitle: "\(setupCount)/1回",
                description: "設営を1回担当する",
                reward: "限定バッジ",
                isAchieved: setupCount >= 1,
                color: .mint
            ),

            Achievement(
                icon: "🛠",
                title: "設営サポーター",
                subtitle: "\(setupCount)/5回",
                description: "設営を5回担当する",
                reward: "限定バッジ",
                isAchieved: setupCount >= 5,
                color: .blue
            ),

            Achievement(
                icon: "🏗",
                title: "設営マスター",
                subtitle: "\(setupCount)/20回",
                description: "設営を20回担当する",
                reward: "限定称号",
                isAchieved: setupCount >= 20,
                color: .orange
            ),
            Achievement(
                icon: "🏅",
                title: "今月の貢献者",
                subtitle: savedBadgeIds.contains("monthlyContributor")
                    ? "獲得済み"
                    : "未獲得",
                description: "月間ミッションをすべて達成する",
                reward: "限定バッジ",
                isAchieved: savedBadgeIds.contains("monthlyContributor"),
                color: .mint
            ),
            Achievement(
                icon: "🥇",
                title: "月間チャンピオン",
                subtitle: "\(monthlyChampionCount)回",
                description: "月間ランキング1位になる",
                reward: "🎾 ガット張り工賃無料券",
                isAchieved: monthlyChampionCount >= 1,
                color: .yellow
            ),

            Achievement(
                icon: "👑",
                title: "三連覇",
                subtitle: "\(monthlyChampionCount)/3回",
                description: "月間1位を3回獲得する",
                reward: "限定称号",
                isAchieved: monthlyChampionCount >= 3,
                color: .yellow
            ),

            Achievement(
                icon: "⭐",
                title: "MVP",
                subtitle: "\(mvpCount)回",
                description: "MVPを獲得する",
                reward: "+20pt",
                isAchieved: mvpCount >= 1,
                color: .yellow
            ),

            Achievement(
                icon: "🌟",
                title: "MVP×5",
                subtitle: "\(mvpCount)/5回",
                description: "MVPを5回獲得する",
                reward: "限定エフェクト",
                isAchieved: mvpCount >= 5,
                color: .purple
            ),

            Achievement(
                icon: "👥",
                title: "初紹介",
                subtitle: "\(referralCount)/1人",
                description: "新しいメンバーを紹介する",
                reward: "+20pt",
                isAchieved: referralCount >= 1,
                color: .blue
            ),

            Achievement(
                icon: "🚀",
                title: "紹介マスター",
                subtitle: "\(referralCount)/10人",
                description: "10人紹介する",
                reward: "限定称号",
                isAchieved: referralCount >= 10,
                color: .cyan
            ),

            Achievement(
                icon: "🎾",
                title: "ガット券GET",
                subtitle: "\(stringingFreeTickets)枚",
                description: "ガット張り工賃無料券を獲得",
                reward: "実績解除",
                isAchieved: stringingFreeTickets >= 1,
                color: .green
            ),
            Achievement(
                icon: "🧹",
                title: "設営王",
                subtitle: savedBadgeIds.contains("setupKing")
                    ? "獲得済み"
                    : "未獲得",
                description: "月間で最も多く設営を担当する",
                reward: "限定バッジ",
                isAchieved: savedBadgeIds.contains("setupKing"),
                color: .orange
            ),

            Achievement(
                icon: "🔥",
                title: "皆勤賞",
                subtitle: savedBadgeIds.contains("perfectAttendance")
                    ? "獲得済み"
                    : "未獲得",
                description: "その月のすべての活動に参加する",
                reward: "限定バッジ",
                isAchieved: savedBadgeIds.contains("perfectAttendance"),
                color: .red
            ),
            Achievement(
                icon: "🎁",
                title: "無料券GET",
                subtitle: "\(freeTickets)枚",
                description: "参加費無料券を獲得",
                reward: "実績解除",
                isAchieved: freeTickets >= 1,
                color: .pink
            )
            ,

            Achievement(
                icon: "🎰",
                title: "初ガチャ",
                subtitle: "\(gachaCount)/1回",
                description: "初めてガチャを回す",
                reward: "実績解除",
                isAchieved: gachaCount >= 1,
                color: .purple
            )
            ,

            Achievement(
                icon: "🎲",
                title: "ガチャ10回",
                subtitle: "\(gachaCount)/10回",
                description: "ガチャを10回回す",
                reward: "参加費500円券 ×1",
                isAchieved: gachaCount >= 10,
                color: .orange
            ),
            Achievement(
                icon: "🎰",
                title: "ガチャ50回",
                subtitle: "\(gachaCount)/50回",
                description: "ガチャを50回回す",
                reward: "参加費無料券 ×1",
                isAchieved: gachaCount >= 50,
                color: .pink
            ),

            Achievement(
                icon: "👑",
                title: "ガチャマスター",
                subtitle: "\(gachaCount)/100回",
                description: "ガチャを100回回す",
                reward: "限定称号",
                isAchieved: gachaCount >= 100,
                color: .yellow
            )
        ]
    }
    var achievedCount: Int {
        achievements.filter { $0.isAchieved }.count
    }
    var ownedTicketSummary: [(icon: String, title: String, count: Int)] {
        [
            ("🎁", "参加費無料券", freeTickets),
            ("🏸", "参加費半額券", halfPriceTickets),
            ("⭐", "対戦指名券", challengeTickets),
            ("🚀", "優先ゲーム券", priorityTickets),
            ("🎾", "ガット張り工賃無料券", stringingFreeTickets),
            ("💰", "参加費500円券", discountTickets),
            ("🧹", "片付けパス", cleanupTickets)
        ]
        .filter { $0.count > 0 }
    }
    func badgeColor(title: String) -> Color {
        switch title {
        case "LEGEND":
            return .yellow

        case "月間王者":
            return .orange
        case "今月の貢献者":
            return .mint
            
        case "MVP":
            return .yellow

        case "常連":
            return .red

        case "ベテラン":
            return .green

        case "設営王", "設営王候補":
            return .orange

        case "皆勤賞":
            return .red

        case "紹介者":
            return .blue

        default:
            return .purple
        }
    }

    func badgeDescription(title: String) -> String {
        switch title {
        case "LEGEND": return "累計ポイントで最高ランクへ到達した証です。"
        case "月間王者": return "月間ランキングで1位を獲得した証です。"
        case "MVP": return "活動でMVPに選ばれた証です。"
        case "常連": return "継続して活動へ参加した証です。"
        case "ベテラン": return "50回以上活動へ参加した証です。"
        case "設営王候補": return "設営を積極的に支えた証です。"
        case "紹介者": return "新しい仲間を紹介した証です。"
        default: return "継続的な活動によって獲得したSIRIUSバッジです。"
        }
    }

    func badgeShortDescription(title: String) -> String {
        switch title {
        case "LEGEND": return "最高ランク到達"
        case "月間王者": return "月間ランキング1位"
        case "MVP": return "MVP獲得"
        case "常連": return "継続参加達成"
        case "ベテラン": return "50回参加達成"
        case "設営王候補": return "設営サポート達成"
        case "紹介者": return "メンバー紹介達成"
        default:
            if title.contains("連続参加") { return "連続参加達成" }
            return "SIRIUS実績達成"
        }
    }

    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.90))
                .frame(width: 24, alignment: .center)
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
    func profileStatBox(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }

    func badmintonProfileRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.58))
            Spacer()
            Text(value.isEmpty ? "未登録" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    value.isEmpty
                        ? Color.white.opacity(0.42)
                        : Color.white
                )
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 10)
    }

    func activityMetric(icon: String, title: String, value: String, color: Color, emphasized: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color.opacity(0.90))
            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(Color.white.opacity(emphasized ? 0.080 : 0.055))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(emphasized ? 0.24 : 0.14), lineWidth: 1)
        }
    }

    func pointRuleRow(icon: String, title: String, point: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.yellow.opacity(0.88))
                .frame(width: 28)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
            Spacer()
            Text(point)
                .font(.headline.weight(.black))
                .foregroundStyle(.cyan)
        }
        .padding(.vertical, 3)
    }

    func achievementBadge(_ achievement: Achievement) -> some View {
        VStack(spacing: 10) {
            Text(achievement.isAchieved ? achievement.icon : "🔒")
                .font(.system(size: 34))

            Text(achievement.title)
                .font(.headline)
                .bold()
                .foregroundStyle(Color.white.opacity(0.96))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(achievement.isAchieved ? "✅ 達成済み" : achievement.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.90))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Divider()

            Text(achievement.description)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.66))
                .lineLimit(2)
                .lineSpacing(3)
                .minimumScaleFactor(0.75)

            HStack(spacing: 3) {
                Text("🎁")
                    .foregroundStyle(.orange)
                highlightedRewardText(achievement.reward)
            }
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial)
        .background(achievement.isAchieved ? achievement.color.opacity(0.12) : Color.black.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    achievementBorderStyle(achievement),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(achievement.isAchieved ? 1 : 0.72)
        .shadow(
            color: achievement.isAchieved
                ? achievementGlowColor(achievement).opacity(0.12)
                : .clear,
            radius: achievement.isAchieved ? 4 : 0
        )
        .onTapGesture {
            selectedAchievement = achievement
        }
    }

    func highlightedRewardText(_ reward: String) -> Text {
        let parts = reward.split(separator: "×", omittingEmptySubsequences: false)
        guard parts.count > 1 else {
            return Text(reward).foregroundColor(.white)
        }

        var result = Text(String(parts[0])).foregroundColor(.white)
        for part in parts.dropFirst() {
            let quantity = part.prefix { $0.isNumber }
            let remainder = part.dropFirst(quantity.count)
            result = result
                + Text("×\(quantity)").foregroundColor(.yellow)
                + Text(String(remainder)).foregroundColor(.white)
        }
        return result
    }

    func achievementGlowColor(_ achievement: Achievement) -> Color {
        switch achievement.title {
        case "BRONZE": return .brown
        case "SILVER": return Color.white.opacity(0.84)
        case "GOLD": return .yellow
        case "PLATINUM": return .cyan
        case "LEGEND": return .purple
        default: return achievement.color
        }
    }

    func achievementBorderStyle(_ achievement: Achievement) -> AnyShapeStyle {
        guard achievement.isAchieved else { return AnyShapeStyle(Color.clear) }
        if achievement.title == "LEGEND" {
            return AnyShapeStyle(
                AngularGradient(
                    colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                    center: .center
                )
            )
        }
        return AnyShapeStyle(achievementGlowColor(achievement).opacity(0.38))
    }
    func ticketRow(icon: String, title: String, count: Int) -> some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(title)
                .font(.headline)

            Spacer()

            Text("\(count)枚")
                .font(.headline)
                .bold()
                .foregroundStyle(count > 0 ? .primary : .secondary)
        }
    }

    func menuRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color.opacity(0.90))
            }
            .frame(width: 36, height: 36)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.90))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.white.opacity(0.48))
                .shadow(color: color.opacity(0.24), radius: 3)
                .frame(width: 16, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(0.10), radius: 7, y: 4)
    }

    func loadSelectedPhoto(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }

            let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 300))
            guard let jpegData = resizedImage.jpegData(compressionQuality: 0.35) else {
                return
            }

            let base64String = jpegData.base64EncodedString()

            await MainActor.run {
                profileImage = resizedImage
            }

            guard !currentUserId.isEmpty else { return }

            do {
                try await db.collection("members")
                    .document(currentUserId)
                    .updateData([
                        "profileImageBase64": base64String
                    ])
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func loadProfileImage(from base64String: String) {
        guard let data = Data(base64Encoded: base64String),
              let image = UIImage(data: data) else {
            return
        }

        profileImage = image
    }

    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let originX = (image.size.width - side) / 2
        let originY = (image.size.height - side) / 2

        guard let cgImage = image.cgImage?.cropping(
            to: CGRect(x: originX, y: originY, width: side, height: side)
        ) else {
            return image
        }

        let squareImage = UIImage(cgImage: cgImage)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    func loadMyRank() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
            .getDocuments { snapshot, _ in
                let members = snapshot?.documents ?? []

                if let index = members.firstIndex(where: { $0.documentID == currentUserId }) {
                    currentRank = index + 1
                } else {
                    currentRank = 0
                }
            }
    }
    func checkForNewAchievementUnlock() {
        guard !currentUserId.isEmpty else { return }

        let achievedAchievements = achievements.filter {
            $0.isAchieved
        }

        let achievedTitles = achievedAchievements.map {
            $0.title
        }

        let seenKey = "seenAchievementTitles_\(currentUserId)"
        let initializedKey = "achievementUnlockInitialized_\(currentUserId)"

        if !UserDefaults.standard.bool(forKey: initializedKey) {

            UserDefaults.standard.set(
                achievedTitles,
                forKey: seenKey
            )

            UserDefaults.standard.set(
                true,
                forKey: initializedKey
            )

            return
        }

        let seenTitles =
            UserDefaults.standard.stringArray(forKey: seenKey) ?? []

        guard let newAchievement = achievedAchievements.first(where: {
            !seenTitles.contains($0.title)
        }) else {
            return
        }

        var updatedTitles = seenTitles
        updatedTitles.append(newAchievement.title)

        UserDefaults.standard.set(
            updatedTitles,
            forKey: seenKey
        )

        unlockedAchievement = newAchievement
        if newAchievement.title == "ガチャ10回" {

            PointService.shared.grantAchievementRewardOnce(
                memberId: currentUserId,
                achievementId: "gacha10",
                ticketField: "discountTickets"
            ) { _ in }

        }

        if newAchievement.title == "ガチャ50回" {

            PointService.shared.grantAchievementRewardOnce(
                memberId: currentUserId,
                achievementId: "gacha50",
                ticketField: "freeTickets"
            ) { _ in }

        }
    }
    func checkForLevelUp() {
        guard !currentUserId.isEmpty else { return }

        let currentLevel = memberLevel
        let levelKey = "lastMemberLevel_\(currentUserId)"

        let savedLevel = UserDefaults.standard.integer(forKey: levelKey)

        // 初回は現在レベルを保存するだけ
        if savedLevel == 0 {
            UserDefaults.standard.set(currentLevel, forKey: levelKey)
            return
        }

        // 前回よりレベルが上がっていたら演出を表示
        if currentLevel > savedLevel {
            previousLevel = savedLevel

            UserDefaults.standard.set(
                currentLevel,
                forKey: levelKey
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showLevelUp = true
            }
        }
    }
    func loadMember() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    return
                }

                name = data["name"] as? String ?? ""
                memberNo = data["memberNo"] as? Int ?? 0
                gender = data["gender"] as? String ?? ""
                level = data["level"] as? String ?? ""
                savedBadgeIds = data["earnedBadges"] as? [String] ?? []
                badmintonStartAge = data["badmintonStartAge"] as? Int ?? 0
                badmintonYears = data["badmintonYears"] as? Int ?? 0
                racket = data["racket"] as? String ?? ""
                stringName = data["stringName"] as? String ?? ""
                tension = data["tension"] as? String ?? ""
                playStyle = data["playStyle"] as? String ?? ""
                dominantHand = data["dominantHand"] as? String ?? ""
                favoriteShot = data["favoriteShot"] as? String ?? ""
                favoriteEvent = data["favoriteEvent"] as? String ?? ""
                courtPosition = data["courtPosition"] as? String ?? ""
                comment = data["comment"] as? String ?? ""
                
                totalPoint = data["totalPoint"] as? Int ?? 0
                availablePoint = data["availablePoint"] as? Int ?? 0
                monthlyPoint = data["monthlyPoint"] as? Int ?? 0

                attendanceCount = data["attendanceCount"] as? Int ?? 0
                setupCount = data["setupCount"] as? Int ?? 0
                streakCount = data["streakCount"] as? Int ?? 0
                mvpCount = data["mvpCount"] as? Int ?? 0
                referralCount = data["referralCount"] as? Int ?? 0
                gachaCount = data["gachaCount"] as? Int ?? 0
                monthlyChampionCount = data["monthlyChampionCount"] as? Int ?? 0
                monthlySecondCount = data["monthlySecondCount"] as? Int ?? 0
                monthlyThirdCount = data["monthlyThirdCount"] as? Int ?? 0
                legendCount = data["legendCount"] as? Int ?? 0
                tournamentCount = data["tournamentCount"] as? Int ?? 0
                totalGames = data["totalGames"] as? Int ?? 0
                totalWins = data["totalWins"] as? Int ?? 0
                longestStreakCount = data["longestStreakCount"] as? Int ?? streakCount
                
                cleanupTickets = data["cleanupTickets"] as? Int ?? 0
                discountTickets = data["discountTickets"] as? Int ?? 0
                halfPriceTickets = data["halfPriceTickets"] as? Int ?? 0
                freeTickets = data["freeTickets"] as? Int ?? 0
                challengeTickets = data["challengeTickets"] as? Int ?? 0
                priorityTickets = data["priorityTickets"] as? Int ?? 0
                stringingFreeTickets = data["stringingFreeTickets"] as? Int ?? 0

                if let profileImageBase64 = data["profileImageBase64"] as? String {
                    loadProfileImage(from: profileImageBase64)
                }
                loadRecentActivities()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    checkForNewAchievementUnlock()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    checkForLevelUp()
                }
                checkDailyLoginReward()
            }
    }
    func checkDailyLoginReward() {
        guard !currentUserId.isEmpty else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let memberRef = db.collection("members").document(currentUserId)

        memberRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }

            if let lastLoginTimestamp = data["lastDailyLoginAt"] as? Timestamp {
                let lastLoginDate = Calendar.current.startOfDay(
                    for: lastLoginTimestamp.dateValue()
                )

                if lastLoginDate == today {
                    return
                }
            }

            PointService.shared.addPoint(
                memberId: currentUserId,
                point: 1,
                title: "デイリーログイン",
                icon: "📅"
            )

            memberRef.updateData([
                "lastDailyLoginAt": Timestamp(date: Date())
            ])
        }
    }
    func loadRecentActivities() {
        guard !currentUserId.isEmpty else { return }

        db.collection("activities")
            .order(by: "date", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 活動履歴取得失敗: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    recentActivities = []
                    return
                }

                var results: [String] = []

                for document in documents {
                    let data = document.data()

                    let title = data["title"] as? String ?? "活動"
                    let place = data["place"] as? String ?? ""
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()

                    let attendanceArray = data["attendance"] as? [[String: String]] ?? []

                    guard let myAttendance = attendanceArray.first(where: {
                        $0["memberId"] == currentUserId
                    }) else {
                        continue
                    }

                    let status = myAttendance["status"] ?? ""

                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "ja_JP")
                    formatter.dateFormat = "M/d"

                    let dateText = formatter.string(from: date)

                    let statusText: String

                    switch status {
                    case "参加":
                        statusText = "✅ 参加"
                    case "不参加":
                        statusText = "❌ 不参加"
                    case "未定":
                        statusText = "⏳ 未定"
                    default:
                        statusText = "・\(status)"
                    }

                    let placeText = place.isEmpty ? "" : "・\(place)"

                    results.append(
                        "\(dateText) \(title)\(placeText) \(statusText)"
                    )

                    if results.count >= 5 {
                        break
                    }
                }

                recentActivities = results
            }
    }
}

extension View {
    func mypageCard() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .background(Color.black.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.07),
                                Color.purple.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 6)
    }

    func siriusScrollEntrance() -> some View {
        scrollTransition(.animated(.easeOut(duration: 0.25)), axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.94)
                .scaleEffect(phase.isIdentity ? 1 : 0.98)
                .offset(y: phase.isIdentity ? 0 : 10)
        }
    }
}

private struct MyPageMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? 0.018 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct MyPagePremiumBackground: View {
    let pulse: Bool

    private let particles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.10, 0.13, 1.2), (0.24, 0.31, 0.8), (0.82, 0.18, 1.0),
        (0.68, 0.43, 0.7), (0.14, 0.62, 0.9), (0.90, 0.72, 1.1),
        (0.36, 0.84, 0.7), (0.73, 0.91, 0.9)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.12, green: 0.04, blue: 0.24),
                        Color.purple.opacity(0.72),
                        Color(red: 0.25, green: 0.04, blue: 0.20).opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(Color.purple.opacity(pulse ? 0.15 : 0.09))
                    .frame(width: 310, height: 310)
                    .blur(radius: 72)
                    .offset(x: pulse ? 110 : 72, y: pulse ? -210 : -170)

                Circle()
                    .fill(Color.yellow.opacity(pulse ? 0.065 : 0.035))
                    .frame(width: 240, height: 240)
                    .blur(radius: 68)
                    .offset(x: pulse ? -120 : -88, y: pulse ? 260 : 220)

                ForEach(Array(particles.enumerated()), id: \.offset) { _, particle in
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: particle.2, height: particle.2)
                        .position(x: proxy.size.width * particle.0, y: proxy.size.height * particle.1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MyPageSettingDetailView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(.cyan)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Achievement: Identifiable {
    let id = UUID()

    let icon: String
    let title: String

    // 進捗表示
    let subtitle: String

    // 条件説明
    let description: String

    // 報酬
    let reward: String

    let isAchieved: Bool
    let color: Color
}
#Preview {
    NavigationStack {
        MyPageView()
    }
}
