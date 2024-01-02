class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since before 2022"
  homepage "https://github.com/nicknacnic/Homebrew-Prune"
  url "https://github.com/nicknacnick/Homebrew-Prune/archive/v1.0.0.tar.gz"
  sha256 "29f09ad7e67399708462771be76868e366d9f1ac"
  license "MIT"

  def install
    bin.install "prune.sh"
  end

  test do
    system "#{bin}/prune.sh", "--version"
  end
end
