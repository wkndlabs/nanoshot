<p align="center">
  <img src="assets/logo.png" alt="Nanoshot" width="128" height="128">
</p>

<h1 align="center">Nanoshot</h1>

<p align="center">
  A tiny menubar screenshot tool for macOS. Region, screen, and window captures with your own global shortcuts, a quick-action preview thumbnail, and optional desktop cleanup while you shoot.
</p>

## Features

- **Three capture modes**: region, full screen, and window, each with its own global shortcut
- **Customizable hotkeys**: rebind anything; Nanoshot surfaces the macOS shortcuts it conflicts with during onboarding
- **Flexible output**: save to the Desktop, a custom folder, or straight to the clipboard
- **Quick preview**: a thumbnail appears in the corner of your choice after each capture with Save/Delete actions
- **Desktop cover**: optionally hide desktop icons and wallpaper clutter during captures
- **Menubar-first**: runs as a menu bar extra; the Dock icon is optional
- **Launch at login**: via `SMAppService`
- **In-app updates**: pulls the latest release from GitHub and swaps itself in place

## Install

Nanoshot is available through three channels. Pick whichever fits.

### Mac App Store

<!-- Replace the placeholder ID once the app is approved. -->
[**Download on the Mac App Store**](https://apps.apple.com/app/nanoshot/id0000000000). One-click install, automatic updates handled by macOS.

### Homebrew

```sh
brew install --cask nanoshot
```

Upgrade with `brew upgrade --cask nanoshot`. The cask tracks the latest GitHub Release, so it updates alongside the direct-download channel.

### Direct download (GitHub Releases)

Grab the latest `Nanoshot.zip` from the [Releases page](https://github.com/wkndlabs/nanoshot/releases), unzip, and drag `Nanoshot.app` into `/Applications`. This build auto-updates itself in place via the in-app updater (see [Releases & auto-update](#releases--auto-update)).

### First launch

On first launch macOS will ask for **Screen Recording** permission, which is required for capture. The onboarding flow walks you through granting it and disabling the default macOS screenshot shortcuts (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) so Nanoshot's bindings can take over.

> **Mac App Store vs. the other channels:** App Store builds are sandboxed and have capture sounds delegated to macOS; they update through the App Store and do **not** use the in-app GitHub updater. Homebrew and direct-download builds are signed + notarized Developer ID builds that update themselves via GitHub Releases.

## Build from source

Requirements: Xcode 26+, macOS 26.4+.

```sh
git clone https://github.com/wkndlabs/nanoshot.git
cd nanoshot
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

## Distribution

Nanoshot has three parallel distribution channels. Each release goes out to all of them.

### 1. Direct download + in-app updater (GitHub Releases)

This is the canonical release; everything else derives from it. The in-app updater:

1. Hits `GET /repos/wkndlabs/nanoshot/releases/latest`
2. Compares `tag_name` (leading `v` stripped) against the running `CFBundleShortVersionString`
3. If newer, downloads the first `.zip` asset, unzips it, and runs a helper script that waits for the current process to exit, swaps the `.app` with `ditto`, strips `com.apple.quarantine`, and relaunches

The repo the updater pulls from is hard-coded in `Updater.swift` via `githubOwner` / `githubRepo`.

### 2. Mac App Store

App Store builds are a separate Xcode target configuration:

- **Sandboxed** (`ENABLE_APP_SANDBOX = YES`, entitlement for `com.apple.security.files.user-selected.read-write` for custom folders)
- **In-app updater disabled** (gated behind a `MAS_BUILD` compile condition; the App Store handles updates)
- Signed with the App Store distribution certificate, submitted via **Product → Archive → Distribute App → App Store Connect**

Screenshots, privacy policy URL, and the Screen Recording usage description string all live in App Store Connect. Keep the `CFBundleShortVersionString` in sync with the GitHub tag so users on different channels see the same version numbers.

### 3. Homebrew Cask

The cask definition lives in this repo at [`Casks/nanoshot.rb`](Casks/nanoshot.rb). It points at the GitHub Release `.zip` and uses Homebrew's `:github_latest` livecheck strategy so version bumps are automatic.

Two ways to publish it:

**Option A: personal tap.** Copy `Casks/nanoshot.rb` into a `Casks/` directory in a repo named `wkndlabs/homebrew-tap`. Users then install with:

```sh
brew tap wkndlabs/tap
brew install --cask nanoshot
```

**Option B: submit to `homebrew/cask`.** Fork [`homebrew/homebrew-cask`](https://github.com/Homebrew/homebrew-cask), drop the file into `Casks/n/nanoshot.rb`, and open a PR. Once merged, `brew install --cask nanoshot` works with no tap required. This is the preferred path for broadly-useful casks, but the project needs to meet Homebrew's [cask acceptance criteria](https://docs.brew.sh/Acceptable-Casks) (signed + notarized, stable homepage, etc.).

Bump the cask on each release with:

```sh
brew bump-cask-pr nanoshot --version 1.2.3
```

…which auto-computes the new `sha256` and opens a PR against wherever the cask currently lives.

### Publishing a release

1. Bump `MARKETING_VERSION` in `Nanoshot.xcodeproj` (Target → Build Settings)
2. Move the `[Unreleased]` entries in [`CHANGELOG.md`](CHANGELOG.md) under the new version header
3. **Developer ID build** (for GitHub + Homebrew):
   - **Product → Archive** → **Distribute App → Developer ID → Upload** (for notarization) → **Export**
   - Zip the exported `Nanoshot.app`: `ditto -c -k --sequesterRsrc --keepParent Nanoshot.app Nanoshot.zip`
4. **App Store build**:
   - Switch to the MAS configuration, **Product → Archive → Distribute App → App Store Connect**
5. Tag and release on GitHub (`git tag v1.2.3 && git push --tags`), upload `Nanoshot.zip`, paste the changelog entries into the release notes
6. The Homebrew cask auto-bumps from the new tag; if bumping manually run `brew bump-cask-pr nanoshot --version 1.2.3`
7. Submit the App Store build for review in App Store Connect

### Signing & notarization

The repo builds with `Apple Development` signing for local dev. For the Developer ID channel (Homebrew + direct download) you need:

- A **Developer ID Application** certificate
- Notarization (`notarytool submit Nanoshot.zip --keychain-profile "AC_PASSWORD" --wait`)
- Stapling (`xcrun stapler staple Nanoshot.app`) *before* zipping the final artifact

The in-app updater strips `com.apple.quarantine` on swapped bundles, but the *first* install a user runs still passes through Gatekeeper, so notarization matters even though the updater can bypass the quarantine prompt afterwards.

## Contributing

Issues and PRs welcome. If you're adding a user-visible feature, please include a screenshot or short screen recording in the PR description.

Before opening a PR:

- Build the `Nanoshot` scheme in Xcode; the project should compile with no warnings
- Manually run the feature you touched (capture modes, preview, hotkey rebinding, settings, onboarding)

## License

MIT. See [`LICENSE`](LICENSE).
