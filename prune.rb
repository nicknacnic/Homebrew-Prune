class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/Homebrew-Prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/refs/tags/1.0.0.zip"
  sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"

  def install
    bin.install "prune.sh"
  end

  # other necessary configurations...
end
