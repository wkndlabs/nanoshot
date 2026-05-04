//
//  ContentView.swift
//  Nanoshot
//

import SwiftUI
import AppKit

struct MenuView: View {
    @ObservedObject private var store = SettingsStore.shared
    @State private var selectedMode: CaptureMode = .region
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(CaptureMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        shortcut: shortcut(for: mode),
                        isSelected: selectedMode == mode,
                        onSelect: { selectedMode = mode }
                    )
                }
            }

            Text(selectedMode.caption)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Button(action: capture) {
                Label("Take Screenshot", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Divider()

            Button(action: showSettings) {
                HStack {
                    Label("Settings…", systemImage: "gearshape")
                    Spacer()
                    Text("⌘,")
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .keyboardShortcut(",")

            Button(action: { NSApp.terminate(nil) }) {
                HStack {
                    Label("Quit Nanoshot", systemImage: "power")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 300)
    }

    private func shortcut(for mode: CaptureMode) -> Shortcut? {
        switch mode {
        case .region: return store.regionShortcut
        case .screen: return store.screenShortcut
        case .window: return store.windowShortcut
        }
    }

    private func capture() {
        for window in NSApp.windows where window.isVisible {
            window.orderOut(nil)
        }
        ScreenCapture.capture(mode: selectedMode)
    }

    private func showSettings() {
        for window in NSApp.windows where window.className.contains("MenuBarExtra") {
            window.orderOut(nil)
        }
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct ModeCard: View {
    let mode: CaptureMode
    let shortcut: Shortcut?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(mode.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                Text(shortcut?.displayString ?? "-")
                    .font(.system(size: 10, weight: .medium, design: .rounded).monospaced())
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuView()
}
