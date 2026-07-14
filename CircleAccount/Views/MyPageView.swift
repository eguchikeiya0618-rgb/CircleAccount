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
    @State private var unlockedAchievement: Achievement?
    
    @State private var showLevelUp = false
    @State private var previousLevel = 1
    
    @State private var recentActivities: [String] = []
    @State private var savedBadgeIds: [String] = []
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
                VStack(spacing: 18) {
                    profileCard
                    pointCard
                    NavigationLink {
                        TicketShopView()
                    } label: {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("チケットショップ")
                                    .font(.headline)

                                Text("ポイントでチケットを交換")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    achievementGrid
                
                    
                    TicketCardView(
                        stringingFreeTickets: stringingFreeTickets,
                        challengeTickets: challengeTickets,
                        priorityTickets: priorityTickets,
                        cleanupTickets: cleanupTickets,
                        discountTickets: discountTickets,
                        halfPriceTickets: halfPriceTickets,
                        freeTickets: freeTickets
                    )
                    ActivityHistoryCardView(
                        recentActivities: recentActivities
                    )
                    if currentUserIsAdmin {
                        adminSection
                    }

                    logoutButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("マイページ")
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
           
            .fullScreenCover(isPresented: $showLevelUp) {
                LevelUpView(
                    oldLevel: previousLevel,
                    newLevel: memberLevel
                )
            }
            .onAppear {
                loadMember()
                loadMyRank()
               
            }
            .onChange(of: selectedPhoto) { _, newItem in
                if let newItem {
                    loadSelectedPhoto(newItem)
                }
            }
        }
    }

    var profileCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
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

                Text(rankIcon)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 5)
            }
            .overlay(
                Circle()
                    .stroke(
                        totalPoint >= 700 ? Color.yellow : Color.blue,
                        lineWidth: 4
                    )
                    .frame(width: 112, height: 112)
            )

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("写真を変更")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            Button {
                showProfileEditor = true
            } label: {
                Label("バドプロフィールを編集", systemImage: "pencil")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(name.isEmpty ? "メンバー" : name)
                .font(.system(size: 34, weight: .black))

            Text("Lv.\(memberLevel)")
                .font(.headline)
                .bold()
                .foregroundStyle(.orange)
            if streakCount > 0 {
                Text("🔥 現在\(streakCount)連続参加中")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.orange)
            } else {
                Text("次の参加から連続記録スタート")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(
                value: Double(totalPoint % 50),
                total: 50
            )
            .tint(.orange)
            .frame(maxWidth: 240)

            Text("あと\(50 - (totalPoint % 50))ptでLv.\(memberLevel + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(rankIcon)
                Text(rankBadge)
                    .tracking(1.2)
            }
            .font(.headline)
            .bold()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(rankColor.opacity(0.14))
            .foregroundStyle(rankColor)
            .clipShape(Capsule())

            Text("Member No. \(String(format: "%06d", memberNo))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(gender) ・ \(level)")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("獲得バッジ", systemImage: "medal.fill")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.orange)

                    Spacer()

                    Text("\(earnedBadges.count)個")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }

                if earnedBadges.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)

                        Text("条件を達成するとバッジを獲得できます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(
                                Array(earnedBadges.enumerated()),
                                id: \.offset
                            ) { _, badge in
                                VStack(spacing: 8) {
                                    Text(badge.icon)
                                        .font(.system(size: 32))
                                        .frame(width: 58, height: 58)
                                        .background(
                                            Circle()
                                                .fill(
                                                    badgeColor(
                                                        title: badge.title
                                                    ).opacity(0.15)
                                                )
                                        )
                                        .overlay {
                                            Circle()
                                                .stroke(
                                                    badgeColor(
                                                        title: badge.title
                                                    ).opacity(0.45),
                                                    lineWidth: 2
                                                )
                                        }

                                    Text(badge.title)
                                        .font(.caption2)
                                        .bold()
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(width: 86)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6).opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditView()
        }
    }

    var pointCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ポイント")
                .font(.title2)
                .bold()

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

    var achievementGrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            NavigationLink {
                AchievementsView(achievements: achievements)
            } label: {
                HStack {
                    Text("🏆 実績")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(achievedCount)/\(achievements.count) 達成")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

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
            .buttonStyle(.plain)
        }
        .mypageCard()
    }
    
    
    var adminSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("管理メニュー")
                .font(.title2)
                .bold()

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
                menuRow(icon: "calendar.circle.fill", title: "カレンダー", color: .purple)
            }
        }
        .mypageCard()
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
            .background(Color.red.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
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

    func achievementBadge(_ achievement: Achievement) -> some View {
        VStack(spacing: 10) {
            Text(achievement.isAchieved ? achievement.icon : "🔒")
                .font(.system(size: 34))

            Text(achievement.title)
                .font(.headline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(achievement.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Divider()

            Text(achievement.description)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("🎁 \(achievement.reward)")
                .font(.caption)
                .bold()
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
        .background(
            achievement.isAchieved
            ? achievement.color.opacity(0.14)
            : Color(.systemGray6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    achievement.isAchieved
                    ? achievement.color.opacity(0.35)
                    : .clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(achievement.isAchieved ? 1 : 0.55)
        .onTapGesture {
            selectedAchievement = achievement
        }
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
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
