# gh-navigator.nvim

This Neovim plugin makes jumping from coding to GitHub as painless as possible.

[![build](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml/badge.svg)](https://github.com/wassimk/gh-navigator.nvim/actions/workflows/build.yml) ![release](https://img.shields.io/github/v/release/wassimk/gh-navigator.nvim?logo=github)

## Setup

### Prerequisites

The plugin primarily acts as a wrapper for the [GitHub CLI](https://cli.github.com/) (`gh`), and also makes a few direct `git` calls. So ensure the `gh` tool is installed and can connect to your GitHub account. 

Here are instructions for macOS users:

1. Install `gh` and connect it to your GitHub account. 

```shell
brew install gh
gh auth login
```

2. If `gh` is already installed, check it's working with:

```shell
gh auth status
```

### Installation

Install **gh-navigator** via your preferred plugin manager. The following example uses [lazy.nvim](https://github.com/folke/lazy.nvim).

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

`GH` is the main command, but it accepts different sub-commands:

### `GH` Command

Open a commit or PR on GitHub by passing a commit SHA, PR number, or search term directly as an argument.

```vim
GH eef4a114e0bacc929d8335ef52b1b859d40097f4
GH 1234
GH refactor the actor class
```

When called with no arguments, the word under the cursor is used instead.

### Sub-Commands

| Sub-Command | Description |
|--------------------|:---------------|
| `GH blame` | Opens the current file in GitHub's blame view. |
| `GH browse` | Opens the current file in GitHub's blob view. |
| `GH pr <arg>` | Opens a PR based on a commit SHA, PR number, or search term (e.g., `GH pr 1234`, `GH pr c2d25b3`, or `GH pr refactor the actor class`). |
| `GH repo <path>` | Opens a certain path in the current repo on GitHub (e.g., `GH repo issues` opens the repo's issues page). Auto-completion is available for paths such as *issues, pulls, actions, releases*, etc.|

> [!Note]
> Both `GH browse` and `GH blame` can accept a range. For instance, in visual mode (**V**), select a set of lines and run `GH blame` to open the blame view for that selection.

### Copy to Clipboard

Append `!` to any command to copy the URL to the system clipboard instead of opening it in the browser.

```vim
GH! pr 1234
GH! browse
GH! blame
GH! repo issues
```
