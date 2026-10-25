# Demo GIF

`gh-navigator.gif` in the repo root is generated from `gh-navigator.tape` with [VHS](https://github.com/charmbracelet/vhs). Regenerate it whenever the plugin's behavior or the README demo should change.

## Requirements

- [VHS](https://github.com/charmbracelet/vhs#installation) (`brew install vhs`)
- Neovim >= 0.10.0, git, and bash
- [GitHub CLI](https://cli.github.com/) (`gh`), installed and authenticated. The demo looks up real PRs on this repo.
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) (optional, the tape tries MonoLisaCode first and VHS falls back to a default font)
- Network access, to clone this repo, [onedark.nvim](https://github.com/navarasu/onedark.nvim), [nvim-notify](https://github.com/rcarriga/nvim-notify), and [snacks.nvim](https://github.com/folke/snacks.nvim) into `/tmp`

## Regenerate

From the repo root:

```shell
vhs demo/gh-navigator.tape
```

This overwrites `gh-navigator.gif`. Commit it along with any tape changes.

## How it works

- `setup.sh` clones this repo from GitHub into `/tmp/gh-navigator-demo`, so `gh` has a real repo on `main` to look up. The plugin code is loaded from this checkout.
- The demo uses `:GH!`, which copies URLs instead of opening a browser. `init.lua` swallows clipboard writes, so recording never touches your real clipboard.
- `init.lua` uses nvim-notify (`wrapped-compact`) for notifications and the snacks.nvim picker for `vim.ui.select`, both pinned to releases. Long URLs show in a popup instead of triggering a hit-enter prompt.
- PR lookups are live, so the `:GH! pr compare` picker reflects the repo's current PRs. The tape filters the picker with `compare sub` to land on PR #10. If that stops matching, update the filter and the `Wait+Screen /pull\/10/` line.
- Steps wait on screen text (`Wait+Screen`), so if the plugin's behavior changes the render fails instead of recording a broken demo.
