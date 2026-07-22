import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件拖拽区域视图
struct FileDropView: View {
    // MARK: - 属性
    @Binding var files: [URL]
    @State private var isDragging = false

    private let supportedTypes: [UTType] = [
        .pdf,
        .jpeg,
        .png,
        .image
    ]

    // MARK: - 视图主体
    var body: some View {
        VStack(spacing: 16) {
            // 拖拽区域
            dropZone

            // 已选文件列表
            if !files.isEmpty {
                fileList
            }
        }
    }

    // MARK: - 拖拽放置区域
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(
                    lineWidth: 2,
                    dash: [8, 4]
                ))
                .foregroundColor(isDragging ? .blue : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragging ? Color.blue.opacity(0.1) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(isDragging ? .blue : .secondary)

                Text("拖拽文件到这里")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("支持 PDF、JPG、PNG 格式")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("或点击选择文件") {
                    selectFiles()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(minHeight: 180)
        .onDrop(of: supportedTypes.map { $0.identifier }, isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - 已选文件列表
    private var fileList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("已选择的文件 (\(files.count) 个)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("清空列表") {
                    withAnimation {
                        files.removeAll()
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(files.enumerated()), id: \.offset) { index, url in
                        fileRow(url: url, index: index)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    // MARK: - 文件行
    private func fileRow(url: URL, index: Int) -> some View {
        HStack(spacing: 8) {
            // 文件图标
            Image(systemName: fileIcon(for: url))
                .foregroundColor(fileIconColor(for: url))

            // 文件名
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // 文件大小
            Text(FileManager.formattedFileSize(for: url))
                .font(.caption2)
                .foregroundColor(.secondary)

            // 删除按钮
            Button {
                withAnimation {
                    let idx = index
                    files = files.enumerated().filter { $0.offset != idx }.map { $0.element }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .alternateSelectedControlTextColor).opacity(0.05))
        )
    }

    // MARK: - 处理拖拽事件
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var processed = false

        for provider in providers {
            // 尝试读取文件 URL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.addFile(url)
                        }
                    }
                }
                processed = true
            }
        }
        return processed
    }

    // MARK: - 选择文件
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = supportedTypes

        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    addFile(url)
                }
            }
        }
    }

    // MARK: - 添加文件（去重检查）
    private func addFile(_ url: URL) {
        guard FileManager.isSupportedFile(url) else { return }
        // 去重：检查文件是否已在列表中
        if !files.contains(where: { $0.resolvingSymlinksInPath() == url.resolvingSymlinksInPath() }) {
            withAnimation {
                files.append(url)
            }
        }
    }

    // MARK: - 文件图标
    private func fileIcon(for url: URL) -> String {
        if FileManager.isPDFFile(url) {
            return "doc.richtext"
        } else if FileManager.isImageFile(url) {
            return "photo"
        }
        return "doc"
    }

    private func fileIconColor(for url: URL) -> Color {
        if FileManager.isPDFFile(url) {
            return .red
        } else if FileManager.isImageFile(url) {
            return .blue
        }
        return .secondary
    }
}
