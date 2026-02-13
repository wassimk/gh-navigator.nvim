# gh-navigator.nvim

Open GitHub URLs for files, blame, commits, PRs, and repos directly from any Neovim buffer.

[![build](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml/badge.svg)](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml) ![release](https://img.shields.io/github/v/release/wassimk/gh-navigator.nvim?logo=github)

## Setup

### Prerequisites

- **Neovim 0.10+**
- **[GitHub CLI](https://cli.github.com/)** (`gh`) — installed and authenticated

```shell
brew install gh
gh auth login
```

### Installation

Install via your preferred plugin manager. The following example uses [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  'wassimk/gh-navigator.nvim',
  version = "*",
  config = true
}
```

> [!IMPORTANT]
> This plugin is actively developed on the `main` branch. I recommend using versioned releases with the *version* key to avoid unexpected breaking changes.

## Usage

The plugin provides a single `:GH` command with sub-commands. Tab completion is available for all sub-commands and their arguments.

### Sub-Commands

| Sub-Command | Description |
|--------------------|:---------------|
| `GH blame` | Opens the current file in GitHub's blame view. |
| `GH browse` | Opens the current file in GitHub's blob view. |
| `GH compare` | Opens GitHub's compare view for the current branch against the default branch. |
| `GH pr <arg>` | Opens a PR by number or search term (e.g., `GH pr 1234` or `GH pr refactor the actor class`). |
| `GH repo <path>` | Opens a path in the current repo on GitHub (e.g., `GH repo issues`). Tab-completable paths include *issues*, *pulls*, *actions*, *releases*, etc. |

> [!Note]
> Both `GH browse` and `GH blame` accept a visual range. Select lines in visual mode (**V**) and run `GH blame` to open the blame view for that selection.

### Bare `GH` Command

When called without a sub-command, `GH` tries to interpret the argument as a commit SHA first, then falls back to a PR search. With no arguments, the word under the cursor is used.

```vim
GH eef4a114e0bacc929d8335ef52b1b859d40097f4
GH 1234
GH refactor the actor class
```

This is a shortcut — `GH pr <arg>` skips the commit check and searches PRs directly.

### Copy to Clipboard

Append `!` to any command to copy the URL to the system clipboard instead of opening it in the browser.

```vim
GH! pr 1234
GH! browse
GH! blame
GH! repo issues
```

### Per-Buffer Repo Detection

The plugin detects the Git repository from the current buffer's file path, not from Neovim's working directory. This means you can open Neovim in a parent folder and edit files across multiple repos without any issues.

### Keymaps

No keymaps are set by default. Here are some examples:

```lua
vim.keymap.set('n', '<leader>go', '<cmd>GH<cr>', { desc = 'GH: open commit or PR' })
vim.keymap.set('n', '<leader>gf', '<cmd>GH browse<cr>', { desc = 'GH: browse file' })
vim.keymap.set('n', '<leader>gb', '<cmd>GH blame<cr>', { desc = 'GH: blame file' })
vim.keymap.set('v', '<leader>gb', ':GH blame<cr>', { desc = 'GH: blame selection' })
```
