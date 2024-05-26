local M = {}

function M.setup()
  local utils = require('gh-navigator.utils')

  if not utils.gh_cli_installed() then
    return
  end

  if not utils.in_github_repo() then
    return
  end

  vim.api.nvim_create_user_command('GHFile', function(command)
    local arg = command.args
    if arg == '' then
      arg = vim.fn.expand('%')
    end

    utils.open_file(arg)
  end, { force = true, nargs = '?', desc = 'Open file in GitHub' })

  vim.api.nvim_create_user_command('GHPR', function(command)
    local arg = command.args
    if arg == '' then
      arg = vim.fn.expand('<cword>')
    end

    if tonumber(arg) then
      utils.open_pr_by_number(arg)
    else
      utils.open_pr_by_search(arg)
    end
  end, { force = true, nargs = '?', desc = 'Open PR using number, commit sha, or search term(s)' })

  vim.api.nvim_create_user_command('GHRepo', function()
    utils.open_repo()
  end, { force = true, desc = 'Open GitHub repository' })
end

return M
