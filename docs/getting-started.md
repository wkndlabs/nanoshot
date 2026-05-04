# Getting started

Nanoshot is a tiny menubar screenshot tool for macOS. Pick whichever install channel fits.

## Install

### Mac App Store

One-click install with automatic updates handled by macOS.

### Homebrew

```sh
brew install --cask nanoshot
```

Upgrade with `brew upgrade --cask nanoshot`. The cask tracks the latest GitHub Release.

### Direct download

Grab the latest `Nanoshot.zip` from the [Releases page](https://github.com/wkndlabs/nanoshot/releases), unzip, and drag `Nanoshot.app` into `/Applications`. Direct-download builds auto-update themselves in place.

## First launch

On first launch, macOS will ask for **Screen Recording** permission, which is required for capture. The onboarding flow walks you through:

1. Granting Screen Recording permission
2. Disabling the default macOS screenshot shortcuts (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) so Nanoshot's bindings can take over

Once that's done, Nanoshot lives in your menu bar. The Dock icon is optional.

## App Store vs. other channels

App Store builds are sandboxed and update through the App Store. Homebrew and direct-download builds are signed + notarized Developer ID builds that update themselves via GitHub Releases.
