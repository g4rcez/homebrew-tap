# Installs the signed app of a wm release: brew install g4rcez/tap/wm
# --HEAD builds the latest main from source instead.
# scripts/release.sh of g4rcez/wm writes this file from scripts/wm.rb.in: change it there.
class Wm < Formula
  desc "Tiling window manager for macOS, configured in Lua"
  homepage "https://wm.garcez.dev"
  url "https://github.com/g4rcez/wm/releases/download/v1.0.0/wm-1.0.0-macos.tar.gz"
  sha256 "cb7dfd90c8add51aeb27da79f3c58753684a53b3ad6922eea7a38314fad968d8"
  license "MIT"

  head do
    url "https://github.com/g4rcez/wm.git", branch: "main"

    depends_on xcode: ["26.0", :build] # the Swift 6.2 toolchain
  end

  depends_on macos: :sonoma

  # macOS keeps the permissions of wm by its signature: Homebrew must leave the signed app as it is.
  skip_clean "wm.app"

  def install
    if build.head?
      # Homebrew already sandboxes the build, and SwiftPM cannot nest its own sandbox in it.
      # The app is signed ad hoc: Homebrew has no certificate of yours.
      with_env(
        "SWIFT_BUILD_FLAGS" => "--disable-sandbox",
        "CODESIGN_IDENTITY" => "-",
        "NO_START"          => "1",
        "NO_STOP"           => "1",
      ) do
        system "./build-app.sh", "release"
      end
      prefix.install ".build/wm.app"
    else
      prefix.install "wm.app"
    end

    bin.install_symlink prefix/"wm.app/Contents/MacOS/wm"
    bin.install_symlink prefix/"wm.app/Contents/MacOS/wmd"

    generate_completions_from_executable(bin/"wm", "completion", shells: [:zsh, :bash])
  end

  def caveats
    <<~EOS
      Start wm with:
        wm daemon start
      After an upgrade, restart it with:
        wm daemon reload

      macOS asks for Accessibility at the first start. Releases are signed with one Developer ID and notarized, so
      upgrades keep the permissions. If you come from 0.5.1 or older (or a --HEAD build), clear its stale grants once:
        wm daemon stop
        tccutil reset Accessibility local.wm
        tccutil reset ScreenCapture local.wm
        wm daemon start

      start_at_login uses this path, which stays the same through upgrades:
        #{opt_prefix}/wm.app
    EOS
  end

  test do
    assert_match "wm", shell_output("#{bin}/wm --help")

    # A release must arrive as it was signed and notarized, or macOS asks for the permissions again.
    unless build.head?
      app = prefix/"wm.app"
      system "/usr/bin/codesign", "--verify", "--deep", "--strict", app
      assert_match "subject.OU] = GH3F86PTMX", shell_output("/usr/bin/codesign -dr - #{app} 2>&1")
      # The sandbox of the test stops Gatekeeper, so this checks that the ticket of the notarization is stapled to the app.
      # scripts/verify-release.sh asks Gatekeeper before the release is published.
      assert_path_exists app/"Contents/CodeResources"
    end
  end
end
