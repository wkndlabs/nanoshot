//
//  OnboardingTip.swift
//  Nanoshot
//

import SwiftUI
import AppKit

@MainActor
final class OnboardingTipController {
    static let shared = OnboardingTipController()

    private var window: NSPanel?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var dismissTimer: Timer?

    private let bubbleSize = NSSize(width: 280, height: 150)
    private let arrowHeight: CGFloat = 10
    private let autoDismissSeconds: TimeInterval = 12

    private init() {}

    /// Shows the tooltip anchored to the menubar status item.
    /// If the status item frame can't be located we retry briefly — SwiftUI's
    /// MenuBarExtra sometimes lags a frame behind app launch.
    func show() {
        dismiss()
        showWithRetries(remaining: 10)
    }

    func dismiss() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.orderOut(nil)
        window?.close()
        window = nil
    }

    private func showWithRetries(remaining: Int) {
        if let anchor = statusItemFrame() {
            present(anchoredTo: anchor)
            return
        }
        guard remaining > 0 else {
            // Fall back to the top-right of the menu bar so we still educate the user.
            if let screen = NSScreen.main {
                let frame = NSRect(
                    x: screen.frame.maxX - 30,
                    y: screen.frame.maxY - 22,
                    width: 24,
                    height: 22
                )
                present(anchoredTo: frame)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showWithRetries(remaining: remaining - 1)
        }
    }

    private func present(anchoredTo anchor: NSRect) {
        let view = OnboardingTipView(onDismiss: { [weak self] in self?.dismiss() })
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: bubbleSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: bubbleSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
        ]

        // Position the panel so its arrow points at the center of the status item.
        let anchorCenterX = anchor.midX
        var origin = NSPoint(
            x: anchorCenterX - bubbleSize.width / 2,
            y: anchor.minY - bubbleSize.height - 4
        )

        if let screen = NSScreen.main {
            let visible = screen.frame
            origin.x = max(visible.minX + 6, min(origin.x, visible.maxX - bubbleSize.width - 6))
        }

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()

        // Dismiss on any click outside the app (e.g. desktop, another app).
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in OnboardingTipController.shared.dismiss() }
        }

        // Dismiss on clicks inside our app that aren't on the bubble itself —
        // notably the menubar icon that opened the status item.
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if event.window !== OnboardingTipController.shared.window {
                Task { @MainActor in OnboardingTipController.shared.dismiss() }
            }
            return event
        }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissSeconds, repeats: false) { _ in
            Task { @MainActor in OnboardingTipController.shared.dismiss() }
        }

        window = panel
    }

    /// Locates the frame of the MenuBarExtra's status item window.
    /// macOS hosts menubar items inside NSStatusBarWindow instances whose
    /// frame matches the clickable button region.
    private func statusItemFrame() -> NSRect? {
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            if className.contains("StatusBar"), window.frame.height > 0, window.frame.height < 40 {
                return window.frame
            }
        }
        return nil
    }
}

private struct OnboardingTipView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BubbleArrow()
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(width: 18, height: 10)
                .shadow(color: .black.opacity(0.05), radius: 1, y: -1)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.tint)
                    Text("Nanoshot lives up here now")
                        .font(.system(size: 13, weight: .semibold))
                }

                Text("Click the menubar icon to take screenshots, open Settings, or check for updates.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text("Got it")
                            .frame(minWidth: 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct BubbleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
