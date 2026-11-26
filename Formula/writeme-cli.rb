# Installs only the notarized Writeme CLI: brew install g4rcez/tap/writeme-cli
# The cask (brew install --cask g4rcez/tap/writeme) installs the app with the same CLI: install one of the two.
# scripts/release-macos.sh of g4rcez/writeme-editor writes this file from scripts/homebrew/writeme-cli.rb.in.
class WritemeCli < Formula
  desc "Open notes and query Writeme from the command-line"
  homepage "https://writeme.dev/"
  url "https://github.com/g4rcez/writeme-editor/releases/download/v2.15.0/writeme-darwin-arm64"
  version "2.15.0"
  sha256 "9c8b51b74d9e24b77b78e0c525c5ef2b18f3981ec56aa63763b615320e998b83"
  license "MIT"

  depends_on arch: :arm64
  depends_on :macos

  def install
    bin.install "writeme-darwin-arm64" => "writeme"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/writeme --help")
    assert_match "42", shell_output("#{bin}/writeme expr '40 + 2'")
    # The binary must arrive as Apple notarized it.
    system "/usr/bin/codesign", "--verify", "--strict", bin/"writeme"
    assert_match "TeamIdentifier=GH3F86PTMX", shell_output("/usr/bin/codesign -dv #{bin}/writeme 2>&1")
  end
end
