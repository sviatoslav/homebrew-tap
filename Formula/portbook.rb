class Portbook < Formula
  desc "Coordinate stable local TCP port reservations across projects"
  homepage "https://github.com/sviatoslav/portbook"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.4.0/portbook_0.4.0_darwin_arm64.tar.gz"
      sha256 "8b749ce1549e035c1b5274244d5476820e7cc4a3fc136701b361bb7d40084fd4"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.4.0/portbook_0.4.0_darwin_amd64.tar.gz"
      sha256 "46c6164f7a2c26b7773f5b160faffcb29e72331edbc3b945b07ba9a8ee030db7"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.4.0/portbook_0.4.0_linux_arm64.tar.gz"
      sha256 "76ee7ebf1300b070b71c830e6b2460f19234edf2207a2ae65453beb089f7585f"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.4.0/portbook_0.4.0_linux_amd64.tar.gz"
      sha256 "adba21dfee891257e54f96a1476d4cd7422872d809aaa4ee50faeae3be83bbc0"
    end
  end

  def install
    bin.install "portbook"
    prefix.install "LICENSE"
  end

  test do
    ENV["HOME"] = testpath.to_s
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

    assert_equal "Removed 16384 ports. Total: 0 ports.\n", shell_output("#{bin}/portbook config remove --all")
    assert_equal "Reset 16384 ports. Total: 16384 ports.\n", shell_output("#{bin}/portbook config reset")
    assert_equal "Reset 0 ports. Total: 16384 ports.\n", shell_output("#{bin}/portbook config reset")
    pool = JSON.parse(shell_output("#{bin}/portbook config show --output json"))
    assert_equal [{ "start" => 49_152, "end" => 65_535 }], pool.fetch("ranges")
    assert_equal port, shell_output("#{bin}/portbook get api")
    assert_match "unknown flag", shell_output("#{bin}/portbook get api --output json 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook release api --output json 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook --output json list 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook config reset --output json 2>&1", 2)
    assert_match "unknown flag", shell_output("#{bin}/portbook config --output json reset 2>&1", 2)
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
