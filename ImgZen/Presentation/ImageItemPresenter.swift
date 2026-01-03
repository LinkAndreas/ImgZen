import Foundation

/// Presents image metadata in a user-friendly format for display in UI.
struct ImageItemPresenter {
    /// The formatted title (filename) for display.
    var title: String {
        metadata.filename
    }

    /// The formatted subtitle showing dimensions and file size.
    var subtitle: String {
        let width = Int(metadata.dimensions.width)
        let height = Int(metadata.dimensions.height)
        let dimensions = "\(width) x \(height) px"
        let filesize = metadata.fileSize.formatted(.byteCount(style: .file))
        return "\(dimensions) ⋅ \(filesize)"
    }

    /// The format badge text derived from the image's content type.
    var badge: String {
        let uti = metadata.contentType

        switch uti {
        case "public.jpeg", "public.jpg":
            return "JPEG"
        case "public.png":
            return "PNG"
        case "public.heic", "public.heif":
            return "HEIC"
        case "public.tiff":
            return "TIFF"
        case "com.compuserve.gif":
            return "GIF"
        case "public.webp":
            return "WebP"
        default:
            // Extract from UTI string
            if uti.contains("jpeg") {
                return "JPEG"
            } else if uti.contains("png") {
                return "PNG"
            } else if uti.contains("heic") || uti.contains("heif") {
                return "HEIC"
            }
            return uti.components(separatedBy: ".").last?.uppercased() ?? "Unknown"
        }
    }

    private let metadata: ImageMetadata

    /// Creates an ImageItemPresenter with the given metadata.
    /// - Parameter metadata: The image metadata to present.
    init(metadata: ImageMetadata) {
        self.metadata = metadata
    }
}
