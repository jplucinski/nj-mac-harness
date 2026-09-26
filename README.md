# macOS overlay for Dev Harness

Hammerspoon client for apps, windows, and launching the tools that already live in [nj-dev-harness](https://github.com/jplucinski/nj-dev-harness) `0.3.0`. This repo does not install the harness, does not edit its files, and does not reimplement projects, Git, Docker, Kubernetes, or the `gtask` palette.

Hyper is **ctrl+alt+cmd**. Caps Lock remapping is not part of this overlay.

Deleting Hammerspoon leaves the harness CLI working. `gtask`, `cproj`, `cwt`, and `resume` are Bash functions from the harness. This installer never writes `~/.dev-harness` or `~/.config/dev-harness`, and it does not change the harness block in `~/.bashrc`.

## Two different tool lists

**Required by the harness.** Bash, Task, Git, `fzf`, ripgrep (`rg`), and `grepai`. The harness installer checks and documents those. This overlay does not reinstall them.

`grepai` is not in `bootstrap/Brewfile`. There is no Homebrew core formula for it. A third-party tap formula does exist (`brew install yoanbernabeu/tap/grepai`); this Brewfile does not add that tap. `brew bundle` here does not install `grepai` and does not replace the harness requirement.

**Recommended Mac toolchain.** The optional Brewfile: core CLI (`go-task`, `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `jq`, `yq`, `zoxide`, `atuin`), Git/Docker/Kubernetes (`lazygit`, `lazydocker`, `kubernetes-cli` for `kubectl`, `k9s`, `stern`, `gh`, `git-delta`), diagnostics (`jless`, `lnav`, `grpcurl`, `xh`), [Herdr](https://herdr.dev), and casks (OrbStack, Obsidian, Hammerspoon, DBeaver Community, Bruno, IntelliJ IDEA, Ghostty).

## Install

1. Install [nj-dev-harness](https://github.com/jplucinski/nj-dev-harness) with `./install.sh --configure-shell`, then run `gtask doctor`.
2. Optionally install the Mac toolchain:

   ```bash
   brew bundle --file bootstrap/Brewfile
   ```

   `./install.sh --brew` is the same opt-in. Plain `./install.sh` never runs `brew bundle`.
3. Symlink Hammerspoon:

   ```bash
   ./install.sh
   ```

   If `~/.hammerspoon` already exists and is not this symlink, the installer stops and tells you how to move that config aside. It will not overwrite a personal config. Run it again to confirm the link; a second run is a no-op.
4. Restart Ghostty so new windows are login Bash, then press **Hyper+Space**.

`gtask` is a Bash function in `~/.bashrc`, not a binary. Launchers open Ghostty with `bash -lc`. That shell reads the login profile, not `~/.bashrc`, and a Mac often puts Homebrew only in zsh. Before the command, the launcher runs `brew shellenv` when `/opt/homebrew/bin/brew` or `/usr/local/bin/brew` exists, then sources `~/.bashrc`. For your own login Bash, put `eval "$(brew shellenv)"` in the Bash profile and source `~/.bashrc` from there too. A Ghostty window whose shell is zsh will not see `gtask`.

Project and worktree choice stays inside `gtask`, `cproj`, `cwt`, and `resume`.

### Uninstall

```bash
./install.sh --uninstall
```

That removes only the symlink this installer created. A personal `~/.hammerspoon` is left alone. Uninstall does not touch the harness.

`./install.sh --dry-run` prints the symlink or uninstall action and does not change the system.

## Shortcuts

| Hyper+ | Action |
| --- | --- |
| I | IntelliJ IDEA: launch, focus, or cycle its standard windows |
| T | Ghostty, same launch / focus / cycle |
| B | Browser (`Google Chrome` unless you change `config.browser` in `macos/hammerspoon/apps.lua`) |
| O | Obsidian, same launch / focus / cycle |
| Left / Right | Left or right half of the focused window's screen |
| Up | Maximize on that screen |
| Tab / Shift+Tab | Next or previous standard window of the focused app |
| [ / ] | Previous or next screen, using each screen's frame |
| Space | Ghostty running `gtask` |
| G / D / K | Ghostty running `lazygit`, `lazydocker`, or `k9s` |
| H | Ghostty running `herdr` |
| / | Cheat sheet from the binding registry. Escape closes it |
| R | Reload Hammerspoon |

Herdr is only that CLI in Ghostty. Hammerspoon does not manage agent sessions, panes, or detach/attach.

The cheat sheet is grouped as Apps, Windows, Dev, and System. Register shortcuts with `bind()` in `macos/hammerspoon/apps.lua`, `windows.lua`, `cheatsheet.lua`, or `init.lua`. `bindings.lua` defines `bind()` and is the only file that calls `hs.hotkey.bind`. The cheat sheet is drawn from that registry.

## Shell aliases

`shell/macos.bash` defines `lg`, `ld`, `k9`, and `t` only. Hammerspoon does not source it. Add this yourself if you want the aliases in Bash:

```bash
source /path/to/this/repo/shell/macos.bash
```

## Not in this overlay

IntelliJ window picker, caffeine, mise, workspaces, desktop layout, focus mode, and a Hammerspoon project database. No second command palette, and no project, Git, Docker, Kubernetes, or Taskfile logic in Lua.

## Checks

Syntax and the registry test do not need a Mac:

```bash
luac -p macos/hammerspoon/*.lua tests/registry_test.lua
lua tests/registry_test.lua
./install.sh --dry-run
```

Launch, focus, cycle, and multi-monitor behavior still need a Mac. Hammerspoon does not run here.
