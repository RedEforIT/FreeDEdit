cask "freededit" do
  version "1.0.0"
  sha256 "7cdd2faaaa7a6d215d73a71d535b17e0121104b504d5067c2dd135c99833cdb9"

  url "https://git.initstack.org/RedEforIT/freededit/-/releases/1.0.0/downloads/FreeDEdit.dmg"
  name "FreeDEdit"
  desc "Swift and AppKit text editor inspired by macOS TextEdit"
  homepage "https://git.initstack.org/RedEforIT/freededit"

  app "FreeDEdit.app"

  zap trash: [
    "~/Library/Preferences/org.initstack.FreeDEdit.plist",
    "~/Library/Saved Application State/org.initstack.FreeDEdit.savedState",
  ]
end
