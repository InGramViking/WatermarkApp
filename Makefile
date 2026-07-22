# Makefile for WatermarkApp
# 使用 swiftc 直接编译 macOS 应用

TARGET_NAME = WatermarkApp
APP_NAME = 水印工具.app
BUILD_DIR = .build
BINARY_PATH = $(BUILD_DIR)/$(TARGET_NAME)
APP_BUNDLE = $(APP_NAME)
INFO_PLIST = WatermarkApp/Info.plist
RESOURCES = WatermarkApp/Resources
ICON_PNG = $(RESOURCES)/watermark.png

# 源文件
SOURCES = \
	WatermarkApp/WatermarkApp.swift \
	WatermarkApp/Models/WatermarkSettings.swift \
	WatermarkApp/Views/ContentView.swift \
	WatermarkApp/Views/SettingsPanel.swift \
	WatermarkApp/Views/FileDropView.swift \
	WatermarkApp/Services/ImageWatermarkService.swift \
	WatermarkApp/Services/PDFWatermarkService.swift \
	WatermarkApp/Utils/FileManager+Extensions.swift

# 依赖框架
FRAMEWORKS = \
	-framework SwiftUI \
	-framework AppKit \
	-framework PDFKit \
	-framework UniformTypeIdentifiers

# 编译标志
SWIFT_FLAGS = \
	-target x86_64-apple-macosx12.0 \
	-sdk $(shell xcrun --show-sdk-path --sdk macosx)

.PHONY: all build clean app run icon

all: app

# 编译可执行文件
build:
	@mkdir -p $(BUILD_DIR)
	swiftc $(SWIFT_FLAGS) $(FRAMEWORKS) -o $(BINARY_PATH) $(SOURCES)

# 生成 .app 应用包（自动签名）
app: build
	@echo "=== 创建 $(APP_NAME) 应用包 ==="
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(BINARY_PATH)" "$(APP_BUNDLE)/Contents/MacOS/$(TARGET_NAME)"
	@cp -r "$(RESOURCES)/." "$(APP_BUNDLE)/Contents/Resources/"
	@sed 's/\$$(EXECUTABLE_NAME)/$(TARGET_NAME)/g' "$(INFO_PLIST)" > "$(APP_BUNDLE)/Contents/Info.plist"
	@codesign --force --deep --sign - "$(APP_BUNDLE)" 2>/dev/null
	@echo "=== 完成: $(APP_BUNDLE) ==="

# 运行应用
run: app
	@open "$(APP_BUNDLE)"

# 清理
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(APP_BUNDLE)
