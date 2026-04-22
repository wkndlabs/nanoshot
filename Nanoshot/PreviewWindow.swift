//
//  PreviewWindow.swift
//  Nanoshot
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum PreviewContext {
    case file(URL)
    case clipboard(NSImage)
}

@MainActor
final class PreviewController {
    static let shared = PreviewController()

    private var window: NSWindow?
    private var dismissTimer: Timer?
    private let autoDismissSeconds: TimeInterval = 5.0
    private let windowSize = NSSize(width: 240, height: 160)

    private init() {}

    func show(image: NSImage, context: PreviewContext) {
        dismiss()

        let view = PreviewView(
            image: image,
            context: context,
            onDismiss: { [weak self] in self?.dismiss() },
            onActionsShown: { [weak self] in self?.pauseAutoDismiss() }
        )

        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: windowSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
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
        panel.sharingType = .none
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
        ]

        position(window: panel, corner: SettingsStore.shared.previewCorner)
        panel.orderFrontRegardless()

        self.window = panel
        scheduleAutoDismiss()
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.close()
        window = nil
    }

    fileprivate func pauseAutoDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    private func scheduleAutoDismiss() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissSeconds, repeats: false) { _ in
            Task { @MainActor in PreviewController.shared.dismiss() }
        }
    }

    private func position(window: NSWindow, corner: PreviewCorner) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = windowSize
        let margin: CGFloat = 20
        let origin: NSPoint

        switch corner {
        case .topLeft:
            origin = NSPoint(x: frame.minX + margin, y: frame.maxY - size.height - margin)
        case .topRight:
            origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.maxY - size.height - margin)
        case .bottomLeft:
            origin = NSPoint(x: frame.minX + margin, y: frame.minY + margin)
        case .bottomRight:
            origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.minY + margin)
        }
        window.setFrameOrigin(origin)
    }
}

private struct PreviewView: View {
    let image: NSImage
    let context: PreviewContext
    let onDismiss: () -> Void
    let onActionsShown: () -> Void

    @State private var showActions = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)

            Image(nsImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(6)

            if showActions {
                actionsOverlay
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            if !showActions {
                withAnimation(.easeOut(duration: 0.15)) { showActions = true }
                onActionsShown()
            }
        }
    }

    private var actionsOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                Button(action: performSave) {
                    VStack(spacing: 6) {
                        Image(systemName: saveIcon)
                            .font(.system(size: 20, weight: .semibold))
                        Text("Save")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(width: 80, height: 72)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)

                Button(action: performDelete) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Delete")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(width: 80, height: 72)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.85))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var saveIcon: String {
        switch context {
        case .file: return "checkmark"
        case .clipboard: return "square.and.arrow.down"
        }
    }

    private func performSave() {
        switch context {
        case .file:
            // Already saved; dismissing confirms the keep.
            onDismiss()
        case .clipboard(let image):
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "Screenshot"
            panel.allowedContentTypes = [UTType.png]
            if panel.runModal() == .OK, let url = panel.url {
                writePNG(image: image, to: url)
            }
            onDismiss()
        }
    }

    private func performDelete() {
        switch context {
        case .file(let url):
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        case .clipboard:
            NSPasteboard.general.clearContents()
        }
        onDismiss()
    }

    private func writePNG(image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }
}
