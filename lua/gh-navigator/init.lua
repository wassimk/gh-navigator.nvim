local M = {}

function M.setup()
  local utils = require('gh-navigator.utils')

  if not utils.gh_cli_installed() then
    return
  end

  if not utils.in_github_repo() then
    return
  end

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
end

M.setup()

return M