class Portbook < Formula
  desc "Coordinate stable local TCP port reservations across projects"
  homepage "https://github.com/sviatoslav/portbook"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.3.0/portbook_0.3.0_darwin_arm64.tar.gz"
      sha256 "7e73c0f7da20daa41f8961b4b65416f9180ccd67c999365ac636a1c1c734ecfd"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.3.0/portbook_0.3.0_darwin_amd64.tar.gz"
      sha256 "5b9f63fdc854f54a3d47695b07c98a5d792476fb93ca876b30e3650a794783a5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.3.0/portbook_0.3.0_linux_arm64.tar.gz"
      sha256 "6f1396c3420c05f4cdd538e2c8eb88a3eea0e7ccabbfb6ac5b41602d859ba771"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.3.0/portbook_0.3.0_linux_amd64.tar.gz"
      sha256 "d173e1b7274dce35e59ca87679061c98554a73c2262fe4193c2238c021968730"
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
    assert_equal port, shell_output("#{bin}/portbook get api")
    assert_match "reservation already exists", shell_output("#{bin}/portbook reserve api 2>&1", 1)
    bookings = JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
    assert_equal 1, bookings.length
    assert_equal "api", bookings.first.fetch("service")
    assert_equal port.to_i, bookings.first.fetch("port")
    refute_path_exists testpath/"config"

    shell_output("#{bin}/portbook config remove --all")
    reset = JSON.parse(shell_output("#{bin}/portbook config reset --output json"))
    assert_equal "config reset", reset.fetch("command")
    assert_equal 16_384, reset.fetch("changed")
    assert_equal 16_384, reset.fetch("total")
    repeated = JSON.parse(shell_output("#{bin}/portbook config --output json reset"))
    assert_equal 0, repeated.fetch("changed")
    pool = JSON.parse(shell_output("#{bin}/portbook config show --output json"))
    assert_equal [{ "start" => 49_152, "end" => 65_535 }], pool.fetch("ranges")
    assert_equal port, shell_output("#{bin}/portbook get api")
    assert_match "unknown flag", shell_output("#{bin}/portbook get api --output json 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook release api --output json 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook --output json list 2>&1", 2)
    assert_equal port, shell_output("#{bin}/portbook get api")

    result = shell_output("#{bin}/portbook release api")
    assert_match "Released port #{port.strip} for \"api\" in ", result
    assert_empty JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
    assert_match "reservation not found", shell_output("#{bin}/portbook get api 2>&1", 1)
    assert_match "reservation not found", shell_output("#{bin}/portbook release api 2>&1", 1)

    api = shell_output("#{bin}/portbook reserve api").to_i
    web = shell_output("#{bin}/portbook reserve web").to_i
    result = shell_output("#{bin}/portbook release --all")
    assert_match "Released 2 bookings in ", result
    assert_match ": #{[api, web].sort.join(", ")}.\n", result
    assert_empty JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
  end
end
