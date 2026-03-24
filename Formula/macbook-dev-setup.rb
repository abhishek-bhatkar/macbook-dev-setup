class MacbookDevSetup < Formula
  desc "Bootstrap a macOS developer terminal environment"
  homepage "https://github.com/abhishek-bhatkar/macbook-dev-setup"
  head "https://github.com/abhishek-bhatkar/macbook-dev-setup.git", branch: "main"
  depends_on :macos

  def install
    bin.install "dev-setup.sh" => "macbook-dev-setup"
  end

  def caveats
    <<~EOS
      Run `macbook-dev-setup` to apply the developer environment setup.

      The script installs Homebrew packages, downloads fonts, and updates shell,
      terminal, and editor configuration files in your home directory.
    EOS
  end

  test do
    assert_match "Usage: dev-setup.sh", shell_output("#{bin}/macbook-dev-setup --help")
  end
end
