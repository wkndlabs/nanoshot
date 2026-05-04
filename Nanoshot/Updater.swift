//
//  Updater.swift
//  Nanoshot
//
//  Lightweight GitHub-based updater. Checks the latest release via the GitHub
//  REST API, compares `tag_name` against the bundle's `CFBundleShortVersionString`,
//  downloads a `.zip` asset containing the updated `.app`, and swaps the bundle
//  in place via a short shell installer that waits for the current process to
//  exit before replacing the binary. No third-party dependencies required.
//

import SwiftUI
import AppKit
import Combine

@MainActor
final class Updater: ObservableObject {
    static let shared = Updater()

    // GitHub repo that hosts Nanoshot releases. Each release must attach a
    // `.zip` asset containing the packaged `Nanoshot.app`.
    static let githubOwner = "wkndlabs"
    static let githubRepo = "nanoshot"

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String)
        case downloading(progress: Double)
        case installing
        case error(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var latestVersion: String?
    @Published private(set) var releaseNotes: String?

    private var downloadURL: URL?
    private var lastCheckDate: Date?

    /// Minimum seconds between background checks on launch so we don't hammer the
    /// GitHub API when the user relaunches in quick succession.
    private let silentCheckCooldown: TimeInterval = 60 * 60 * 6

    private init() {}

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Silent: only surfaces UI when an update is available. Rate-limited.
    /// Interactive: always shows feedback (up-to-date / available / error).
    func checkForUpdates(silent: Bool) {
        if silent {
            if let last = lastCheckDate, Date().timeIntervalSince(last) < silentCheckCooldown {
                return
            }
        }

        if case .checking = status { return }
        if case .downloading = status { return }

        status = .checking

        Task {
            do {
                let release = try await fetchLatestRelease()
                lastCheckDate = Date()

                let trimmedTag = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                let isNewer = Self.compareVersions(trimmedTag, currentVersion) == .orderedDescending

                guard isNewer else {
                    status = .upToDate
                    if !silent { presentUpToDateAlert() }
                    return
                }

                guard let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) else {
                    status = .error("Release has no .zip asset")
                    if !silent { presentErrorAlert("The latest release is missing a .zip asset.") }
                    return
                }

                latestVersion = trimmedTag
                releaseNotes = release.body
                downloadURL = asset.browser_download_url
                status = .available(version: trimmedTag)

                presentUpdatePrompt()
            } catch {
                status = .error(error.localizedDescription)
                if !silent { presentErrorAlert(error.localizedDescription) }
            }
        }
    }

    // MARK: - GitHub API

    private struct Release: Decodable {
        let tag_name: String
        let name: String?
        let body: String?
        let assets: [Asset]
    }

    private struct Asset: Decodable {
        let name: String
        let browser_download_url: URL
    }

    private func fetchLatestRelease() async throws -> Release {
        let urlString = "https://api.github.com/repos/\(Self.githubOwner)/\(Self.githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            throw UpdaterError.badURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Nanoshot-Updater", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw UpdaterError.noReleases
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw UpdaterError.httpStatus(http.statusCode)
        }
        return try JSONDecoder().decode(Release.self, from: data)
    }

    // MARK: - Version comparison

    static func compareVersions(_ a: String, _ b: String) -> ComparisonResult {
        let lhs = a.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = b.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l != r { return l < r ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    // MARK: - User prompts

    private func presentUpdatePrompt() {
        guard let version = latestVersion else { return }
        let alert = NSAlert()
        alert.messageText = "Nanoshot \(version) is available"
        alert.informativeText = {
            if let notes = releaseNotes, !notes.isEmpty {
                let trimmed = notes.count > 800 ? String(notes.prefix(800)) + "…" : notes
                return "You're on \(currentVersion). Install now to update?\n\n\(trimmed)"
            }
            return "You're on \(currentVersion). Install now to update?"
        }()
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if alert.runModal() == .alertFirstButtonReturn {
            downloadAndInstall()
        } else {
            SettingsStore.shared.applyActivationPolicy()
        }
    }

    private func presentUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "Nanoshot is up to date"
        alert.informativeText = "You're on version \(currentVersion)."
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func presentErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Update check failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: - Download + install

    private func downloadAndInstall() {
        guard let downloadURL else { return }
        status = .downloading(progress: 0)

        // The download callback fires on a background queue; we hop to the main
        // actor inside and reference the singleton directly to avoid capturing
        // a weak self across isolation boundaries.
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let task = session.downloadTask(with: downloadURL) { tempURL, _, error in
            // The temp file is deleted after this callback returns, so persist
            // it (or capture the error) before hopping back to the main actor.
            let result: Result<URL, Error>
            if let error {
                result = .failure(error)
            } else if let tempURL {
                let target = FileManager.default.temporaryDirectory
                    .appendingPathComponent("NanoshotUpdate-\(UUID().uuidString).zip")
                do {
                    try FileManager.default.moveItem(at: tempURL, to: target)
                    result = .success(target)
                } catch {
                    result = .failure(error)
                }
            } else {
                result = .failure(UpdaterError.downloadProducedNoFile)
            }

            Task { @MainActor in
                let updater = Updater.shared
                switch result {
                case .failure(let err):
                    updater.status = .error(err.localizedDescription)
                    updater.presentErrorAlert(err.localizedDescription)
                case .success(let url):
                    do {
                        try updater.installFromZip(url)
                    } catch {
                        updater.status = .error(error.localizedDescription)
                        updater.presentErrorAlert(error.localizedDescription)
                    }
                }
            }
        }
        task.resume()
    }

    private func installFromZip(_ zipURL: URL) throws {
        status = .installing

        let workingDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NanoshotUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workingDir, withIntermediateDirectories: true)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-q", "-o", zipURL.path, "-d", workingDir.path]
        try unzip.run()
        unzip.waitUntilExit()
        guard unzip.terminationStatus == 0 else {
            throw UpdaterError.unzipFailed
        }

        guard let newAppURL = Self.findAppBundle(in: workingDir) else {
            throw UpdaterError.missingAppBundle
        }

        let currentAppURL = Bundle.main.bundleURL
        let pid = ProcessInfo.processInfo.processIdentifier

        // Installer script: wait for the current Nanoshot process to exit,
        // atomically swap the app bundle, then relaunch it.
        let script = """
        #!/bin/bash
        set -e
        # Wait for the old instance to quit.
        while kill -0 \(pid) 2>/dev/null; do
            sleep 0.2
        done
        # Swap the bundle. Use ditto to preserve extended attributes / signatures.
        /bin/rm -rf "\(currentAppURL.path)"
        /usr/bin/ditto "\(newAppURL.path)" "\(currentAppURL.path)"
        # Strip quarantine so Gatekeeper doesn't prompt on relaunch.
        /usr/bin/xattr -d -r com.apple.quarantine "\(currentAppURL.path)" 2>/dev/null || true
        /usr/bin/open "\(currentAppURL.path)"
        /bin/rm -rf "\(workingDir.path)"
        /bin/rm -f "\(zipURL.path)"
        """

        let scriptURL = workingDir.appendingPathComponent("install.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path
        )

        let installer = Process()
        installer.executableURL = URL(fileURLWithPath: "/bin/bash")
        installer.arguments = [scriptURL.path]
        try installer.run()

        // Give the installer a beat to enter its wait loop before we exit.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.terminate(nil)
        }
    }

    private static func findAppBundle(in directory: URL) -> URL? {
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for item in items where item.pathExtension == "app" {
                return item
            }
            // Zips produced by Xcode's archive sometimes nest the .app one level deep.
            for item in items {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                    if let found = findAppBundle(in: item) {
                        return found
                    }
                }
            }
        }
        return nil
    }
}

private enum UpdaterError: LocalizedError {
    case badURL
    case noReleases
    case httpStatus(Int)
    case unzipFailed
    case missingAppBundle
    case downloadProducedNoFile

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid update URL."
        case .noReleases: return "No releases published yet."
        case .httpStatus(let code): return "GitHub returned HTTP \(code)."
        case .unzipFailed: return "Failed to unzip update."
        case .missingAppBundle: return "Update archive did not contain a .app bundle."
        case .downloadProducedNoFile: return "Download produced no file."
        }
    }
}
