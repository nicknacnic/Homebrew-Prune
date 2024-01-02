class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/Homebrew-Prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/refs/tags/1.0.0.zip"
  sha256 "e34314380f6a246d8a651be8b7250e4f6b45e008e834ca27a1374c085f3ae0be"

  def install
    bin.install "prune.sh" => "prune"
  end

  # other necessary configurations...
end
