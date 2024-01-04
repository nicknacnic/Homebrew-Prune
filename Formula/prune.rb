class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/homebrew-prune"
  url "https://github.com/nicknacnic/homebrew-prune/archive/refs/tags/1.1.zip"
  sha256 "c157aae33ed21a79280628d96cf548cda298bab9092c55818d6f2c3f071b20a7"

  depends_on "jq"

  def install
    bin.install "prune.sh" => "prune"
  end

end
