# NTFSDesk

NTFSDesk 是一个用 SwiftUI 写的 macOS 存储卷管理工具，界面参考简约磁盘管理器风格。

## 功能

- 显示当前已挂载的磁盘/分区
- 查看容量、文件系统、挂载路径、读写状态
- 打开卷到 Finder
- 推出磁盘
- NTFS 写入开关界面状态
- 浏览文件夹
- 识别常见文件类型：图片、视频、音频、PDF、文本、代码、文档、压缩包、镜像、应用包
- 快速预览文本/代码/部分文件信息

## 用 Xcode 运行

1. 双击打开 `NTFSDesk.xcodeproj`
2. 顶部 Scheme 选择 `NTFSDesk`
3. 运行目标选择 `My Mac`
4. 点击左上角 Run 按钮

也可以在终端里编译：

```bash
swift build
```

## 同步到 GitHub

第一次上传：

```bash
cd "/Users/apple/Documents/mac NTFS"
git init
git add .
git commit -m "Initial NTFSDesk app"
git branch -M main
git remote add origin https://github.com/你的用户名/NTFSDesk.git
git push -u origin main
```

后续更新：

```bash
cd "/Users/apple/Documents/mac NTFS"
git add .
git commit -m "Update NTFSDesk"
git push
```

如果你用 GitHub Desktop：

1. 打开 GitHub Desktop
2. 选择 `File` -> `Add Local Repository`
3. 选择 `/Users/apple/Documents/mac NTFS`
4. 点击 `Publish repository`
5. 后续修改后点击 `Commit to main`，再点 `Push origin`

## 说明

当前 NTFS 写入按钮是应用内开关状态。真正控制 NTFS 读写挂载需要接入 macFUSE/ntfs-3g 或单独的特权 helper。
