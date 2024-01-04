class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/homebrew-prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/refs/tags/1.1.zip"
  sha256 "f4b71fb7b69c04edb252b5240f6a8bfc68d14b7aaaf98904c372f3306dd5eb48"

  depends_on "jq"

  def install
    bin.install "prune.sh" => "prune"
  end

end
