import SwiftUI
import FirebaseFirestore

struct NoticeView: View {

    private let db = Firestore.firestore()

    @State private var noticeText = ""
    @State private var notices: [String] = []

    var body: some View {
        NavigationStack {
            VStack {

                TextField("お知らせを書く", text: $noticeText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("投稿") {
                    addNotice()
                }
                .buttonStyle(.borderedProminent)

                List(notices, id: \.self) { notice in
                    Text(notice)
                }
            }
            .navigationTitle("お知らせ")
            .onAppear {
                loadNotices()
            }
        }
    }

    func addNotice() {
        guard !noticeText.isEmpty else { return }

        db.collection("notices").addDocument(data: [
            "text": noticeText,
            "createdAt": Timestamp()
        ])

        noticeText = ""
        loadNotices()
    }

    func loadNotices() {
        db.collection("notices")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in

                notices = snapshot?.documents.compactMap {
                    $0["text"] as? String
                } ?? []
            }
    }
}

#Preview {
    NoticeView()
}
