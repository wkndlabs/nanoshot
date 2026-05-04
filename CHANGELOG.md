# Changelog

All notable changes to Nanoshot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Post-onboarding tooltip that points at the menubar icon so users can find the app
  after it disappears from the Dock (`OnboardingTip.swift`).
- Dock icon is temporarily re-shown while the Settings window is open, even when
  "Show Nanoshot in the Dock" is off.
- GitHub Releases auto-updater (`Updater.swift`):
  - Silent check on launch (rate-limited to every 6h).
  - Manual "Check for Updates" button in Settings → General → Updates.
  - Downloads the release `.zip`, swaps the app bundle via a helper script, and
    relaunches.

## [1.0.0] - 2026-04-22

Initial release.

### Added
- Menu bar extra with region, screen, and window capture modes.
- Customizable global hotkeys (defaults: ⌘⇧4 region, ⌘⇧3 screen, ⌘⇧5 window).
- Post-capture preview thumbnail with Save / Delete actions (configurable corner).
- Output destinations: Desktop, custom folder, or clipboard.
- Capture options: include cursor, remove window shadow, play capture sound,
  hide desktop items during capture.
- Optional Dock icon, launch at login via `SMAppService`.
- First-run onboarding covering Screen Recording permission and the macOS
  default-shortcut conflict.
- Reset action that clears preferences and relaunches to the initial setup.

[Unreleased]: https://github.com/wkndlabs/nanoshot/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/wkndlabs/nanoshot/releases/tag/v1.0.0
