local plenary_dir = os.getenv('PLENARY_DIR') or '/tmp/plenary.nvim'

if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/nvim-lua/plenary.nvim',
    plenary_dir,
  })
end

vim.opt.rtp:append('.')
vim.opt.rtp:append(plenary_dir)

-- Allow spec files to require('helpers')
package.path = './tests/?.lua;' .. package.path

vim.cmd('runtime plugin/plenary.vim')
require('plenary.busted')
