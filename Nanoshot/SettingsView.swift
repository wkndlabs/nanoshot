//
//  SettingsView.swift
//  Nanoshot
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

struct SettingsView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var updater = Updater.shared
    @State private var showResetConfirm = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            shortcutsTab
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            captureTab
                .tabItem { Label("Capture", systemImage: "camera") }
        }
        .frame(width: 500, height: 460)
    }

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Keyboard Shortcuts")
                .font(.headline)
            Text("Click a field and press the keys you want to use.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ShortcutRow(
                    icon: CaptureMode.region.icon,
                    title: CaptureMode.region.title,
                    shortcut: Binding(
                        get: { store.regionShortcut },
                        set: { store.regionShortcut = $0 }
                    )
                )
                ShortcutRow(
                    icon: CaptureMode.screen.icon,
                    title: CaptureMode.screen.title,
                    shortcut: Binding(
                        get: { store.screenShortcut },
                        set: { store.screenShortcut = $0 }
                    )
                )
                ShortcutRow(
                    icon: CaptureMode.window.icon,
                    title: CaptureMode.window.title,
                    shortcut: Binding(
                        get: { store.windowShortcut },
                        set: { store.windowShortcut = $0 }
                    )
                )
            }

            Text("If a shortcut doesn't fire, macOS probably owns it. Open System Settings → Keyboard → Keyboard Shortcuts → Screenshots and uncheck conflicting entries.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var captureTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Save to")
                    .font(.headline)
                Picker("", selection: Binding(
                    get: { store.destinationKind },
                    set: { store.destinationKind = $0 }
                )) {
                    ForEach(DestinationKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                if store.destinationKind == .customFolder {
                    HStack(spacing: 8) {
                        Text(displayFolderPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        Button("Choose…", action: chooseFolder)
                    }
                    .padding(.leading, 22)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Options")
                    .font(.headline)
                Toggle("Include cursor in capture", isOn: Binding(
                    get: { store.includeCursor },
                    set: { store.includeCursor = $0 }
                ))
                Toggle("Remove shadow from window captures", isOn: Binding(
                    get: { store.disableShadow },
                    set: { store.disableShadow = $0 }
                ))
                Toggle("Play capture sound", isOn: Binding(
                    get: { store.playSound },
                    set: { store.playSound = $0 }
                ))
                Toggle("Hide desktop items during capture", isOn: Binding(
                    get: { store.hideDesktopItems },
                    set: { store.hideDesktopItems = $0 }
                ))
            }
            .toggleStyle(.checkbox)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)
                HStack(alignment: .top, spacing: 14) {
                    CornerPicker(selection: Binding(
                        get: { store.previewCorner },
                        set: { store.previewCorner = $0 }
                    ))
                    Text("After a screenshot, a thumbnail appears at this corner. Click it to Save or Delete.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Startup")
                    .font(.headline)
                Toggle("Launch at login", isOn: Binding(
                    get: { store.launchAtLogin },
                    set: { store.setLaunchAtLogin($0) }
                ))
                Text("Open Nanoshot automatically when you sign in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.headline)
                Toggle("Show Nanoshot in the Dock", isOn: Binding(
                    get: { store.showInDock },
                    set: { store.showInDock = $0 }
                ))
                Text("Keep the app icon visible in the Dock alongside the menubar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Updates")
                    .font(.headline)
                HStack(spacing: 10) {
                    Button(action: { updater.checkForUpdates(silent: false) }) {
                        Text(updateButtonTitle)
                            .frame(minWidth: 140)
                    }
                    .disabled(isCheckingOrInstalling)
                    Text(updateStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                Text("Current version \(updater.currentVersion). Updates are delivered via GitHub Releases.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Reset")
                    .font(.headline)
                HStack {
                    Button("Reset Nanoshot…", role: .destructive) {
                        showResetConfirm = true
                    }
                    Spacer()
                }
                Text("Clears all preferences and shortcuts, then relaunches to the initial setup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .toggleStyle(.checkbox)
        .padding(20)
        .alert("Reset Nanoshot?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { store.resetAll() }
        } message: {
            Text("This clears all preferences and shortcuts, then relaunches Nanoshot to the initial setup. This cannot be undone.")
        }
    }

    private var displayFolderPath: String {
        if store.customFolderPath.isEmpty { return "No folder chosen" }
        return (store.customFolderPath as NSString).abbreviatingWithTildeInPath
    }

    private var updateButtonTitle: String {
        switch updater.status {
        case .checking: return "Checking…"
        case .downloading: return "Downloading…"
        case .installing: return "Installing…"
        case .available(let v): return "Install \(v)"
        default: return "Check for Updates"
        }
    }

    private var updateStatusText: String {
        switch updater.status {
        case .idle: return ""
        case .checking: return "Contacting GitHub…"
        case .upToDate: return "You're on the latest version."
        case .available(let v): return "Version \(v) is available."
        case .downloading(let p):
            if p > 0 { return "Downloading (\(Int(p * 100))%)…" }
            return "Downloading…"
        case .installing: return "Installing update, app will relaunch."
        case .error(let msg): return msg
        }
    }

    private var isCheckingOrInstalling: Bool {
        switch updater.status {
        case .checking, .downloading, .installing: return true
        default: return false
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Pick a folder for screenshots"
        if panel.runModal() == .OK, let url = panel.url {
            store.customFolderPath = url.path
        }
    }
}

private struct ShortcutRow: View {
    let icon: String
    let title: String
    @Binding var shortcut: Shortcut?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(title)
                .frame(width: 80, alignment: .leading)
            Spacer()
            ShortcutRecorder(shortcut: $shortcut)
        }
    }
}

struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut?
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleRecording) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded).monospaced())
                    .frame(minWidth: 110, minHeight: 22)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
                    .foregroundStyle(shortcut == nil && !isRecording ? Color.secondary : Color.primary)
            }
            .buttonStyle(.plain)

            Button {
                shortcut = nil
                stopRecording()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(shortcut == nil && !isRecording)
            .opacity(shortcut == nil && !isRecording ? 0.3 : 1)
        }
        .onDisappear { stopRecording() }
    }

    private var label: String {
        if isRecording { return "Press keys…" }
        return shortcut?.displayString ?? "Not set"
    }

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        isRecording = true
        // Tear down our Carbon hotkeys so they don't fire (e.g. trigger a screenshot)
        // while the user is trying to bind a new shortcut.
        HotkeyManager.shared.unregisterAll()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if Int(event.keyCode) == kVK_Escape {
                stopRecording()
                return nil
            }
            let requiredMods: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
            if event.modifierFlags.intersection(requiredMods).isEmpty {
                NSSound.beep()
                return nil
            }
            if let new = Shortcut(event: event) {
                shortcut = new
            }
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        // Re-arm hotkeys from the current (possibly updated) settings.
        SettingsStore.shared.applyHotkeys()
    }
}

private struct CornerPicker: View {
    @Binding var selection: PreviewCorner

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                cell(.topLeft)
                cell(.topRight)
            }
            HStack(spacing: 4) {
                cell(.bottomLeft)
                cell(.bottomRight)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private func cell(_ corner: PreviewCorner) -> some View {
        Button(action: { selection = corner }) {
            RoundedRectangle(cornerRadius: 4)
                .fill(selection == corner ? Color.accentColor : Color.secondary.opacity(0.2))
                .frame(width: 28, height: 20)
        }
        .buttonStyle(.plain)
        .help(corner.title)
    }
}

#Preview {
    SettingsView()
}
