# 🏷️ 水印工具

一个简洁高效的 macOS 桌面应用，用于为 **PDF** 和 **图片（JPG/PNG）** 批量添加自定义文字水印。

> 所有处理在本地完成，不上传任何数据，保护你的文件隐私。

---

## ✨ 功能特性

### 📂 文件处理
- 支持 **PDF**、**JPG**、**JPEG**、**PNG** 格式
- **拖拽**文件到窗口即可添加
- 或点击 **选择文件** 通过文件选择器选取
- 支持 **批量** 多文件同时处理
- 自动 **去重**，避免重复添加

### 🎨 水印定制

| 参数 | 范围 | 说明 |
|------|------|------|
| 文字内容 | 自定义 | 任意文本，支持中文 |
| 字体大小 | 12 ~ 200 px | 滑块实时调节 |
| 旋转角度 | -90° ~ 90° | 以图片中心为原点旋转 |
| 透明度 | 1% ~ 100% | 控制水印可见度 |
| 颜色 | 任意色 | 系统颜色选择器 |

### 📐 布局模式

- **单水印** — 在文件正中央添加一个水印
- **平铺** — 多行多列重复覆盖，可自定义水平和垂直间距

### 📁 输出设置
- 保存到 **原文件所在目录**（自动添加 `_watermarked` 后缀）
- 或保存到 **自定义目录**

---

## 🖥️ 系统要求

- macOS 12+
- 约 5MB 磁盘空间

## 🛠️ 构建

```bash
# 编译并生成应用包
make app

# 编译并运行
make run

# 清理构建产物
make clean
```

### 从源码构建

```bash
git clone <repo-url>
cd WatermarkApp
make run
```

---

## 📦 项目结构

```
WatermarkApp/
├── WatermarkApp.swift          # 应用入口（AppDelegate）
├── main.swift                  # 启动入口
├── Info.plist                  # 应用配置
├── Resources/
│   └── watermark.png           # 应用图标
├── Models/
│   └── WatermarkSettings.swift # 水印参数模型
├── Views/
│   ├── ContentView.swift       # 主界面
│   ├── SettingsPanel.swift     # 设置面板
│   └── FileDropView.swift      # 文件拖拽视图
├── Services/
│   ├── ImageWatermarkService.swift # 图片水印处理
│   └── PDFWatermarkService.swift   # PDF 水印处理
└── Utils/
    └── FileManager+Extensions.swift # 文件工具扩展
```

---

## ⚙️ 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** | 用户界面 |
| **AppKit** | 系统集成、颜色选择、图片处理 |
| **PDFKit** | PDF 文档解析与渲染 |
| **Core Graphics** | 水印文本绘制与位图处理 |

---

## 🔒 隐私声明

- 所有文件处理在 **本地计算机** 完成
- 不建立任何网络连接
- 不上传文件或数据到任何服务器
- 不会收集任何用户信息

---

## 📄 许可证

Copyright © 2024. MIT License.
