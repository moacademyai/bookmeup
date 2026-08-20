import UIKit

/// Storage for Beauty Passport photos.
///
/// Photos are written to the app container and referenced by name, so the passport
/// entry stays a small record. Swapping this service for cloud storage later means
/// returning a `.remote` reference here — no passport screen changes.
enum PassportPhotoStore {
    private static let folderName = "BeautyPassportPhotos"
    private static let maxPixelSize: CGFloat = 1600
    private static let cache = NSCache<NSString, UIImage>()

    /// Persists a captured or picked photo and returns its reference.
    static func save(_ image: UIImage) -> PassportPhotoReference? {
        guard let data = downscaled(image).jpegData(compressionQuality: 0.82) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
        } catch {
            print("[BeautyPassport] Nepavyko išsaugoti nuotraukos: \(error.localizedDescription)")
            return nil
        }
        cache.setObject(image, forKey: name as NSString)
        return .local(name)
    }

    /// Loads the image behind a reference, if it can be resolved locally.
    static func image(for reference: PassportPhotoReference) -> UIImage? {
        switch reference {
        case .asset(let name):
            return UIImage(named: name)
        case .local(let name):
            if let cached = cache.object(forKey: name as NSString) { return cached }
            guard let data = try? Data(contentsOf: directory.appendingPathComponent(name)),
                  let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: name as NSString)
            return image
        case .remote:
            return nil
        }
    }

    /// Deletes a stored photo. Bundled and remote references are left alone.
    static func remove(_ reference: PassportPhotoReference?) {
        guard case .local(let name) = reference else { return }
        cache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }

    // MARK: - Private

    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    /// Keeps files small enough to store and fast enough to redraw.
    private static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxPixelSize else { return image }
        let scale = maxPixelSize / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
