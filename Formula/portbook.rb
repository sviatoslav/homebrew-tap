class Portbook < Formula
  desc "Coordinate stable local TCP port reservations across projects"
  homepage "https://github.com/sviatoslav/portbook"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.1.0/portbook_0.1.0_darwin_arm64.tar.gz"
      sha256 "1844b0a0bb9b3c90f3a29ffced0f94099831cd7310bf229903d6909b5d3a0af2"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.1.0/portbook_0.1.0_darwin_amd64.tar.gz"
      sha256 "31a765bef3766b7e03324701e9a08a3db084aa95421dbb9fde8ca2bb6a7d05ab"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.1.0/portbook_0.1.0_linux_arm64.tar.gz"
      sha256 "cdc262a3294d468fe32e23354c024426f3caf2b92c78db04652206e8ddb8deaa"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.1.0/portbook_0.1.0_linux_amd64.tar.gz"
      sha256 "099eb336e16da300b8c9c545cf85359005f056f3ba1add55a4dafa9eb63a1533"
    end
  end

  def install
    bin.install "portbook"
    prefix.install "LICENSE"
  end

  test do
    ENV["XDG_CONFIG_HOME"] = (testpath/"xdg").to_s
    ENV["PORTBOOK_CONFIG_DIR"] = (testpath/"config").to_s
    assert_match "portbook #{version} (commit ", shell_output("#{bin}/portbook --version")

    port = shell_output("#{bin}/portbook reserve api")
    assert_match(/\A[0-9]+\n\z/, port)
    assert_operator port.to_i, :>=, 49152
    assert_operator port.to_i, :<=, 65535
    assert_equal port, shell_output("#{bin}/portbook reserve api")
    bookings = JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
    assert_equal 1, bookings.length
    assert_equal "api", bookings.first.fetch("service")
    assert_equal port.to_i, bookings.first.fetch("port")
    refute_path_exists testpath/"config"

    result = JSON.parse(shell_output("#{bin}/portbook release api"))
    assert_equal true, result.fetch("released")
    assert_empty JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
  end
end
