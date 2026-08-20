import Foundation

/// Every destination the owner environment can push.
///
/// One route type for all five tabs means a card on Today can link straight into a
/// setting under Business without either screen knowing about the other.
nonisolated enum OwnerRoute: Hashable {
    case module(OwnerModule)
    case staff(UUID)
    case role(UUID)
    case location(UUID)
}
