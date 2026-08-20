import SwiftUI
import UIKit

enum SiriusDesignSystem {
    static let cardCornerRadius: CGFloat = 24
    static let compactCornerRadius: CGFloat = 16
    static let screenHorizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 18

    static let blue = Color(red: 0.18, green: 0.54, blue: 1.0)
    static let purple = Color(red: 0.48, green: 0.23, blue: 0.92)
    static let gold = Color(red: 0.94, green: 0.72, blue: 0.25)
    static let silver = Color(red: 0.72, green: 0.75, blue: 0.82)
    static let orange = Color(red: 0.96, green: 0.48, blue: 0.16)
    static let red = Color(red: 0.88, green: 0.20, blue: 0.24)
}

enum SiriusHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct SiriusLoadingStateView: View {
    let accessibilityMessage: String

    init(_ accessibilityMessage: String = "読み込み中") {
        self.accessibilityMessage = accessibilityMessage
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("SiRiUS")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [SiriusDesignSystem.blue, .cyan, SiriusDesignSystem.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: SiriusDesignSystem.purple.opacity(0.32), radius: 10)

            Text("Loading...")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityMessage)
    }
}

struct SiriusEmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(SiriusDesignSystem.gold.opacity(0.88))

            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            if let message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.64))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, SiriusDesignSystem.cardPadding)
        .accessibilityElement(children: .combine)
    }
}

struct SiriusPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                        .symbolEffect(.bounce, value: selectedTab == 0)
                    Text("ホーム")
                }
                .tag(0)

            ActivitiesView()
                .tabItem {
                    Image(systemName: "calendar")
                        .symbolEffect(.bounce, value: selectedTab == 1)
                    Text("活動")
                }
                .tag(1)

            QRCheckInView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                        .symbolEffect(.bounce, value: selectedTab == 2)
                    Text("QR受付")
                }
                .tag(2)

            PointCardView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                        .symbolEffect(.bounce, value: selectedTab == 3)
                    Text("ポイント")
                }
                .tag(3)

            MyPageView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                        .symbolEffect(.bounce, value: selectedTab == 4)
                    Text("マイページ")
                }
                .tag(4)
        }
        .tint(SiriusDesignSystem.purple)
        .onChange(of: selectedTab) { _, _ in
            SiriusHaptics.light()
        }
    }
}

#Preview {
    MainTabView()
}
