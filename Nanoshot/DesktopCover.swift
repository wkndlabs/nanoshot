//
//  DesktopCover.swift
//  Nanoshot
//

import AppKit

/// Hides desktop icons for the duration of a screenshot without touching Finder.
///
/// Places a borderless, mouse-ignoring window on every screen at a level that sits
/// just above the desktop-icon window but below normal app windows. The window is
/// filled with the current wallpaper image, so visually the desktop looks the same
/// minus the icons. Regular app windows, menubars, and overlays (e.g. the
/// `screencapture` crosshair) remain on top.
@MainActor
final class DesktopCover {
    static let shared = DesktopCover()

    private var windows: [NSWindow] = []

    private init() {}

    func show() {
        guard windows.isEmpty else { return }

        let coveredLevel = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1
        )

        for screen in NSScreen.screens {
            let window = makeWindow(for: screen, level: coveredLevel)
            window.orderFront(nil)
            window.display()
            windows.append(window)
        }
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    private func makeWindow(for screen: NSScreen, level: NSWindow.Level) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = level
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle,
        ]

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: screen.frame.size))
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleAxesIndependently
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.black.cgColor

        if let url = NSWorkspace.shared.desktopImageURL(for: screen),
           let image = NSImage(contentsOf: url) {
            imageView.image = image
        }

        window.contentView = imageView
        return window
    }
}
