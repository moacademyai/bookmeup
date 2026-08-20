import Foundation

/// Where one Beauty Passport photo actually lives.
///
/// A passport entry never carries image data — it stores a short reference string
/// produced by this type. That keeps the record light, lets bundled demo photography
/// and specialist-captured photos share the same field, and means moving photos to a
/// backend later only teaches this type (and `PassportPhotoStore`) a new prefix while
/// the whole Beauty Passport UI stays untouched.
nonisolated enum PassportPhotoReference: Hashable, Codable {
    /// Photography bundled in the asset catalog — demo content only.
    case asset(String)
    /// A photo captured or picked by the specialist, kept in the app container.
    case local(String)
    /// Reserved for cloud storage once photos move to a backend.
    case remote(URL)

    private static let localPrefix = "local:"
    private static let remotePrefix = "remote:"

    /// Parses the string persisted on `BeautyPassportEntry`.
    init?(storedValue: String?) {
        guard let storedValue,
              !storedValue.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        if storedValue.hasPrefix(Self.localPrefix) {
            self = .local(String(storedValue.dropFirst(Self.localPrefix.count)))
        } else if storedValue.hasPrefix(Self.remotePrefix),
                  let url = URL(string: String(storedValue.dropFirst(Self.remotePrefix.count))) {
            self = .remote(url)
        } else {
            self = .asset(storedValue)
        }
    }

    /// The string written back into the entry.
    var storedValue: String {
        switch self {
        case .asset(let name): name
        case .local(let name): Self.localPrefix + name
        case .remote(let url): Self.remotePrefix + url.absoluteString
        }
    }

    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }
}
