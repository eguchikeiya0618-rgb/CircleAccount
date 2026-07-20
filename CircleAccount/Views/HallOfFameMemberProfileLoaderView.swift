import SwiftUI
import FirebaseFirestore

struct HallOfFameMemberProfileLoaderView: View {
    private let db = Firestore.firestore()

    let memberId: String
    let memberName: String

    @State private var member: Member?
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if isLoading {
                loadingView

            } else if let member {
                MemberProfileView(member: member)

            } else {
                errorView
            }
        }
        .navigationTitle(
            memberName.isEmpty
                ? "プロフィール"
                : memberName
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMember()
        }
    }

    // MARK: - 読み込み中

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)

            Text("プロフィールを読み込み中...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - エラー表示

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(
                systemName:
                    "person.crop.circle.badge.exclamationmark"
            )
            .font(.system(size: 54))
            .foregroundStyle(.orange)

            Text("プロフィールを表示できません")
                .font(.headline)

            Text(
                errorMessage.isEmpty
                    ? "メンバー情報が見つかりませんでした"
                    : errorMessage
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button("再読み込み") {
                loadMember()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Firebase

    private func loadMember() {
        isLoading = true
        errorMessage = ""

        if !memberId.isEmpty {
            loadMemberById(memberId)
        } else {
            loadMemberByName(memberName)
        }
    }

    private func loadMemberById(
        _ id: String
    ) {
        db.collection("members")
            .document(id)
            .getDocument { snapshot, error in
                if let error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage =
                            "メンバー情報の取得に失敗しました\n"
                            + error.localizedDescription
                    }
                    return
                }

                guard
                    let snapshot,
                    snapshot.exists,
                    let data = snapshot.data()
                else {
                    loadMemberByName(memberName)
                    return
                }

                let loadedMember = makeMember(
                    id: snapshot.documentID,
                    data: data
                )

                DispatchQueue.main.async {
                    member = loadedMember
                    isLoading = false
                }
            }
    }

    private func loadMemberByName(
        _ name: String
    ) {
        guard !name.isEmpty else {
            DispatchQueue.main.async {
                isLoading = false
                errorMessage =
                    "メンバー名が保存されていません"
            }
            return
        }

        db.collection("members")
            .whereField(
                "name",
                isEqualTo: name
            )
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage =
                            "メンバー情報の取得に失敗しました\n"
                            + error.localizedDescription
                    }
                    return
                }

                guard
                    let document =
                        snapshot?.documents.first
                else {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage =
                            "「\(name)」のプロフィールが見つかりませんでした"
                    }
                    return
                }

                let loadedMember = makeMember(
                    id: document.documentID,
                    data: document.data()
                )

                DispatchQueue.main.async {
                    member = loadedMember
                    isLoading = false
                }
            }
    }

    // MARK: - Member変換

    private func makeMember(
        id: String,
        data: [String: Any]
    ) -> Member {
        Member(
            id: id,

            name:
                data["name"] as? String
                ?? "メンバー",

            role:
                MemberRole(
                    rawValue:
                        data["role"] as? String
                        ?? ""
                )
                ?? .member,

            isAdmin:
                data["isAdmin"] as? Bool
                ?? false,

            isActive:
                data["isActive"] as? Bool
                ?? true,

            gender:
                Gender(
                    rawValue:
                        data["gender"] as? String
                        ?? ""
                )
                ?? .male,

            level:
                MemberLevel(
                    rawValue:
                        data["level"] as? String
                        ?? ""
                )
                ?? .beginner,

            totalPoint:
                data["totalPoint"] as? Int
                ?? 0,

            availablePoint:
                data["availablePoint"] as? Int
                ?? 0,

            cleanupTickets:
                data["cleanupTickets"] as? Int
                ?? 0,

            discountTickets:
                data["discountTickets"] as? Int
                ?? 0,

            halfPriceTickets:
                data["halfPriceTickets"] as? Int
                ?? 0,

            freeTickets:
                data["freeTickets"] as? Int
                ?? 0,

            challengeTickets:
                data["challengeTickets"] as? Int
                ?? 0,

            priorityTickets:
                data["priorityTickets"] as? Int
                ?? 0,

            attendanceCount:
                data["attendanceCount"] as? Int
                ?? 0,

            setupCount:
                data["setupCount"] as? Int
                ?? 0,

            streakCount:
                data["streakCount"] as? Int
                ?? 0,

            monthlyChampionCount:
                data["monthlyChampionCount"] as? Int
                ?? 0,

            monthlySecondCount:
                data["monthlySecondCount"] as? Int
                ?? 0,

            monthlyThirdCount:
                data["monthlyThirdCount"] as? Int
                ?? 0,

            mvpCount:
                data["mvpCount"] as? Int
                ?? 0,

            monthlyPoint:
                data["monthlyPoint"] as? Int
                ?? 0,

            legendCount:
                data["legendCount"] as? Int
                ?? 0,

            isLegend:
                data["isLegend"] as? Bool
                ?? false,

            profileImageBase64:
                data["profileImageBase64"] as? String
                ?? "",

            earnedBadges:
                data["earnedBadges"] as? [String]
                ?? [],

            badmintonStartAge:
                data["badmintonStartAge"] as? Int
                ?? 0,

            badmintonYears:
                data["badmintonYears"] as? Int
                ?? 0,

            racket:
                data["racket"] as? String
                ?? "",

            stringName:
                data["stringName"] as? String
                ?? "",

            tension:
                data["tension"] as? String
                ?? "",

            playStyle:
                data["playStyle"] as? String
                ?? "",

            comment:
                data["comment"] as? String
                ?? "",

            dominantHand:
                data["dominantHand"] as? String
                ?? "",

            favoriteShot:
                data["favoriteShot"] as? String
                ?? "",

            createdAt:
                (data["createdAt"] as? Timestamp)?
                    .dateValue()
                ?? Date()
        )
    }
}

#Preview {
    NavigationStack {
        HallOfFameMemberProfileLoaderView(
            memberId: "",
            memberName: "けーや"
        )
    }
}
