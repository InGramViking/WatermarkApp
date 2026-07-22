import Foundation

// MARK: - 文件管理扩展
extension FileManager {

    /// 支持的图片文件扩展名
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png"]

    /// 支持的 PDF 文件扩展名
    static let pdfExtension = "pdf"

    /// 所有支持的文件扩展名
    static let supportedExtensions: Set<String> = imageExtensions.union([pdfExtension])

    // MARK: - 检查文件类型

    /// 判断文件是否为支持的图片格式
    /// - Parameter url: 文件 URL
    /// - Returns: 是否为图片
    static func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }

    /// 判断文件是否为 PDF
    /// - Parameter url: 文件 URL
    /// - Returns: 是否为 PDF
    static func isPDFFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == pdfExtension
    }

    /// 判断文件是否为支持的类型
    /// - Parameter url: 文件 URL
    /// - Returns: 是否支持
    static func isSupportedFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }

    // MARK: - 文件命名

    /// 为输出文件生成带水印后缀的文件名
    /// - Parameter url: 原始文件 URL
    /// - Returns: 带 "_watermarked" 后缀的文件名
    static func watermarkedFileName(for url: URL) -> String {
        let fileName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        return "\(fileName)_watermarked.\(ext)"
    }

    /// 生成输出文件 URL
    /// - Parameters:
    ///   - sourceURL: 源文件 URL
    ///   - outputDirectory: 输出目录（nil 表示原目录）
    /// - Returns: 输出文件 URL
    static func outputFileURL(for sourceURL: URL, outputDirectory: URL?) -> URL {
        let fileName = watermarkedFileName(for: sourceURL)

        if let outputDir = outputDirectory {
            return outputDir.appendingPathComponent(fileName)
        } else {
            return sourceURL.deletingLastPathComponent().appendingPathComponent(fileName)
        }
    }

    // MARK: - 文件大小格式化

    /// 获取文件大小并格式化为可读字符串
    /// - Parameter url: 文件 URL
    /// - Returns: 格式化后的大小字符串（如 "1.5 MB"）
    static func formattedFileSize(for url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "未知"
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
