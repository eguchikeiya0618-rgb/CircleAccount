import SwiftUI
import FirebaseFirestore

struct RankingMember: Identifiable {
    let id: String
    let name: String
    let monthlyPoint: Int
}

struct RankingView: View {

    @State private var members: [RankingMember] = []

    private let db = Firestore.firestore()

    var body: some View {

        List {

            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in

                HStack {

                    Text(rankEmoji(index + 1))
                        .font(.title2)

                    VStack(alignment: .leading) {

                        Text(member.name)
                            .bold()

                        Text("\(member.monthlyPoint)pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(index + 1)位")
                        .bold()
                }
                .padding(.vertical,8)
            }
        }
        .navigationTitle("月間ランキング")
        .onAppear {
            loadRanking()
        }
    }

    func loadRanking() {

        db.collection("members")
            .order(by: "monthlyPoint", descending: true)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else { return }

                members = docs.map {

                    RankingMember(
                        id: $0.documentID,
                        name: $0["name"] as? String ?? "",
                        monthlyPoint: $0["monthlyPoint"] as? Int ?? 0
                    )
                }
            }
    }

    func rankEmoji(_ rank:Int)->String{

        switch rank{

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
}

#Preview {
    NavigationStack{
        RankingView()
    }
}
