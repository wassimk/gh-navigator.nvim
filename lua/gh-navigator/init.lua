local M = {}

function M.setup()
  local utils = require('gh-navigator.utils')

  if not utils.gh_cli_installed() then
    return
  end

  if not utils.in_github_repo() then
    return
  end

  vim.api.nvim_create_user_command(
    'GH',
    function(command)
      local arg = command.args
      if arg == '' then
        arg = vim.fn.expand('<cword>')
      end

      if utils.is_commit(arg) then
        utils.open_commit(arg)
      else
        utils.open_pr(arg)
      end
    end,
    { force = true, nargs = '?', desc = 'Heuristically open commit sha or PR in GitHub using number or search term(s)' }
  )

  vim.api.nvim_create_user_command('GHBlame', function(command)
    local filename = command.args
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if command.range == 0 then
      utils.open_blame(filename)
    else
      filename = filename .. '#' .. 'L' .. command.line1 .. '-' .. 'L' .. command.line2
      utils.open_blame(filename)
    end
  end, { force = true, range = true, nargs = '?', desc = 'Open blame in GitHub' })

  vim.api.nvim_create_user_command('GHBrowse', function(command)
    local filename = command.args
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if command.range == 0 then
      utils.open_file(filename)
    else
      filename = filename .. ':' .. command.line1 .. '-' .. command.line2
      utils.open_file(filename)
    end
  end, { force = true, range = true, nargs = '?', desc = 'Browse to file in GitHub' })

  vim.api.nvim_create_user_command('GHFile', function(command)
    vim.deprecate('GHFile', 'GHBrowse', 'v0.2.0', 'gh-navigator', false)

    local filename = command.args
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if command.range == 0 then
      utils.open_file(filename)
    else
      filename = filename .. ':' .. command.line1 .. '-' .. command.line2
      utils.open_file(filename)
    end
  end, { force = true, range = true, nargs = '?', desc = 'Open file in GitHub' })

  vim.api.nvim_create_user_command('GHPR', function(command)
    local arg = command.args
    if arg == '' then
      arg = vim.fn.expand('<cword>')
    end

    utils.open_pr(arg)
  end, { force = true, nargs = '?', desc = 'Open PR in GitHub using commit sha, number, or search term(s)' })

  vim.api.nvim_create_user_command('GHRepo', function()
    utils.open_repo()
  end, { force = true, desc = 'Open GitHub repository' })
end

return M
