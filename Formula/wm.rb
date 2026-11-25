# Installs the signed app of a wm release: brew install g4rcez/tap/wm
# --HEAD builds the latest main from source instead.
# scripts/release.sh of g4rcez/wm writes this file from scripts/wm.rb.in: change it there.
class Wm < Formula
  desc "Tiling window manager for macOS, configured in Lua"
  homepage "https://wm.garcez.dev"
  url "https://github.com/g4rcez/wm/releases/download/v0.5.1/wm-0.5.1-macos.tar.gz"
  sha256 "26ddf5977366c14857fa9c0253bff67ae1b31f4ff861e4690f8a9866739166ab"
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

      macOS asks for Accessibility at the first start. Releases are signed with one certificate, so upgrades keep the
      permissions. If you come from a build older than 0.5.0 (or a --HEAD build), clear its stale grants once:
        tccutil reset Accessibility local.wm
        tccutil reset ScreenCapture local.wm

      start_at_login uses this path, which stays the same through upgrades:
        #{opt_prefix}/wm.app
    EOS
  end

  test do
    assert_match "wm", shell_output("#{bin}/wm --help")
  end
end
