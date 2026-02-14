local helpers = require('helpers')

describe('gh-navigator', function()
  local captured_gh_cmd, captured_complete
  local spy_calls
  local is_commit_return

  local function setup_plugin()
    spy_calls = {}
    is_commit_return = false

    package.loaded['gh-navigator'] = nil
    package.loaded['gh-navigator.init'] = nil
    package.loaded['gh-navigator.utils'] = nil

    local utils = require('gh-navigator.utils')
    utils.gh_cli_installed = function()
      return true
    end
    utils.buf_repo_dir = function()
      return '/mock/repo'
    end
    utils.buf_relative_path = function(_)
      return helpers.expand_result or 'current_file.lua'
    end
    utils.is_commit = function(arg)
      table.insert(spy_calls, { fn = 'is_commit', args = { arg } })
      return is_commit_return
    end
    utils.open_commit = function(sha, bang)
      table.insert(spy_calls, { fn = 'open_commit', args = { sha, bang } })
    end
    utils.open_pr = function(arg, bang)
      table.insert(spy_calls, { fn = 'open_pr', args = { arg, bang } })
    end
    utils.open_blame = function(filename, bang)
      table.insert(spy_calls, { fn = 'open_blame', args = { filename, bang } })
    end
    utils.open_file = function(filename, bang)
      table.insert(spy_calls, { fn = 'open_file', args = { filename, bang } })
    end
    utils.open_repo = function(path, bang)
      table.insert(spy_calls, { fn = 'open_repo', args = { path, bang } })
    end
    utils.open_compare = function(bang)
      table.insert(spy_calls, { fn = 'open_compare', args = { bang } })
    end

    -- Capture the command callback and completion function
    local orig_create = vim.api.nvim_create_user_command
    vim.api.nvim_create_user_command = function(name, callback, opts)
      if name == 'GH' then
        captured_gh_cmd = callback
        captured_complete = opts.complete
      end
      orig_create(name, callback, opts)
    end

    require('gh-navigator').setup()

    vim.api.nvim_create_user_command = orig_create
  end

  before_each(function()
    helpers.setup_mocks()
    pcall(vim.api.nvim_del_user_command, 'GH')
    setup_plugin()
  end)

  after_each(function()
    pcall(vim.api.nvim_del_user_command, 'GH')
    helpers.teardown_mocks()
  end)

  -- Helper: filter spy_calls by function name
  local function calls_to(fn_name)
    return vim.tbl_filter(function(c)
      return c.fn == fn_name
    end, spy_calls)
  end

  describe('setup', function()
    it('does not create GH command when gh cli is not installed', function()
      pcall(vim.api.nvim_del_user_command, 'GH')

      package.loaded['gh-navigator'] = nil
      package.loaded['gh-navigator.init'] = nil
      package.loaded['gh-navigator.utils'] = nil

      local utils = require('gh-navigator.utils')
      utils.gh_cli_installed = function()
        return false
      end

      require('gh-navigator').setup()

      assert.equals(0, vim.fn.exists(':GH'))
    end)

    it('registers GH command when guards pass', function()
      assert.equals(2, vim.fn.exists(':GH'))
    end)
  end)

  describe('command dispatch', function()
    it('calls open_commit when word under cursor is a commit', function()
      is_commit_return = true
      helpers.expand_result = 'abc123'

      captured_gh_cmd({
        args = '',
        fargs = {},
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local commits = calls_to('open_commit')
      assert.equals(1, #commits)
      assert.equals('abc123', commits[1].args[1])
      assert.is_false(commits[1].args[2])
    end)

    it('calls open_pr when word under cursor is not a commit', function()
      is_commit_return = false
      helpers.expand_result = 'some-word'

      captured_gh_cmd({
        args = '',
        fargs = {},
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local prs = calls_to('open_pr')
      assert.equals(1, #prs)
      assert.equals('some-word', prs[1].args[1])
      assert.is_false(prs[1].args[2])
    end)

    it('dispatches browse subcommand to open_file', function()
      helpers.expand_result = 'current_file.lua'

      captured_gh_cmd({
        args = 'browse',
        fargs = { 'browse' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local files = calls_to('open_file')
      assert.equals(1, #files)
      assert.equals('current_file.lua', files[1].args[1])
    end)

    it('dispatches browse with explicit filename', function()
      captured_gh_cmd({
        args = 'browse lua/init.lua',
        fargs = { 'browse', 'lua/init.lua' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local files = calls_to('open_file')
      assert.equals(1, #files)
      assert.equals('lua/init.lua', files[1].args[1])
    end)

    it('dispatches blame subcommand to open_blame', function()
      helpers.expand_result = 'current_file.lua'

      captured_gh_cmd({
        args = 'blame',
        fargs = { 'blame' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local blames = calls_to('open_blame')
      assert.equals(1, #blames)
      assert.equals('current_file.lua', blames[1].args[1])
    end)

    it('dispatches pr subcommand to open_pr', function()
      captured_gh_cmd({
        args = 'pr 42',
        fargs = { 'pr', '42' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local prs = calls_to('open_pr')
      assert.equals(1, #prs)
      assert.equals('42', prs[1].args[1])
    end)

    it('dispatches sha subcommand to open_commit', function()
      captured_gh_cmd({
        args = 'sha abc123',
        fargs = { 'sha', 'abc123' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local commits = calls_to('open_commit')
      assert.equals(1, #commits)
      assert.equals('abc123', commits[1].args[1])
      assert.is_false(commits[1].args[2])
    end)

    it('dispatches compare subcommand to open_compare', function()
      captured_gh_cmd({
        args = 'compare',
        fargs = { 'compare' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local compares = calls_to('open_compare')
      assert.equals(1, #compares)
      assert.is_false(compares[1].args[1])
    end)

    it('dispatches repo subcommand to open_repo', function()
      captured_gh_cmd({
        args = 'repo issues',
        fargs = { 'repo', 'issues' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local repos = calls_to('open_repo')
      assert.equals(1, #repos)
      assert.equals('issues', repos[1].args[1])
    end)

    it('falls back to commit detection for unknown subcommand', function()
      is_commit_return = true

      captured_gh_cmd({
        args = 'abc123def',
        fargs = { 'abc123def' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local commits = calls_to('open_commit')
      assert.equals(1, #commits)
      assert.equals('abc123def', commits[1].args[1])
    end)

    it('falls back to open_pr for unknown non-commit subcommand', function()
      is_commit_return = false

      captured_gh_cmd({
        args = 'some-query',
        fargs = { 'some-query' },
        bang = false,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local prs = calls_to('open_pr')
      assert.equals(1, #prs)
      assert.equals('some-query', prs[1].args[1])
    end)

    it('blame includes line range with range opts', function()
      helpers.expand_result = 'lua/init.lua'

      captured_gh_cmd({
        args = 'blame',
        fargs = { 'blame' },
        bang = false,
        range = 2,
        line1 = 5,
        line2 = 10,
      })

      local blames = calls_to('open_blame')
      assert.equals(1, #blames)
      assert.equals('lua/init.lua#L5-L10', blames[1].args[1])
    end)

    it('browse includes line range with range opts', function()
      helpers.expand_result = 'lua/init.lua'

      captured_gh_cmd({
        args = 'browse',
        fargs = { 'browse' },
        bang = false,
        range = 2,
        line1 = 5,
        line2 = 10,
      })

      local files = calls_to('open_file')
      assert.equals(1, #files)
      assert.equals('lua/init.lua:5-10', files[1].args[1])
    end)

    it('passes bang flag through to handler', function()
      is_commit_return = true
      helpers.expand_result = 'abc123'

      captured_gh_cmd({
        args = '',
        fargs = {},
        bang = true,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local commits = calls_to('open_commit')
      assert.equals(1, #commits)
      assert.is_true(commits[1].args[2])
    end)

    it('passes bang flag through to subcommand', function()
      helpers.expand_result = 'file.lua'

      captured_gh_cmd({
        args = 'browse',
        fargs = { 'browse' },
        bang = true,
        range = 0,
        line1 = 0,
        line2 = 0,
      })

      local files = calls_to('open_file')
      assert.equals(1, #files)
      assert.is_true(files[1].args[2])
    end)
  end)

  describe('completion', function()
    it('returns all subcommands for bare GH', function()
      local result = captured_complete('', 'GH ', 3)

      assert.is_not_nil(result)
      table.sort(result)
      assert.same({ 'blame', 'browse', 'compare', 'pr', 'repo', 'sha' }, result)
    end)

    it('filters subcommands by prefix', function()
      local result = captured_complete('b', 'GH b', 4)

      assert.is_not_nil(result)
      table.sort(result)
      assert.same({ 'blame', 'browse' }, result)
    end)

    it('completes repo sub-arguments', function()
      local result = captured_complete('wi', 'GH repo wi', 10)

      assert.is_not_nil(result)
      assert.same({ 'wikis' }, result)
    end)

    it('returns all subcommands with visual range prefix', function()
      local result = captured_complete('', "'<,'>GH ", 8)

      assert.is_not_nil(result)
      table.sort(result)
      assert.same({ 'blame', 'browse', 'compare', 'pr', 'repo', 'sha' }, result)
    end)

    it('returns all subcommands with bang', function()
      local result = captured_complete('', 'GH! ', 4)

      assert.is_not_nil(result)
      table.sort(result)
      assert.same({ 'blame', 'browse', 'compare', 'pr', 'repo', 'sha' }, result)
    end)

    it('returns nil for subcommand without completer', function()
      local result = captured_complete('', 'GH browse ', 10)

      assert.is_nil(result)
    end)
  end)
end)
