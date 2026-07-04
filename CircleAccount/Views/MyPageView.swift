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

    @State private var totalPoint = 0
    @State private var availablePoint = 0
    @State private var attendanceCount = 0
    @State private var setupCount = 0

    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var freeTickets = 0

    @State private var legendCount = 0
    @State private var isLegend = false

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var rankName: String {
        if isLegend { return "👑 LEGEND MEMBER" }
        if totalPoint >= 400 { return "💎 Platinum" }
        if totalPoint >= 200 { return "🏸🏸🏸 Gold" }
        if totalPoint >= 100 { return "🏸🏸 Silver" }
        return "🏸 Bronze"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    pointSummaryCard
                    activityStatsCard
                    ticketCard
                    achievementCard

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
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isLegend ? Color.yellow : Color.blue, lineWidth: 3)
                    )
            } else {
                Image(systemName: isLegend ? "crown.fill" : "person.crop.circle.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(isLegend ? .yellow : .blue)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("写真を変更")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(isLegend ? 0.2 : 1))
                    .clipShape(Capsule())
            }

            Text(name.isEmpty ? "メンバー" : name)
                .font(.title)
                .bold()

            Text(rankName)
                .font(.headline)
                .foregroundStyle(isLegend ? .yellow : .secondary)

            Text("Member No. \(String(format: "%06d", memberNo))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(gender)
                Text("・")
                Text(level)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if isLegend {
                Text("LEGEND達成 \(legendCount)回")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: isLegend
                    ? [Color.black, Color(red: 0.95, green: 0.72, blue: 0.22)]
                    : [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(isLegend ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    var pointSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ポイント")
                .font(.headline)

            HStack {
                statBox(
                    icon: "star.circle.fill",
                    title: "累計",
                    value: "\(totalPoint)pt",
                    color: .yellow
                )

                statBox(
                    icon: "gift.circle.fill",
                    title: "利用可能",
                    value: "\(availablePoint)pt",
                    color: .blue
                )
            }

            if isLegend {
                Divider()

                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LEGEND MEMBER")
                            .font(.headline)
                            .bold()

                        Text("達成回数 \(legendCount)回")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .cardBackground()
    }

    var activityStatsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("活動実績")
                .font(.headline)

            HStack {
                statBox(
                    icon: "figure.badminton",
                    title: "参加",
                    value: "\(attendanceCount)回",
                    color: .green
                )

                statBox(
                    icon: "wrench.and.screwdriver.fill",
                    title: "設営",
                    value: "\(setupCount)回",
                    color: .orange
                )
            }
        }
        .cardBackground()
    }

    var ticketCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保有チケット")
                .font(.headline)

            ticketRow(icon: "🧹", title: "片付け免除", count: cleanupTickets)
            Divider()
            ticketRow(icon: "💴", title: "100円引き", count: discountTickets)
            Divider()
            ticketRow(icon: "👑", title: "LEGEND特典（参加費無料）", count: freeTickets)
        }
        .cardBackground()
    }

    var achievementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏅 実績")
                .font(.headline)

            achievementRow(
                icon: attendanceCount >= 1 ? "✅" : "🔒",
                title: "初参加",
                subtitle: attendanceCount >= 1 ? "達成済み" : "まだ未達成"
            )

            achievementRow(
                icon: attendanceCount >= 50 ? "✅" : "🔒",
                title: "50回参加",
                subtitle: "\(attendanceCount)/50回"
            )

            achievementRow(
                icon: setupCount >= 30 ? "✅" : "🔒",
                title: "設営30回",
                subtitle: "\(setupCount)/30回"
            )

            achievementRow(
                icon: isLegend ? "👑" : "🔒",
                title: "LEGEND達成",
                subtitle: isLegend ? "\(legendCount)回達成" : "400pt交換で達成"
            )
        }
        .cardBackground()
    }

    var adminSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("🛠 管理メニュー")
                .font(.headline)

            NavigationLink {
                MembersView()
            } label: {
                menuRow(icon: "person.3.fill", title: "メンバー管理", color: .blue)
            }

            NavigationLink {
                ActivitiesView()
            } label: {
                menuRow(icon: "calendar", title: "活動管理", color: .orange)
            }

            NavigationLink {
                AccountingView()
            } label: {
                menuRow(icon: "creditcard.fill", title: "会計管理", color: .green)
            }

            NavigationLink {
                CalendarView()
            } label: {
                menuRow(icon: "calendar.circle.fill", title: "カレンダー", color: .purple)
            }
        }
        .cardBackground()
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
                Text("ログアウト")
                    .bold()
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
     
    }
    func statBox(icon: String, title: String, value: String, color: Color) -> some View {
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

    func ticketRow(icon: String, title: String, count: Int) -> some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(title)

            Spacer()

            Text("\(count)枚")
                .bold()
        }
    }

    func achievementRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Text(icon)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(title)
                    .bold()

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    func menuRow(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
            to: CGRect(
                x: originX,
                y: originY,
                width: side,
                height: side
            )
        ) else {
            return image
        }

        let squareImage = UIImage(cgImage: cgImage)

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    func loadMember() {
        guard !currentUserId.isEmpty else { return }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                guard let data = snapshot?.data(),
                      error == nil else {
                    return
                }

                name = data["name"] as? String ?? ""
                memberNo = data["memberNo"] as? Int ?? 0
                gender = data["gender"] as? String ?? ""
                level = data["level"] as? String ?? ""

                totalPoint = data["totalPoint"] as? Int ?? 0
                availablePoint = data["availablePoint"] as? Int ?? 0

                attendanceCount = data["attendanceCount"] as? Int ?? 0
                setupCount = data["setupCount"] as? Int ?? 0

                cleanupTickets = data["cleanupTickets"] as? Int ?? 0
                discountTickets = data["discountTickets"] as? Int ?? 0
                freeTickets = data["freeTickets"] as? Int ?? 0

                legendCount = data["legendCount"] as? Int ?? 0
                isLegend = data["isLegend"] as? Bool ?? false

                if let profileImageBase64 = data["profileImageBase64"] as? String {
                    loadProfileImage(from: profileImageBase64)
                }
            }
    }
}

extension View {
    func cardBackground() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
