import SwiftUI
import FirebaseFirestore
import UIKit

struct RankingView: View {
    @State private var members: [Member] = []

    private let db = Firestore.firestore()

    var body: some View {
        List {
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                NavigationLink {
                    MemberProfileView(member: member)
                } label: {
                    HStack(spacing: 14) {
                        Text(rankEmoji(index + 1))
                            .font(.title2)
                            .frame(width: 34)

                        profileImageView(
                            base64String: member.profileImageBase64,
                            rank: index + 1
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.primary)

                            HStack(spacing: 6) {
                                Text(member.memberRank.rawValue)
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(rankColor(member.memberRank))

                                Text("・")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(member.monthlyPoint)pt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text("\(index + 1)位")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("月間ランキング")
        .onAppear {
            loadRanking()
        }
    }

    func profileImageView(
        base64String: String,
        rank: Int
    ) -> some View {
        Group {
            if let image = decodeImage(from: base64String) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.gray.opacity(0.45))
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    profileBorderColor(rank: rank),
                    lineWidth: rank <= 3 ? 3 : 1
                )
        }
    }

    func decodeImage(from base64String: String) -> UIImage? {
        guard
            !base64String.isEmpty,
            let data = Data(base64Encoded: base64String),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }

    func loadRanking() {
        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ ランキング取得失敗: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    members = []
                    return
                }

                members = documents.map { document in
                    let data = document.data()

                    return Member(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        role: MemberRole(
                            rawValue: data["role"] as? String ?? "メンバー"
                        ) ?? .member,
                        isAdmin: data["isAdmin"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,
                        gender: Gender(
                            rawValue: data["gender"] as? String ?? "男性"
                        ) ?? .male,
                        level: MemberLevel(
                            rawValue: data["level"] as? String ?? "初心者"
                        ) ?? .beginner,
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
                }
            }
    }

    func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "🏸"
        }
    }

    func profileBorderColor(rank: Int) -> Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .brown
        default:
            return .gray.opacity(0.2)
        }
    }

    func rankColor(_ rank: MemberRank) -> Color {
        switch rank {
        case .bronze:
            return .brown
        case .silver:
            return .gray
        case .gold:
            return .orange
        case .platinum:
            return .purple
        case .legend:
            return .yellow
        }
    }
}

#Preview {
    NavigationStack {
        RankingView()
    }
}
