class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/homebrew-prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/refs/tags/1.1.zip"
  sha256 "6268cba951adcea79c6e0e8967e68a800d1e08ce2e5a22b449aca6f296563601"

  depends_on "jq"

  def install
    bin.install "prune.sh" => "prune"
  end

end
