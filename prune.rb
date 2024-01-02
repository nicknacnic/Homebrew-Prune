class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since before 2022"
  homepage "https://github.com/nicknacnic/Homebrew-Prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/v1.0.0.tar.gz"
  sha256 "779905dadb9e6bf30921cdeeda6ce6bb6a0c16d5"
  license "MIT"

  def install
    bin.install "prune.sh"
  end

  test do
    system "#{bin}/prune.sh", "--version"
  end
end
