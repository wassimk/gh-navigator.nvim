# README demo for gh-navigator.nvim
#
# Render from the repo root (gh must be installed and authenticated):
#   vhs demo/gh-navigator.tape
#
# demo/setup.sh clones this repo into /tmp/gh-navigator-demo so gh has a real GitHub repo to look up.

Output gh-navigator.gif

Require bash
Require git
Require gh
Require nvim

Set Shell "bash"
Set FontFamily "MonoLisaCode, JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1000
Set Height 600
Set Padding 16
Set Theme "OneHalfDark"
Set TypingSpeed 60ms
Set CursorBlink false

# Setup: fresh clone, then open a plugin file in nvim with the minimal config
Hide
Type "bash demo/setup.sh && source /tmp/gh-navigator-demo/env.sh && cd /tmp/gh-navigator-demo/gh-navigator.nvim && nvim -u $DEMO_INIT lua/gh-navigator/init.lua"
Enter
Wait+Screen@60s /function M\.setup/
Sleep 1s
Show

Sleep 800ms

# Browse a selection of lines
Type "10G"
Sleep 400ms
Type "V"
Down@120ms 11
Sleep 600ms
Type ":GH! browse"
Sleep 500ms
Enter
Wait+Screen /L10-L21/
Sleep 2.5s

# Blame the same lines
Type "gv"
Sleep 400ms
Type ":GH! blame"
Sleep 500ms
Enter
Wait+Screen /blame\//
Sleep 2.5s

# Blame popup from gitsigns (<leader>hh), then bare GH on the commit SHA under the cursor
Escape
Sleep 300ms
Space
Type "hh"
Wait+Screen /extract open_or_copy/
Sleep 1.5s
# Pressing it again moves the cursor into the popup, onto the SHA
Space
Type "hh"
Sleep 800ms
Type ":GH!"
Sleep 500ms
Enter
Wait+Screen /commit\//
Sleep 2.5s
# Find the PR that commit came from, also using the SHA under the cursor
Type ":GH! pr"
Sleep 500ms
Enter
Wait+Screen /pull\/12/
Sleep 2.5s
Type ":q"
Enter
Sleep 600ms

# Search PRs, then narrow the matches in the picker
Type ":GH! pr README"
Sleep 500ms
Enter
Wait+Screen /Select a PR/
Sleep 1.5s
Type "badges"
Sleep 1s
Enter
Wait+Screen /pull\/34/
Sleep 2.5s

# Jump to a repo page
Type ":GH! repo issues"
Sleep 500ms
Enter
Wait+Screen /\/issues/

# Hold on the result before looping
Sleep 3s
