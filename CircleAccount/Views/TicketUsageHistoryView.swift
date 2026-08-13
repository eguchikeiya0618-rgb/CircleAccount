import SwiftUI
import FirebaseFirestore

struct TicketUsage: Identifiable {
    let id: String
    let memberName: String
    let ticket: String
    let icon: String
    let usedAt: Date
    let status: String
}

struct TicketUsageHistoryView: View {
    private let db = Firestore.firestore()

    @State private var usages: [TicketUsage] = []
    @State private var selectedFilter: TicketUsageFilter = .all
    @State private var isLoading = false

    private var filteredUsages: [TicketUsage] {
        switch selectedFilter {
        case .all:
            return usages
        case .unchecked:
            return usages.filter { $0.status == "未確認" }
        case .checked:
            return usages.filter { $0.status != "未確認" }
        }
    }

    private var uncheckedCount: Int {
        usages.filter { $0.status == "未確認" }.count
    }

    private var checkedCount: Int {
        usages.filter { $0.status != "未確認" }.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.indigo.opacity(0.94),
                    Color.purple.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    summaryCards
                    filterPicker
                    usageList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Ticket History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadUsages()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CIRCLE ACCOUNT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(2.2)
                        .foregroundStyle(.white.opacity(0.62))

                    Text("チケット使用履歴")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }

            Text("使用されたチケットと確認状況を管理できます")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.70))
        }
        .padding(.top, 8)
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "未確認",
                value: "\(uncheckedCount)件",
                icon: "exclamationmark.circle.fill",
                accent: .red
            )

            summaryCard(
                title: "確認済み",
                value: "\(checkedCount)件",
                icon: "checkmark.seal.fill",
                accent: .green
            )

            summaryCard(
                title: "合計",
                value: "\(usages.count)件",
                icon: "tray.full.fill",
                accent: .cyan
            )
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        icon: String,
        accent: Color
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(TicketUsageFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            selectedFilter == filter
                            ? Color.black
                            : Color.white.opacity(0.72)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                            ? Color.white
                            : Color.white.opacity(0.08)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var usageList: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)

                Text("読み込み中...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.60))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 42)
        } else if filteredUsages.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "ticket")
                    .font(.system(size: 38))
                    .foregroundStyle(.white.opacity(0.42))

                Text("該当する履歴がありません")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("チケットが使用されると、ここに表示されます")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 38)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredUsages) { usage in
                    usageCard(usage)
                }
            }
        }
    }

    private func usageCard(_ usage: TicketUsage) -> some View {
        let isUnchecked = usage.status == "未確認"

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.72),
                                    Color.indigo.opacity(0.70)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)

                    Text(usage.icon.isEmpty ? "🎫" : usage.icon)
                        .font(.system(size: 27))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(usage.ticket.isEmpty ? "チケット" : usage.ticket)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Label(usage.memberName, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.66))

                    Label(formatDate(usage.usedAt), systemImage: "clock.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.50))
                }

                Spacer()

                Text(isUnchecked ? "未確認" : "確認済み")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(isUnchecked ? .red : .green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.09))
                    .clipShape(Capsule())
            }

            if isUnchecked {
                Button {
                    markAsChecked(id: usage.id)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("確認済みにする")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.88)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("確認済み")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isUnchecked
                    ? Color.red.opacity(0.30)
                    : Color.white.opacity(0.10),
                    lineWidth: 1
                )
        }
    }

    private func loadUsages() {
        isLoading = true

        db.collection("ticketUsages")
            .order(by: "usedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("チケット履歴読み込み失敗: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    return
                }

                let loadedUsages: [TicketUsage] = snapshot?.documents.map { document in
                    let data = document.data()

                    return TicketUsage(
                        id: document.documentID,
                        memberName: data["memberName"] as? String ?? "不明",
                        ticket: data["ticket"] as? String ?? "",
                        icon: data["icon"] as? String ?? "",
                        usedAt: (data["usedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "未確認"
                    )
                } ?? []

                DispatchQueue.main.async {
                    usages = loadedUsages
                    isLoading = false
                }
            }
    }

    private func markAsChecked(id: String) {
        db.collection("ticketUsages")
            .document(id)
            .updateData([
                "status": "確認済み"
            ]) { error in
                if let error = error {
                    print("チケット確認更新失敗: \(error.localizedDescription)")
                    return
                }

                loadUsages()
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

private enum TicketUsageFilter: String, CaseIterable, Identifiable {
    case all
    case unchecked
    case checked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "すべて"
        case .unchecked:
            return "未確認"
        case .checked:
            return "確認済み"
        }
    }
}

#Preview {
    NavigationStack {
        TicketUsageHistoryView()
    }
}
