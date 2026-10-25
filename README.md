# Sviatoslav's Homebrew tap

Homebrew formulae for sviatoslav's tools.

## Portbook

[Portbook](https://github.com/sviatoslav/portbook) coordinates stable local TCP
port reservations across projects, worktrees, and coding agents.

```sh
brew install sviatoslav/tap/portbook
portbook --version
```

The formula installs published [Portbook binaries](https://github.com/sviatoslav/portbook/releases)
for macOS and Linux on Intel/AMD x86-64 or ARM64.
Each platform archive is verified against its release SHA256 checksum.

To update or uninstall:

```sh
brew update
brew upgrade sviatoslav/tap/portbook
brew uninstall portbook
```

Uninstalling removes the executable, not Portbook's configuration or bookings.

## Maintaining the formula

Update the four URLs and SHA256 values only after the corresponding release
assets are published and verified. Run `brew style`, `brew audit --strict
--online --os=all --arch=all`, and `brew test` for `sviatoslav/tap/portbook`.
CI verifies native installation and the functional test on all four targets.
