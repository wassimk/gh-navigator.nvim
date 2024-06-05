# gh-navigator.nvim

This Neovim plugin makes jumping from coding to GitHub as painless as possible.

[![build](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml/badge.svg)](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml) ![release](https://img.shields.io/github/v/release/wassimk/gh-navigator.nvim?logo=github)

## Setup

### Prerequisites

The plugin is mostly a wrapper around the [GitHub CLI](https://cli.github.com/), `gh`, with a few direct calls to `git`. So ensure the `gh` tool is installed and can connect to your GitHub account.

An example of how to setup `gh` for a macOS user is:

```shell
brew install gh
gh auth login
```

If you already have the `gh` tool installed, ensure it's working:

```shell
gh auth status
```

### Installation

Install **gh-navigator** using your plugin manager of choice. For example, here it is using [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  'wassimk/gh-navigator.nvim',
  version = "*",
  config = true
}
```

I'll also be actively developing this plugin using the `main` branch, so use versioned releases with the `version` key to avoid unexpected breaking changes.

### Commands

| Command | Description |
|---------|:------------|
| `GH` | Heuristically open commit sha or PR using number or search term(s) |
| `GHBlame` | Open the current file in blame view |
| `GHFile` | Open the current file in blob view |
| `GHPR` | Open PR by commit SHA, PR number, or search term(s) |
| `GHRepo` | Open the current repo |

### Usage

Move the cursor over a sha, PR number, or word and execute the commands. The word under the cursor will be the argument.

You can also call them with an argument. `:GHPR 1234` or `:GHPR c2d25b3` or `:GH refactor the actor class`

Most commands accept a range. For example, highlight the lines you want to blame and execute `:GHBlame`.

