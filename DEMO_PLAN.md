# gh-navigator.nvim Demo Plan

## Record

```bash
asciinema rec demo.cast --cols 120 --rows 30 --idle-time-limit 2
```

Then inside the recorded shell:

```bash
nvim lua/gh-navigator/init.lua
```

## Script (4 commands)

### 1. Browse with line range

Select a few lines visually, then:
:GH! browse

### 3. Blame
:GH! blame

### 2. PR by number
:GH! pr 28

### 3. Commit sha
:GH!

### 5. PR search
:GH! pr testing


## Render GIF

```bash
agg --font-family "MonoLisa Variable,Symbols Nerd Font" --font-dir "$HOME/Library/Fonts" demo.cast demo.gif
```
