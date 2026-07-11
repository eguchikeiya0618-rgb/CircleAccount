import SwiftUI

struct TicketCardView: View {

    let stringingFreeTickets: Int
    let challengeTickets: Int
    let priorityTickets: Int
    let cleanupTickets: Int
    let discountTickets: Int
    let halfPriceTickets: Int
    let freeTickets: Int

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("保有チケット")
                .font(.title2)
                .bold()

            ticketRow(icon: "🎾", title: "ガット張り工賃無料券", count: stringingFreeTickets)
            Divider()

            ticketRow(icon: "⭐", title: "対戦指名券", count: challengeTickets)
            Divider()

            ticketRow(icon: "🚀", title: "優先ゲーム券", count: priorityTickets)
            Divider()

            ticketRow(icon: "🧹", title: "片付けパス", count: cleanupTickets)
            Divider()

            ticketRow(icon: "💰", title: "参加費500円券", count: discountTickets)
            Divider()

            ticketRow(icon: "🏸", title: "参加費半額券", count: halfPriceTickets)
            Divider()

            ticketRow(icon: "🎁", title: "参加費無料券", count: freeTickets)

        }
        .mypageCard()
    }

    func ticketRow(icon: String, title: String, count: Int) -> some View {

        HStack {

            Text(icon)
                .font(.title2)

            Text(title)
                .font(.headline)

            Spacer()

            Text("\(count)枚")
                .font(.headline)
                .bold()
                .foregroundStyle(count > 0 ? .primary : .secondary)
        }
    }
}
