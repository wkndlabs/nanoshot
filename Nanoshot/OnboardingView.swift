//
//  OnboardingView.swift
//  Nanoshot
//

import SwiftUI
import AppKit
import CoreGraphics

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var stepIndex: Int = 0
    @State private var hasScreenRecording: Bool = CGPreflightScreenCaptureAccess()
    @State private var pollTimer: Timer?

    private let totalSteps = 2

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            progressDots
            Divider()
            footer
        }
        .frame(width: 500, height: 560)
        .onAppear(perform: startPolling)
        .onDisappear(perform: stopPolling)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("NanoshotLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
            Text(stepIndex == 0 ? "Welcome to Nanoshot" : "Replace Default Shortcuts")
                .font(.title2)
                .bold()
            Text(stepIndex == 0
                 ? "A tiny menubar screenshot tool for region, screen, and window captures."
                 : "macOS owns ⌘⇧3, ⌘⇧4, and ⌘⇧5 by default. Turn them off so Nanoshot's shortcuts can take over.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 28)
        .padding(.bottom, 22)
    }

    @ViewBuilder private var content: some View {
        switch stepIndex {
        case 0: permissionsStep
        default: shortcutsStep
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("One permission is needed:")
                .font(.system(size: 13, weight: .semibold))

            PermissionRow(
                icon: "rectangle.on.rectangle",
                title: "Screen Recording",
                description: "Lets Nanoshot capture screens, windows, and regions.",
                isGranted: hasScreenRecording,
                action: requestScreenRecording
            )

            if !hasScreenRecording {
                Text("Clicking Grant shows the macOS prompt. If you've previously denied it, use Open System Settings and toggle Nanoshot on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open System Settings", action: openScreenRecordingSettings)
                    .buttonStyle(.link)
                    .font(.caption)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var shortcutsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to do it")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(number: 1, text: "Click **Open Keyboard Settings** below.")
                InstructionRow(number: 2, text: "Select **Screenshots** in the sidebar.")
                InstructionRow(number: 3, text: "Uncheck the shortcuts you want Nanoshot to use, typically *Save picture of screen as file*, *Save picture of selected area as file*, and *Screenshot and recording options*.")
                InstructionRow(number: 4, text: "Come back and open **Settings…** from the Nanoshot menu to set your own bindings.")
            }

            Button(action: openKeyboardShortcutsSettings) {
                Label("Open Keyboard Settings", systemImage: "arrow.up.right.square")
            }
            .controlSize(.regular)

            Text("You can skip this for now, the Nanoshot menu still works without global shortcuts.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                Circle()
                    .fill(idx == stepIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            if stepIndex == 0 {
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut(.cancelAction)
            } else {
                Button("Back") { stepIndex -= 1 }
            }
            Spacer()
            Button(action: advance) {
                Text(stepIndex == totalSteps - 1 ? "Finish" : "Continue")
                    .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .disabled(stepIndex == 0 && !hasScreenRecording)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    private func advance() {
        if stepIndex < totalSteps - 1 {
            stepIndex += 1
        } else {
            onComplete()
        }
    }

    private func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if !CGPreflightScreenCaptureAccess() {
                openScreenRecordingSettings()
            }
        }
    }

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openKeyboardShortcutsSettings() {
        // macOS 13+ preferred pane URL. Falls back to the generic keyboard pane.
        let candidates = [
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Shortcuts",
            "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts",
        ]
        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let granted = CGPreflightScreenCaptureAccess()
            if granted != hasScreenRecording {
                hasScreenRecording = granted
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Granted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("Grant", action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 22, height: 22)
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            Text(markdown: text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension Text {
    init(markdown: String) {
        if let attr = try? AttributedString(markdown: markdown) {
            self.init(attr)
        } else {
            self.init(markdown)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
