import SwiftUI
import FirebaseFirestore

struct ActivityDetailView: View {
    @Binding var activity: Activity

    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @AppStorage("currentUserIsAdmin")
    private var currentUserIsAdmin = false

    @State private var memberNames: [String: String] = [:]
    @State private var memberGenders: [String: Gender] = [:]
    @State private var memberLevels: [String: MemberLevel] = [:]

    @State private var isShowingQRCode = false

    @State private var challengeTickets = 0
    @State private var priorityTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0

    @State private var showUseTicketAlert = false
    @State private var selectedTicketTitle = ""
    @State private var selectedTicketField = ""
    @State private var selectedTicketIcon = ""

    @State private var ticketToCancel: UsedTicket?

    @State private var selectedSetupMemberIds: Set<String> = []
    @State private var setupPointGrantedMemberIds: Set<String> = []
    @State private var showSetupPointDoneAlert = false

    private var attendingIds: [String] {
        activity.attendance
            .filter { $0.status == .attending }
            .map { $0.memberId }
    }

    private var undecidedIds: [String] {
        activity.attendance
            .filter { $0.status == .undecided }
            .map { $0.memberId }
    }

    private var absentIds: [String] {
        activity.attendance
            .filter { $0.status == .absent }
            .map { $0.memberId }
    }

    private var paidCount: Int {
        activity.paidMembers.count
    }

    private var unpaidCount: Int {
        max(attendingIds.count - activity.paidMembers.count, 0)
    }

    private var collectedAmount: Int {
        activity.fee * paidCount
    }

    private var uncollectedAmount: Int {
        activity.fee * unpaidCount
    }

    var body: some View {
        let discount = discountAmount()
        let payment = max(activity.fee - discount, 0)

        ZStack {
            premiumBackground

            ScrollView {
                VStack(spacing: 18) {
                    heroCard(
                        discount: discount,
                        payment: payment
                    )

                    ticketSection

                    if currentUserIsAdmin {
                        adminActionSection
                        usedTicketSection()
                    }

                    attendanceSummarySection
                    accountingSection
                    participantPaymentSection
                    waitingListSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("ACTIVITY")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchMemberNames()
            loadMyTickets()
            setupPointGrantedMemberIds = Set(
                activity.setupPointGrantedMembers
            )
        }
        .sheet(isPresented: $isShowingQRCode) {
            QRCodeView(activity: activity)
        }
        .alert(
            "チケットを使用しますか？",
            isPresented: $showUseTicketAlert
        ) {
            Button("キャンセル", role: .cancel) { }

            Button("使用する", role: .destructive) {
                useTicket()
            }
        } message: {
            Text("使用すると元には戻せません。")
        }
        .alert(item: $ticketToCancel) { ticket in
            Alert(
                title: Text("使用済みチケットを取り消しますか？"),
                message: Text(
                    "\(memberNames[ticket.memberId] ?? "メンバー") の「\(ticket.ticketType)」を取り消します。チケットも1枚戻します。"
                ),
                primaryButton: .destructive(
                    Text("取り消す")
                ) {
                    cancelUsedTicket(ticket)
                },
                secondaryButton: .cancel(
                    Text("キャンセル")
                )
            )
        }
        .alert(
            "設営ポイントを付与しました",
            isPresented: $showSetupPointDoneAlert
        ) {
            Button("OK", role: .cancel) { }
        }
    }

    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(
                        red: 0.022,
                        green: 0.050,
                        blue: 0.15
                    ),
                    Color(
                        red: 0.11,
                        green: 0.035,
                        blue: 0.22
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 34)
                .offset(x: 175, y: -310)

            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 35)
                .offset(x: -175, y: 360)
        }
    }

    private func heroCard(
        discount: Int,
        payment: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 58, height: 58)

                    Text("🏸")
                        .font(.system(size: 30))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("SiRiUS ACTIVITY")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.9)
                        .foregroundStyle(.cyan.opacity(0.72))

                    Text(activity.title)
                        .font(
                            .system(
                                size: 28,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer()
            }

            VStack(spacing: 11) {
                premiumInfoRow(
                    icon: "calendar",
                    title: "DATE",
                    value: formatDate(activity.date),
                    color: .cyan
                )

                premiumInfoRow(
                    icon: "clock.fill",
                    title: "TIME",
                    value:
                        "\(formatTime(activity.startTime))〜\(formatTime(activity.endTime))",
                    color: .orange
                )

                premiumInfoRow(
                    icon: "mappin.and.ellipse",
                    title: "PLACE",
                    value: activity.place,
                    color: .pink
                )

                premiumInfoRow(
                    icon: "person.3.fill",
                    title: "CAPACITY",
                    value: "\(activity.capacity)人",
                    color: .purple
                )
            }

            Divider()
                .overlay(Color.white.opacity(0.14))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("本日のお支払い")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(payment)円")
                        .font(
                            .system(
                                size: 30,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.cyan)
                }

                if discount > 0 {
                    HStack {
                        Text("通常参加費")
                            .foregroundStyle(.white.opacity(0.56))

                        Spacer()

                        Text("\(activity.fee)円")
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .font(.subheadline)

                    HStack {
                        Text("チケット割引")
                            .foregroundStyle(.green)

                        Spacer()

                        Text("-\(discount)円")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                } else {
                    HStack {
                        Text("参加費")
                            .foregroundStyle(.white.opacity(0.56))

                        Spacer()

                        Text("\(activity.fee)円")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .font(.subheadline)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
            )
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.12),
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 28,
                        style: .continuous
                    )
                )
            }
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        Color.cyan.opacity(0.25),
                        Color.purple.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
        .shadow(
            color: Color.cyan.opacity(0.12),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    private func premiumInfoRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(color.opacity(0.16))
                .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.46))

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.065))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
        )
    }

    private var ticketSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "ticket.fill",
                title: "チケット",
                subtitle: "AVAILABLE TICKETS",
                color: .orange
            )

            ticketButton(
                title: "対戦指名券",
                icon: "🏸",
                field: "challengeTickets",
                count: challengeTickets,
                isUsed: hasUsedTicket("対戦指名券"),
                color: .blue
            )

            ticketButton(
                title: "優先ゲーム券",
                icon: "🚀",
                field: "priorityTickets",
                count: priorityTickets,
                isUsed: hasUsedTicket("優先ゲーム券"),
                color: .purple
            )

            ticketButton(
                title: "参加費無料券",
                icon: "🎁",
                field: "freeTickets",
                count: freeTickets,
                isUsed: hasUsedTicket("参加費無料券"),
                color: .green,
                disablesWhenPaymentTicketUsed: true
            )

            ticketButton(
                title: "参加費500円券",
                icon: "💰",
                field: "discountTickets",
                count: discountTickets,
                isUsed: hasUsedTicket("参加費500円券"),
                color: .yellow,
                disablesWhenPaymentTicketUsed: true
            )

            ticketButton(
                title: "参加費半額券",
                icon: "🏸",
                field: "halfPriceTickets",
                count: halfPriceTickets,
                isUsed: hasUsedTicket("参加費半額券"),
                color: .orange,
                disablesWhenPaymentTicketUsed: true
            )
        }
        .premiumSectionCard()
    }

    @ViewBuilder
    private func ticketButton(
        title: String,
        icon: String,
        field: String,
        count: Int,
        isUsed: Bool,
        color: Color,
        disablesWhenPaymentTicketUsed: Bool = false
    ) -> some View {
        let unavailable =
            count <= 0
            || isUsed
            || (
                disablesWhenPaymentTicketUsed
                && hasUsedPaymentTicket()
                && !isUsed
            )

        if count > 0 || isUsed {
            Button {
                guard !unavailable else { return }

                selectedTicketTitle = title
                selectedTicketField = field
                selectedTicketIcon = icon
                showUseTicketAlert = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                        .fill(color.opacity(0.16))
                        .frame(width: 48, height: 48)

                        Text(isUsed ? "✅" : icon)
                            .font(.system(size: 25))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isUsed ? "\(title) 使用済み" : title)
                            .font(.subheadline)
                            .fontWeight(.black)
                            .foregroundStyle(.white)

                        Text(
                            isUsed
                                ? "この活動で使用済みです"
                                : "所持数 \(count)枚"
                        )
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                    }

                    Spacer()

                    if !isUsed {
                        Text("使用")
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundStyle(unavailable ? .gray : color)
                    }
                }
                .padding(13)
                .background(Color.white.opacity(0.065))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 17,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 17,
                        style: .continuous
                    )
                    .stroke(
                        color.opacity(unavailable ? 0.06 : 0.18),
                        lineWidth: 1
                    )
                }
                .opacity(unavailable && !isUsed ? 0.48 : 1)
            }
            .buttonStyle(.plain)
            .disabled(unavailable)
        }
    }

    private var adminActionSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader(
                icon: "shield.lefthalf.filled",
                title: "管理者メニュー",
                subtitle: "ADMIN TOOLS",
                color: .indigo
            )

            Button {
                isShowingQRCode = true
            } label: {
                HStack {
                    Image(systemName: "qrcode")
                    Text("QRコードを表示")
                        .fontWeight(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.white)
                .padding(15)
                .background(
                    LinearGradient(
                        colors: [
                            Color.indigo.opacity(0.72),
                            Color.blue.opacity(0.70)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .premiumSectionCard()
    }

    private var attendanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "person.3.fill",
                title: "出欠状況",
                subtitle: "ATTENDANCE",
                color: .cyan
            )

            HStack(spacing: 10) {
                attendanceStat(
                    title: "参加",
                    value: attendingIds.count,
                    color: .green
                )

                attendanceStat(
                    title: "未定",
                    value: undecidedIds.count,
                    color: .orange
                )

                attendanceStat(
                    title: "不参加",
                    value: absentIds.count,
                    color: .red
                )
            }

            attendanceNameSection(
                title: "参加",
                memberIds: attendingIds,
                color: .green
            )

            attendanceNameSection(
                title: "未定",
                memberIds: undecidedIds,
                color: .orange
            )

            attendanceNameSection(
                title: "不参加",
                memberIds: absentIds,
                color: .red
            )
        }
        .premiumSectionCard()
    }

    private func attendanceStat(
        title: String,
        value: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))

            Text("\(value)人")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.065))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
        )
    }

    private func attendanceNameSection(
        title: String,
        memberIds: [String],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundStyle(color)

                Spacer()

                Text("\(memberIds.count)人")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
            }

            if memberIds.isEmpty {
                Text("該当者なし")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.vertical, 3)
            } else {
                ForEach(memberIds, id: \.self) { memberId in
                    memberNameRow(memberId)
                }
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.055))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    private var accountingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "yensign.circle.fill",
                title: "会計",
                subtitle: "ACCOUNTING",
                color: .green
            )

            premiumAmountRow(
                title: "回収済み",
                value: collectedAmount,
                color: .green
            )

            premiumAmountRow(
                title: "未回収",
                value: uncollectedAmount,
                color: .red
            )

            Text("支払済 \(paidCount)人 / 未払い \(unpaidCount)人")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.50))
        }
        .premiumSectionCard()
    }

    private func premiumAmountRow(
        title: String,
        value: Int,
        color: Color
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.64))

            Spacer()

            Text("\(value)円")
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(color)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
        )
    }

    private var participantPaymentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "person.crop.circle.badge.checkmark",
                title: "参加者・支払い状況",
                subtitle: "MEMBERS",
                color: .purple
            )

            if attendingIds.isEmpty {
                emptyMessage("まだ参加者はいません")
            } else {
                ForEach(attendingIds, id: \.self) { memberId in
                    participantRow(memberId)
                }
            }

            if currentUserIsAdmin {
                Button {
                    grantSetupPoints()
                } label: {
                    Label(
                        selectedSetupMemberIds.isEmpty
                            ? "設営した人を選択してください"
                            : "選択した\(selectedSetupMemberIds.count)人に設営ポイント付与",
                        systemImage: "hammer.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.82),
                                Color.red.opacity(0.72)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .opacity(
                        selectedSetupMemberIds.isEmpty ? 0.45 : 1
                    )
                }
                .buttonStyle(.plain)
                .disabled(selectedSetupMemberIds.isEmpty)
            }
        }
        .premiumSectionCard()
    }

    private func participantRow(
        _ memberId: String
    ) -> some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                memberNameRow(memberId)

                Spacer()

                Text(
                    activity.paidMembers.contains(memberId)
                        ? "支払い済み"
                        : "未払い"
                )
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(
                    activity.paidMembers.contains(memberId)
                        ? Color.green
                        : Color.red
                )
            }

            if currentUserIsAdmin {
                HStack(spacing: 9) {
                    Button {
                        if selectedSetupMemberIds.contains(memberId) {
                            selectedSetupMemberIds.remove(memberId)
                        } else {
                            selectedSetupMemberIds.insert(memberId)
                        }
                    } label: {
                        Label(
                            setupPointGrantedMemberIds.contains(memberId)
                                ? "給付済み"
                                : "設営",
                            systemImage:
                                setupPointGrantedMemberIds.contains(memberId)
                                ? "checkmark.circle.fill"
                                : (
                                    selectedSetupMemberIds.contains(memberId)
                                    ? "checkmark.square.fill"
                                    : "square"
                                )
                        )
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            setupPointGrantedMemberIds.contains(memberId)
                                ? Color.green
                                : Color.orange
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        setupPointGrantedMemberIds.contains(memberId)
                    )

                    Button {
                        togglePaid(memberId)
                    } label: {
                        Text(
                            activity.paidMembers.contains(memberId)
                                ? "支払い取消"
                                : "支払い確認"
                        )
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            activity.paidMembers.contains(memberId)
                                ? Color.orange.opacity(0.78)
                                : Color.green.opacity(0.78)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.055))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    private var waitingListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "hourglass",
                title: "キャンセル待ち",
                subtitle: "WAITING LIST",
                color: .orange
            )

            if activity.waitingList.isEmpty {
                emptyMessage("キャンセル待ちはいません")
            } else {
                ForEach(activity.waitingList, id: \.self) { memberId in
                    memberNameRow(memberId)
                        .padding(12)
                        .background(Color.white.opacity(0.055))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 15,
                                style: .continuous
                            )
                        )
                }
            }
        }
        .premiumSectionCard()
    }

    private func sectionHeader(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(color.opacity(0.16))
                .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.42))

                Text(title)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }

    private func memberNameRow(
        _ memberId: String
    ) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(
                    memberGenders[memberId] == .female
                        ? Color.pink
                        : Color.blue
                )
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(memberNames[memberId] ?? "読み込み中...")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if currentUserIsAdmin {
                    Text(memberLevels[memberId]?.rawValue ?? "")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
        }
    }

    private func emptyMessage(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.46))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 15,
                    style: .continuous
                )
            )
    }

    private func hasUsedTicket(
        _ ticketType: String
    ) -> Bool {
        activity.usedTickets.contains {
            $0.memberId == currentUserId
            && $0.ticketType == ticketType
        }
    }

    private func hasUsedPaymentTicket() -> Bool {
        let paymentTicketTypes = [
            "参加費無料券",
            "参加費500円券",
            "参加費半額券"
        ]

        return activity.usedTickets.contains {
            $0.memberId == currentUserId
            && paymentTicketTypes.contains($0.ticketType)
        }
    }

    private func useTicket() {
        let usedAt = Date()

        PointService.shared.useTicket(
            memberId: currentUserId,
            ticketField: selectedTicketField,
            title: selectedTicketTitle,
            icon: selectedTicketIcon,
            activityId: activity.id
        )

        let newTicket = UsedTicket(
            memberId: currentUserId,
            ticketType: selectedTicketTitle,
            usedAt: usedAt
        )

        activity.usedTickets.append(newTicket)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.6
        ) {
            loadMyTickets()
        }

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "usedTickets": FieldValue.arrayUnion([[
                    "memberId": currentUserId,
                    "ticketType": selectedTicketTitle,
                    "usedAt": Timestamp(date: usedAt),
                    "activityId": activity.id
                ]])
            ])
    }

    private func discountAmount() -> Int {
        if hasUsedTicket("参加費無料券") {
            return activity.fee
        }

        if hasUsedTicket("参加費半額券") {
            return activity.fee / 2
        }

        if hasUsedTicket("参加費500円券") {
            return max(activity.fee - 500, 0)
        }

        return 0
    }

    private func loadMyTickets() {
        guard !currentUserId.isEmpty else {
            return
        }

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, _ in
                let data = snapshot?.data()

                DispatchQueue.main.async {
                    challengeTickets =
                        data?["challengeTickets"] as? Int
                        ?? 0

                    priorityTickets =
                        data?["priorityTickets"] as? Int
                        ?? 0

                    discountTickets =
                        data?["discountTickets"] as? Int
                        ?? 0

                    halfPriceTickets =
                        data?["halfPriceTickets"] as? Int
                        ?? 0

                    freeTickets =
                        data?["freeTickets"] as? Int
                        ?? 0
                }
            }
    }

    private func fetchMemberNames() {
        memberNames = [:]
        memberGenders = [:]
        memberLevels = [:]

        let ids = Array(
            Set(
                attendingIds
                + undecidedIds
                + absentIds
                + activity.waitingList
                + activity.usedTickets.map { $0.memberId }
            )
        )

        for memberId in ids {
            db.collection("members")
                .document(memberId)
                .getDocument { snapshot, error in
                    if let error {
                        print(
                            "参加者取得エラー: \(error.localizedDescription)"
                        )
                        return
                    }

                    let data = snapshot?.data()

                    let name =
                        data?["name"] as? String
                        ?? "ID不一致: \(memberId)"

                    let gender =
                        Gender(
                            rawValue:
                                data?["gender"] as? String
                                ?? "男性"
                        )
                        ?? .male

                    let level =
                        MemberLevel(
                            rawValue:
                                data?["level"] as? String
                                ?? "初心者"
                        )
                        ?? .beginner

                    DispatchQueue.main.async {
                        memberNames[memberId] = name
                        memberGenders[memberId] = gender
                        memberLevels[memberId] = level
                    }
                }
        }
    }

    private func grantPoints() {
        guard !activity.pointGranted else {
            return
        }

        for memberId in attendingIds {
            PointService.shared.addPoint(
                memberId: memberId,
                point: 5,
                title: "練習参加",
                icon: "🏸",
                addAttendanceCount: true
            )
        }

        for memberId in absentIds {
            PointService.shared.resetAttendanceStreak(
                memberId: memberId
            )
        }

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "pointGranted": true,
                "pointGrantedAt": Timestamp()
            ])

        activity.pointGranted = true
        activity.pointGrantedAt = Date()
    }

    private func usedTicketSection() -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader(
                icon: "ticket.fill",
                title: "使用済みチケット",
                subtitle: "USED TICKETS",
                color: .red
            )

            if activity.usedTickets.isEmpty {
                emptyMessage("まだ使用済みチケットはありません")
            } else {
                ForEach(activity.usedTickets) { ticket in
                    HStack(spacing: 11) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ticket.ticketType)
                                .font(.subheadline)
                                .fontWeight(.black)
                                .foregroundStyle(.white)

                            Text(
                                memberNames[ticket.memberId]
                                ?? "読み込み中..."
                            )
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.46))
                        }

                        Spacer()

                        Button("取消") {
                            ticketToCancel = ticket
                        }
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(.red)
                    }
                    .padding(13)
                    .background(Color.white.opacity(0.055))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                    )
                }
            }
        }
        .premiumSectionCard()
    }

    private func cancelUsedTicket(
        _ ticket: UsedTicket
    ) {
        let ticketField: String

        switch ticket.ticketType {
        case "対戦指名券":
            ticketField = "challengeTickets"

        case "優先ゲーム券":
            ticketField = "priorityTickets"

        case "参加費無料券":
            ticketField = "freeTickets"

        case "参加費500円券":
            ticketField = "discountTickets"

        case "参加費半額券":
            ticketField = "halfPriceTickets"

        default:
            return
        }

        db.collection("activities")
            .document(activity.id)
            .getDocument { snapshot, error in
                if let error {
                    print(
                        "使用済みチケット取得エラー: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let data = snapshot?.data(),
                    var usedTicketsArray =
                        data["usedTickets"] as? [[String: Any]]
                else {
                    return
                }

                if let index =
                    usedTicketsArray.firstIndex(
                        where: { item in
                            let memberId =
                                item["memberId"] as? String

                            let ticketType =
                                item["ticketType"] as? String

                            return memberId == ticket.memberId
                                && ticketType == ticket.ticketType
                        }
                    ) {
                    usedTicketsArray.remove(at: index)
                }

                db.collection("activities")
                    .document(activity.id)
                    .updateData([
                        "usedTickets": usedTicketsArray
                    ])

                db.collection("members")
                    .document(ticket.memberId)
                    .updateData([
                        ticketField:
                            FieldValue.increment(Int64(1))
                    ])

                DispatchQueue.main.async {
                    if let localIndex =
                        activity.usedTickets.firstIndex(
                            where: {
                                $0.memberId == ticket.memberId
                                && $0.ticketType == ticket.ticketType
                                && $0.usedAt == ticket.usedAt
                            }
                        ) {
                        activity.usedTickets.remove(at: localIndex)
                    } else if let localIndex =
                        activity.usedTickets.firstIndex(
                            where: {
                                $0.memberId == ticket.memberId
                                && $0.ticketType == ticket.ticketType
                            }
                        ) {
                        activity.usedTickets.remove(at: localIndex)
                    }

                    if ticket.memberId == currentUserId {
                        loadMyTickets()
                    }
                }
            }
    }

    private func togglePaid(
        _ memberId: String
    ) {
        let activityId = activity.id

        if activity.paidMembers.contains(memberId) {
            activity.paidMembers.removeAll {
                $0 == memberId
            }

            db.collection("activities")
                .document(activityId)
                .updateData([
                    "paidMembers":
                        FieldValue.arrayRemove([memberId])
                ])
        } else {
            activity.paidMembers.append(memberId)

            db.collection("activities")
                .document(activityId)
                .updateData([
                    "paidMembers":
                        FieldValue.arrayUnion([memberId])
                ])
        }
    }

    private func formatDate(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func formatTime(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDateTime(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    private func grantSetupPoints() {
        guard !selectedSetupMemberIds.isEmpty else {
            return
        }

        let memberIds = Array(selectedSetupMemberIds)

        for memberId in memberIds {
            PointService.shared.addPoint(
                memberId: memberId,
                point: 3,
                title: "設営参加",
                icon: "🛠"
            )

            db.collection("members")
                .document(memberId)
                .updateData([
                    "setupCount":
                        FieldValue.increment(Int64(1))
                ])
        }

        setupPointGrantedMemberIds.formUnion(memberIds)

        activity.setupPointGrantedMembers =
            Array(setupPointGrantedMemberIds)

        db.collection("activities")
            .document(activity.id)
            .updateData([
                "setupPointGrantedMembers":
                    Array(setupPointGrantedMemberIds)
            ])

        selectedSetupMemberIds.removeAll()
        showSetupPointDoneAlert = true
    }
}

private extension View {
    func premiumSectionCard() -> some View {
        self
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
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
            }
            .shadow(
                color: Color.black.opacity(0.16),
                radius: 14,
                x: 0,
                y: 8
            )
    }
}
