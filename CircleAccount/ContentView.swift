import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @AppStorage("currentUserId") private var currentUserId = ""

    var body: some View {
        Group {
            if Auth.auth().currentUser != nil && !currentUserId.isEmpty {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
