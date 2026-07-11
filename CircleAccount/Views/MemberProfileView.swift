import SwiftUI

struct MemberProfileView: View {

    let member: Member

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                if let data = Data(base64Encoded: member.profileImageBase64),
                   let image = UIImage(data: data) {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())

                } else {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 130))
                        .foregroundStyle(.gray)

                }

                Text(member.name)
                    .font(.largeTitle)
                    .bold()

                Text(member.memberRank.rawValue)
                    .font(.title3)

                VStack(spacing: 14) {

                    profileRow("累計ポイント", "\(member.totalPoint)pt")

                    profileRow("今月ポイント", "\(member.monthlyPoint)pt")

                    profileRow("参加回数", "\(member.attendanceCount)回")

                    profileRow("設営回数", "\(member.setupCount)回")

                    profileRow("月間優勝", "\(member.monthlyChampionCount)回")

                    profileRow("MVP", "\(member.mvpCount)回")

                }

                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            }

            .padding()

        }

        .navigationTitle(member.name)

    }

    func profileRow(_ title: String,_ value:String) -> some View {

        HStack{

            Text(title)

            Spacer()

            Text(value)
                .bold()

        }

    }

}

#Preview {

    NavigationStack {

        MemberProfileView(
            member: Member(
                name: "けーや",
                role: .member,
                isAdmin: false,
                isActive: true
            )
        )

    }

}
