class Prune < Formula
  desc "A script to uninstall Homebrew packages not accessed since a specified date"
  homepage "https://github.com/nicknacnic/Homebrew-Prune"
  url "https://github.com/nicknacnic/Homebrew-Prune/archive/refs/tags/1.0.1.zip"
  sha256 "49a7228fe6efdaff33cc99f42937dc2736b44e00f200b60e8c1a5f64f2d37a8e"

  def install
    bin.install "prune.sh" => "prune"
  end

  # other necessary configurations...
end
