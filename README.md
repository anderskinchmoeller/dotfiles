# Dotfiles

Personal macOS configuration managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Included

- Zsh and Bash profiles
- Ghostty, Kitty, Hyper, and tmux
- Neovim
- MATLAB startup configuration
- yabai, skhd, SketchyBar, and Karabiner-Elements
- Obsidian application settings and portable settings for all three vaults
- macOS defaults
- Homebrew packages
- skhd LaunchAgent

SSH keys, shell history, credentials, caches, generated files, and backups are intentionally excluded.

## Install

Clone the repository, inspect the links in `install.conf.yaml`, and run:

```sh
./install
```

The default profile is deliberately non-destructive: Dotbot will relink existing symlinks, but it will not overwrite regular files or directories. On an existing machine, move conflicting live files aside after verifying their copies in this repository, then run the installer again.

Optional profiles are separate because they install software or change system preferences:

```sh
./install profiles/packages.conf.yaml
./install profiles/macos.conf.yaml
./install profiles/services.conf.yaml
./install profiles/obsidian.conf.yaml
```

The macOS profile applies user-level Finder, Dock, keyboard, trackpad,
screenshot, menu-bar, and application preferences. It skips non-macOS hosts
and does not require administrator access by default. To also set the Mac's
computer and local host names, opt in explicitly:

```sh
DOTFILES_COMPUTER_NAME="Anders-MacBook" ./install profiles/macos.conf.yaml
```

Set `DOTFILES_SCREENSHOTS_FOLDER` to override the default `~/Screenshots`
location, or `DOTFILES_RESTART_APPS=0` to avoid restarting Finder, Dock, and
SystemUIServer after applying preferences.

The Obsidian profile merges the stored JSON settings into the existing vaults. It deliberately preserves notes, workspaces, downloaded plugin code, caches, and local credential-bearing plugin settings.

The skhd service uses the maintained `jackielii/skhd.zig` app bundle and its managed `com.jackielii.skhd` service. The services profile disables the obsolete custom and C implementation LaunchAgents before registering it, so only one daemon owns the hotkeys. On first install, grant the skhd app Accessibility and Input Monitoring access when macOS asks.

Pass Dotbot flags after the profile name, for example:

```sh
./install install.conf.yaml --dry-run
```

## Local-only settings

Keep tokens, credentials, private keys, and machine-specific overrides in ignored `*.local`, `*.secret`, `.env`, or `private/` files. Never add SSH private keys, `~/.pgpass`, shell history, or application credential stores.

## Updating

Edit the files in this repository. Once installed, most managed paths are symlinks, so application changes are reflected here automatically. Review `git diff` before committing.
