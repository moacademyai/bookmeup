import SwiftUI

/// Lifecycle of a single appointment, shared by the client and employee views.
nonisolated enum BookingStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case pending
    case confirmed
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "Laukia patvirtinimo"
        case .confirmed: "Patvirtinta"
        case .completed: "Įvykęs"
        case .cancelled: "Atšaukta"
        }
    }

    var symbolName: String {
        switch self {
        case .pending: "hourglass"
        case .confirmed: "checkmark.circle"
        case .completed: "checkmark.seal"
        case .cancelled: "xmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .pending: Palette.marigold
        case .confirmed: Palette.forest
        case .completed: Palette.eucalyptus
        case .cancelled: Palette.terracotta
        }
    }

    var isActive: Bool { self == .pending || self == .confirmed }
}
