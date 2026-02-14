local helpers = require('helpers')

describe('gh-navigator.utils', function()
  local utils

  before_each(function()
    helpers.setup_mocks()
    package.loaded['gh-navigator.utils'] = nil
    utils = require('gh-navigator.utils')
  end)

  after_each(function()
    helpers.teardown_mocks()
    package.loaded['gh-navigator.utils'] = nil
  end)

  --- Set up mocks so buf_repo_dir() returns the given repo root.
  local function mock_buf_repo(repo_root, buf_dir)
    helpers.expand_results['%:p:h'] = buf_dir or repo_root .. '/lua'
    helpers.set_system_response('rev-parse --show-toplevel', repo_root .. '\n')
  end

  describe('gh_cli_installed', function()
    it('returns true when gh is executable', function()
      vim.fn.executable = function(_)
        return 1
      end

      assert.is_true(utils.gh_cli_installed())
    end)

    it('returns false and notifies when gh is not executable', function()
      vim.fn.executable = function(_)
        return 0
      end

      assert.is_false(utils.gh_cli_installed())
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('GitHub CLI'))
    end)
  end)

  describe('buf_repo_dir', function()
    it('returns repo root for a buffer inside a git repo', function()
      helpers.expand_results['%:p:h'] = '/home/user/project/src'
      helpers.set_system_response('rev-parse --show-toplevel', '/home/user/project\n')

      assert.equals('/home/user/project', utils.buf_repo_dir())
    end)

    it('returns nil when buffer has no file', function()
      helpers.expand_results['%:p:h'] = ''

      -- Mock: no normal windows with files either
      vim.api.nvim_list_wins = function()
        return {}
      end

      assert.is_nil(utils.buf_repo_dir())
    end)

    it('falls back to normal window buffer for floats', function()
      helpers.expand_results['%:p:h'] = ''
      helpers.set_system_response('rev-parse --show-toplevel', '/home/user/project\n')

      vim.api.nvim_list_wins = function()
        return { 1001, 1002 }
      end
      vim.api.nvim_win_get_config = function(win)
        if win == 1001 then
          return { relative = 'editor' } -- float
        end
        return { relative = '' } -- normal
      end
      vim.api.nvim_win_get_buf = function(_)
        return 42
      end
      vim.api.nvim_buf_get_name = function(_)
        return '/home/user/project/src/main.lua'
      end
      vim.fn.fnamemodify = function(name, mod)
        if mod == ':h' then
          return name:match('(.+)/[^/]+$') or name
        end
        return name
      end

      assert.equals('/home/user/project', utils.buf_repo_dir())
    end)

    it('returns nil when not in a git repo', function()
      helpers.expand_results['%:p:h'] = '/tmp/no-repo'
      helpers.set_system_response('rev-parse --show-toplevel', 'fatal: not a git repository\n', 128)

      vim.api.nvim_list_wins = function()
        return {}
      end

      assert.is_nil(utils.buf_repo_dir())
    end)

    it('falls back to normal window when current buffer path is not in a repo', function()
      helpers.expand_results['%:p:h'] = '/tmp/scratch'

      local call_count = 0
      vim.system = function(cmd, _)
        call_count = call_count + 1
        if call_count == 1 then
          -- First call: current buffer's dir fails
          return {
            wait = function()
              return { stdout = 'fatal: not a git repository\n', stderr = '', code = 128 }
            end,
          }
        else
          -- Second call: normal window's buffer succeeds
          return {
            wait = function()
              return { stdout = '/home/user/project\n', stderr = '', code = 0 }
            end,
          }
        end
      end

      vim.api.nvim_list_wins = function()
        return { 1001 }
      end
      vim.api.nvim_win_get_config = function(_)
        return { relative = '' }
      end
      vim.api.nvim_win_get_buf = function(_)
        return 42
      end
      vim.api.nvim_buf_get_name = function(_)
        return '/home/user/project/src/main.lua'
      end
      vim.fn.fnamemodify = function(name, mod)
        if mod == ':h' then
          return name:match('(.+)/[^/]+$') or name
        end
        return name
      end

      assert.equals('/home/user/project', utils.buf_repo_dir())
    end)

    it('returns nil when float and no normal windows have files', function()
      helpers.expand_results['%:p:h'] = ''

      vim.api.nvim_list_wins = function()
        return { 1001 }
      end
      vim.api.nvim_win_get_config = function(_)
        return { relative = 'editor' } -- float only
      end

      assert.is_nil(utils.buf_repo_dir())
    end)
  end)

  describe('buf_relative_path', function()
    it('returns path relative to repo root', function()
      helpers.expand_results['%:p'] = '/home/user/project/src/main.lua'

      assert.equals('src/main.lua', utils.buf_relative_path('/home/user/project'))
    end)

    it('returns nil when buffer has no file', function()
      helpers.expand_results['%:p'] = ''

      assert.is_nil(utils.buf_relative_path('/home/user/project'))
    end)
  end)

  describe('is_commit', function()
    it('returns true for clean rev-parse output', function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('rev-parse --verify', 'abc123def456\n')

      assert.is_true(utils.is_commit('abc123def456'))
    end)

    it('returns false for non-zero exit code', function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('rev-parse --verify', 'fatal: Needed a single revision\n', 128)

      assert.is_false(utils.is_commit('not-a-commit'))
    end)

    it('returns false when not in a repo', function()
      helpers.expand_results['%:p:h'] = ''

      assert.is_false(utils.is_commit('abc123'))
    end)
  end)

  describe('open_compare', function()
    before_each(function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')
      helpers.set_system_response('rev-parse --abbrev-ref HEAD', 'my-feature-branch\n')
    end)

    it('constructs compare URL with branch name and opens it', function()
      utils.open_compare(false)

      assert.equals('https://github.com/owner/repo/compare/my-feature-branch', helpers.opened_url)
    end)

    it('copies compare URL to clipboard with bang', function()
      utils.open_compare(true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/compare/my-feature-branch', helpers.last_register_value)
    end)

    it('notifies when not in a repo', function()
      helpers.expand_results['%:p:h'] = ''

      utils.open_compare(false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Not in a Git repository'))
    end)

    it('notifies when gh repo view fails', function()
      helpers.clear_system_responses()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '', 1)

      utils.open_compare(false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Could not determine GitHub repository URL'))
    end)
  end)

  describe('open_blame', function()
    before_each(function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')
      helpers.set_system_response('rev-parse HEAD', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2\n')
    end)

    it('constructs blame URL with commit SHA and opens it', function()
      utils.open_blame('lua/init.lua', false)

      assert.equals(
        'https://github.com/owner/repo/blame/a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2/lua/init.lua',
        helpers.opened_url
      )
    end)

    it('copies blame URL to clipboard with bang', function()
      utils.open_blame('lua/init.lua', true)

      assert.equals('+', helpers.last_register)
      assert.equals(
        'https://github.com/owner/repo/blame/a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2/lua/init.lua',
        helpers.last_register_value
      )
    end)

    it('includes line range fragment in URL', function()
      utils.open_blame('lua/init.lua#L5-L10', false)

      assert.equals(
        'https://github.com/owner/repo/blame/a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2/lua/init.lua#L5-L10',
        helpers.opened_url
      )
    end)

    it('notifies when gh repo view fails', function()
      helpers.clear_system_responses()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '', 1)

      utils.open_blame('lua/init.lua', false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Could not determine GitHub repository URL'))
    end)
  end)

  describe('open_commit', function()
    before_each(function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')
    end)

    it('constructs commit URL and opens it', function()
      utils.open_commit('abc123', false)

      assert.equals('https://github.com/owner/repo/commit/abc123', helpers.opened_url)
    end)

    it('copies commit URL to clipboard with bang', function()
      utils.open_commit('abc123', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/commit/abc123', helpers.last_register_value)
    end)

    it('handles purely numeric sha without treating it as an issue', function()
      utils.open_commit('36234615', false)

      assert.equals('https://github.com/owner/repo/commit/36234615', helpers.opened_url)
    end)

    it('notifies when gh repo view fails', function()
      helpers.clear_system_responses()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('repo view', '', 1)

      utils.open_commit('abc123', false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Could not determine GitHub repository URL'))
    end)
  end)

  describe('open_file', function()
    it('opens file URL from gh browse', function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('rev-parse HEAD', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2\n')
      helpers.set_system_response('browse', 'https://github.com/owner/repo/blob/a1b2c3d4/lua/init.lua\n')

      utils.open_file('lua/init.lua', false)

      assert.equals('https://github.com/owner/repo/blob/a1b2c3d4/lua/init.lua', helpers.opened_url)
    end)

    it('copies file URL to clipboard with bang', function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('rev-parse HEAD', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2\n')
      helpers.set_system_response('browse', 'https://github.com/owner/repo/blob/a1b2c3d4/lua/init.lua\n')

      utils.open_file('lua/init.lua', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/blob/a1b2c3d4/lua/init.lua', helpers.last_register_value)
    end)

    it('notifies when gh browse fails', function()
      mock_buf_repo('/mock/repo')
      helpers.set_system_response('rev-parse HEAD', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2\n')
      helpers.set_system_response('browse', '', 1)

      utils.open_file('nonexistent.lua', false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Could not determine GitHub repository URL'))
    end)
  end)

  describe('open_pr', function()
    before_each(function()
      mock_buf_repo('/mock/repo')
    end)

    it('opens PR by number', function()
      helpers.set_system_response('pr view', '{"url":"https://github.com/owner/repo/pull/42"}')

      utils.open_pr('42', false)

      assert.equals('https://github.com/owner/repo/pull/42', helpers.opened_url)
    end)

    it('copies PR URL to clipboard with bang when numeric', function()
      helpers.set_system_response('pr view', '{"url":"https://github.com/owner/repo/pull/42"}')

      utils.open_pr('42', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/pull/42', helpers.last_register_value)
    end)

    it('opens single search result directly', function()
      local results = vim.json.encode({
        { number = 1, title = 'Fix bug', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
      })
      helpers.set_system_response('pr list', results)

      utils.open_pr('fix bug', false)

      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('presents vim.ui.select for multiple search results', function()
      local results = vim.json.encode({
        { number = 1, title = 'Fix bug A', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
        { number = 2, title = 'Fix bug B', author = { name = 'Bob' }, url = 'https://github.com/owner/repo/pull/2' },
      })
      helpers.set_system_response('pr list', results)

      utils.open_pr('fix bug', false)

      assert.equals(2, #helpers.select_items)
      -- auto-selects first item
      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('notifies when no search results found', function()
      helpers.set_system_response('pr list', '[]')

      utils.open_pr('nonexistent', false)

      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('No PR found'))
    end)

    it('notifies when PR number not found', function()
      helpers.set_system_response('pr view', '', 1)

      utils.open_pr('999', false)

      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('not found'))
    end)

    it('includes PRs of all states in search results', function()
      local results = vim.json.encode({
        { number = 1, title = 'Merged PR', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
        { number = 2, title = 'Closed PR', author = { name = 'Bob' }, url = 'https://github.com/owner/repo/pull/2' },
        { number = 3, title = 'Open PR', author = { name = 'Carol' }, url = 'https://github.com/owner/repo/pull/3' },
      })
      helpers.set_system_response('pr list', results)

      utils.open_pr('fix bug', false)

      assert.equals(3, #helpers.select_items)
      -- auto-selects first item
      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('handles PR with nil author gracefully', function()
      local results = vim.json.encode({
        { number = 1, title = 'Orphaned PR', author = vim.NIL, url = 'https://github.com/owner/repo/pull/1' },
      })
      helpers.set_system_response('pr list', results)

      utils.open_pr('orphaned', false)

      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('treats commit sha with scientific notation chars as search query', function()
      local results = vim.json.encode({
        { number = 1, title = 'Old commit', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
      })
      helpers.set_system_response('pr list', results)

      utils.open_pr('36e54817', false)

      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('notifies when pr search command fails', function()
      helpers.set_system_response('pr list', '', 1)

      utils.open_pr('some query', false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('PR search failed'))
    end)
  end)

  describe('open_repo', function()
    before_each(function()
      mock_buf_repo('/mock/repo')
    end)

    it('opens repo URL with path appended', function()
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('issues', false)

      assert.equals('https://github.com/owner/repo/issues', helpers.opened_url)
    end)

    it('copies repo URL to clipboard with bang', function()
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('pulls', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/pulls', helpers.last_register_value)
    end)

    it('opens repo root with empty path', function()
      helpers.set_system_response('repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('', false)

      assert.equals('https://github.com/owner/repo', helpers.opened_url)
    end)

    it('notifies error when gh repo view fails', function()
      helpers.set_system_response('repo view', '', 1)

      utils.open_repo('issues', false)

      assert.is_nil(helpers.opened_url)
      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Could not determine GitHub repository URL'))
    end)
  end)
end)
