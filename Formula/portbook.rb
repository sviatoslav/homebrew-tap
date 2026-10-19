class Portbook < Formula
  desc "Coordinate stable local TCP port reservations across projects"
  homepage "https://github.com/sviatoslav/portbook"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.2.0/portbook_0.2.0_darwin_arm64.tar.gz"
      sha256 "d09ed479de43275efe5334e3f01772639fed714f2f497b2ce196ee4f8ed7ce76"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.2.0/portbook_0.2.0_darwin_amd64.tar.gz"
      sha256 "420fa9adbac2f7ab3d89d7e6af0b15a2ff115954fcdba331039e4f7f50d4d06b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.2.0/portbook_0.2.0_linux_arm64.tar.gz"
      sha256 "45eb3be3b60d8a1ed5b23a809246ca5e43202df9f93843dfd84725d5d8829723"
    end
    on_intel do
      url "https://github.com/sviatoslav/portbook/releases/download/v0.2.0/portbook_0.2.0_linux_amd64.tar.gz"
      sha256 "708e49be3d7bf2558f865093e909118072acb433749ae5d4be35bd16289ab9ad"
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

    result = JSON.parse(shell_output("#{bin}/portbook release api"))
    assert_equal true, result.fetch("released")
    assert_empty JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
    assert_match "reservation not found", shell_output("#{bin}/portbook get api 2>&1", 1)
    assert_match "reservation not found", shell_output("#{bin}/portbook release api 2>&1", 1)

    shell_output("#{bin}/portbook reserve api")
    shell_output("#{bin}/portbook reserve web")
    result = JSON.parse(shell_output("#{bin}/portbook release --all"))
    assert_equal true, result.fetch("all")
    assert_equal 2, result.fetch("released")
    assert_equal result.fetch("ports").sort, result.fetch("ports")
    assert_empty JSON.parse(shell_output("#{bin}/portbook list")).fetch("bookings")
  end
end
