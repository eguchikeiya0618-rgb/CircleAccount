import SwiftUI
import FirebaseFirestore

struct ProfileEditView: View {
    private let db = Firestore.firestore()

    @Environment(\.dismiss) private var dismiss

    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var badmintonStartAge = ""
    @State private var badmintonYears = ""
    @State private var racket = ""
    @State private var stringName = ""
    @State private var tension = ""
    @State private var playStyle = ""
    @State private var dominantHand = ""
    @State private var favoriteShot = ""
    @State private var comment = ""

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var message = ""
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection

                    if isLoading {
                        ProgressView("プロフィールを読み込み中...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else {
                        basicSection
                        equipmentSection
                        styleSection
                        saveButton

                        if !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("バドプロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
            .alert("保存しました", isPresented: $showSavedAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("バドミントンプロフィールを更新しました。")
            }
        }
    }

    var headerSection: some View {
        VStack(spacing: 8) {
            Text("🏸")
                .font(.system(size: 54))

            Text("バドミントンプロフィール")
                .font(.title2)
                .bold()

            Text("みんなが話しかけやすくなる情報を登録しましょう")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    var basicSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                icon: "calendar",
                title: "競技経験"
            )

            profileTextField(
                title: "競技開始年齢",
                placeholder: "例：10",
                text: $badmintonStartAge,
                unit: "歳",
                keyboardType: .numberPad
            )

            profileTextField(
                title: "競技歴",
                placeholder: "例：20",
                text: $badmintonYears,
                unit: "年",
                keyboardType: .numberPad
            )
        }
        .profileEditCard()
    }

    var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                icon: "sportscourt.fill",
                title: "使用用具"
            )

            profileTextField(
                title: "使用ラケット",
                placeholder: "例：ASTROX 100ZZ",
                text: $racket
            )

            profileTextField(
                title: "ガット",
                placeholder: "例：EXBOLT 65",
                text: $stringName
            )

            profileTextField(
                title: "テンション",
                placeholder: "例：26",
                text: $tension,
                unit: "ポンド",
                keyboardType: .decimalPad
            )
        }
        .profileEditCard()
    }

    var styleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                icon: "person.fill",
                title: "プレースタイル・ひとこと"
            )

            VStack(alignment: .leading, spacing: 7) {
                Text("プレースタイル")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)

                TextField(
                    "例：後衛・スマッシュ中心",
                    text: $playStyle
                )
                .textFieldStyle(.roundedBorder)
                VStack(alignment: .leading, spacing: 7) {
                    Text("得意ショット")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    TextField(
                        "例：スマッシュ・ヘアピン・ドライブ",
                        text: $favoriteShot
                    )
                    .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text("利き手")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    Picker("利き手", selection: $dominantHand) {
                        Text("未選択").tag("")
                        Text("右利き").tag("右利き")
                        Text("左利き").tag("左利き")
                    }
                    .pickerStyle(.segmented)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("ひとこと")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)

                TextEditor(text: $comment)
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25))
                    }

                Text("例：ミックスと男子ダブルスに出たいです！")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .profileEditCard()
    }

    var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            HStack {
                Spacer()

                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("プロフィールを保存")
                        .bold()
                }

                Spacer()
            }
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isSaving || currentUserId.isEmpty)
        .opacity(isSaving || currentUserId.isEmpty ? 0.6 : 1)
    }

    func sectionTitle(
        icon: String,
        title: String
    ) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .bold()
            .foregroundStyle(.blue)
    }

    func profileTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        unit: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)

            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.roundedBorder)

                if let unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    func loadProfile() {
        guard !currentUserId.isEmpty else {
            message = "メンバー情報が取得できません"
            isLoading = false
            return
        }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error {
                        message = "読み込み失敗：\(error.localizedDescription)"
                        return
                    }

                    guard let data = snapshot?.data() else {
                        message = "プロフィール情報が見つかりません"
                        return
                    }

                    let startAge =
                        data["badmintonStartAge"] as? Int ?? 0

                    let years =
                        data["badmintonYears"] as? Int ?? 0

                    badmintonStartAge =
                        startAge == 0 ? "" : String(startAge)

                    badmintonYears =
                        years == 0 ? "" : String(years)

                    racket =
                        data["racket"] as? String ?? ""

                    stringName =
                        data["stringName"] as? String ?? ""

                    tension =
                        data["tension"] as? String ?? ""

                    playStyle =
                        data["playStyle"] as? String ?? ""
                    favoriteShot =
                        data["favoriteShot"] as? String ?? ""
                    dominantHand =
                        data["dominantHand"] as? String ?? ""

                    comment =
                        data["comment"] as? String ?? ""
                }
            }
    }

    func saveProfile() {
        guard !currentUserId.isEmpty else {
            message = "メンバー情報が取得できません"
            return
        }

        message = ""
        isSaving = true

        let startAge =
            Int(badmintonStartAge.trimmingCharacters(in: .whitespaces)) ?? 0

        let years =
            Int(badmintonYears.trimmingCharacters(in: .whitespaces)) ?? 0

        let updateData: [String: Any] = [
            "badmintonStartAge": startAge,
            "badmintonYears": years,
            "racket": racket.trimmingCharacters(in: .whitespacesAndNewlines),
            "stringName": stringName.trimmingCharacters(in: .whitespacesAndNewlines),
            "tension": tension.trimmingCharacters(in: .whitespacesAndNewlines),
            "playStyle": playStyle.trimmingCharacters(in: .whitespacesAndNewlines),
            "favoriteShot": favoriteShot.trimmingCharacters(in: .whitespacesAndNewlines),
            "dominantHand": dominantHand,
            "comment": comment.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        db.collection("members")
            .document(currentUserId)
            .updateData(updateData) { error in
                DispatchQueue.main.async {
                    isSaving = false

                    if let error {
                        message = "保存失敗：\(error.localizedDescription)"
                        return
                    }

                    showSavedAlert = true
                }
            }
    }
}

extension View {
    func profileEditCard() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(
                color: .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

#Preview {
    ProfileEditView()
}
