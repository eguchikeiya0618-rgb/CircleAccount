import SwiftUI
import FirebaseFirestore

struct MonthlyMissionView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    let attendanceCount: Int
    let setupCount: Int
    let earlyAnswerCount: Int

    private let attendanceTarget = 5
    private let setupTarget = 3
    private let earlyAnswerTarget = 3

    private var isAllCompleted: Bool {
        attendanceCount >= attendanceTarget &&
        setupCount >= setupTarget &&
        earlyAnswerCount >= earlyAnswerTarget
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors:[.black,
                        Color(red:0.03,green:0.05,blue:0.16),
                        Color(red:0.12,green:0.04,blue:0.24)],
                startPoint:.topLeading,
                endPoint:.bottomTrailing
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing:20){
                    header
                    missionCard(icon:"🏸",title:"今月5回参加",current:attendanceCount,target:attendanceTarget,color:.cyan)
                    missionCard(icon:"🧹",title:"今月3回設営",current:setupCount,target:setupTarget,color:.orange)
                    missionCard(icon:"⏰",title:"今月3回早期回答",current:earlyAnswerCount,target:earlyAnswerTarget,color:.purple)
                    rewardCard
                }
                .padding()
            }
        }
        .navigationTitle("MISSION")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for:.navigationBar)
        .toolbarColorScheme(.dark, for:.navigationBar)
        .onAppear{
            if isAllCompleted { grantMonthlyMissionBadge() }
        }
    }

    var header: some View{
        VStack(spacing:10){
            Text("🎯").font(.system(size:64))
            Text("MONTHLY MISSION")
                .font(.system(size:28,weight:.black,design:.rounded))
                .foregroundStyle(.white)
            Text("サークルへの参加と貢献で限定バッジを獲得")
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth:.infinity)
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:28))
    }

    func missionCard(icon:String,title:String,current:Int,target:Int,color:Color)->some View{
        let value=min(current,target)
        let done=current>=target
        return VStack(alignment:.leading,spacing:14){
            HStack{
                Text(icon).font(.system(size:34))
                VStack(alignment:.leading){
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text("\(value)/\(target)")
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName:done ? "checkmark.circle.fill":"circle")
                    .foregroundStyle(done ? .green:.gray)
                    .font(.title)
            }
            ProgressView(value:Double(value),total:Double(target))
                .tint(done ? .green:color)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:24))
    }

    var rewardCard: some View{
        VStack(spacing:12){
            Text(isAllCompleted ? "🎉 COMPLETE":"🏆 REWARD")
                .font(.title2).bold().foregroundStyle(.white)
            Text("限定バッジ「今月の貢献者」")
                .foregroundStyle(.white)
            Text(isAllCompleted ? "プロフィールへ自動付与されます":"すべて達成で限定バッジ獲得")
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth:.infinity)
        .padding()
        .background(isAllCompleted ? Color.green.opacity(0.2):Color.orange.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius:24))
    }

    func grantMonthlyMissionBadge() {
        guard !currentUserId.isEmpty else { return }
        db.collection("members").document(currentUserId).updateData([
            "earnedBadges": FieldValue.arrayUnion(["monthlyContributor"])
        ])
    }
}

#Preview{
    NavigationStack{
        MonthlyMissionView(attendanceCount:2,setupCount:1,earlyAnswerCount:1)
    }
}
