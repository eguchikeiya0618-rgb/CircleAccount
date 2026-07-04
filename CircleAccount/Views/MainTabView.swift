import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }

            ActivitiesView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("活動")
                }

            QRCheckInView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("QR受付")
                }

            PointCardView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("ポイント")
                }

            MyPageView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("マイページ")
                }
        }
    }
}

#Preview {
    MainTabView()
}
