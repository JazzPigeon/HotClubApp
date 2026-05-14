import UIKit

enum ImageProcessor {
    static func jpegDataResized(_ data: Data, maxEdge: CGFloat = 1600, quality: CGFloat = 0.82) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw ImageProcessorError.notAnImage
        }
        let largest = max(image.size.width, image.size.height)
        let scale = largest > maxEdge ? maxEdge / largest : 1
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpeg = resized.jpegData(compressionQuality: quality) else {
            throw ImageProcessorError.encodeFailed
        }
        return jpeg
    }
}

enum ImageProcessorError: Error {
    case notAnImage
    case encodeFailed
}
