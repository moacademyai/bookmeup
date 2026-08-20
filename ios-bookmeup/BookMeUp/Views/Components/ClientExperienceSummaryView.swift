import SwiftUI

/// „Kliento pasirinkimai“ — what the specialist sees.
///
/// Never the questionnaire. `ClientExperienceSummary` turns the answers into a few
/// lines that can be read in seconds, and an unanswered question produces no row at all,
/// so this card is always exactly as long as what the client actually shared.
///
/// It renders whatever the store holds right now, which is why a preference the client
/// changes in their profile is already correct the next time a specialist opens either
/// the booking detail or the client 360.
struct ClientExperienceSummaryView: View {
    let profile: ClientExperienceProfile?
    var style: Style = .compact

    @Environment(BusinessStore.self) private var business

    enum Style {
        /// Before an appointment: only what changes how this visit is served.
        case compact
        /// On the client profile: the same plus their service interests.
        case detailed
    }

    private var lines: [ExperienceSummaryLine] {
        let options = ClientExperienceCatalog.hospitalityOptions(for: business.business)
        return switch style {
        case .compact: ClientExperienceSummary.lines(for: profile, hospitalityOptions: options)
        case .detailed: ClientExperienceSummary.detailedLines(for: profile, hospitalityOptions: options)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if lines.isEmpty {
                Text("Klientas dar nepasidalino savo pasirinkimais.")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lines) { line in
                        row(line)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.wave")
                .font(.footnote)
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Kliento pasirinkimai")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Klientas pasidalino, kaip nori būti aptarnautas")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func row(_ line: ExperienceSummaryLine) -> some View {
        if line.isClientWritten {
            VStack(alignment: .leading, spacing: 6) {
                Label(line.caption, systemImage: line.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                Text(line.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Palette.eucalyptus.opacity(0.24), in: .rect(cornerRadius: 14))
        } else {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: line.symbolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                    .frame(width: 26, height: 26)
                    .background(Palette.eucalyptus.opacity(0.35), in: .circle)

                VStack(alignment: .leading, spacing: 1) {
                    if style == .detailed {
                        Text(line.caption)
                            .font(.caption2)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    Text(line.text)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
