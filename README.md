# Nanoshot

A tiny menubar screenshot tool for macOS. Region, screen, and window captures with your own global shortcuts, a quick-action preview thumbnail, and optional desktop cleanup while you shoot.

## Features

- **Three capture modes** — region, full screen, and window, each with its own global shortcut
- **Customizable hotkeys** — rebind anything; Nanoshot surfaces the macOS shortcuts it conflicts with during onboarding
- **Flexible output** — save to the Desktop, a custom folder, or straight to the clipboard
- **Quick preview** — a thumbnail appears in the corner of your choice after each capture with Save/Delete actions
- **Desktop cover** — optionally hide desktop icons and wallpaper clutter during captures
- **Menubar-first** — runs as a menu bar extra; the Dock icon is optional
- **Launch at login** — via `SMAppService`
- **In-app updates** — pulls the latest release from GitHub and swaps itself in place

## Install

Download the latest `Nanoshot.zip` from the [Releases](../../releases) page, unzip, and drag `Nanoshot.app` into `/Applications`.

On first launch macOS will ask for **Screen Recording** permission — this is required for capture. The onboarding flow walks you through granting it and disabling the default macOS screenshot shortcuts (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) so Nanoshot's bindings can take over.

## Build from source

Requirements: Xcode 26+, macOS 26.4+.

```sh
git clone https://github.com/<owner>/Nanoshot.git
cd Nanoshot
open Nanoshot.xcodeproj
```

Then build and run the `Nanoshot` scheme. The project has no external dependencies.

## Default shortcuts

| Mode   | Shortcut |
|--------|----------|
| Region | ⌘⇧4      |
| Screen | ⌘⇧3      |
| Window | ⌘⇧5      |

These clash with the macOS defaults until you turn them off in **System Settings → Keyboard → Keyboard Shortcuts → Screenshots**. Onboarding links you straight there.

## Project layout

```
Nanoshot/
├── NanoshotApp.swift     # @main, AppDelegate, onboarding + settings-window plumbing
├── ContentView.swift     # MenuBarExtra popover
├── SettingsView.swift    # Preferences window (General / Shortcuts / Capture)
├── OnboardingView.swift  # First-run flow
├── OnboardingTip.swift   # Post-onboarding "we live in the menubar now" bubble
├── SettingsStore.swift   # @MainActor store backed by UserDefaults; also hosts ScreenCapture
├── Shortcut.swift        # Carbon-based global hotkey model + HotkeyManager
├── PreviewWindow.swift   # Post-capture thumbnail panel
├── DesktopCover.swift    # Fullscreen wallpaper cover during captures
└── Updater.swift         # GitHub Releases auto-updater
```

## Releases & auto-update

Nanoshot ships updates through GitHub Releases. The updater:

1. Hits `GET /repos/{owner}/{repo}/releases/latest`
2. Compares `tag_name` (leading `v` stripped) against the running `CFBundleShortVersionString`
3. If newer, downloads the first `.zip` asset on the release, unzips it, and runs a helper script that waits for the current process to exit, swaps the `.app` with `ditto`, strips `com.apple.quarantine`, and relaunches

### Publishing a release

1. Bump `MARKETING_VERSION` in `Nanoshot.xcodeproj` (Target → Build Settings)
2. Move the `[Unreleased]` entries in [`CHANGELOG.md`](CHANGELOG.md) under the new version header
3. **Product → Archive** in Xcode, then **Distribute App → Copy App**
4. Zip the resulting `Nanoshot.app` (`ditto -c -k --sequesterRsrc --keepParent Nanoshot.app Nanoshot.zip`)
5. On GitHub, create a release with tag `1.2.3` (or `v1.2.3`) and attach `Nanoshot.zip`

The repo the updater pulls from is configured in `Updater.swift` via `githubOwner` / `githubRepo`.

### Signing & notarization

The repo builds with `Apple Development` signing for local dev. For public releases you'll want a Developer ID certificate and notarization so Gatekeeper doesn't frown at first launch — the updater strips quarantine on the swapped bundle, but the *first* install a user runs still passes through Gatekeeper normally.

## Contributing

Issues and PRs welcome. If you're adding a user-visible feature, please include a screenshot or short screen recording in the PR description.

Before opening a PR:

- Build the `Nanoshot` scheme in Xcode — the project should compile with no warnings
- Manually run the feature you touched (capture modes, preview, hotkey rebinding, settings, onboarding)

## License

TBD — add a `LICENSE` file (MIT is the usual pick for projects like this).
