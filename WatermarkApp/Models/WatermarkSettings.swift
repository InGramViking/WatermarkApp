import Foundation
import SwiftUI

// MARK: - 水印布局模式
enum WatermarkLayout: String, CaseIterable, Identifiable {
    case single = "单水印"
    case tiled = "平铺"

    var id: String { rawValue }
}

// MARK: - 水印参数设置模型
class WatermarkSettings: ObservableObject {
    // MARK: - 水印文字内容
    @Published var text: String = "水印"

    // MARK: - 字体大小 (12-200)
    @Published var fontSize: CGFloat = 26 {
        didSet {
            if fontSize < 12 { fontSize = 12 }
            if fontSize > 200 { fontSize = 200 }
        }
    }

    // MARK: - 旋转角度 (-90° ~ 90°)
    @Published var rotation: Double = -45 {
        didSet {
            if rotation < -90 { rotation = -90 }
            if rotation > 90 { rotation = 90 }
        }
    }

    // MARK: - 透明度 (1-100%)
    @Published var opacity: Double = 30 {
        didSet {
            if opacity < 1 { opacity = 1 }
            if opacity > 100 { opacity = 100 }
        }
    }

    // MARK: - 水印颜色
    @Published var color: Color = .gray

    // MARK: - 布局模式
    @Published var layout: WatermarkLayout = .tiled

    // MARK: - 平铺水平间距
    @Published var horizontalSpacing: CGFloat = 200 {
        didSet {
            if horizontalSpacing < 50 { horizontalSpacing = 50 }
            if horizontalSpacing > 500 { horizontalSpacing = 500 }
        }
    }

    // MARK: - 平铺垂直间距
    @Published var verticalSpacing: CGFloat = 200 {
        didSet {
            if verticalSpacing < 50 { verticalSpacing = 50 }
            if verticalSpacing > 500 { verticalSpacing = 500 }
        }
    }

    // MARK: - 获取透明度值 (0.0 ~ 1.0)
    var opacityValue: CGFloat {
        return opacity / 100.0
    }

    // MARK: - 获取 NSColor
    var nsColor: NSColor {
        NSColor(color)
    }

    // MARK: - 获取文本属性字典
    var textAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont.systemFont(ofSize: fontSize)
        return [
            .font: font,
            .foregroundColor: nsColor
        ]
    }
}
