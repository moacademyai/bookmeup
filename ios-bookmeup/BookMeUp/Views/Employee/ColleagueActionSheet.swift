import SwiftUI

/// What a specialist is about to do to somebody else's appointment.
nonisolated enum ColleagueAction: Identifiable {
    case move(Booking)
    case cancel(Booking)

    var id: String {
        switch self {
        case .move(let booking): "move-\(booking.id.uuidString)"
        case .cancel(let booking): "cancel-\(booking.id.uuidString)"
        }
    }

    var booking: Booking {
        switch self {
        case .move(let booking), .cancel(let booking): booking
        }
    }

    var title: String {
        switch self {
        case .move(let booking): "Perkelti \(booking.clientName.possessive) vizitą?"
        case .cancel: "Atšaukti šį vizitą?"
        }
    }

    var confirmTitle: String {
        switch self {
        case .move: "Perkelti"
        case .cancel: "Atšaukti vizitą"
        }
    }

    var isDestructive: Bool {
        if case .cancel = self { return true }
        return false
    }

    var explanation: String {
        switch self {
        case .move: "Vizitas priklauso kolegai. Toliau galėsi pasirinkti naują laiką."
        case .cancel: "Vizitas priklauso kolegai. Klientas gaus pranešimą, o laikas grįš į laisvų laikų sąrašą."
        }
    }
}

/// A deliberate stop before changing a colleague's appointment.
///
/// It exists because the calendar makes helping a colleague easy, and anything easy
/// enough to do on purpose is easy enough to do by accident. One clear screen naming
/// the client, the specialist and the time is enough friction for V1 — no passwords,
/// no typing the client's name back.
struct ColleagueActionSheet: View {
    let action: ColleagueAction
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var booking: Booking { action.booking }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(action.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 26)
                .padding(.bottom, 18)

            VStack(spacing: 0) {
                row(label: "Klientas", value: booking.clientName)
                Divider().overlay(Palette.hairline)
                row(label: "Specialistas", value: booking.specialistName)
                Divider().overlay(Palette.hairline)
                row(label: "Laikas", value: "\(booking.start.relativeDayText) · \(booking.start.timeText)")
            }
            .cardSurface(padding: 0, cornerRadius: 18)

            Text(action.explanation)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            Spacer(minLength: 18)

            VStack(spacing: 10) {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(action.confirmTitle)
                }
                .buttonStyle(
                    action.isDestructive
                        ? AnyButtonStyle(QuietButtonStyle(tint: Palette.terracotta))
                        : AnyButtonStyle(MarigoldButtonStyle())
                )

                Button("Atšaukti") { dismiss() }
                    .buttonStyle(QuietButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.bone)
        .presentationDetents([.height(430)])
        .presentationDragIndicator(.visible)
    }

    private func row(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

/// Lets one view choose between two button styles without duplicating the button.
struct AnyButtonStyle: ButtonStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}

nonisolated extension String {
    /// "Ieva Kazlauskaitė" → "Ievos Kazlauskaitės", so a confirmation reads like a
    /// sentence rather than a database row. Falls back to the plain name whenever the
    /// ending is not one this rule covers.
    var possessive: String {
        split(separator: " ")
            .map { word -> String in
                let name = String(word)
                switch true {
                case name.hasSuffix("as"): return String(name.dropLast(2)) + "o"
                case name.hasSuffix("is"): return String(name.dropLast(2)) + "io"
                case name.hasSuffix("us"): return String(name.dropLast(2)) + "aus"
                case name.hasSuffix("ė"): return String(name.dropLast()) + "ės"
                case name.hasSuffix("a"): return String(name.dropLast()) + "os"
                default: return name
                }
            }
            .joined(separator: " ")
    }
}
