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

    init(activity: Activity, onSaved: @escaping () -> Void, onCancel: @escaping () -> Void) {
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
            ScrollView {
                VStack(spacing: 14) {
                    TextField("タイトル", text: $editTitle)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        tempDate = editDate
                        isShowingDatePicker = true
                    } label: {
                        HStack {
                            Text("日付")
                            Spacer()
                            Text(formatDateValue(editDate))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.blue)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Text(formatJapaneseDate(editDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        tempStartTime = editStartTime
                        isShowingStartPicker = true
                    } label: {
                        HStack {
                            Text("開始時間")
                            Spacer()
                            Text(formatTime(editStartTime))
                                .font(.title3)
                                .bold()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        tempEndTime = editEndTime
                        isShowingEndPicker = true
                    } label: {
                        HStack {
                            Text("終了時間")
                            Spacer()
                            Text(formatTime(editEndTime))
                                .font(.title3)
                                .bold()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    TextField("場所", text: $editPlace)
                        .textFieldStyle(.roundedBorder)

                    TextField("参加費", text: $editFee)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    TextField("定員", text: $editCapacity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    TextField("メモ", text: $editMemo)
                        .textFieldStyle(.roundedBorder)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("保存する") {
                        updateActivity()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                }
                .padding()
            }
            .navigationTitle("活動編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
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

    var datePickerSheet: some View {
        NavigationStack {
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

    var canSave: Bool {
        !editTitle.isEmpty &&
        !editPlace.isEmpty &&
        Int(editFee) != nil &&
        Int(editCapacity) != nil
    }

    func updateActivity() {
        errorMessage = ""

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
            if let error = error {
                errorMessage = "保存失敗: \(error.localizedDescription)"
                return
            }

            onSaved()
        }
    }

    func timePickerSheet(
        title: String,
        time: Binding<Date>,
        onCancel: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        NavigationStack {
            VStack {
                DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
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

    func formatDateValue(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    func formatJapaneseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

