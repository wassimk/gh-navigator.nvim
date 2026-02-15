# gh-navigator.nvim

Open GitHub URLs for files, blame, commits, PRs, and repos directly from any Neovim buffer.

![gh-navigator demo](gh-navigator.gif)

*`:GH!` copies the URL to the clipboard — without `!`, it opens in your browser.*

## 📋 Requirements

- **Neovim 0.10+**
- **[GitHub CLI](https://cli.github.com/)** (`gh`) — installed and authenticated

```shell
brew install gh
gh auth login
```

## 🛠️ Installation

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

## ✨ Usage

The plugin provides a single `:GH` command. The fastest way to use it is with no sub-command at all — it figures out what you mean.

### The Bare `GH` Command

Place your cursor on a commit SHA or PR number and run `:GH` with no arguments — the word under the cursor is used automatically. You can also pass an argument directly. `GH` tries to interpret it as a commit SHA first, then falls back to a PR search.

```vim
GH eef4a114e0bacc929d8335ef52b1b859d40097f4
GH 1234
GH refactor the actor class
```

### Explicit Sub-Commands

When you want to skip the inference and be explicit, use a sub-command. Tab completion is available for all sub-commands and their arguments.

| Sub-Command | Description |
|--------------------|:---------------|
| `GH blame` | Opens the current file in GitHub's blame view. |
| `GH browse` | Opens the current file in GitHub's blob view. |
| `GH compare` | Opens GitHub's compare view for the current branch against the default branch. |
| `GH pr <arg>` | Opens a PR by number or search term (e.g., `GH pr 1234` or `GH pr refactor the actor class`). Skips the commit check and searches PRs directly. |
| `GH sha <ref>` | Opens a commit by SHA. Useful when a SHA is purely numeric and would otherwise be treated as a PR number. |
| `GH repo <path>` | Opens a path in the current repo on GitHub (e.g., `GH repo issues`). Tab-completable paths include *issues*, *pulls*, *actions*, *releases*, etc. |

### Visual Line Ranges

Both `GH browse` and `GH blame` accept a visual range. Select lines in visual mode (**V**) and run the command to open that exact selection on GitHub.

```vim
" Select lines, then:
:'<,'>GH browse
:'<,'>GH blame
```

### Copy to Clipboard

Append `!` to any command to copy the URL to the system clipboard instead of opening it in the browser.

```vim
GH! pr 1234
GH! browse
GH! blame
GH! repo issues
```

### Repo Pages

Use `GH repo` to jump to top-level pages of the current repository. Tab completion lists all available paths.

```vim
GH repo issues
GH repo pulls
GH repo actions
GH repo releases
```

### Compare

Open GitHub's compare view for the current branch against the default branch.

```vim
GH compare
```

### Per-Buffer Repo Detection

The plugin detects the Git repository from the current buffer's file path, not from Neovim's working directory. This means you can open Neovim in a parent folder and edit files across multiple repos without any issues.

### ⌨️ Keymaps

No keymaps are set by default. Here are some examples:

```lua
-- Open and navigate
vim.keymap.set('n', '<leader>go', '<cmd>GH<cr>', { desc = 'GH: open commit or PR' })
vim.keymap.set('n', '<leader>gf', '<cmd>GH browse<cr>', { desc = 'GH: browse file' })
vim.keymap.set('n', '<leader>gb', '<cmd>GH blame<cr>', { desc = 'GH: blame file' })
vim.keymap.set('n', '<leader>gc', '<cmd>GH compare<cr>', { desc = 'GH: compare branch' })

-- Visual mode (line ranges)
vim.keymap.set('v', '<leader>gf', ':GH browse<cr>', { desc = 'GH: browse selection' })
vim.keymap.set('v', '<leader>gb', ':GH blame<cr>', { desc = 'GH: blame selection' })

-- Copy URL to clipboard (! variant)
vim.keymap.set('n', '<leader>gF', '<cmd>GH! browse<cr>', { desc = 'GH: copy file URL' })
vim.keymap.set('n', '<leader>gB', '<cmd>GH! blame<cr>', { desc = 'GH: copy blame URL' })
vim.keymap.set('v', '<leader>gF', ':GH! browse<cr>', { desc = 'GH: copy selection URL' })
vim.keymap.set('v', '<leader>gB', ':GH! blame<cr>', { desc = 'GH: copy blame selection URL' })
```

## 🔧 Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```

This activates a pre-commit hook that auto-generates `doc/gh-navigator.nvim.txt` from `README.md` whenever the README is staged. Requires [pandoc](https://pandoc.org/installing.html).
