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
      utils.open_blame(filename, opts.bang)
    else
      filename = filename .. '#' .. 'L' .. opts.line1 .. '-' .. 'L' .. opts.line2
      utils.open_blame(filename, opts.bang)
    end
  end

  local function browse(args, opts)
    local filename = args[1] or ''
    if filename == '' then
      filename = vim.fn.expand('%:.')
    end

    if opts.range == 0 then
      utils.open_file(filename, opts.bang)
    else
      filename = filename .. ':' .. opts.line1 .. '-' .. opts.line2
      utils.open_file(filename, opts.bang)
    end
  end

  local function pr(args, opts)
    local arg = table.concat(args, ' ')

    if arg == '' then
      arg = vim.fn.expand('<cword>')
    end
    utils.open_pr(arg, opts.bang)
  end

  local function repo(args, opts)
    local arg = args and args[1] or ''

    utils.open_repo(arg, opts.bang)
  end

  local function compare(_, opts)
    utils.open_compare(opts.bang)
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
    compare = {
      call = function(args, opts)
        compare(args, opts)
      end,
    },
    pr = {
      call = function(args, opts)
        pr(args, opts)
      end,
    },
    repo = {
      call = function(args, opts)
        repo(args, opts)
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
        utils.open_commit(arg, opts.bang)
      else
        utils.open_pr(arg, opts.bang)
      end
    else
      local subcommand_key = fargs[1]
      local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
      local subcommand = subcommand_tbl[subcommand_key]
      if not subcommand then
        local arg = opts.args
        if utils.is_commit(arg) then
          utils.open_commit(arg, opts.bang)
        else
          utils.open_pr(arg, opts.bang)
        end
        return
      end
      subcommand.call(args, opts)
    end
  end

  vim.api.nvim_create_user_command('GH', gh_cmd, {
    nargs = '*',
    range = true,
    force = true,
    bang = true,
    desc = 'GitHub Navigator',
    complete = function(arg_lead, cmdline, _)
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*GH[!]*%s(%S+)%s(.*)$")

      if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
        return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
      end

      if cmdline:match("^['<,'>]*GH[!]*%s+%w*$") then
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
end

return M
