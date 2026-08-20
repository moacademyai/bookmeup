import SwiftUI

/// „Lojalumo taškai“.
///
/// Two questions, in this order: how many points do I have, and what can I do with them.
/// Everything else — the tier, the history, the rules — sits below, because it is only
/// interesting once those two are answered.
///
/// The balance is computed from the client's real completed visits and is labelled as a
/// demonstration until a loyalty backend exists. A client is never told they own something
/// the platform cannot yet honour.
struct LoyaltyView: View {
    @Environment(BookMeUpStore.self) private var store

    private var account: LoyaltyAccount { store.loyaltyAccount }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                balance
                rewards
                history
                explanation
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Lojalumo taškai")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    // MARK: - Balance

    private var balance: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.pointsText)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.onPine)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("taškų")
                    .font(.subheadline)
                    .foregroundStyle(Palette.onPine.opacity(0.7))
            }

            if let next = account.nextTier, let remaining = account.pointsToNextTier {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Palette.onPine.opacity(0.16))
                            Capsule()
                                .fill(Palette.marigold)
                                .frame(width: max(geometry.size.width * account.tierProgress, 6))
                        }
                    }
                    .frame(height: 8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: account.tierProgress)

                    Text("Dar \(remaining) tšk. iki „\(next.title)“")
                        .font(.caption)
                        .foregroundStyle(Palette.onPine.opacity(0.75))
                }
            } else {
                Text("Aukščiausias lygis: \(account.tier.title)")
                    .font(.caption)
                    .foregroundStyle(Palette.onPine.opacity(0.75))
            }

            Label(account.tier.perk, systemImage: "checkmark.seal")
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.onPine)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Palette.onPine.opacity(0.12), in: .capsule)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Palette.pine, in: .rect(cornerRadius: 26))
    }

    // MARK: - Rewards

    private var rewards: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ką galiu gauti")
            VStack(spacing: 0) {
                ForEach(LoyaltyProgram.rewards) { reward in
                    rewardRow(reward)
                    if reward.id != LoyaltyProgram.rewards.last?.id {
                        ProfileRowDivider()
                    }
                }
            }
            .cardSurface(padding: 16)
        }
    }

    private func rewardRow(_ reward: LoyaltyReward) -> some View {
        let isAvailable = account.points >= reward.cost
        return HStack(spacing: 12) {
            Image(systemName: reward.symbolName)
                .font(.footnote)
                .foregroundStyle(isAvailable ? Palette.forest : Palette.inkSoft)
                .frame(width: 34, height: 34)
                .background(
                    (isAvailable ? Palette.eucalyptus.opacity(0.45) : Palette.hairline),
                    in: .rect(cornerRadius: 10)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                Text(reward.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Text("\(reward.cost)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(isAvailable ? Palette.forest : Palette.inkSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (isAvailable ? Palette.eucalyptus.opacity(0.4) : Palette.surface),
                    in: .capsule
                )
                .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
    }

    // MARK: - History

    @ViewBuilder
    private var history: some View {
        if account.history.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Taškų dar nesurinkta")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Taškai pradedami kaupti po pirmo įvykusio vizito.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Taškų istorija")
                VStack(spacing: 0) {
                    ForEach(account.history.prefix(8)) { entry in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Palette.ink)
                                Text(entry.detail)
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Text("+\(entry.points)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.forest)
                        }
                        .padding(.vertical, 11)
                        if entry.id != account.history.prefix(8).last?.id {
                            ProfileRowDivider()
                        }
                    }
                }
                .cardSurface(padding: 16)
            }
        }
    }

    // MARK: - Rules

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                "Už kiekvieną išleistą eurą gaunate \(LoyaltyProgram.pointsPerEuro) taškų.",
                systemImage: "info.circle"
            )
            if let notice = account.source.notice {
                Label(notice, systemImage: "hammer")
            }
        }
        .font(.caption)
        .foregroundStyle(Palette.inkSoft)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
