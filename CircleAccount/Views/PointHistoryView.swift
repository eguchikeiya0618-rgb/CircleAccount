import SwiftUI
import FirebaseFirestore

struct PointHistoryView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var histories: [PointHistory] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            premiumBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    summaryCard

                    if isLoading {
                        loadingView
                    } else if !errorMessage.isEmpty {
                        errorView
                    } else if histories.isEmpty {
                        emptyView
                    } else {
                        historyList
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("ポイント履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadHistories()
        }
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.03, green: 0.06, blue: 0.16),
                Color(red: 0.09, green: 0.03, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.cyan.opacity(0.14))
                .frame(width: 250, height: 250)
                .blur(radius: 78)
                .offset(x: 100, y: -90)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 290, height: 290)
                .blur(radius: 88)
                .offset(x: -115, y: 120)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.28),
                                    Color.blue.opacity(0.22),
                                    Color.purple.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("POINT HISTORY")
                        .font(.caption.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(.cyan)

                    Text("ポイント獲得・利用履歴")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                summaryItem(
                    title: "獲得",
                    value: "+\(earnedPoint)pt",
                    systemImage: "arrow.up.circle.fill",
                    isPositive: true
                )

                summaryItem(
                    title: "利用",
                    value: "\(usedPoint)pt",
                    systemImage: "arrow.down.circle.fill",
                    isPositive: false
                )

                summaryItem(
                    title: "履歴",
                    value: "\(histories.count)件",
                    systemImage: "list.bullet.rectangle.fill",
                    isPositive: nil
                )
            }
        }
        .premiumHistoryCard()
    }

    private var historyList: some View {
        LazyVStack(spacing: 12) {
            ForEach(histories) { history in
                historyRow(history)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.cyan)
                .scaleEffect(1.15)

            Text("ポイント履歴を読み込み中...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.60))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .premiumHistoryCard()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 84, height: 84)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
            }

            Text("ポイント履歴はまだありません")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text("活動参加やチケット利用の履歴が\nここに表示されます")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.50))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .premiumHistoryCard()
    }

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.red)

            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)

            Button {
                loadHistories()
            } label: {
                Label("再読み込み", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .premiumHistoryCard()
    }

    private var earnedPoint: Int {
        histories
            .filter { $0.point > 0 }
            .reduce(0) { $0 + $1.point }
    }

    private var usedPoint: Int {
        histories
            .filter { $0.point < 0 }
            .reduce(0) { $0 + $1.point }
    }

    private func summaryItem(
        title: String,
        value: String,
        systemImage: String,
        isPositive: Bool?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    isPositive == true
                        ? Color.cyan
                        : isPositive == false
                            ? Color.red.opacity(0.85)
                            : Color.purple.opacity(0.90)
                )

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                }
        )
    }

    private func historyRow(_ history: PointHistory) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        history.point >= 0
                            ? Color.cyan.opacity(0.12)
                            : Color.red.opacity(0.12)
                    )
                    .frame(width: 48, height: 48)

                Text(history.icon)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(history.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(formatDate(history.date))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer(minLength: 12)

            Text("\(history.point > 0 ? "+" : "")\(history.point)pt")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(
                    history.point >= 0
                        ? Color.cyan
                        : Color.red.opacity(0.88)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            history.point >= 0
                                ? Color.cyan.opacity(0.14)
                                : Color.red.opacity(0.14),
                            lineWidth: 1
                        )
                }
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 7)
    }

    private func loadHistories() {
        guard !currentUserId.isEmpty else {
            histories = []
            errorMessage = ""
            return
        }

        isLoading = true
        errorMessage = ""

        db.collection("members")
            .document(currentUserId)
            .collection("pointHistories")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error = error {
                        errorMessage = "履歴の読み込みに失敗しました: \(error.localizedDescription)"
                        return
                    }

                    histories = snapshot?.documents.compactMap { document in
                        let data = document.data()

                        return PointHistory(
                            id: document.documentID,
                            title: data["title"] as? String ?? "",
                            point: data["point"] as? Int ?? 0,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            icon: data["icon"] as? String ?? "⭐"
                        )
                    } ?? []
                }
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private extension View {
    func premiumHistoryCard() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
            )
            .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    NavigationStack {
        PointHistoryView()
    }
}
