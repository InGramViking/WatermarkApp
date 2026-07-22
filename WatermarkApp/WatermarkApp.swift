import SwiftUI

// MARK: - 应用入口
@main
struct WatermarkApp: App {
    // MARK: - 视图
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 650)
        }
        .windowStyle(.titleBar)
        .commands {
            // 自定义菜单命令
            CommandGroup(replacing: .newItem) {}
        }
    }

    // MARK: - 初始化
    init() {
        // 设置全局外观支持暗色模式
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }
}
