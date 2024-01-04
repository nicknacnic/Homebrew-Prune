class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/homebrew-prune"
  url "https://github.com/nicknacnic/homebrew-prune/archive/refs/tags/1.1.zip"
  sha256 "76e1ad9ccd66565dd0b58b30b7d15c9e89873d9e31f5b9f5c5e00ef6f1bf3f8d"

  depends_on "jq"

  def install
    bin.install "prune.sh" => "prune"
  end

end
