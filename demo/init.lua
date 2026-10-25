--
-- Minimal config for recording the README demo with VHS (see demo/gh-navigator.tape)
--

local demo_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local plugin_dir = vim.fn.fnamemodify(demo_dir, ':h')

local function clone(url, dir, ref)
  if vim.fn.isdirectory(dir) == 0 then
    local cmd = { 'git', 'clone', '--depth', '1' }
    if ref then
      vim.list_extend(cmd, { '--branch', ref })
    end
    vim.list_extend(cmd, { url, dir })
    vim.fn.system(cmd)
  end
end

local onedark_dir = os.getenv('ONEDARK_DIR') or '/tmp/onedark.nvim'
local notify_dir = '/tmp/nvim-notify-v3.15.0'
local snacks_dir = '/tmp/snacks.nvim-v2.31.0'
local gitsigns_dir = '/tmp/gitsigns.nvim-v2.1.0'

clone('https://github.com/navarasu/onedark.nvim', onedark_dir)
clone('https://github.com/rcarriga/nvim-notify', notify_dir, 'v3.15.0')
clone('https://github.com/folke/snacks.nvim', snacks_dir, 'v2.31.0')
clone('https://github.com/lewis6991/gitsigns.nvim', gitsigns_dir, 'v2.1.0')

vim.opt.rtp:prepend(plugin_dir)
vim.opt.rtp:append(onedark_dir)
vim.opt.rtp:append(notify_dir)
vim.opt.rtp:append(snacks_dir)
vim.opt.rtp:append(gitsigns_dir)

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.wrap = false
vim.opt.shortmess:append('I')
vim.opt.statusline = ' %f %m%=%l:%c '
vim.opt.winborder = 'rounded'
-- Keys pressed for mappings stay off screen, so popups appear without showing how
vim.opt.showcmd = false
vim.g.mapleader = ' '

require('onedark').setup({ style = 'darker' })
require('onedark').load()

-- `:GH!` copies URLs to the clipboard. Swallow them so recording never touches the real clipboard.
local function noop() end
local function empty()
  return {}
end
vim.g.clipboard = {
  name = 'demo',
  copy = { ['+'] = noop, ['*'] = noop },
  paste = { ['+'] = empty, ['*'] = empty },
}

-- Notifications and vim.ui.select styled like the author's setup: nvim-notify and the snacks picker
require('notify').setup({ render = 'wrapped-compact', stages = 'static', timeout = 3500 })
vim.notify = require('notify')

require('snacks').setup({ picker = { enabled = true, ui_select = true } })

-- Blame popups, for running bare :GH! on the commit SHA under the cursor.
-- <leader>hh matches the author's mapping; pressing it again moves into the popup.
require('gitsigns').setup({
  on_attach = function(bufnr)
    vim.keymap.set('n', '<leader>hh', function()
      require('gitsigns').blame_line({ full = true })
    end, { buffer = bufnr, desc = 'blame line float' })
  end,
})

require('gh-navigator').setup()
