import SwiftUI

// MARK: - 处理状态
enum ProcessingState: Equatable {
    case idle
    case processing(progress: Double, currentFile: String)
    case completed(successCount: Int, failCount: Int)
    case failed(String)
}

// MARK: - 主界面视图
struct ContentView: View {
    // MARK: - 状态属性
    @StateObject private var settings = WatermarkSettings()
    @State private var files: [URL] = []
    @State private var processingState: ProcessingState = .idle
    @State private var outputDirectory: URL?
    @State private var useCustomOutputDirectory = false
    @State private var showCompletionAlert = false
    @State private var completionMessage = ""

    // MARK: - 视图主体
    var body: some View {
        HSplitView {
            // 左侧：文件选择 + 进度 + 操作按钮
            leftPanel
                .frame(minWidth: 350, maxWidth: .infinity)

            // 右侧：所有设置（水印参数 + 输出设置）
            rightPanel
                .frame(minWidth: 350, maxWidth: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert("处理完成", isPresented: $showCompletionAlert) {
            Button("确定") {
                showCompletionAlert = false
            }
        } message: {
            Text(completionMessage)
        }
    }

    // MARK: - 左侧面板：文件选择 + 进度 + 操作
    private var leftPanel: some View {
        VStack(spacing: 12) {
            // 标题
            headerView

            // 文件选择区域
            FileDropView(files: $files)

            // 已选文件统计
            if !files.isEmpty {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("共 \(files.count) 个文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if canClearFiles {
                        Button("清空") {
                            withAnimation {
                                files.removeAll()
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 4)
            }

            // 进度显示
            progressView

            Spacer()

            // 操作按钮
            actionButtons
        }
        .padding()
    }

    // MARK: - 右侧面板：所有设置
    private var rightPanel: some View {
        SettingsPanel(
            settings: settings,
            useCustomOutputDirectory: $useCustomOutputDirectory,
            outputDirectory: $outputDirectory,
            onSelectOutputDirectory: {
                selectOutputDirectory()
            },
            onResetSettings: {
                resetSettings()
            }
        )
    }

    // MARK: - 标题
    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "drop.degreesign")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("PDF & 图片水印工具")
                    .font(.headline)

                Text("所有处理在本地完成")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - 进度显示
    @ViewBuilder
    private var progressView: some View {
        if case .processing(let progress, let currentFile) = processingState {
            VStack(spacing: 8) {
                HStack {
                    Label("处理中", systemImage: "gearshape.fill")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }

                ProgressView(value: progress)
                    .progressViewStyle(.linear)

                HStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("正在处理: \(currentFile)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.05))
            )
        } else if case .completed(let successCount, let failCount) = processingState {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: failCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(failCount > 0 ? .orange : .green)

                    Text("处理完成")
                        .font(.headline)
                        .foregroundColor(failCount > 0 ? .orange : .green)
                }

                HStack(spacing: 16) {
                    Label("\(successCount) 个成功", systemImage: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)

                    if failCount > 0 {
                        Label("\(failCount) 个失败", systemImage: "xmark")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill((failCount > 0 ? Color.orange : Color.green).opacity(0.05))
            )
        } else if case .failed(let error) = processingState {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("处理失败: \(error)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.05))
            )
        } else {
            // 空闲状态提示 - 只在不为空时显示
            if !files.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("准备就绪，可以开始处理")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.05))
                )
            }
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 8) {
            // 主按钮：开始处理 / 再次处理
            if case .processing = processingState {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                Button(action: {}) {
                    Label("处理中...", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
            } else if case .completed = processingState {
                Button(action: {
                    startProcessing()
                }) {
                    Label("再次处理", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    withAnimation {
                        files.removeAll()
                        processingState = .idle
                    }
                } label: {
                    Label("重置并清空", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: {
                    startProcessing()
                }) {
                    Label("开始处理", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(files.isEmpty)
            }
        }
    }

    // MARK: - 是否可以清空文件
    private var canClearFiles: Bool {
        if case .processing = processingState { return false }
        return true
    }

    // MARK: - 选择输出目录
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "选择水印文件输出目录"
        panel.prompt = "选择"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                outputDirectory = url
            }
        }
    }

    // MARK: - 重置所有设置为默认值
    private func resetSettings() {
        settings.text = "水印"
        settings.fontSize = 26
        settings.rotation = -45
        settings.opacity = 30
        settings.color = .gray
        settings.layout = .tiled
        settings.horizontalSpacing = 200
        settings.verticalSpacing = 200
        useCustomOutputDirectory = false
        outputDirectory = nil
    }

    // MARK: - 开始处理
    private func startProcessing() {
        guard !files.isEmpty else { return }

        processingState = .processing(progress: 0, currentFile: "")
        let totalFiles = files.count
        var successCount = 0
        var failCount = 0

        Task {
            for (index, fileURL) in files.enumerated() {
                // 更新进度
                let progress = Double(index) / Double(totalFiles)
                await MainActor.run {
                    self.processingState = .processing(
                        progress: progress,
                        currentFile: fileURL.lastPathComponent
                    )
                }

                // 确定输出路径
                let outputURL: URL
                if useCustomOutputDirectory, let customDir = outputDirectory {
                    outputURL = FileManager.outputFileURL(for: fileURL, outputDirectory: customDir)
                } else {
                    outputURL = FileManager.outputFileURL(for: fileURL, outputDirectory: nil)
                }

                // 执行处理
                do {
                    if FileManager.isImageFile(fileURL) {
                        try ImageWatermarkService.addWatermark(
                            to: fileURL,
                            outputURL: outputURL,
                            settings: settings
                        )
                    } else if FileManager.isPDFFile(fileURL) {
                        try PDFWatermarkService.addWatermark(
                            to: fileURL,
                            outputURL: outputURL,
                            settings: settings
                        )
                    }
                    successCount += 1
                } catch {
                    failCount += 1
                    print("处理失败: \(fileURL.lastPathComponent) - \(error.localizedDescription)")
                }
            }

            // 更新最终状态
            await MainActor.run {
                self.processingState = .completed(
                    successCount: successCount,
                    failCount: failCount
                )

                // 显示提示
                if failCount > 0 {
                    completionMessage = "处理完成!\n成功: \(successCount) 个\n失败: \(failCount) 个\n请检查文件是否损坏或格式是否正确。"
                } else {
                    completionMessage = "处理完成!\n成功处理 \(successCount) 个文件。\n文件已保存到\(useCustomOutputDirectory ? "自定义位置" : "原目录")。"
                }
                showCompletionAlert = true
            }
        }
    }
}
