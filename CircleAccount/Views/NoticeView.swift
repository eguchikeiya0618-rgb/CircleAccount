import SwiftUI
import FirebaseFirestore

struct NoticeItem: Identifiable {
    let id: String
    let text: String
    let createdAt: Date
}

struct NoticeView: View {
    private let db = Firestore.firestore()

    @State private var noticeText = ""
    @State private var notices: [NoticeItem] = []
    @State private var isPosting = false
    @State private var isLoading = false
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        NavigationStack {
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
                        composerCard
                        noticeList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("NOTICE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadNotices()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: "megaphone.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CIRCLE ACCOUNT")
                    .font(.caption2)
                    .fontWeight(.black)
                    .tracking(2.1)
                    .foregroundStyle(.white.opacity(0.56))

                Text("お知らせ管理")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("メンバーへ最新情報を共有できます")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("新しいお知らせ", systemImage: "square.and.pencil")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(noticeText.count)/200")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        noticeText.count > 180
                        ? Color.orange
                        : Color.white.opacity(0.48)
                    )
            }

            ZStack(alignment: .topLeading) {
                if noticeText.isEmpty {
                    Text("お知らせ内容を入力してください")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 15)
                }

                TextEditor(text: $noticeText)
                    .focused($isEditorFocused)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.white.opacity(0.07))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                        .stroke(
                            isEditorFocused
                            ? Color.cyan.opacity(0.65)
                            : Color.white.opacity(0.10),
                            lineWidth: 1
                        )
                    }
                    .onChange(of: noticeText) { _, newValue in
                        if newValue.count > 200 {
                            noticeText = String(newValue.prefix(200))
                        }
                    }
            }

            Button {
                addNotice()
            } label: {
                HStack(spacing: 9) {
                    if isPosting {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }

                    Text(isPosting ? "投稿中..." : "お知らせを投稿")
                        .fontWeight(.black)
                }
                .font(.subheadline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [.white, .cyan.opacity(0.86)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 15,
                        style: .continuous
                    )
                )
                .opacity(canPost ? 1 : 0.45)
            }
            .buttonStyle(.plain)
            .disabled(!canPost)
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var noticeList: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("投稿履歴")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(notices.count)件")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.52))
            }

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)

                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(.ultraThinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
            } else if notices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "megaphone")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.36))

                    Text("まだお知らせはありません")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("投稿した内容がここに表示されます")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(.ultraThinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(notices) { notice in
                        noticeCard(notice)
                    }
                }
            }
        }
    }

    private func noticeCard(_ notice: NoticeItem) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.17))
                    .frame(width: 44, height: 44)

                Image(systemName: "megaphone.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(notice.text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Label(
                    formatDate(notice.createdAt),
                    systemImage: "clock.fill"
                )
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.48))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.09), lineWidth: 1)
        }
    }

    private var canPost: Bool {
        !noticeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isPosting
    }

    private func addNotice() {
        let trimmedText = noticeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedText.isEmpty else { return }

        isPosting = true

        db.collection("notices").addDocument(data: [
            "text": trimmedText,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            DispatchQueue.main.async {
                isPosting = false

                if let error {
                    print("お知らせ投稿失敗: \(error.localizedDescription)")
                    return
                }

                noticeText = ""
                isEditorFocused = false
                loadNotices()
            }
        }
    }

    private func loadNotices() {
        isLoading = true

        db.collection("notices")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    print("お知らせ取得失敗: \(error.localizedDescription)")

                    DispatchQueue.main.async {
                        notices = []
                        isLoading = false
                    }
                    return
                }

                let loadedNotices: [NoticeItem] =
                    snapshot?.documents.compactMap { document in
                        let data = document.data()

                        guard let text = data["text"] as? String else {
                            return nil
                        }

                        let createdAt =
                            (data["createdAt"] as? Timestamp)?
                            .dateValue()
                            ?? Date()

                        return NoticeItem(
                            id: document.documentID,
                            text: text,
                            createdAt: createdAt
                        )
                    } ?? []

                DispatchQueue.main.async {
                    notices = loadedNotices
                    isLoading = false
                }
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NoticeView()
}
