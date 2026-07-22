import SwiftUI

// MARK: - 水印参数设置面板
struct SettingsPanel: View {
    // MARK: - 属性
    @ObservedObject var settings: WatermarkSettings
    @Binding var useCustomOutputDirectory: Bool
    @Binding var outputDirectory: URL?
    var onSelectOutputDirectory: () -> Void
    var onResetSettings: () -> Void

    // MARK: - 视图主体
    var body: some View {
        VStack(spacing: 0) {
            // 设置标题
            HStack {
                Label("设置", systemImage: "gearshape.fill")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // 设置内容（可滚动）
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 文字内容
                    textContentSection

                    // 外观设置
                    appearanceSection

                    // 布局设置
                    layoutSection

                    // 平铺间距（仅平铺模式显示）
                    if settings.layout == .tiled {
                        spacingSection
                    }

                    // 输出设置
                    outputSection

                    // 重置按钮
                    Button(action: onResetSettings) {
                        Label("重置所有设置", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }

    // MARK: - 文字内容设置
    private var textContentSection: some View {
        GroupBox(label: Label("文字内容", systemImage: "textformat")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("请输入水印文字", text: $settings.text)
                    .textFieldStyle(.roundedBorder)

                Text("水印文字将显示在文件上")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 外观设置
    private var appearanceSection: some View {
        GroupBox(label: Label("外观设置", systemImage: "paintbrush")) {
            VStack(spacing: 16) {
                // 字体大小
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("字体大小")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.fontSize))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $settings.fontSize, in: 12...200, step: 1) {
                        Text("字体大小")
                    } minimumValueLabel: {
                        Text("12")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("200")
                            .font(.caption)
                    }
                }

                // 旋转角度
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("旋转角度")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.rotation))°")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $settings.rotation, in: -90...90, step: 1) {
                        Text("旋转角度")
                    } minimumValueLabel: {
                        Text("-90°")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("90°")
                            .font(.caption)
                    }
                }

                // 透明度
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("透明度")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.opacity))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $settings.opacity, in: 1...100, step: 1) {
                        Text("透明度")
                    } minimumValueLabel: {
                        Text("1%")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("100%")
                            .font(.caption)
                    }
                }

                // 颜色选择
                VStack(alignment: .leading, spacing: 4) {
                    Text("水印颜色")
                        .font(.subheadline)

                    HStack {
                        ColorPicker("选择颜色", selection: $settings.color, supportsOpacity: false)
                            .labelsHidden()

                        RoundedRectangle(cornerRadius: 6)
                            .fill(settings.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )

                        Text("点击右侧色块选择颜色")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 布局设置
    private var layoutSection: some View {
        GroupBox(label: Label("布局设置", systemImage: "grid")) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("布局模式", selection: $settings.layout) {
                    ForEach(WatermarkLayout.allCases) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 16) {
                    layoutDescription(
                        icon: "rectangle.center.inset.filled",
                        title: "单水印",
                        description: "在文件正中央添加一个水印"
                    )

                    Divider()
                        .frame(height: 40)

                    layoutDescription(
                        icon: "rectangle.grid.3x2",
                        title: "平铺",
                        description: "多行多列重复水印覆盖"
                    )
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 平铺间距设置
    private var spacingSection: some View {
        GroupBox(label: Label("平铺间距", systemImage: "arrow.up.and.down.and.arrow.left.and.right")) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("水平间距")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.horizontalSpacing)) px")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $settings.horizontalSpacing, in: 50...500, step: 10) {
                        Text("水平间距")
                    } minimumValueLabel: {
                        Text("50")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("500")
                            .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("垂直间距")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.verticalSpacing)) px")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $settings.verticalSpacing, in: 50...500, step: 10) {
                        Text("垂直间距")
                    } minimumValueLabel: {
                        Text("50")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("500")
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 输出设置
    private var outputSection: some View {
        GroupBox(label: Label("输出设置", systemImage: "folder")) {
            VStack(alignment: .leading, spacing: 8) {
                // 自定义输出目录开关
                HStack {
                    Text("保存到自定义位置")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $useCustomOutputDirectory)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.85)
                }

                // 自定义目录路径选择
                if useCustomOutputDirectory {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(outputDirectory?.path ?? "请选择输出目录")
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.secondary)
                            .layoutPriority(0)

                        Spacer(minLength: 4)

                        Button("选择...") {
                            onSelectOutputDirectory()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                } else {
                    Text("文件将保存到原文件所在目录，文件名自动添加 _watermarked 后缀")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 布局描述组件
    private func layoutDescription(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
