import Foundation

extension Client {
    /// Numbers are stored in E.164; this is the readable form for the interface.
    @MainActor
    var phoneDisplay: String {
        hasPhone ? PhoneFormat.display(phone) : ""
    }
}
