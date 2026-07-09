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
    
    @State private var currentRank = 0

    @State private var referralCount = 0
    
    @State private var totalPoint = 0
    @State private var availablePoint = 0
    @State private var monthlyPoint = 0

    @State private var attendanceCount = 0
    @State private var setupCount = 0
    @State private var mvpCount = 0
    @State private var monthlyChampionCount = 0
    @State private var monthlySecondCount = 0
    @State private var monthlyThirdCount = 0

    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0
    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var stringingFreeTickets = 0

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?

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
                    achievementGrid
                    ticketCard

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

            Text(name.isEmpty ? "メンバー" : name)
                .font(.system(size: 34, weight: .black))

            Text("Lv.\(memberLevel)")
                .font(.headline)
                .bold()
                .foregroundStyle(.orange)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
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
            HStack {
                Text("🏆 実績")
                    .font(.title2)
                    .bold()

                Spacer()

                Text("\(achievedCount)/\(achievements.count) 達成")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                ForEach(achievements) { achievement in
                    achievementBadge(achievement)
                }
            }
        }
        .mypageCard()
    }
    var ticketCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保有チケット")
                .font(.title2)
                .bold()

            ticketRow(icon: "🎾", title: "ガット張り工賃無料券", count: stringingFreeTickets)
            Divider()
            ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets)
            Divider()
            ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets)
            Divider()
            ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets)
            Divider()
            ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets)
            Divider()
            ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets)
            Divider()
            ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets)
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
                isAchieved: true,
                color: .brown
            ),
            Achievement(
                icon: "🥈",
                title: "SILVER",
                subtitle: totalPoint >= 100 ? "達成" : "\(totalPoint)/100pt",
                isAchieved: totalPoint >= 100,
                color: .gray
            ),
            Achievement(
                icon: "🥇",
                title: "GOLD",
                subtitle: totalPoint >= 200 ? "達成" : "\(totalPoint)/200pt",
                isAchieved: totalPoint >= 200,
                color: .orange
            ),
            Achievement(
                icon: "💎",
                title: "PLATINUM",
                subtitle: totalPoint >= 400 ? "達成" : "\(totalPoint)/400pt",
                isAchieved: totalPoint >= 400,
                color: .purple
            ),
            Achievement(
                icon: "👑",
                title: "LEGEND",
                subtitle: totalPoint >= 700 ? "達成" : "\(totalPoint)/700pt",
                isAchieved: totalPoint >= 700,
                color: .yellow
            ),
            Achievement(
                icon: "🎉",
                title: "初参加",
                subtitle: attendanceCount >= 1 ? "達成" : "\(attendanceCount)/1回",
                isAchieved: attendanceCount >= 1,
                color: .blue
            ),
            Achievement(
                icon: "🔥",
                title: "常連",
                subtitle: "\(attendanceCount)/10回",
                isAchieved: attendanceCount >= 10,
                color: .orange
            ),
            Achievement(
                icon: "💪",
                title: "ベテラン",
                subtitle: "\(attendanceCount)/50回",
                isAchieved: attendanceCount >= 50,
                color: .green
            ),
            Achievement(
                icon: "⚡",
                title: "100回参加",
                subtitle: "\(attendanceCount)/100回",
                isAchieved: attendanceCount >= 100,
                color: .red
            ),
            Achievement(
                icon: "🧹",
                title: "設営参加",
                subtitle: "\(setupCount)/1回",
                isAchieved: setupCount >= 1,
                color: .mint
            ),
            Achievement(
                icon: "🛠",
                title: "設営10回",
                subtitle: "\(setupCount)/10回",
                isAchieved: setupCount >= 10,
                color: .orange
            ),
            Achievement(
                icon: "🏗",
                title: "設営30回",
                subtitle: "\(setupCount)/30回",
                isAchieved: setupCount >= 30,
                color: .brown
            ),
            Achievement(
                icon: "🥇",
                title: "月間1位",
                subtitle: "\(monthlyChampionCount)回",
                isAchieved: monthlyChampionCount >= 1,
                color: .yellow
            ),
            Achievement(
                icon: "👑",
                title: "三連覇",
                subtitle: "\(monthlyChampionCount)/3回",
                isAchieved: monthlyChampionCount >= 3,
                color: .yellow
            ),
            Achievement(
                icon: "⭐",
                title: "MVP",
                subtitle: "\(mvpCount)回",
                isAchieved: mvpCount >= 1,
                color: .yellow
            ),
            Achievement(
                icon: "🌟",
                title: "MVP5回",
                subtitle: "\(mvpCount)/5回",
                isAchieved: mvpCount >= 5,
                color: .purple
            ),
            Achievement(
                icon: "👥",
                title: "初紹介",
                subtitle: "\(referralCount)/1人",
                isAchieved: referralCount >= 1,
                color: .blue
            ),
            Achievement(
                icon: "🚀",
                title: "紹介10人",
                subtitle: "\(referralCount)/10人",
                isAchieved: referralCount >= 10,
                color: .cyan
            ),
            Achievement(
                icon: "🎾",
                title: "ガット券GET",
                subtitle: "\(stringingFreeTickets)枚",
                isAchieved: stringingFreeTickets >= 1,
                color: .green
            ),
            Achievement(
                icon: "🎁",
                title: "無料券GET",
                subtitle: "\(freeTickets)枚",
                isAchieved: freeTickets >= 1,
                color: .pink
            )
        ]
    }

    var achievedCount: Int {
        achievements.filter { $0.isAchieved }.count
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
        VStack(spacing: 8) {
            Text(achievement.isAchieved ? achievement.icon : "🔒")
                .font(.system(size: 30))

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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            achievement.isAchieved
            ? achievement.color.opacity(0.14)
            : Color(.systemGray6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    achievement.isAchieved ? achievement.color.opacity(0.35) : .clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(achievement.isAchieved ? 1 : 0.55)
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

                totalPoint = data["totalPoint"] as? Int ?? 0
                availablePoint = data["availablePoint"] as? Int ?? 0
                monthlyPoint = data["monthlyPoint"] as? Int ?? 0

                attendanceCount = data["attendanceCount"] as? Int ?? 0
                setupCount = data["setupCount"] as? Int ?? 0
                mvpCount = data["mvpCount"] as? Int ?? 0
                referralCount = data["referralCount"] as? Int ?? 0
                monthlyChampionCount = data["monthlyChampionCount"] as? Int ?? 0
                monthlySecondCount = data["monthlySecondCount"] as? Int ?? 0
                monthlyThirdCount = data["monthlyThirdCount"] as? Int ?? 0

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
    let subtitle: String
    let isAchieved: Bool
    let color: Color
}
#Preview {
    NavigationStack {
        MyPageView()
    }
}
