cask "nanoshot" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/wkndlabs/nanoshot/releases/download/v#{version}/Nanoshot.zip",
      verified: "github.com/wkndlabs/nanoshot/"
  name "Nanoshot"
  desc "Menubar screenshot tool for region, screen, and window captures"
  homepage "https://github.com/wkndlabs/nanoshot"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Nanoshot.app"

  zap trash: [
    "~/Library/Preferences/weekendlabs.Nanoshot.plist",
    "~/Library/Application Support/Nanoshot",
    "~/Library/Caches/weekendlabs.Nanoshot",
    "~/Library/Saved Application State/weekendlabs.Nanoshot.savedState",
  ]
end
