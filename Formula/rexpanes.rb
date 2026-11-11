class Rexpanes < Formula
  desc "Pick a Rex pane by its number, like tmux display-panes"
  homepage "https://github.com/g4rcez/rexpanes"
  url "https://github.com/g4rcez/rexpanes/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "b5528eef789cc0f6111fe3c2525aad1e454a3b5e372fda89bf1b16ede4d674ef"
  license "MIT"

  depends_on "jq"
  depends_on :macos

  def install
    # rexpanes.lua finds bin/rexpanes next to itself, so both go to the same share directory.
    pkgshare.install "rexpanes.lua", "bin"
  end

  def caveats
    <<~EOS
      Add this to your Rex init.lua:

        dofile("#{opt_pkgshare}/rexpanes.lua") {
          key = "ctrl+p>q",
        }
    EOS
  end

  test do
    assert_predicate pkgshare/"bin/rexpanes", :executable?
    assert_match "pane_select", (pkgshare/"rexpanes.lua").read
    assert_match "\e[1;1H", shell_output("#{pkgshare}/bin/rexpanes render 1 7aa2f7 6 5")
  end
end
