# Builds wm from the source of a tagged release: brew install g4rcez/tap/wm
# --HEAD builds the latest main instead.
class Wm < Formula
  desc "Tiling window manager for macOS, configured in Lua"
  homepage "https://wm.garcez.dev"
  url "https://github.com/g4rcez/wm/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "5fd62fddae77b820712984e9b5d610ded43f09cce33175d8670b628b7f815d24"
  license "MIT"
  head "https://github.com/g4rcez/wm.git", branch: "main"

  depends_on xcode: ["26.0", :build] # the Swift 6.2 toolchain
  depends_on macos: :sonoma

  def install
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
    bin.install_symlink prefix/"wm.app/Contents/MacOS/wm"
    bin.install_symlink prefix/"wm.app/Contents/MacOS/wmd"

    generate_completions_from_executable(bin/"wm", "completion", shells: [:zsh, :bash])
  end

  def caveats
    <<~EOS
      Start wm with:
        wm daemon start

      macOS asks for Accessibility the first time. The app is signed ad hoc, so macOS asks again after each
      `brew upgrade wm`. Sign it with your own certificate to keep the permissions:
        codesign --force --sign "<certificate>" #{opt_prefix}/wm.app

      start_at_login needs the app in a fixed place. Copy it to /Applications:
        ditto #{opt_prefix}/wm.app /Applications/wm.app
    EOS
  end

  test do
    assert_match "wm", shell_output("#{bin}/wm --help")
  end
end
