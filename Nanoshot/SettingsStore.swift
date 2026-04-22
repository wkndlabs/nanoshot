//
//  SettingsStore.swift
//  Nanoshot
//

import SwiftUI
import AppKit
import Combine
import ServiceManagement

enum CaptureMode: String, CaseIterable, Identifiable, Codable {
    case region
    case screen
    case window

    var id: String { rawValue }

    var title: String {
        switch self {
        case .region: return "Region"
        case .screen: return "Screen"
        case .window: return "Window"
        }
    }

    var icon: String {
        switch self {
        case .region: return "rectangle.dashed"
        case .screen: return "display"
        case .window: return "macwindow"
        }
    }

    var caption: String {
        switch self {
        case .region: return "Drag to select an area"
        case .screen: return "Capture the entire display"
        case .window: return "Click a window to capture"
        }
    }
}

enum DestinationKind: String, CaseIterable, Identifiable, Codable {
    case desktop
    case customFolder
    case clipboard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .desktop: return "Desktop"
        case .customFolder: return "Custom folder…"
        case .clipboard: return "Clipboard only"
        }
    }
}

enum PreviewCorner: String, CaseIterable, Identifiable, Codable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Keys {
        static let region = "shortcut.region"
        static let screen = "shortcut.screen"
        static let window = "shortcut.window"
        static let showInDock = "showInDock"
        static let hasSetDefaults = "hasSetInitialDefaults"
        static let destinationKind = "destinationKind"
        static let customFolderPath = "customFolderPath"
        static let includeCursor = "includeCursor"
        static let disableShadow = "disableShadow"
        static let playSound = "playSound"
        static let hideDesktopItems = "hideDesktopItems"
        static let previewCorner = "previewCorner"
    }

    @Published var regionShortcut: Shortcut? {
        didSet { saveShortcut(regionShortcut, forKey: Keys.region); applyHotkeys() }
    }
    @Published var screenShortcut: Shortcut? {
        didSet { saveShortcut(screenShortcut, forKey: Keys.screen); applyHotkeys() }
    }
    @Published var windowShortcut: Shortcut? {
        didSet { saveShortcut(windowShortcut, forKey: Keys.window); applyHotkeys() }
    }
    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: Keys.showInDock)
            applyActivationPolicy()
        }
    }
    @Published var destinationKind: DestinationKind {
        didSet { UserDefaults.standard.set(destinationKind.rawValue, forKey: Keys.destinationKind) }
    }
    @Published var customFolderPath: String {
        didSet { UserDefaults.standard.set(customFolderPath, forKey: Keys.customFolderPath) }
    }
    @Published var includeCursor: Bool {
        didSet { UserDefaults.standard.set(includeCursor, forKey: Keys.includeCursor) }
    }
    @Published var disableShadow: Bool {
        didSet { UserDefaults.standard.set(disableShadow, forKey: Keys.disableShadow) }
    }
    @Published var playSound: Bool {
        didSet { UserDefaults.standard.set(playSound, forKey: Keys.playSound) }
    }
    @Published var hideDesktopItems: Bool {
        didSet { UserDefaults.standard.set(hideDesktopItems, forKey: Keys.hideDesktopItems) }
    }
    @Published var previewCorner: PreviewCorner {
        didSet { UserDefaults.standard.set(previewCorner.rawValue, forKey: Keys.previewCorner) }
    }
    @Published private(set) var launchAtLogin: Bool

    private init() {
        let defaults = UserDefaults.standard

        // Seed sensible defaults on first launch so hotkeys work once macOS defaults are disabled.
        if !defaults.bool(forKey: Keys.hasSetDefaults) {
            defaults.set(true, forKey: Keys.hasSetDefaults)
            Self.saveShortcutRaw(Shortcut.defaultRegion, forKey: Keys.region)
            Self.saveShortcutRaw(Shortcut.defaultScreen, forKey: Keys.screen)
            Self.saveShortcutRaw(Shortcut.defaultWindow, forKey: Keys.window)
            defaults.set(true, forKey: Keys.playSound)
        }

        self.regionShortcut = Self.loadShortcut(forKey: Keys.region)
        self.screenShortcut = Self.loadShortcut(forKey: Keys.screen)
        self.windowShortcut = Self.loadShortcut(forKey: Keys.window)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.destinationKind = DestinationKind(rawValue: defaults.string(forKey: Keys.destinationKind) ?? "") ?? .desktop
        self.customFolderPath = defaults.string(forKey: Keys.customFolderPath) ?? ""
        self.includeCursor = defaults.bool(forKey: Keys.includeCursor)
        self.disableShadow = defaults.bool(forKey: Keys.disableShadow)
        self.playSound = defaults.bool(forKey: Keys.playSound)
        self.hideDesktopItems = defaults.bool(forKey: Keys.hideDesktopItems)
        self.previewCorner = PreviewCorner(rawValue: defaults.string(forKey: Keys.previewCorner) ?? "") ?? .bottomRight
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: Hotkeys

    func applyHotkeys() {
        HotkeyManager.shared.register(key: "region", shortcut: regionShortcut) {
            ScreenCapture.capture(mode: .region)
        }
        HotkeyManager.shared.register(key: "screen", shortcut: screenShortcut) {
            ScreenCapture.capture(mode: .screen)
        }
        HotkeyManager.shared.register(key: "window", shortcut: windowShortcut) {
            ScreenCapture.capture(mode: .window)
        }
    }

    // MARK: Activation policy

    /// Applies activation policy based on the `showInDock` preference. Callers that
    /// temporarily raise the app (onboarding, settings window) should invoke this
    /// afterwards to restore the user's chosen mode.
    func applyActivationPolicy() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    // MARK: Launch at login

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSSound.beep()
        }
        // Re-read system state so the UI reflects reality even if the request failed
        // or required approval in System Settings.
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: Reset

    /// Wipes all persisted app state and relaunches the app. UserDefaults keys
    /// owned by other parts of the app (e.g. AppDelegate's onboarding flag) are
    /// included because we clear the entire persistent domain.
    func resetAll() {
        HotkeyManager.shared.unregisterAll()
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        UserDefaults.standard.synchronize()

        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    // MARK: Destination resolution

    func destinationFolderURL() -> URL {
        if destinationKind == .customFolder, !customFolderPath.isEmpty {
            return URL(fileURLWithPath: customFolderPath)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    // MARK: Persistence helpers

    private func saveShortcut(_ shortcut: Shortcut?, forKey key: String) {
        Self.saveShortcutRaw(shortcut, forKey: key)
    }

    private static func saveShortcutRaw(_ shortcut: Shortcut?, forKey key: String) {
        let defaults = UserDefaults.standard
        if let shortcut, let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private static func loadShortcut(forKey key: String) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }
}

enum ScreenCapture {
    // Retain running Processes so they aren't deallocated before their
    // termination handler fires, that would silently skip the preview.
    @MainActor private static var activeProcesses: [Process] = []

    @MainActor
    static func capture(mode: CaptureMode) {
        // Dismiss any still-visible preview so it isn't captured in the next shot.
        PreviewController.shared.dismiss()

        let store = SettingsStore.shared
        // Window captures don't include the desktop, so skip the cover in that mode.
        let coverDesktop = store.hideDesktopItems && mode != .window

        var args: [String] = []
        if !store.playSound { args.append("-x") }
        if store.includeCursor { args.append("-C") }
        if mode == .window && store.disableShadow { args.append("-o") }

        switch mode {
        case .region: args.append("-i")
        case .window: args.append("-iW")
        case .screen: break
        }

        let usingClipboard = store.destinationKind == .clipboard
        let fileURL: URL?
        if usingClipboard {
            args.append("-c")
            fileURL = nil
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
            let filename = "Nanoshot \(formatter.string(from: Date())).png"
            let url = store.destinationFolderURL().appendingPathComponent(filename)
            args.append(url.path)
            fileURL = url
        }

        if coverDesktop {
            DesktopCover.shared.show()
        }

        // Give any popover a moment to dismiss (and the cover a moment to render)
        // before the screencapture overlay takes over the screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = args
            process.terminationHandler = { proc in
                let success = proc.terminationStatus == 0
                DispatchQueue.main.async {
                    activeProcesses.removeAll { $0 === proc }
                    if coverDesktop { DesktopCover.shared.hide() }
                    if success {
                        presentPreview(fileURL: fileURL, usingClipboard: usingClipboard)
                    }
                }
            }
            activeProcesses.append(process)
            do {
                try process.run()
            } catch {
                activeProcesses.removeAll { $0 === process }
                if coverDesktop { DesktopCover.shared.hide() }
                NSSound.beep()
            }
        }
    }

    @MainActor
    private static func presentPreview(fileURL: URL?, usingClipboard: Bool) {
        if usingClipboard {
            if let image = NSImage(pasteboard: .general) {
                PreviewController.shared.show(image: image, context: .clipboard(image))
            }
        } else if let fileURL, let image = NSImage(contentsOf: fileURL) {
            PreviewController.shared.show(image: image, context: .file(fileURL))
        }
    }
}
