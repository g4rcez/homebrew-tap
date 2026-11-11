class Rexflash < Formula
  desc "Hint and flash-style label picker for Rex terminal panes"
  homepage "https://github.com/g4rcez/rexflash"
  version "0.1.0"
  license "MIT"

  depends_on :macos

  on_arm do
    url "https://github.com/g4rcez/rexflash/releases/download/v#{version}/rexflash-v#{version}-aarch64-apple-darwin.tar.gz"
    sha256 "15c0f0b58b0af2c3e6816aec844c803f35a939f398ac103689756b0c9033013c"
  end

  on_intel do
    url "https://github.com/g4rcez/rexflash/releases/download/v#{version}/rexflash-v#{version}-x86_64-apple-darwin.tar.gz"
    sha256 "720c3cbcb6b99c2add114574f0345966e6ac7e5050afb65309aa614f5eefc7f9"
  end

  def install
    bin.install "rexflash"
    # A Rex layer can start with a short PATH, so the extension needs the absolute path of the binary.
    inreplace "rexflash.lua", 'local DEFAULT_BIN = "rexflash"', "local DEFAULT_BIN = \"#{opt_bin}/rexflash\""
    pkgshare.install "rexflash.lua"
  end

  def caveats
    <<~EOS
      Add this to your Rex init.lua:

        dofile("#{opt_pkgshare}/rexflash.lua") {
          hint_key = "ctrl+p>y",
          flash_key = "ctrl+p>/",
        }
    EOS
  end

  test do
    # rexflash needs a Rex pane and opens /dev/tty even on a bad call, so the test only checks the files.
    assert_predicate bin/"rexflash", :executable?
    assert_match "#{opt_bin}/rexflash", (pkgshare/"rexflash.lua").read
  end
end
