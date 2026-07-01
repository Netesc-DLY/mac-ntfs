import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: VolumeStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.13, blue: 0.14), Color(red: 0.18, green: 0.18, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebar
                divider
                detail
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleBlock
            Text("启动卷")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.top, 4)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(store.volumes) { volume in
                        volumeRow(volume)
                    }
                }
                .padding(.trailing, 8)
            }

            Spacer(minLength: 0)

            Button {
                store.refreshVolumes()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimarySidebarButtonStyle())

            Text(store.message.isEmpty ? "" : store.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
        }
        .padding(20)
        .frame(width: 360)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
    }

    private var titleBlock: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.96, blue: 0.95), Color(red: 0.12, green: 0.78, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(Text("N").font(.system(size: 19, weight: .bold)).foregroundStyle(.black))
            Text("NTFSDesk")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func volumeRow(_ volume: VolumeItem) -> some View {
        Button {
            store.select(volume: volume)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(volume.id == store.selectedVolumeID ? Color.orange : Color.orange.opacity(0.9))
                    .frame(width: 9, height: 9)
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color(red: 0.25, green: 0.95, blue: 0.9))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(volume.fileSystemName + " · " + volume.statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(volume.id == store.selectedVolumeID ? Color.white.opacity(0.09) : Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(volume.id == store.selectedVolumeID ? 0.08 : 0.03), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.05)).frame(width: 1)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            topActions
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerCard
                    usageSection
                    infoPanel
                    folderPanel
                }
                .padding(34)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.20, blue: 0.22), Color(red: 0.16, green: 0.16, blue: 0.17)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var topActions: some View {
        HStack(spacing: 16) {
            actionButton(title: "打开", systemImage: "square.and.arrow.up", size: 72) {
                store.openSelectedVolumeInFinder()
            }
            actionButton(title: "推出", systemImage: "eject", size: 72) {
                store.ejectSelectedVolume()
            }
            actionButton(title: store.ntfsWriteEnabled ? "关闭写入" : "开启写入", systemImage: "externaldrive.badge.checkmark", size: 72) {
                store.toggleNTFSWrite()
            }
            Button {
                store.writePendingFileToSelectedVolume()
            } label: {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(store.ntfsWriteEnabled ? Color(red: 0.23, green: 0.88, blue: 0.82).opacity(0.22) : Color.white.opacity(0.04))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(store.ntfsWriteEnabled ? Color(red: 0.26, green: 0.93, blue: 0.88) : Color.white.opacity(0.35))
                        )
                    Text(store.writeButtonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(store.ntfsWriteEnabled ? .white : Color.white.opacity(0.35))
                }
            }
            .buttonStyle(.plain)
            .disabled(!store.ntfsWriteEnabled)
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.015))
    }

    private func actionButton(title: String, systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color(red: 0.26, green: 0.93, blue: 0.88))
                    )
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 24) {
            Image(systemName: "internaldrive")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color.white.opacity(0.82))
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(store.selectedVolume?.name ?? "未选择卷")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 12, height: 12)
                    Text(store.selectedVolume?.statusText ?? "-")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text(store.selectedVolume?.displayCapacity ?? "-")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )
                Text(store.selectedVolume?.mountPath ?? "/")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 4)
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 40)
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(red: 0.23, green: 0.88, blue: 0.82))
                        .frame(width: max(0, geo.size.width * (store.selectedVolume?.usageFraction ?? 0)), height: 40)
                }
            }
            .frame(height: 40)

            HStack {
                Text("已使用：" + (store.selectedVolume?.displayUsed ?? "-"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("未使用：" + (store.selectedVolume?.displayAvailable ?? "-"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var infoPanel: some View {
        VStack(spacing: 0) {
            infoRow(label: "挂载路径:", value: store.selectedVolume?.mountPath ?? "-")
            infoRow(label: "文件系统:", value: store.selectedVolume?.fileSystemName ?? "-")
            infoRow(label: "状态:", value: store.selectedVolume?.statusText ?? "-")
            infoRow(label: "NTFS 写入:", value: store.ntfsWriteStatusText)
        }
        .padding(22)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
    }

    private var folderPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("文件浏览")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    if let entry = store.selectedEntry {
                        store.openFile(entry)
                    } else if let folder = store.selectedFolderURL {
                        NSWorkspace.shared.open(folder)
                    }
                } label: {
                    Label("打开所选", systemImage: "folder")
                }
                .buttonStyle(ToolButtonStyle())

                Button {
                    store.goBack()
                } label: {
                    Label("返回", systemImage: "arrow.left")
                }
                .buttonStyle(ToolButtonStyle())
            }

            if let folder = store.selectedFolderURL {
                Text(folder.path)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
            }

            VStack(spacing: 0) {
                HStack {
                    tableHeader("名称", width: 0.54)
                    tableHeader("类型", width: 0.16)
                    tableHeader("大小", width: 0.15)
                    tableHeader("修改时间", width: 0.15)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04))

                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.currentFolderEntries) { entry in
                            folderRow(entry)
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
                .frame(minHeight: 220, maxHeight: 280)
            }
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            previewPanel
        }
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("快速预览")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if let entry = store.selectedEntry {
                    Button {
                        store.openFile(entry)
                    } label: {
                        Label(entry.openActionTitle, systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(ToolButtonStyle())
                }
            }

                Text(store.previewTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            ScrollView {
                Text(store.previewText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.top, 2)
            }
            .frame(minHeight: 140, maxHeight: 220)
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func tableHeader(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func folderRow(_ entry: FileEntry) -> some View {
        Button {
            store.select(entry: entry)
            if entry.isDirectory {
                store.loadFolder(url: entry.url)
            } else {
                store.selectSourceForWrite(entry)
            }
        } label: {
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: entry.fileKind.iconName)
                        .foregroundStyle(iconColor(for: entry.fileKind))
                        .frame(width: 18, height: 18)
                    Text(entry.name)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Text(entry.fileTypeText)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 110, alignment: .leading)

                Text(entry.displaySize)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 110, alignment: .leading)

                Text(entry.modifiedText)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 170, alignment: .leading)
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(store.pendingWriteSourceURL == entry.url ? Color(red: 0.23, green: 0.88, blue: 0.82).opacity(0.14) : (store.selectedEntry == entry ? Color.white.opacity(0.08) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    private func iconColor(for kind: FileEntry.FileKind) -> Color {
        switch kind {
        case .folder: return Color(red: 0.95, green: 0.8, blue: 0.25)
        case .image: return Color(red: 0.32, green: 0.89, blue: 0.76)
        case .video: return Color(red: 0.53, green: 0.74, blue: 1.0)
        case .audio: return Color(red: 0.95, green: 0.67, blue: 0.4)
        case .pdf: return Color(red: 1.0, green: 0.42, blue: 0.36)
        case .text, .code, .document: return Color.white.opacity(0.86)
        case .archive: return Color(red: 0.88, green: 0.57, blue: 0.98)
        case .app: return Color(red: 0.54, green: 0.92, blue: 0.52)
        case .diskImage: return Color(red: 0.72, green: 0.75, blue: 0.83)
        case .binary: return Color(red: 0.72, green: 0.82, blue: 0.95)
        case .unknown: return Color.white.opacity(0.6)
        }
    }
}

struct PrimarySidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .padding(.vertical, 13)
            .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.13))
            .background(Color(red: 0.99, green: 0.74, blue: 0.18).opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(Capsule())
    }
}

struct ToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.04))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
