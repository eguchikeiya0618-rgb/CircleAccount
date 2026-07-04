import SwiftUI
import FirebaseFirestore

struct MembersView: View {
    private let db = Firestore.firestore()
    
    @FocusState private var isInputFocused: Bool
    
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("currentUserName") private var currentUserName = ""
    @AppStorage("currentUserIsAdmin") private var currentUserIsAdmin = false

    @State private var members: [Member] = []

    @State private var newName = ""
    @State private var selectedRole: MemberRole = .member
    @State private var selectedGender: Gender = .male
    @State private var selectedLevel: MemberLevel = .beginner
    @State private var newMemberIsAdmin = false

    @State private var isShowingEditSheet = false
    @State private var editingMemberId = ""
    @State private var editName = ""
    @State private var editRole: MemberRole = .member
    @State private var editGender: Gender = .male
    @State private var editLevel: MemberLevel = .beginner
    @State private var editIsAdmin = false

    @State private var memberToDelete: Member?
    @State private var isShowingDeleteAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(members) { member in
                        HStack {
                            ProfileImageView(
                                imageBase64: member.profileImageBase64,
                                size: 44
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)

                                if currentUserIsAdmin {
                                    Text("\(member.isAdmin ? "管理者" : member.role.rawValue) / \(member.level.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(member.isAdmin ? "管理者" : member.role.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if currentUserIsAdmin {
                                Button {
                                    startEdit(member)
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.blue)

                                Button(role: .destructive) {
                                    memberToDelete = member
                                    isShowingDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }

                if currentUserIsAdmin || members.isEmpty {
                    VStack(spacing: 12) {
                        TextField("名前", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)

                        Picker("性別", selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("レベル", selection: $selectedLevel) {
                            ForEach(MemberLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }

                        Picker("役割", selection: $selectedRole) {
                            ForEach(MemberRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }

                        Toggle("管理者", isOn: $newMemberIsAdmin)

                        Button("メンバーを追加") {
                            addMember()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newName.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("メンバー")
            .onAppear {
                loadMembers()
            }
            .sheet(isPresented: $isShowingEditSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        TextField("名前", text: $editName)
                            .textFieldStyle(.roundedBorder)

                        Picker("性別", selection: $editGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("レベル", selection: $editLevel) {
                            ForEach(MemberLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }

                        Picker("役割", selection: $editRole) {
                            ForEach(MemberRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }

                        Toggle("管理者", isOn: $editIsAdmin)

                        Button("保存する") {
                            updateMember()
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()
                    }
                    .padding()
                    .navigationTitle("メンバー編集")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                isShowingEditSheet = false
                            }
                        }
                    }
                }
                .interactiveDismissDisabled(true)
            }
            .alert("メンバーを削除しますか？", isPresented: $isShowingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}

                Button("削除", role: .destructive) {
                    if let member = memberToDelete {
                        deleteMember(member)
                    }
                }
            } message: {
                if let member = memberToDelete {
                    Text(member.isAdmin
                         ? "\(member.name)さんは管理者です。本当に削除しますか？この操作は元に戻せません。"
                         : "\(member.name)さんを削除します。この操作は元に戻せません。")
                }
            }
        }
    }

    func genderDot(_ gender: Gender) -> some View {
        Circle()
            .fill(gender == .male ? Color.blue : Color.pink)
            .frame(width: 12, height: 12)
    }

    func startEdit(_ member: Member) {
        editingMemberId = member.id
        editName = member.name
        editRole = member.role
        editGender = member.gender
        editLevel = member.level
        editIsAdmin = member.isAdmin
        isShowingEditSheet = true
    }

    func addMember() {
        db.collection("members")
            .order(by: "memberNo", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("会員番号取得失敗: \(error.localizedDescription)")
                    return
                }

                let maxMemberNo = snapshot?.documents.first?.data()["memberNo"] as? Int ?? 0
                let nextMemberNo = maxMemberNo + 1

                db.collection("members").addDocument(data: [
                    "memberNo": nextMemberNo,
                    "name": newName,
                    "role": selectedRole.rawValue,
                    "gender": selectedGender.rawValue,
                    "level": selectedLevel.rawValue,
                    "isAdmin": newMemberIsAdmin,
                    "isActive": true,

                    "totalPoint": 0,
                    "availablePoint": 0,
                    "cleanupTickets": 0,
                    "discountTickets": 0,
                    "freeTickets": 0,
                    "attendanceCount": 0,
                    "setupCount": 0,

                    "createdAt": Timestamp()
                ]) { error in
                    if let error = error {
                        print("メンバー保存失敗: \(error)")
                        return
                    }

                    newName = ""
                    selectedRole = .member
                    selectedGender = .male
                    selectedLevel = .beginner
                    newMemberIsAdmin = false
                    isInputFocused = false
                    loadMembers()
                }
            }
    }

    func updateMember() {
        db.collection("members").document(editingMemberId).updateData([
            "name": editName,
            "role": editRole.rawValue,
            "gender": editGender.rawValue,
            "level": editLevel.rawValue,
            "isAdmin": editIsAdmin,
            "isActive": true
        ]) { error in
            if let error = error {
                print("更新失敗: \(error.localizedDescription)")
                return
            }

            isShowingEditSheet = false
            loadMembers()
        }
    }

    func deleteMember(_ member: Member) {
        db.collection("members").document(member.id).delete { error in
            if let error = error {
                print("メンバー削除失敗: \(error)")
                return
            }

            members.removeAll { $0.id == member.id }
            memberToDelete = nil
        }
    }

    func loadMembers() {
        db.collection("members")
            .order(by: "memberNo", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("メンバー読み込み失敗: \(error)")
                    return
                }

                members = snapshot?.documents.compactMap { document in
                    let data = document.data()

                    return Member(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        role: MemberRole(rawValue: data["role"] as? String ?? "メンバー") ?? .member,
                        isAdmin: data["isAdmin"] as? Bool ?? false,
                        isActive: data["isActive"] as? Bool ?? true,
                        gender: Gender(rawValue: data["gender"] as? String ?? "男性") ?? .male,
                        level: MemberLevel(rawValue: data["level"] as? String ?? "初心者") ?? .beginner,
                        totalPoint: data["totalPoint"] as? Int ?? 0,
                        availablePoint: data["availablePoint"] as? Int ?? 0,
                        cleanupTickets: data["cleanupTickets"] as? Int ?? 0,
                        discountTickets: data["discountTickets"] as? Int ?? 0,
                        freeTickets: data["freeTickets"] as? Int ?? 0,
                        attendanceCount: data["attendanceCount"] as? Int ?? 0,
                        setupCount: data["setupCount"] as? Int ?? 0,
                        legendCount: data["legendCount"] as? Int ?? 0,
                        isLegend: data["isLegend"] as? Bool ?? false,
                        profileImageBase64: data["profileImageBase64"] as? String ?? ""
                    )
                } ?? []
            }
    }
}

#Preview {
    MembersView()
}
