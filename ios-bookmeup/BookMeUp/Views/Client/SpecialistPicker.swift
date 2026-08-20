import SwiftUI

/// The monogram that stands in for a specialist's face.
///
/// The salon has photographs of work, not of people, so inventing a portrait would be a
/// lie. Initials on a tinted disc read as a person, stay legible at any size and never
/// misrepresent who is behind the chair.
struct SpecialistAvatar: View {
    let member: TeamMember
    var size: CGFloat = 46
    var isSelected: Bool = false

    /// A stable tint per person, so the same master always looks the same everywhere.
    private var tint: Color {
        let palette: [Color] = [Palette.forest, Palette.terracotta, Palette.marigold, Palette.success]
        let index = abs(member.name.hashValue) % palette.count
        return palette[index]
    }

    var body: some View {
        Text(member.initials)
            .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.16), in: .circle)
            .overlay {
                Circle().stroke(isSelected ? tint : Color.clear, lineWidth: 2)
            }
    }
}

/// Choosing the master before the time.
///
/// Order matters here: who does the work changes which times exist, so this sits above
/// the calendar and every card carries that person's real availability for the day the
/// client is looking at. "Bet kuris" is first and deliberately framed as the fastest
/// route — a client with no preference should not have to compare four people.
struct SpecialistPicker: View {
    let options: [SpecialistOption]
    /// The chosen master's name, or `nil` for "no preference".
    @Binding var selectedName: String?
    /// The master this client already goes to here, marked so a returning client
    /// recognises them without reading four cards.
    var usualName: String?

    private var anyCount: Int { options.combinedSlots.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Meistras", accessory: options.count > 1 ? "\(options.count)" : nil)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if options.count > 1 {
                        anyCard
                    }
                    ForEach(options) { option in
                        card(option)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, 2, for: .scrollContent)
            .scrollClipDisabled()

            if let selected = options.first(where: { $0.member.name == selectedName }) {
                biography(selected.member)
            }
        }
    }

    private var anyCard: some View {
        let isSelected = selectedName == nil
        return Button {
            select(nil)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.forest)
                    .frame(width: 46, height: 46)
                    .background(Palette.eucalyptus.opacity(0.5), in: .circle)

                Text("Bet kuris")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Greičiausias laikas")
                    .font(.caption2)
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(anyCount > 0 ? "\(anyCount) \(LithuanianPlural.freeSlot(anyCount))" : "Nėra laisvų laikų")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(anyCount > 0 ? Palette.success : Palette.inkSoft)
                    .lineLimit(1)
            }
            .modifier(SpecialistCardChrome(isSelected: isSelected, isEnabled: anyCount > 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bet kuris meistras")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func card(_ option: SpecialistOption) -> some View {
        let isSelected = selectedName == option.member.name
        return Button {
            select(option.member.name)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                SpecialistAvatar(member: option.member, isSelected: isSelected)

                Text(option.member.firstName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                if option.member.name == usualName {
                    Text("Jūsų meistras")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Palette.marigold.opacity(0.85), in: .capsule)
                }

                HStack(spacing: 4) {
                    if let rating = option.member.ratingText {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Palette.marigold)
                        Text(rating)
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                    }
                    Text(option.member.craft)
                        .font(.caption2)
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(option.availabilityText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(option.isFree ? Palette.success : Palette.inkSoft)
                    .lineLimit(1)
            }
            .modifier(SpecialistCardChrome(isSelected: isSelected, isEnabled: option.isFree))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.member.name), \(option.member.craft). \(option.availabilityText)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func biography(_ member: TeamMember) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let experience = member.experienceText {
                Label(experience, systemImage: "seal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.forest)
            }
            if !member.bio.isEmpty {
                Text(member.bio)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Palette.eucalyptus.opacity(0.28), in: .rect(cornerRadius: 16))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func select(_ name: String?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            selectedName = name
        }
    }
}

/// Shared card shape for the picker, so the "any" tile and a person tile are the same
/// object with different contents.
private struct SpecialistCardChrome: ViewModifier {
    let isSelected: Bool
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .frame(width: 134, height: 162, alignment: .leading)
            .padding(12)
            .opacity(isEnabled ? 1 : 0.55)
            .background(isSelected ? Palette.elevated : Palette.surface, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Palette.forest : Palette.hairline, lineWidth: isSelected ? 2 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(Palette.forest)
                        .padding(10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(.rect)
    }
}
