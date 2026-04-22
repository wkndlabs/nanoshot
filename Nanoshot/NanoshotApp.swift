//
//  NanoshotApp.swift
//  Nanoshot
//

import SwiftUI
import AppKit

@main
struct NanoshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            Image("TrayIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let onboardingKey = "hasCompletedOnboarding"

    private var onboardingWindow: NSWindow?
    private var settingsCloseObserver: NSObjectProtocol?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Decide dock visibility as early as possible so the icon doesn't flash on launch.
        // - During first-run onboarding the app is always visible in the Dock.
        // - Otherwise honor the user's `showInDock` preference.
        if !UserDefaults.standard.bool(forKey: Self.onboardingKey) {
            NSApp.setActivationPolicy(.regular)
        } else {
            SettingsStore.shared.applyActivationPolicy()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        SettingsStore.shared.applyHotkeys()
        observeSettingsWindow()
        if !UserDefaults.standard.bool(forKey: Self.onboardingKey) {
            showOnboarding()
        } else {
            Updater.shared.checkForUpdates(silent: true)
        }
    }

    /// When the Settings window is visible, force the Dock icon on regardless of
    /// the `showInDock` preference so users have a normal app window to interact
    /// with. When it closes, revert to the preference.
    private func observeSettingsWindow() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else { return }
            guard Self.isSettingsWindow(window) else { return }
            Task { @MainActor in
                AppDelegate.current?.trackSettingsWindow(window)
            }
        }
    }

    /// AppDelegate is a singleton in practice (one per app), but `NSApp.delegate`
    /// gives us a way to reach it from a Sendable closure without capturing self.
    fileprivate static var current: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    fileprivate func trackSettingsWindow(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        if let existing = settingsCloseObserver {
            NotificationCenter.default.removeObserver(existing)
        }
        settingsCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let delegate = AppDelegate.current, let obs = delegate.settingsCloseObserver {
                    NotificationCenter.default.removeObserver(obs)
                    delegate.settingsCloseObserver = nil
                }
                SettingsStore.shared.applyActivationPolicy()
            }
        }
    }

    private static func isSettingsWindow(_ window: NSWindow) -> Bool {
        if window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" {
            return true
        }
        // Fall back to inspecting the hosted view hierarchy for SettingsView,
        // in case SwiftUI changes its window identifier between macOS versions.
        guard let root = window.contentView else { return false }
        return containsSettingsView(root)
    }

    private static func containsSettingsView(_ view: NSView) -> Bool {
        if String(describing: type(of: view)).contains("SettingsView") { return true }
        for sub in view.subviews {
            if containsSettingsView(sub) { return true }
        }
        return false
    }

    func showOnboarding() {
        let view = OnboardingView(onComplete: { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.onboardingKey)
            self?.dismissOnboarding()
        })

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.center()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    private func dismissOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
        SettingsStore.shared.applyActivationPolicy()
        // If showInDock is off, the app just disappeared from the Dock. Point users
        // at the menubar icon so they don't think the app quit.
        if !SettingsStore.shared.showInDock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                OnboardingTipController.shared.show()
            }
        }
    }
}
