local M = {}

function M.setup()
  local utils = require('gh-navigator.utils')

  if not utils.gh_cli_installed() then
    return
  end

  if not utils.in_github_repo() then
    return
  end

  local function blame(args, opts)
    local filename = args[1] or ''
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if opts.range == 0 then
      utils.open_blame(filename)
    else
      filename = filename .. '#' .. 'L' .. opts.line1 .. '-' .. 'L' .. opts.line2
      utils.open_blame(filename)
    end
  end

  local function browse(args, opts)
    local filename = args[1] or ''
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if opts.range == 0 then
      utils.open_file(filename)
    else
      filename = filename .. ':' .. opts.line1 .. '-' .. opts.line2
      utils.open_file(filename)
    end
  end

  local function pr(args)
    local arg = table.concat(args, ' ')

    if arg == '' then
      arg = vim.fn.expand('<cword>')
    end
    utils.open_pr(arg)
  end

  local function repo(args)
    local arg = args and args[1] or ''

    utils.open_repo(arg)
  end

  local subcommand_tbl = {
    browse = {
      call = function(args, opts)
        browse(args, opts)
      end,
    },
    blame = {
      call = function(args, opts)
        blame(args, opts)
      end,
    },
    pr = {
      call = function(args)
        pr(args)
      end,
    },
    repo = {
      call = function(args)
        repo(args)
      end,
      complete = function(subcmd_arg_lead)
        local repo_args = {
          'actions',
          'discussions',
          'issues',
          'projects',
          'pulls',
          'pulse',
          'releases',
          'security',
          'settings',
          'wikis',
        }
        return vim
          .iter(repo_args)
          :filter(function(repo_arg)
            return repo_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
      end,
    },
  }

  local function gh_cmd(opts)
    local fargs = opts.fargs

    if #fargs == 0 then
      local arg = opts.args

      if arg == '' then
        arg = vim.fn.expand('<cword>')
      end

      if utils.is_commit(arg) then
        utils.open_commit(arg)
      else
        utils.open_pr(arg)
      end
    else
      local subcommand_key = fargs[1]
      local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
      local subcommand = subcommand_tbl[subcommand_key]
      if not subcommand then
        vim.notify('Unknown command: ' .. subcommand_key, vim.log.levels.ERROR, { title = 'GH Navigator' })
        return
      end
      subcommand.call(args, opts)
    end
  end

  vim.api.nvim_create_user_command('GH', gh_cmd, {
    nargs = '*',
    range = true,
    force = true,
    bang = false,
    desc = 'GitHub Navigator',
    complete = function(arg_lead, cmdline, _)
      local subcmd_key, subcmd_arg_lead = cmdline:match('^GH[!]*%s(%S+)%s(.*)$')
      if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
        return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
      end
      if cmdline:match('^GH[!]*%s+%w*$') then
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return vim
          .iter(subcommand_keys)
          :filter(function(key)
            return key:find(arg_lead) ~= nil
          end)
          :totable()
      end
    end,
  })

  vim.api.nvim_create_user_command('GHBlame', function(command)
    vim.deprecate('GHBlame', 'GH blame', 'v0.2.0', 'gh-navigator', false)
    blame(command.args, command)
  end, { force = true, range = true, nargs = '?', desc = 'Open blame in GitHub' })

  vim.api.nvim_create_user_command('GHBrowse', function(command)
    vim.deprecate('GHBrowse', 'GH browse', 'v0.2.0', 'gh-navigator', false)
    browse(command.args, command)
  end, { force = true, range = true, nargs = '?', desc = 'Browse to file in GitHub' })

  vim.api.nvim_create_user_command('GHFile', function(command)
    vim.deprecate('GHFile', 'GH browse', 'v0.2.0', 'gh-navigator', false)
    browse(command.args, command)
  end, { force = true, range = true, nargs = '?', desc = 'Open file in GitHub' })

  vim.api.nvim_create_user_command('GHPR', function(command)
    vim.deprecate('GHPR', 'GH pr', 'v0.2.0', 'gh-navigator', false)
    pr(command.fargs)
  end, { force = true, nargs = '?', desc = 'Open PR in GitHub using commit sha, number, or search term(s)' })

  vim.api.nvim_create_user_command('GHRepo', function(command)
    vim.deprecate('GHRepo', 'GH repo', 'v0.2.0', 'gh-navigator', false)
    repo(command.fargs)
  end, { force = true, nargs = '?', desc = 'Open GitHub repository' })
end

return M
