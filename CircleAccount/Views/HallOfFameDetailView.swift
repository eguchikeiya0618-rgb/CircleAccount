import SwiftUI

struct HallOfFameDetailView: View {
    let record: HallOfFameRecord
    let memberImages: [String: String]

    @State private var screenAppeared = false
    @State private var crownGlow = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            detailBackground
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 18) {
                    championHeader

                    monthlyAwardsSection

                    pointTopThreeSection

                    permanentRecordNotice
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .opacity(screenAppeared ? 1 : 0)
                .offset(y: screenAppeared ? 0 : 18)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(formattedMonth(record.month))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 演出

    private func startAnimations() {
        guard !screenAppeared else {
            return
        }

        withAnimation(
            .spring(
                response: 0.65,
                dampingFraction: 0.75
            )
        ) {
            screenAppeared = true
        }

        withAnimation(
            .easeInOut(duration: 1.1)
                .repeatForever(autoreverses: true)
        ) {
            crownGlow = true
        }
    }

    // MARK: - ヘッダー

    private var championHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(
                                    crownGlow ? 0.70 : 0.28
                                ),
                                Color.orange.opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 6,
                            endRadius: 100
                        )
                    )
                    .frame(width: 205, height: 205)
                    .scaleEffect(crownGlow ? 1.10 : 0.92)

                ProfileImageView(
                    imageBase64: profileImage(
                        memberId: record.displayPointKingId,
                        memberName: record.displayPointKingName
                    ),
                    size: 112
                )
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.yellow,
                                    Color.orange,
                                    Color.white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                }
                .shadow(
                    color: Color.orange.opacity(0.45),
                    radius: 18
                )

                Text("👑")
                    .font(.system(size: 43))
                    .offset(x: 45, y: -48)
                    .scaleEffect(crownGlow ? 1.10 : 0.94)
            }

            VStack(spacing: 5) {
                Text("MONTHLY CHAMPION")
                    .font(
                        .system(
                            size: 10,
                            weight: .black
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(.orange)

                Text(record.displayPointKingName)
                    .font(
                        .system(
                            size: 33,
                            weight: .black,
                            design: .rounded
                        )
                    )

                Text("\(record.displayPointKingPoint)pt")
                    .font(
                        .system(
                            size: 25,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.orange,
                                Color.purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(formattedMonth(record.month))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.16),
                    Color.orange.opacity(0.08),
                    Color.purple.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 29)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 29)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.65),
                            Color.orange.opacity(0.28),
                            Color.purple.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: Color.orange.opacity(0.13),
            radius: 16,
            x: 0,
            y: 8
        )
    }

    // MARK: - 月間表彰

    private var monthlyAwardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                icon: "trophy.fill",
                title: "月間表彰",
                subtitle: "MONTHLY AWARDS",
                color: .orange
            )

            awardDetailRow(
                icon: "👑",
                title: "ポイント王",
                subtitle: "POINT KING",
                name: record.displayPointKingName,
                value: "\(record.displayPointKingPoint)pt",
                color: .orange,
                memberId: record.displayPointKingId
            )

            awardDetailRow(
                icon: "🏸",
                title: "参加王",
                subtitle: "ATTENDANCE KING",
                name: record.attendanceKingName,
                value:
                    record.attendanceKingName.isEmpty
                    ? "記録なし"
                    : "\(record.attendanceKingCount)回",
                color: .blue
            )

            awardDetailRow(
                icon: "🔨",
                title: "設営王",
                subtitle: "SETUP KING",
                name: record.setupKingName,
                value:
                    record.setupKingName.isEmpty
                    ? "記録なし"
                    : "\(record.setupKingCount)回",
                color: .green
            )
            awardDetailRow(
                icon: "⭐️",
                title: "月間MVP",
                subtitle: "MONTHLY MVP",
                name: record.mvpName,
                value: "MVP",
                color: .yellow,
                memberId: record.mvpId
            )
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    Color.orange.opacity(0.12),
                    lineWidth: 1
                )
        }
    }

    private func awardDetailRow(
        icon: String,
        title: String,
        subtitle: String,
        name: String,
        value: String,
        color: Color,
        memberId: String = ""
    ) -> some View {
        Group {
            if name.isEmpty {
                awardDetailContent(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    name: name,
                    value: value,
                    color: color,
                    memberId: memberId,
                    showsChevron: false
                )
            } else {
                NavigationLink {
                    HallOfFameMemberProfileLoaderView(
                        memberId: memberId,
                        memberName: name
                    )
                } label: {
                    awardDetailContent(
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        name: name,
                        value: value,
                        color: color,
                        memberId: memberId,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func awardDetailContent(
        icon: String,
        title: String,
        subtitle: String,
        name: String,
        value: String,
        color: Color,
        memberId: String,
        showsChevron: Bool
    ) -> some View {
        let imageBase64 = profileImage(
            memberId: memberId,
            memberName: name
        )

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 58, height: 58)

                if !name.isEmpty && !imageBase64.isEmpty {
                    ProfileImageView(
                        imageBase64: imageBase64,
                        size: 50
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                color.opacity(0.75),
                                lineWidth: 2
                            )
                    }
                } else {
                    Text(icon)
                        .font(.system(size: 30))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(
                        .system(
                            size: 8,
                            weight: .black
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    name.isEmpty
                        ? "記録なし"
                        : name
                )
                .font(.headline)
                .bold()
                .lineLimit(1)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(13)
        .background(color.opacity(0.055))
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    color.opacity(0.12),
                    lineWidth: 1
                )
        }
    }
    // MARK: - TOP3

    private var pointTopThreeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                icon: "list.number",
                title: "ポイントランキング",
                subtitle: "POINT TOP 3",
                color: .purple
            )

            topThreeRow(
                rank: 1,
                name: record.displayPointKingName,
                point: record.displayPointKingPoint,
                memberId: record.displayPointKingId
            )

            if !record.secondName.isEmpty {
                topThreeRow(
                    rank: 2,
                    name: record.secondName,
                    point: record.secondPoint
                )
            }

            if !record.thirdName.isEmpty {
                topThreeRow(
                    rank: 3,
                    name: record.thirdName,
                    point: record.thirdPoint
                )
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    Color.purple.opacity(0.12),
                    lineWidth: 1
                )
        }
    }

    private func topThreeRow(
        rank: Int,
        name: String,
        point: Int,
        memberId: String = ""
    ) -> some View {
        let imageBase64 = profileImage(
            memberId: memberId,
            memberName: name
        )

        return Group {
            if name.isEmpty {
                topThreeRowContent(
                    rank: rank,
                    name: name,
                    point: point,
                    imageBase64: imageBase64,
                    showsChevron: false
                )
            } else {
                NavigationLink {
                    HallOfFameMemberProfileLoaderView(
                        memberId: memberId,
                        memberName: name
                    )
                } label: {
                    topThreeRowContent(
                        rank: rank,
                        name: name,
                        point: point,
                        imageBase64: imageBase64,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func topThreeRowContent(
        rank: Int,
        name: String,
        point: Int,
        imageBase64: String,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(rankIcon(rank))
                .font(.system(size: 30))
                .frame(width: 40)

            if !imageBase64.isEmpty {
                ProfileImageView(
                    imageBase64: imageBase64,
                    size: 45
                )
                .overlay {
                    Circle()
                        .stroke(
                            rankColor(rank).opacity(0.75),
                            lineWidth: 1.5
                        )
                }
            } else {
                Circle()
                    .fill(
                        rankColor(rank).opacity(0.13)
                    )
                    .frame(width: 45, height: 45)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(
                                rankColor(rank)
                            )
                    }
            }

            Text(
                name.isEmpty
                    ? "記録なし"
                    : name
            )
            .font(.headline)
            .bold()
            .lineLimit(1)

            Spacer()

            Text("\(point)pt")
                .font(.headline)
                .bold()
                .foregroundStyle(rankColor(rank))

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            rankColor(rank).opacity(0.06)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 17)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(
                    rankColor(rank).opacity(0.10),
                    lineWidth: 1
                )
        }
    }

    // MARK: - 永久保存表示

    private var permanentRecordNotice: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.13))
                    .frame(width: 44, height: 44)

                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("永久保存された記録")
                    .font(.headline)
                    .bold()

                Text("この月の表彰結果は変更されません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("HISTORY")
                .font(
                    .system(
                        size: 8,
                        weight: .black
                    )
                )
                .tracking(1)
                .foregroundStyle(.orange)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.10),
                    Color(.systemBackground)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - 共通部品

    private func sectionTitle(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.13))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .bold()

                Text(subtitle)
                    .font(
                        .system(
                            size: 8,
                            weight: .black
                        )
                    )
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func profileImage(
        memberId: String,
        memberName: String
    ) -> String {
        if !memberId.isEmpty,
           let image = memberImages[memberId],
           !image.isEmpty {
            return image
        }

        return memberImages[memberName] ?? ""
    }

    private func rankIcon(
        _ rank: Int
    ) -> String {
        switch rank {
        case 1:
            return "🥇"

        case 2:
            return "🥈"

        case 3:
            return "🥉"

        default:
            return "\(rank)"
        }
    }

    private func rankColor(
        _ rank: Int
    ) -> Color {
        switch rank {
        case 1:
            return .orange

        case 2:
            return .gray

        case 3:
            return .brown

        default:
            return .primary
        }
    }

    private func formattedMonth(
        _ month: String
    ) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.locale =
            Locale(identifier: "ja_JP")
        inputFormatter.dateFormat = "yyyy-MM"

        let outputFormatter = DateFormatter()
        outputFormatter.locale =
            Locale(identifier: "ja_JP")
        outputFormatter.dateFormat = "yyyy年M月"

        guard
            let date =
                inputFormatter.date(from: month)
        else {
            return month
        }

        return outputFormatter.string(from: date)
    }

    // MARK: - 背景

    private var detailBackground: some View {
        TimelineView(.animation) { timeline in
            let time =
                timeline.date
                    .timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.055))
                    .frame(width: 280, height: 280)
                    .blur(radius: 25)
                    .offset(
                        x:
                            CGFloat(
                                sin(time * 0.18)
                            ) * 100,
                        y: -250
                    )

                Circle()
                    .fill(Color.purple.opacity(0.05))
                    .frame(width: 260, height: 260)
                    .blur(radius: 27)
                    .offset(
                        x:
                            CGFloat(
                                cos(time * 0.15)
                            ) * 110,
                        y: 300
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        HallOfFameDetailView(
            record: HallOfFameRecord(
                id: "preview",
                month: "2026-07",
                championName: "けーや",
                championPoint: 83,
                secondName: "こーちゃん",
                secondPoint: 70,
                thirdName: "ぽよ",
                thirdPoint: 60,
                pointKingName: "けーや",
                pointKingPoint: 83,
                pointKingId: "",
                attendanceKingName: "けーや",
                attendanceKingCount: 12,
                setupKingName: "こーちゃん",
                setupKingCount: 8,

                mvpId: "",
                mvpName: "ぽよ",
                mvpPoint: 60
            ),
            memberImages: [:]
        )
    }
}
