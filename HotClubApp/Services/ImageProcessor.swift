import UIKit

enum ImageProcessor {
    static let cropDisplayMaxEdge: CGFloat = 1024
    static let cropExportMaxEdge: CGFloat = 3200
    static let cropOutputEdge: CGFloat = 1600

    static func prepareForCrop(_ data: Data) throws -> (display: UIImage, export: UIImage) {
        guard let raw = UIImage(data: data) else {
            throw ImageProcessorError.notAnImage
        }
        return try prepareForCrop(raw)
    }

    static func prepareForCrop(_ image: UIImage) throws -> (display: UIImage, export: UIImage) {
        let normalized = normalized(image)
        let export = downscaled(normalized, maxEdge: cropExportMaxEdge)
        let display = downscaled(normalized, maxEdge: cropDisplayMaxEdge)
        return (display, export)
    }

    static func encodeSquareCrop(
        image: UIImage,
        scale: CGFloat,
        offset: CGSize,
        outputSide: CGFloat = cropOutputEdge,
        quality: CGFloat = 0.82
    ) throws -> Data {
        let cropped = renderSquareCrop(
            image: image,
            cropSide: outputSide,
            scale: scale,
            offset: offset
        )
        guard let jpeg = cropped.jpegData(compressionQuality: quality) else {
            throw ImageProcessorError.encodeFailed
        }
        return jpeg
    }

    static func downscaled(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let normalized = normalized(image)
        let largest = max(normalized.size.width, normalized.size.height)
        guard largest > maxEdge else { return normalized }

        let scale = maxEdge / largest
        let newSize = CGSize(
            width: normalized.size.width * scale,
            height: normalized.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func jpegDataResized(_ data: Data, maxEdge: CGFloat = 1600, quality: CGFloat = 0.82) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw ImageProcessorError.notAnImage
        }
        let normalized = normalized(image)
        let largest = max(normalized.size.width, normalized.size.height)
        let scale = largest > maxEdge ? maxEdge / largest : 1
        let newSize = CGSize(width: normalized.size.width * scale, height: normalized.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpeg = resized.jpegData(compressionQuality: quality) else {
            throw ImageProcessorError.encodeFailed
        }
        return jpeg
    }

    static func jpegFromSquareUIImage(
        _ image: UIImage,
        maxEdge: CGFloat = 1600,
        quality: CGFloat = 0.82
    ) throws -> Data {
        let normalized = normalized(image)
        let edge = min(max(normalized.size.width, normalized.size.height), maxEdge)
        let targetSize = CGSize(width: edge, height: edge)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let output = renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpeg = output.jpegData(compressionQuality: quality) else {
            throw ImageProcessorError.encodeFailed
        }
        return jpeg
    }

    static func renderSquareCrop(
        image: UIImage,
        cropSide: CGFloat,
        scale: CGFloat,
        offset: CGSize
    ) -> UIImage {
        let normalized = normalized(image)
        let side = max(cropSide, 1)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))

        return renderer.image { _ in
            let imageSize = normalized.size
            let fillScale = max(side / imageSize.width, side / imageSize.height)
            let totalScale = fillScale * scale
            let drawSize = CGSize(width: imageSize.width * totalScale, height: imageSize.height * totalScale)
            let origin = CGPoint(
                x: (side - drawSize.width) / 2 + offset.width,
                y: (side - drawSize.height) / 2 + offset.height
            )
            normalized.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    static func clampCropOffset(
        _ offset: CGSize,
        scale: CGFloat,
        imageSize: CGSize,
        cropSide: CGFloat
    ) -> CGSize {
        let fillScale = max(cropSide / imageSize.width, cropSide / imageSize.height)
        let totalScale = fillScale * max(scale, 1)
        let displayWidth = imageSize.width * totalScale
        let displayHeight = imageSize.height * totalScale
        let maxX = max(0, (displayWidth - cropSide) / 2)
        let maxY = max(0, (displayHeight - cropSide) / 2)

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

enum ImageProcessorError: Error {
    case notAnImage
    case encodeFailed
}
