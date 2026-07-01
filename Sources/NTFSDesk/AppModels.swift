import AppKit
import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct VolumeItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let fileSystemName: String
    let isWritable: Bool
    let capacity: Int64
    let available: Int64
    let used: Int64
    let mountPath: String

    var usageFraction: Double {
        guard capacity > 0 else { return 0 }
        return min(max(Double(used) / Double(capacity), 0), 1)
    }

    var statusText: String {
        isWritable ? "可写" : "只读"
    }

    var displayCapacity: String {
        ByteCountFormatter.string(fromByteCount: capacity, countStyle: .decimal)
    }

    var displayUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .decimal)
    }

    var displayAvailable: String {
        ByteCountFormatter.string(fromByteCount: available, countStyle: .decimal)
    }
}

struct FileEntry: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let fileSize: Int64
    let modified: Date?
    let fileKind: FileKind

    enum FileKind: String, Hashable {
        case folder
        case image
        case video
        case audio
        case pdf
        case text
        case archive
        case app
        case code
        case document
        case diskImage
        case binary
        case unknown

        var label: String {
            switch self {
            case .folder: return "文件夹"
            case .image: return "图片"
            case .video: return "视频"
            case .audio: return "音频"
            case .pdf: return "PDF"
            case .text: return "文本"
            case .archive: return "压缩包"
            case .app: return "应用"
            case .code: return "代码"
            case .document: return "文档"
            case .diskImage: return "镜像"
            case .binary: return "二进制"
            case .unknown: return "文件"
            }
        }

        var iconName: String {
            switch self {
            case .folder: return "folder.fill"
            case .image: return "photo.fill"
            case .video: return "film.fill"
            case .audio: return "waveform"
            case .pdf: return "doc.richtext.fill"
            case .text: return "doc.text.fill"
            case .archive: return "shippingbox.fill"
            case .app: return "app.fill"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .document: return "doc.fill"
            case .diskImage: return "opticaldisc"
            case .binary: return "cpu.fill"
            case .unknown: return "questionmark.folder.fill"
            }
        }
    }

    var fileTypeText: String {
        fileKind.label
    }

    var displaySize: String {
        guard !isDirectory else { return "-" }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var modifiedText: String {
        guard let modified else { return "-" }
        return Self.dateFormatter.string(from: modified)
    }

    var canPreviewInline: Bool {
        switch fileKind {
        case .image, .pdf, .text, .code, .document:
            return true
        default:
            return false
        }
    }

    var openActionTitle: String {
        switch fileKind {
        case .folder: return "打开文件夹"
        case .image: return "查看图片"
        case .video: return "播放视频"
        case .audio: return "播放音频"
        case .pdf: return "查看 PDF"
        case .text, .code, .document: return "查看内容"
        case .archive: return "打开压缩包"
        case .app: return "运行应用"
        case .diskImage: return "挂载镜像"
        default: return "用默认应用打开"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}

final class VolumeStore: ObservableObject {
    @Published var volumes: [VolumeItem] = []
    @Published var selectedVolumeID: VolumeItem.ID?
    @Published var selectedFolderURL: URL?
    @Published var currentFolderEntries: [FileEntry] = []
    @Published var message: String = ""
    @Published var selectedEntry: FileEntry?
    @Published var previewText: String = "选择一个文件查看预览"
    @Published var previewTitle: String = "预览"
    @Published var previewURL: URL?
    @Published var ntfsWriteEnabled: Bool = false
    @Published var pendingWriteSourceURL: URL?

    init() {
        refreshVolumes()
    }

    var selectedVolume: VolumeItem? {
        volumes.first { $0.id == selectedVolumeID }
    }

    func refreshVolumes() {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeIsReadOnlyKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsInternalKey,
            .volumeLocalizedFormatDescriptionKey,
            .volumeURLForRemountingKey,
            .volumeUUIDStringKey,
        ]

        let mountedURLs = fm.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: []) ?? []
        let items: [VolumeItem] = mountedURLs.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = Int64(values.volumeAvailableCapacity ?? 0)
            let used = max(total - available, 0)
            let name = values.volumeName ?? url.lastPathComponent
            let fsName = values.volumeLocalizedFormatDescription ?? "未知"
            let writable = !(values.volumeIsReadOnly ?? false)
            return VolumeItem(
                url: url,
                name: name,
                fileSystemName: fsName,
                isWritable: writable,
                capacity: total,
                available: available,
                used: used,
                mountPath: url.path
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        volumes = items
        if selectedVolumeID == nil {
            selectedVolumeID = items.first?.id ?? selectedVolumeID
        } else if let currentSelection = selectedVolumeID, !items.contains(where: { $0.id == currentSelection }) {
            selectedVolumeID = items.first?.id
        }

        if let volume = selectedVolume {
            loadFolder(url: volume.url)
        }
    }

    func select(volume: VolumeItem) {
        selectedVolumeID = volume.id
        loadFolder(url: volume.url)
    }

    func openSelectedVolumeInFinder() {
        guard let url = selectedVolume?.url else { return }
        NSWorkspace.shared.open(url)
    }

    func ejectSelectedVolume() {
        guard let url = selectedVolume?.url else { return }
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: url)
            message = "已请求推出 \(url.lastPathComponent)"
        } catch {
            message = "推出失败：\(error.localizedDescription)"
        }
    }

    func toggleNTFSWrite() {
        ntfsWriteEnabled.toggle()
        message = ntfsWriteEnabled ? "NTFS 写入已开启" : "NTFS 写入已关闭"
        if !ntfsWriteEnabled {
            pendingWriteSourceURL = nil
        }
    }

    var ntfsWriteButtonTitle: String {
        ntfsWriteEnabled ? "关闭 NTFS 写入" : "开启 NTFS 写入"
    }

    var ntfsWriteStatusText: String {
        ntfsWriteEnabled ? "写入开启" : "写入关闭"
    }

    func openFolder(_ entry: FileEntry) {
        guard entry.isDirectory else {
            openFile(entry)
            return
        }
        loadFolder(url: entry.url)
    }

    func openFile(_ entry: FileEntry) {
        switch entry.fileKind {
        case .folder:
            loadFolder(url: entry.url)
        case .text, .code, .document:
            showPreview(for: entry)
        case .image, .video, .audio, .pdf, .archive, .app, .diskImage, .binary, .unknown:
            NSWorkspace.shared.open(entry.url)
            showPreview(for: entry)
        }
    }

    func selectSourceForWrite(_ entry: FileEntry) {
        guard ntfsWriteEnabled else {
            message = "先开启 NTFS 写入"
            return
        }
        guard !entry.isDirectory else {
            message = "请选择一个文件，不要选文件夹"
            return
        }
        pendingWriteSourceURL = entry.url
        message = "已选中待写入文件：\(entry.name)"
    }

    func writePendingFileToSelectedVolume() {
        guard ntfsWriteEnabled else {
            message = "当前是只读，无法写入"
            return
        }
        guard let volume = selectedVolume else {
            message = "未选择目标卷"
            return
        }
        guard let source = pendingWriteSourceURL else {
            message = "先选择一个要写入的文件"
            return
        }

        let destination = volume.url.appendingPathComponent(source.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            message = "已写入：\(source.lastPathComponent)"
            pendingWriteSourceURL = nil
            refreshVolumes()
            if let folder = selectedFolderURL {
                loadFolder(url: folder)
            }
        } catch {
            message = "写入失败：\(error.localizedDescription)"
        }
    }

    var writeButtonTitle: String {
        ntfsWriteEnabled ? "写入到当前卷" : "只读中"
    }

    func goBack() {
        guard let current = selectedFolderURL,
              let parent = current.deletingLastPathComponent().path == current.path ? nil : current.deletingLastPathComponent() else { return }
        if selectedVolume?.url.path == current.path { return }
        loadFolder(url: parent)
    }

    func loadFolder(url: URL) {
        selectedFolderURL = url
        selectedEntry = nil
        previewTitle = "预览"
        previewText = "选择一个文件查看预览"
        previewURL = nil
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        do {
            let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(keys), options: options)
            let entries = urls.compactMap { item -> FileEntry? in
                guard let values = try? item.resourceValues(forKeys: keys) else { return nil }
                return FileEntry(
                    url: item,
                    name: item.lastPathComponent,
                    isDirectory: values.isDirectory ?? false,
                    fileSize: Int64(values.fileSize ?? 0),
                    modified: values.contentModificationDate,
                    fileKind: Self.detectKind(for: item, isDirectory: values.isDirectory ?? false)
                )
            }
            .sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            currentFolderEntries = entries
            message = "已加载 \(url.lastPathComponent)"
        } catch {
            currentFolderEntries = []
            message = "无法读取目录：\(error.localizedDescription)"
        }
    }

    func select(entry: FileEntry) {
        selectedEntry = entry
        showPreview(for: entry)
    }

    func showPreview(for entry: FileEntry) {
        previewTitle = entry.name
        previewURL = entry.url
        guard !entry.isDirectory else {
            previewText = "文件夹无法直接预览"
            return
        }
        if entry.fileKind == .image, let image = NSImage(contentsOf: entry.url) {
            previewText = "图片已加载：\(Int(image.size.width)) × \(Int(image.size.height))"
            return
        }
        if let data = try? Data(contentsOf: entry.url, options: .mappedIfSafe) {
            switch entry.fileKind {
            case .image:
                previewText = "图片已加载：\(entry.name)"
            case .video, .audio, .archive, .app, .diskImage, .binary, .unknown:
                previewText = Self.describeBinary(data: data, fileKind: entry.fileKind)
            case .text, .code, .document:
                let limited = data.prefix(256_000)
                if let text = String(data: limited, encoding: .utf8) ?? String(data: limited, encoding: .unicode) {
                    previewText = text.isEmpty ? "文件内容为空" : text
                } else {
                    previewText = "无法按文本读取"
                }
            case .pdf:
                previewText = "PDF 文件，已可用默认应用打开"
            case .folder:
                previewText = "文件夹"
            }
        } else {
            previewText = "无法读取文件内容"
        }
    }

    private static func detectKind(for url: URL, isDirectory: Bool) -> FileEntry.FileKind {
        if isDirectory { return .folder }
        let ext = url.pathExtension.lowercased()
        let imageExts: Set<String> = ["png", "jpg", "jpeg", "heic", "heif", "gif", "tiff", "tif", "bmp", "webp", "icns"]
        let videoExts: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm", "mpg", "mpeg", "3gp", "ts"]
        let audioExts: Set<String> = ["mp3", "m4a", "wav", "aiff", "aac", "flac", "ogg", "oga", "opus"]
        let archiveExts: Set<String> = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "cab", "pkg"]
        let codeExts: Set<String> = ["swift", "m", "mm", "c", "h", "cpp", "hpp", "js", "ts", "json", "xml", "yaml", "yml", "toml", "ini", "cfg", "conf", "sh", "py", "java", "kt", "go", "rs", "sql", "html", "css", "md", "txt", "log", "plist", "env"]
        let documentExts: Set<String> = ["rtf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "csv", "odt", "ods", "odp"]
        if imageExts.contains(ext) { return .image }
        if videoExts.contains(ext) { return .video }
        if audioExts.contains(ext) { return .audio }
        if ext == "pdf" { return .pdf }
        if archiveExts.contains(ext) { return .archive }
        if ext == "app" { return .app }
        if ext == "dmg" || ext == "iso" || ext == "img" { return .diskImage }
        if codeExts.contains(ext) { return .code }
        if documentExts.contains(ext) { return .document }
        if ext.isEmpty { return .unknown }
        return .binary
    }

    private static func describeBinary(data: Data, fileKind: FileEntry.FileKind) -> String {
        let prefix = data.prefix(96)
        let hex = prefix.map { String(format: "%02X", $0) }.joined(separator: " ")
        return """
        \(fileKind.label) 文件，无法直接文本预览。
        文件头:
        \(hex.isEmpty ? "-" : hex)
        """
    }
}
