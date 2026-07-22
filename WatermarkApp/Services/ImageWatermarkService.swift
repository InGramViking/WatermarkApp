import AppKit
import Foundation

// MARK: - 图片水印处理服务
class ImageWatermarkService {

    // MARK: - 错误类型
    enum WatermarkError: LocalizedError {
        case failedToLoadImage
        case failedToCreateBitmapContext
        case failedToSaveImage

        var errorDescription: String? {
            switch self {
            case .failedToLoadImage:
                return "无法加载图片文件"
            case .failedToCreateBitmapContext:
                return "无法创建位图上下文"
            case .failedToSaveImage:
                return "无法保存处理后的图片"
            }
        }
    }

    // MARK: - 给单张图片添加水印

    /// 为指定图片 URL 添加水印
    /// - Parameters:
    ///   - imageURL: 源图片文件 URL
    ///   - outputURL: 输出文件 URL
    ///   - settings: 水印参数设置
    /// - Throws: WatermarkError
    static func addWatermark(
        to imageURL: URL,
        outputURL: URL,
        settings: WatermarkSettings
    ) throws {
        // 加载图片
        guard let image = NSImage(contentsOf: imageURL) else {
            throw WatermarkError.failedToLoadImage
        }

        // 获取图片尺寸
        let imageSize = image.size

        // 创建位图上下文
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageSize.width),
            pixelsHigh: Int(imageSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw WatermarkError.failedToCreateBitmapContext
        }

        // 设置上下文
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            NSGraphicsContext.restoreGraphicsState()
            throw WatermarkError.failedToCreateBitmapContext
        }
        NSGraphicsContext.current = context

        // 绘制原始图片
        image.draw(at: .zero, from: .zero, operation: .copy, fraction: 1.0)

        // 绘制水印
        let watermarkRect = CGRect(origin: .zero, size: imageSize)
        drawWatermark(in: context.cgContext, rect: watermarkRect, settings: settings)

        // 恢复图形上下文
        NSGraphicsContext.restoreGraphicsState()

        // 生成输出图片数据
        guard let imageData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw WatermarkError.failedToSaveImage
        }

        // 写入文件
        try imageData.write(to: outputURL)
    }

    // MARK: - 绘制水印

    /// 在指定的 CGContext 中绘制水印
    /// - Parameters:
    ///   - context: CGContext
    ///   - rect: 绘制区域
    ///   - settings: 水印参数设置
    private static func drawWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 保存原始上下文状态
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

    // MARK: - 单水印（居中）

    /// 在图片中央绘制单个水印
    private static func drawSingleWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 创建水印属性字符串
        let attributes = settings.textAttributes
        let attributedString = NSAttributedString(string: settings.text, attributes: attributes)
        let textSize = attributedString.size()

        // 计算居中位置
        let centerX = rect.midX
        let centerY = rect.midY

        // 保存状态，应用旋转
        context.saveGState()

        // 平移到中心点
        context.translateBy(x: centerX, y: centerY)
        // 应用旋转（角度转弧度）
        let radians = settings.rotation * .pi / 180.0
        context.rotate(by: radians)

        // 绘制文本（以中心点为基准偏移半个文本尺寸）
        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)

        context.restoreGState()
    }

    // MARK: - 平铺水印

    /// 在图片上平铺绘制多个水印
    private static func drawTiledWatermark(
        in context: CGContext,
        rect: CGRect,
        settings: WatermarkSettings
    ) {
        // 创建水印属性字符串
        let attributes = settings.textAttributes
        let attributedString = NSAttributedString(string: settings.text, attributes: attributes)
        let textSize = attributedString.size()

        // 计算行列数（确保覆盖整个图片）
        let horizontalCount = max(1, Int(ceil(rect.width / settings.horizontalSpacing)) + 1)
        let verticalCount = max(1, Int(ceil(rect.height / settings.verticalSpacing)) + 1)

        // 计算起始偏移（居中偏移，使水印分布均匀）
        let totalWidth = CGFloat(horizontalCount - 1) * settings.horizontalSpacing
        let totalHeight = CGFloat(verticalCount - 1) * settings.verticalSpacing
        let startX = (rect.width - totalWidth) / 2
        let startY = (rect.height - totalHeight) / 2

        // 循环绘制每一行每一列
        for row in 0..<verticalCount {
            for col in 0..<horizontalCount {
                // 计算当前水印位置
                let posX = startX + CGFloat(col) * settings.horizontalSpacing
                let posY = startY + CGFloat(row) * settings.verticalSpacing

                // 保存状态，应用旋转
                context.saveGState()

                // 平移到当前位置
                context.translateBy(x: posX, y: posY)
                // 应用旋转
                let radians = settings.rotation * .pi / 180.0
                context.rotate(by: radians)

                // 绘制文本
                let textRect = CGRect(
                    x: -textSize.width / 2,
                    y: -textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                attributedString.draw(in: textRect)

                context.restoreGState()
            }
        }
    }

}
