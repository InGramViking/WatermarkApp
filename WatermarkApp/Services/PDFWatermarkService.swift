import PDFKit
import AppKit
import Foundation

// MARK: - PDF 水印处理服务
class PDFWatermarkService {

    // MARK: - 错误类型
    enum WatermarkError: LocalizedError {
        case failedToLoadPDF
        case failedToCreatePDFData
        case failedToSavePDF

        var errorDescription: String? {
            switch self {
            case .failedToLoadPDF:
                return "无法加载 PDF 文件"
            case .failedToCreatePDFData:
                return "无法创建 PDF 数据"
            case .failedToSavePDF:
                return "无法保存处理后的 PDF 文件"
            }
        }
    }

    // MARK: - 给 PDF 添加水印

    /// 为指定 PDF 文件添加水印
    /// - Parameters:
    ///   - pdfURL: 源 PDF 文件 URL
    ///   - outputURL: 输出文件 URL
    ///   - settings: 水印参数设置
    /// - Throws: WatermarkError
    static func addWatermark(
        to pdfURL: URL,
        outputURL: URL,
        settings: WatermarkSettings
    ) throws {
        // 加载 PDF 文档
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw WatermarkError.failedToLoadPDF
        }

        // 遍历每一页添加水印
        let pageCount = pdfDocument.pageCount
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            // 获取页面 bounds
            let pageBounds = page.bounds(for: PDFDisplayBox.mediaBox)

            // 创建图片上下文用于绘制水印
            let imageWidth = Int(pageBounds.width)
            let imageHeight = Int(pageBounds.height)

            // 如果页面尺寸无效则跳过
            guard imageWidth > 0, imageHeight > 0 else { continue }

            // 创建位图上下文
            guard let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: imageWidth,
                pixelsHigh: imageHeight,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else { continue }

            // 设置图形上下文
            NSGraphicsContext.saveGraphicsState()
            guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
                NSGraphicsContext.restoreGraphicsState()
                continue
            }
            NSGraphicsContext.current = context

            // 绘制原始页面内容
            let pageImage = NSImage(size: pageBounds.size)
            pageImage.lockFocus()
            guard let pageContext = NSGraphicsContext.current else {
                pageImage.unlockFocus()
                NSGraphicsContext.restoreGraphicsState()
                continue
            }
            // 在 NSImage 中绘制 PDF 页面
            page.draw(with: PDFDisplayBox.mediaBox, to: pageContext.cgContext)
            pageImage.unlockFocus()

            // 绘制原始页面到位图
            pageImage.draw(at: .zero, from: .zero, operation: .copy, fraction: 1.0)

            // 绘制水印
            let drawRect = CGRect(origin: .zero, size: pageBounds.size)
            drawWatermark(in: context.cgContext, rect: drawRect, settings: settings)

            // 恢复图形上下文
            NSGraphicsContext.restoreGraphicsState()

            // 将位图转换为 TIFF 表示
            guard let tiffData = bitmapRep.tiffRepresentation else { continue }

            // 创建新的图片
            guard let watermarkedImage = NSImage(data: tiffData) else { continue }

            // 创建新的 PDF 页面来替换原页面
            let newPage = PDFPage(image: watermarkedImage)
            if let newPage = newPage {
                pdfDocument.removePage(at: pageIndex)
                pdfDocument.insert(newPage, at: pageIndex)
            }
        }

        // 保存处理后的 PDF
        guard let outputData = pdfDocument.dataRepresentation() else {
            throw WatermarkError.failedToSavePDF
        }

        try outputData.write(to: outputURL)
    }

    // MARK: - 绘制水印（PDF 版）

    /// 在 PDF 页面的 CGContext 中绘制水印
    /// - Parameters:
    ///   - context: CGContext
    ///   - rect: 页面区域
    ///   - settings: 水印参数设置
    private static func drawWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 保存上下文状态
        context.saveGState()

        // 设置透明度
        context.setAlpha(settings.opacityValue)

        // 根据布局模式绘制
        switch settings.layout {
        case .single:
            drawSingleWatermark(in: context, rect: rect, settings: settings)
        case .tiled:
            drawTiledWatermark(in: context, rect: rect, settings: settings)
        }

        // 恢复上下文状态
        context.restoreGState()
    }

    // MARK: - 单水印（居中）- PDF 版

    /// 在 PDF 页面中央绘制单个水印
    private static func drawSingleWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 创建文本属性
        let attributes = settings.textAttributes
        let attributedString = NSAttributedString(string: settings.text, attributes: attributes)
        let textSize = attributedString.size()

        // 计算居中位置
        let centerX = rect.midX
        let centerY = rect.midY

        // 应用旋转
        context.saveGState()
        context.translateBy(x: centerX, y: centerY)

        let radians = settings.rotation * .pi / 180.0
        context.rotate(by: radians)

        // 在 Core Graphics 中绘制文本
        let line = CTLineCreateWithAttributedString(attributedString)
        context.textPosition = CGPoint(
            x: -textSize.width / 2,
            y: -textSize.height / 2
        )
        CTLineDraw(line, context)

        context.restoreGState()
    }

    // MARK: - 平铺水印 - PDF 版

    /// 在 PDF 页面上平铺绘制多个水印
    private static func drawTiledWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 创建文本属性
        let attributes = settings.textAttributes
        let attributedString = NSAttributedString(string: settings.text, attributes: attributes)
        let textSize = attributedString.size()

        // 计算行列数
        let horizontalCount = max(1, Int(ceil(rect.width / settings.horizontalSpacing)) + 1)
        let verticalCount = max(1, Int(ceil(rect.height / settings.verticalSpacing)) + 1)

        // 计算起始偏移（居中）
        let totalWidth = CGFloat(horizontalCount - 1) * settings.horizontalSpacing
        let totalHeight = CGFloat(verticalCount - 1) * settings.verticalSpacing
        let startX = (rect.width - totalWidth) / 2
        let startY = (rect.height - totalHeight) / 2

        // 创建 CTLine
        let line = CTLineCreateWithAttributedString(attributedString)

        // 循环绘制
        for row in 0..<verticalCount {
            for col in 0..<horizontalCount {
                let posX = startX + CGFloat(col) * settings.horizontalSpacing
                let posY = startY + CGFloat(row) * settings.verticalSpacing

                context.saveGState()
                context.translateBy(x: posX, y: posY)

                let radians = settings.rotation * .pi / 180.0
                context.rotate(by: radians)

                context.textPosition = CGPoint(
                    x: -textSize.width / 2,
                    y: -textSize.height / 2
                )
                CTLineDraw(line, context)

                context.restoreGState()
            }
        }
    }

}
