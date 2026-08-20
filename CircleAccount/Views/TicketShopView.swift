import SwiftUI
import FirebaseFirestore

struct TicketShopView: View {
    private let db = Firestore.firestore()

    @AppStorage("currentUserId")
    private var currentUserId = ""

    @State private var availablePoint = 0

    @State private var cleanupTickets = 0
    @State private var discountTickets = 0
    @State private var halfPriceTickets = 0
    @State private var freeTickets = 0

    @State private var isLoading = true
    @State private var isExchanging = false
    @State private var message = ""

    @State private var activeAlert: TicketShopAlert?
    @State private var showConfetti = false

    private let tickets: [ShopTicket] = [
        ShopTicket(
            id: "cleanup",
            title: "片付けパス",
            description: "活動後の片付けを1回免除",
            icon: "🧹",
            price: 100,
            firestoreField: "cleanupTickets"
        ),

        ShopTicket(
            id: "discount",
            title: "参加費500円券",
            description: "参加費から500円割引",
            icon: "💰",
            price: 200,
            firestoreField: "discountTickets"
        ),

        ShopTicket(
            id: "halfPrice",
            title: "参加費半額券",
            description: "参加費が1回半額",
            icon: "🏸",
            price: 400,
            firestoreField: "halfPriceTickets"
        ),

        ShopTicket(
            id: "free",
            title: "参加費無料券",
            description: "参加費が1回無料",
            icon: "🎁",
            price: 700,
            firestoreField: "freeTickets"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                pointHeader

                if isLoading {
                    SiriusLoadingStateView("ショップを読み込み中")
                        .padding(.top, 28)

                } else {
                    ticketList

                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("チケットショップ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadShopData()
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .confirmation(let ticket):
                return confirmationAlert(ticket: ticket)

            case .success(let ticket):
                return successAlert(ticket: ticket)
            }
        }
        .overlay {
            if showConfetti {
                TicketShopConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }

    // MARK: - 所持ポイント表示

    var pointHeader: some View {
        VStack(spacing: 12) {
            Text("🎫")
                .font(.system(size: 52))

            Text("SiRiUS TICKET SHOP")
                .font(.title2)
                .bold()

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)

                Text("所持ポイント")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(availablePoint)pt")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.10))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - チケット一覧

    var ticketList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("交換できるチケット")
                .font(.title2)
                .bold()

            ForEach(tickets) { ticket in
                ticketRow(ticket)
            }
        }
    }

    func ticketRow(_ ticket: ShopTicket) -> some View {
        let canExchange = availablePoint >= ticket.price
        let ownedCount = ownedTicketCount(ticket)

        return Button {
            guard canExchange, !isExchanging else {
                return
            }

            activeAlert = .confirmation(ticket)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Text(ticket.icon)
                        .font(.system(size: 46))
                        .frame(width: 72, height: 72)
                        .background(
                            LinearGradient(
                                colors: [
                                    ticketColor(ticket).opacity(0.28),
                                    ticketColor(ticket).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    ticketColor(ticket).opacity(0.45),
                                    lineWidth: 1.5
                                )
                        }

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(ticket.title)
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.primary)

                            if ticket.id == "free" {
                                Text("超レア")
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.opacity(0.15))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(ticket.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(ticketRarity(ticket))
                            .font(.caption)
                            .foregroundStyle(ticketColor(ticket))
                    }

                    Spacer()
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("必要ポイント")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)

                            Text("\(ticket.price)pt")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(
                                    canExchange ? .primary : .secondary
                                )
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("所持枚数")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(ownedCount)枚")
                            .font(.headline)
                            .bold()
                    }
                }

                if canExchange {
                    HStack {
                        Spacer()

                        Text("交換する")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.white)

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(ticketColor(ticket))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    HStack {
                        Spacer()

                        Text("あと\(ticket.price - availablePoint)pt必要")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        ticketColor(ticket).opacity(
                            canExchange ? 0.28 : 0.08
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(0.06),
                radius: 10,
                x: 0,
                y: 5
            )
            .opacity(canExchange ? 1 : 0.58)
        }
        .buttonStyle(.plain)
        .disabled(!canExchange || isExchanging)
    }
    func ticketColor(_ ticket: ShopTicket) -> Color {
        switch ticket.id {
        case "cleanup":
            return .brown

        case "discount":
            return .orange

        case "halfPrice":
            return .purple

        case "free":
            return .pink

        default:
            return .blue
        }
    }

    func ticketRarity(_ ticket: ShopTicket) -> String {
        switch ticket.id {
        case "cleanup":
            return "★★☆☆☆"

        case "discount":
            return "★★★☆☆"

        case "halfPrice":
            return "★★★★☆"

        case "free":
            return "★★★★★"

        default:
            return "★★☆☆☆"
        }
    }
    // MARK: - 確認ダイアログ

    func confirmationAlert(
        ticket: ShopTicket
    ) -> Alert {
        Alert(
            title: Text("\(ticket.icon) \(ticket.title)"),
            message: Text(
                """
                このチケットと交換しますか？

                必要ポイント：\(ticket.price)pt
                現在のポイント：\(availablePoint)pt
                交換後：\(availablePoint - ticket.price)pt
                """
            ),
            primaryButton: .cancel(
                Text("キャンセル")
            ),
            secondaryButton: .default(
                Text("交換する")
            ) {
                exchangeTicket(ticket)
            }
        )
    }

    // MARK: - 交換完了ダイアログ

    func successAlert(
        ticket: ShopTicket
    ) -> Alert {
        Alert(
            title: Text("🎉 交換完了"),
            message: Text(
                """
                \(ticket.title)を
                1枚獲得しました！

                残りポイント：\(availablePoint)pt
                """
            ),
            dismissButton: .default(
                Text("OK")
            )
        )
    }

    // MARK: - チケット交換処理

    func exchangeTicket(
        _ ticket: ShopTicket
    ) {
        guard !currentUserId.isEmpty else {
            message = "メンバー情報が取得できません"
            return
        }

        guard !isExchanging else {
            return
        }

        isExchanging = true
        message = ""

        let memberRef = db.collection("members")
            .document(currentUserId)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                snapshot = try transaction.getDocument(memberRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let currentPoint =
                snapshot.data()?["availablePoint"] as? Int ?? 0

            guard currentPoint >= ticket.price else {
                let error = NSError(
                    domain: "TicketShop",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "ポイントが不足しています"
                    ]
                )

                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(
                [
                    "availablePoint":
                        FieldValue.increment(
                            Int64(-ticket.price)
                        ),

                    ticket.firestoreField:
                        FieldValue.increment(Int64(1))
                ],
                forDocument: memberRef
            )

            let historyRef = memberRef
                .collection("pointHistories")
                .document()

            transaction.setData(
                [
                    "title": "\(ticket.title)と交換",
                    "point": -ticket.price,
                    "icon": ticket.icon,
                    "date": Timestamp()
                ],
                forDocument: historyRef
            )

            return nil

        }) { _, error in
            DispatchQueue.main.async {
                isExchanging = false

                if let error {
                    message =
                        "交換失敗：\(error.localizedDescription)"
                    return
                }

                availablePoint -= ticket.price
                increaseLocalTicketCount(ticket)

                withAnimation {
                    showConfetti = true
                }

                activeAlert = .success(ticket)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation {
                        showConfetti = false
                    }
                }
            }
        }
    }

    // MARK: - Firestore読み込み

    func loadShopData() {
        guard !currentUserId.isEmpty else {
            message = "メンバー情報が取得できません"
            isLoading = false
            return
        }

        isLoading = true
        message = ""

        db.collection("members")
            .document(currentUserId)
            .getDocument { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error {
                        message =
                            "読み込み失敗：\(error.localizedDescription)"
                        return
                    }

                    guard let data = snapshot?.data() else {
                        message =
                            "メンバー情報が見つかりません"
                        return
                    }

                    availablePoint =
                        data["availablePoint"] as? Int ?? 0

                    cleanupTickets =
                        data["cleanupTickets"] as? Int ?? 0

                    discountTickets =
                        data["discountTickets"] as? Int ?? 0

                    halfPriceTickets =
                        data["halfPriceTickets"] as? Int ?? 0

                    freeTickets =
                        data["freeTickets"] as? Int ?? 0
                }
            }
    }

    // MARK: - 所持枚数

    func ownedTicketCount(
        _ ticket: ShopTicket
    ) -> Int {
        switch ticket.firestoreField {
        case "cleanupTickets":
            return cleanupTickets

        case "discountTickets":
            return discountTickets

        case "halfPriceTickets":
            return halfPriceTickets

        case "freeTickets":
            return freeTickets

        default:
            return 0
        }
    }

    func increaseLocalTicketCount(
        _ ticket: ShopTicket
    ) {
        switch ticket.firestoreField {
        case "cleanupTickets":
            cleanupTickets += 1

        case "discountTickets":
            discountTickets += 1

        case "halfPriceTickets":
            halfPriceTickets += 1

        case "freeTickets":
            freeTickets += 1

        default:
            break
        }
    }
}

// MARK: - ショップ商品

struct ShopTicket: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let price: Int
    let firestoreField: String
}

// MARK: - アラート種類

enum TicketShopAlert: Identifiable {
    case confirmation(ShopTicket)
    case success(ShopTicket)

    var id: String {
        switch self {
        case .confirmation(let ticket):
            return "confirmation-\(ticket.id)"

        case .success(let ticket):
            return "success-\(ticket.id)"
        }
    }
}

#Preview {
    NavigationStack {
        TicketShopView()
    }
}
struct TicketShopConfettiView: View {
    private let confettiPieces = Array(0..<70)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces, id: \.self) { index in
                    TicketShopConfettiPiece(
                        index: index,
                        screenSize: geometry.size
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
    }
}

struct TicketShopConfettiPiece: View {
    let index: Int
    let screenSize: CGSize

    @State private var isFalling = false

    private var startX: CGFloat {
        CGFloat((index * 47) % 100) / 100 * screenSize.width
    }

    private var endXOffset: CGFloat {
        CGFloat((index % 7) - 3) * 18
    }

    private var delay: Double {
        Double(index % 15) * 0.035
    }

    private var duration: Double {
        1.5 + Double(index % 8) * 0.08
    }

    private var symbol: String {
        let symbols = ["🎉", "✨", "⭐", "🎊", "💎"]
        return symbols[index % symbols.count]
    }

    var body: some View {
        Text(symbol)
            .font(.system(size: CGFloat(13 + index % 10)))
            .position(
                x: startX + (isFalling ? endXOffset : 0),
                y: isFalling
                    ? screenSize.height + 40
                    : -30
            )
            .rotationEffect(
                .degrees(isFalling ? Double(index * 45) : 0)
            )
            .opacity(isFalling ? 0.15 : 1)
            .animation(
                .easeIn(duration: duration)
                    .delay(delay),
                value: isFalling
            )
            .onAppear {
                isFalling = true
            }
    }
}
