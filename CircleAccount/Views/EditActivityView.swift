import SwiftUI
import FirebaseFirestore

struct EditActivityView: View {
    private let db = Firestore.firestore()

    let activity: Activity
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var editTitle: String
    @State private var editDate: Date
    @State private var tempDate: Date

    @State private var editStartTime: Date
    @State private var editEndTime: Date
    @State private var editPlace: String
    @State private var editFee: String
    @State private var editCapacity: String
    @State private var editMemo: String

    @State private var isShowingDatePicker = false
    @State private var isShowingStartPicker = false
    @State private var isShowingEndPicker = false

    @State private var tempStartTime: Date
    @State private var tempEndTime: Date
    @State private var errorMessage = ""
    @State private var isSaving = false

    init(
        activity: Activity,
        onSaved: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.activity = activity
        self.onSaved = onSaved
        self.onCancel = onCancel

        _editTitle = State(initialValue: activity.title)
        _editDate = State(initialValue: activity.date)
        _tempDate = State(initialValue: activity.date)
        _editStartTime = State(initialValue: activity.startTime)
        _editEndTime = State(initialValue: activity.endTime)
        _editPlace = State(initialValue: activity.place)
        _editFee = State(initialValue: "\(activity.fee)")
        _editCapacity = State(initialValue: "\(activity.capacity)")
        _editMemo = State(initialValue: activity.memo)
        _tempStartTime = State(initialValue: activity.startTime)
        _tempEndTime = State(initialValue: activity.endTime)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerCard
                        basicInfoCard
                        scheduleCard
                        venueAndFeeCard
                        memoCard

                        if !errorMessage.isEmpty {
                            errorCard
                        }

                        saveButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("活動編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .sheet(isPresented: $isShowingDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $isShowingStartPicker) {
                timePickerSheet(
                    title: "開始時間",
                    time: $tempStartTime,
                    onCancel: {
                        isShowingStartPicker = false
                    },
                    onDone: {
                        editStartTime = tempStartTime
                        isShowingStartPicker = false
                    }
                )
            }
            .sheet(isPresented: $isShowingEndPicker) {
                timePickerSheet(
                    title: "終了時間",
                    time: $tempEndTime,
                    onCancel: {
                        isShowingEndPicker = false
                    },
                    onDone: {
                        editEndTime = tempEndTime
                        isShowingEndPicker = false
                    }
                )
            }
        }
    }

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.03, green: 0.06, blue: 0.16),
                Color(red: 0.10, green: 0.03, blue: 0.19)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.cyan.opacity(0.13))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 100, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 85)
                .offset(x: -110, y: 120)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.30),
                                Color.blue.opacity(0.24),
                                Color.purple.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ACTIVITY EDIT")
                    .font(.caption.weight(.black))
                    .tracking(1.4)
                    .foregroundStyle(.cyan)

                Text("活動内容を編集")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .premiumEditCard()
    }

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                title: "基本情報",
                systemImage: "text.cursor"
            )

            premiumTextField(
                title: "タイトル",
                placeholder: "活動タイトル",
                text: $editTitle,
                systemImage: "pencil"
            )
        }
        .premiumEditCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                title: "日時",
                systemImage: "clock.fill"
            )

            Button {
                tempDate = editDate
                isShowingDatePicker = true
            } label: {
                premiumSelectionRow(
                    title: "日付",
                    value: formatDateValue(editDate),
                    subtitle: formatJapaneseDate(editDate),
                    systemImage: "calendar"
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button {
                    tempStartTime = editStartTime
                    isShowingStartPicker = true
                } label: {
                    timeSelectionCard(
                        title: "開始",
                        value: formatTime(editStartTime),
                        systemImage: "play.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    tempEndTime = editEndTime
                    isShowingEndPicker = true
                } label: {
                    timeSelectionCard(
                        title: "終了",
                        value: formatTime(editEndTime),
                        systemImage: "stop.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .premiumEditCard()
    }

    private var venueAndFeeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                title: "会場・参加条件",
                systemImage: "mappin.and.ellipse"
            )

            premiumTextField(
                title: "場所",
                placeholder: "開催場所",
                text: $editPlace,
                systemImage: "mappin.circle.fill"
            )

            HStack(spacing: 12) {
                premiumNumberField(
                    title: "参加費",
                    placeholder: "0",
                    suffix: "円",
                    text: $editFee,
                    systemImage: "yensign.circle.fill"
                )

                premiumNumberField(
                    title: "定員",
                    placeholder: "0",
                    suffix: "人",
                    text: $editCapacity,
                    systemImage: "person.2.fill"
                )
            }
        }
        .premiumEditCard()
    }

    private var memoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                title: "メモ",
                systemImage: "note.text"
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .foregroundStyle(.cyan)

                    Text("連絡事項・補足")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.65))
                }

                TextEditor(text: $editMemo)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.07))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            }
                    )
            }
        }
        .premiumEditCard()
    }

    private var errorCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.88))

            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red.opacity(0.14))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.30), lineWidth: 1)
                }
        )
    }

    private var saveButton: some View {
        Button {
            updateActivity()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                }

                Text(isSaving ? "保存中..." : "変更を保存")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canSave && !isSaving
                        ? [.cyan, .blue, .purple]
                        : [Color.gray.opacity(0.45), Color.gray.opacity(0.35)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: canSave && !isSaving ? Color.cyan.opacity(0.25) : .clear,
                radius: 18,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSave || isSaving)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack {
                    DatePicker(
                        "活動日",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()

                    Spacer()
                }
            }
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isShowingDatePicker = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        editDate = tempDate
                        isShowingDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var canSave: Bool {
        !editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(editFee) != nil &&
        Int(editCapacity) != nil
    }

    private func sectionTitle(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
    }

    private func premiumTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.65))

            TextField(placeholder, text: text)
                .foregroundStyle(.white)
                .tint(.cyan)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        }
                )
        }
    }

    private func premiumNumberField(
        title: String,
        placeholder: String,
        suffix: String,
        text: Binding<String>,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 6) {
                TextField(placeholder, text: text)
                    .keyboardType(.numberPad)
                    .foregroundStyle(.white)
                    .tint(.cyan)

                Text(suffix)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func premiumSelectionRow(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: systemImage)
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))

                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.42))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
        )
    }

    private func timeSelectionCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.60))

                Spacer()
            }

            Text(value)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
        )
    }

    private func updateActivity() {
        errorMessage = ""
        isSaving = true

        db.collection("activities").document(activity.id).updateData([
            "title": editTitle,
            "date": Timestamp(date: editDate),
            "startTime": Timestamp(date: editStartTime),
            "endTime": Timestamp(date: editEndTime),
            "place": editPlace,
            "fee": Int(editFee) ?? 0,
            "capacity": Int(editCapacity) ?? 0,
            "memo": editMemo
        ]) { error in
            DispatchQueue.main.async {
                isSaving = false

                if let error = error {
                    errorMessage = "保存失敗: \(error.localizedDescription)"
                    return
                }

                onSaved()
            }
        }
    }

    private func timePickerSheet(
        title: String,
        time: Binding<Date>,
        onCancel: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        NavigationStack {
            VStack {
                DatePicker(
                    title,
                    selection: time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .padding()

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("決定") {
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatDateValue(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    private func formatJapaneseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private extension View {
    func premiumEditCard() -> some View {
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
            .shadow(
                color: Color.black.opacity(0.24),
                radius: 18,
                x: 0,
                y: 10
            )
    }
}
