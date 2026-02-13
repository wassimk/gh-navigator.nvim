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

  describe('in_github_repo', function()
    it('returns true for non-empty system output', function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')

      assert.is_true(utils.in_github_repo())
    end)

    it('returns false silently for empty system output', function()
      -- default mock returns '' when no pattern matches
      assert.is_false(utils.in_github_repo())
      assert.equals(0, #helpers.notifications)
    end)
  end)

  describe('is_commit', function()
    it('returns true for clean rev-parse output', function()
      helpers.set_system_response('git rev-parse', 'abc123def456\n')

      assert.is_true(utils.is_commit('abc123def456'))
    end)

    it('returns false when output contains fatal', function()
      helpers.set_system_response('git rev-parse', 'fatal: Needed a single revision\n')

      assert.is_false(utils.is_commit('not-a-commit'))
    end)
  end)

  describe('open_compare', function()
    before_each(function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')
      helpers.set_system_response('git branch', 'feature-branch\n')
    end)

    it('constructs compare URL and opens it', function()
      utils.open_compare(false)

      assert.equals('https://github.com/owner/repo/compare/feature-branch', helpers.opened_url)
    end)

    it('copies compare URL to clipboard with bang', function()
      utils.open_compare(true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/compare/feature-branch', helpers.last_register_value)
    end)
  end)

  describe('open_blame', function()
    before_each(function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')
      helpers.set_system_response('git branch', 'main\n')
    end)

    it('constructs blame URL and opens it', function()
      utils.open_blame('lua/init.lua', false)

      assert.equals('https://github.com/owner/repo/blame/main/lua/init.lua', helpers.opened_url)
    end)

    it('copies blame URL to clipboard with bang', function()
      utils.open_blame('lua/init.lua', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/blame/main/lua/init.lua', helpers.last_register_value)
    end)

    it('includes line range fragment in URL', function()
      utils.open_blame('lua/init.lua#L5-L10', false)

      assert.equals('https://github.com/owner/repo/blame/main/lua/init.lua#L5-L10', helpers.opened_url)
    end)
  end)

  describe('open_commit', function()
    it('opens commit URL from gh browse', function()
      helpers.set_system_response('gh browse', 'https://github.com/owner/repo/commit/abc123\n')

      utils.open_commit('abc123', false)

      assert.equals('https://github.com/owner/repo/commit/abc123', helpers.opened_url)
    end)

    it('copies commit URL to clipboard with bang', function()
      helpers.set_system_response('gh browse', 'https://github.com/owner/repo/commit/abc123\n')

      utils.open_commit('abc123', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/commit/abc123', helpers.last_register_value)
    end)
  end)

  describe('open_file', function()
    it('opens file URL from gh browse', function()
      helpers.set_system_response('gh browse', 'https://github.com/owner/repo/blob/main/lua/init.lua\n')

      utils.open_file('lua/init.lua', false)

      assert.equals('https://github.com/owner/repo/blob/main/lua/init.lua', helpers.opened_url)
    end)

    it('copies file URL to clipboard with bang', function()
      helpers.set_system_response('gh browse', 'https://github.com/owner/repo/blob/main/lua/init.lua\n')

      utils.open_file('lua/init.lua', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/blob/main/lua/init.lua', helpers.last_register_value)
    end)
  end)

  describe('open_pr', function()
    it('opens PR by number', function()
      helpers.set_system_response('gh pr view', '{"url":"https://github.com/owner/repo/pull/42"}')

      utils.open_pr('42', false)

      assert.equals('https://github.com/owner/repo/pull/42', helpers.opened_url)
    end)

    it('copies PR URL to clipboard with bang when numeric', function()
      helpers.set_system_response('gh pr view', '{"url":"https://github.com/owner/repo/pull/42"}')

      utils.open_pr('42', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/pull/42', helpers.last_register_value)
    end)

    it('opens single search result directly', function()
      local results = vim.json.encode({
        { number = 1, title = 'Fix bug', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
      })
      helpers.set_system_response('gh pr list', results)

      utils.open_pr('fix bug', false)

      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('presents vim.ui.select for multiple search results', function()
      local results = vim.json.encode({
        { number = 1, title = 'Fix bug A', author = { name = 'Alice' }, url = 'https://github.com/owner/repo/pull/1' },
        { number = 2, title = 'Fix bug B', author = { name = 'Bob' }, url = 'https://github.com/owner/repo/pull/2' },
      })
      helpers.set_system_response('gh pr list', results)

      utils.open_pr('fix bug', false)

      assert.equals(2, #helpers.select_items)
      -- auto-selects first item
      assert.equals('https://github.com/owner/repo/pull/1', helpers.opened_url)
    end)

    it('notifies when no search results found', function()
      helpers.set_system_response('gh pr list', '[]')

      utils.open_pr('nonexistent', false)

      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('No PR found'))
    end)

    it('notifies when PR number not found (Could not resolve)', function()
      helpers.set_system_response('gh pr view', 'Could not resolve to a PullRequest')

      utils.open_pr('999', false)

      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('not found'))
    end)
  end)

  describe('open_repo', function()
    it('opens repo URL with path appended', function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('issues', false)

      assert.equals('https://github.com/owner/repo/issues', helpers.opened_url)
    end)

    it('copies repo URL to clipboard with bang', function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('pulls', true)

      assert.equals('+', helpers.last_register)
      assert.equals('https://github.com/owner/repo/pulls', helpers.last_register_value)
    end)

    it('opens repo root with empty path', function()
      helpers.set_system_response('gh repo view', '{"url":"https://github.com/owner/repo"}')

      utils.open_repo('', false)

      assert.equals('https://github.com/owner/repo/', helpers.opened_url)
    end)

    it('notifies error when no git remotes found', function()
      helpers.set_system_response('gh repo view', 'no git remotes found')

      utils.open_repo('issues', false)

      assert.equals(1, #helpers.notifications)
      assert.truthy(helpers.notifications[1].msg:find('Not in a GitHub'))
    end)
  end)
end)
