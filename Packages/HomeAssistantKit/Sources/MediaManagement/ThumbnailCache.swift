import UIKit

/// Downsampled thumbnails, cached in memory. Full-size photos are only decoded when
/// the user opens them, which keeps grids of hundreds of photos smooth.
public actor ThumbnailCache {
    public static let shared = ThumbnailCache()

    private let cache = NSCache<NSURL, UIImage>()

    public init(countLimit: Int = 300) {
        cache.countLimit = countLimit
    }

    public func thumbnail(for url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        let key = "\(url.absoluteString)#\(Int(maxPixelSize))"
        let cacheKey = NSURL(string: key) ?? url as NSURL
        if let cached = cache.object(forKey: cacheKey) { return cached }

        guard let image = UIImage(contentsOfFile: url.path(percentEncoded: false)) else { return nil }
        let scale = maxPixelSize / max(image.size.width, image.size.height, 1)
        let size = scale < 1
            ? CGSize(width: image.size.width * scale, height: image.size.height * scale)
            : image.size
        guard let thumbnail = await image.byPreparingThumbnail(ofSize: size) else { return nil }

        cache.setObject(thumbnail, forKey: cacheKey)
        return thumbnail
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}
