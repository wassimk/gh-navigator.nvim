--
-- utils.lua
--

local M = {}

local function copy_to_clipboard(url)
  vim.fn.setreg('+', url)
  vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO, { title = 'GH Navigator' })
end

local function open_or_copy(url, bang)
  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

local async_coroutines = setmetatable({}, { __mode = 'k' })

local function safe_resume(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then
    vim.notify('GH Navigator: ' .. tostring(err), vim.log.levels.ERROR, { title = 'GH Navigator' })
  end
end

local function run_cmd(exe, dir, args)
  local cmd = vim.list_extend({ exe }, args)
  local opts = { cwd = dir, text = true }

  local co = coroutine.running()
  if not co or not async_coroutines[co] then
    return vim.system(cmd, opts):wait()
  end

  vim.system(cmd, opts, function(result)
    vim.schedule(function()
      safe_resume(co, result)
    end)
  end)
  return coroutine.yield()
end

local function run_git(dir, args)
  return run_cmd('git', dir, args)
end

local function run_gh(dir, args)
  return run_cmd('gh', dir, args)
end

local function github_ref(dir)
  local result = run_git(dir, { 'rev-parse', 'HEAD' })
  return vim.trim(result.stdout)
end

local function current_branch(dir)
  local result = run_git(dir, { 'rev-parse', '--abbrev-ref', 'HEAD' })
  return vim.trim(result.stdout)
end

local function repo_url(dir)
  local result = run_gh(dir, { 'repo', 'view', '--json', 'url' })
  if result.code ~= 0 then
    return nil
  end
  return vim.json.decode(result.stdout).url
end

local function gh_repo_error_notify()
  vim.notify('Could not determine GitHub repository URL', vim.log.levels.ERROR, { title = 'GH Navigator' })
end

local function blame_url(filename, dir)
  local url = repo_url(dir)
  if not url then
    return nil
  end
  return url .. '/blame/' .. github_ref(dir) .. '/' .. filename
end

function M.not_in_repo_notify()
  vim.notify('Not in a Git repository', vim.log.levels.ERROR, { title = 'GH Navigator' })
end

local function ui_select_pr(prs, bang)
  vim.ui.select(prs, {
    prompt = 'Select a PR:',
    format_item = function(pr)
      local author = (pr.author and pr.author.name) or 'Unknown Author'

      return '#' .. tostring(pr.number) .. ' ' .. pr.title .. ' - ' .. author
    end,
  }, function(choice)
    if choice ~= nil then
      open_or_copy(choice.url, bang)
    end
  end)
end

local function open_pr_by_number(number, bang, dir)
  local result = run_gh(dir, { 'pr', 'view', tostring(number), '--json', 'url' })

  if result.code == 0 then
    open_or_copy(vim.json.decode(result.stdout).url, bang)
  else
    vim.notify('PR #' .. number .. ' not found', vim.log.levels.INFO, { title = 'GH Navigator' })
  end
end

local function open_pr_by_search(query, bang, dir)
  local result = run_gh(dir, { 'pr', 'list', '--search', query, '--state', 'all', '--json', 'number,title,author,url' })

  if result.code ~= 0 then
    vim.notify('PR search failed for: ' .. query, vim.log.levels.ERROR, { title = 'GH Navigator' })
    return
  end

  local results = vim.json.decode(result.stdout)

  if vim.tbl_count(results) == 1 then
    open_or_copy(results[1].url, bang)
  elseif vim.tbl_count(results) > 1 then
    ui_select_pr(results, bang)
  else
    vim.notify('No PR found for: ' .. query, vim.log.levels.INFO, { title = 'GH Navigator' })
  end
end

local function repo_root_for_dir(dir)
  local result = run_git(dir, { 'rev-parse', '--show-toplevel' })
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

function M.buf_repo_dir()
  -- Try the current buffer's file path first.
  local buf_dir = vim.fn.expand('%:p:h')
  if buf_dir ~= '' then
    local root = repo_root_for_dir(buf_dir)
    if root then
      return root
    end
  end

  -- Current buffer has no file or is not in a repo (e.g., floating/scratch buffer).
  -- Fall back to the first normal window's buffer.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      if name ~= '' then
        local root = repo_root_for_dir(vim.fn.fnamemodify(name, ':h'))
        if root then
          return root
        end
      end
    end
  end

  return nil
end

function M.buf_relative_path(repo_dir)
  local abs_path = vim.fn.expand('%:p')
  if abs_path == '' then
    return nil
  end

  local prefix = repo_dir .. '/'
  if abs_path:sub(1, #prefix) == prefix then
    return abs_path:sub(#prefix + 1)
  end

  return abs_path
end

function M.open_compare(bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  local url = repo_url(dir)
  if not url then
    return gh_repo_error_notify()
  end

  open_or_copy(url .. '/compare/' .. current_branch(dir), bang)
end

function M.open_blame(filename, bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  local url = blame_url(filename, dir)
  if not url then
    return gh_repo_error_notify()
  end

  open_or_copy(url, bang)
end

function M.open_commit(sha, bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  local url = repo_url(dir)
  if not url then
    return gh_repo_error_notify()
  end

  open_or_copy(url .. '/commit/' .. sha, bang)
end

function M.open_file(filename, bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  local ref = github_ref(dir)
  local result = run_gh(dir, { 'browse', filename, '-n', '--branch', ref })
  if result.code ~= 0 then
    return gh_repo_error_notify()
  end

  local url = vim.trim(result.stdout)
  open_or_copy(url, bang)
end

function M.open_pr(number_or_query, bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  if number_or_query:match('^%d+$') then
    open_pr_by_number(number_or_query, bang, dir)
  else
    open_pr_by_search(number_or_query, bang, dir)
  end
end

function M.open_repo(path, bang, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return M.not_in_repo_notify()
  end

  local url = repo_url(dir)
  if not url then
    return gh_repo_error_notify()
  end

  if path ~= '' then
    url = url .. '/' .. path
  end
  open_or_copy(url, bang)
end

function M.is_commit(arg, dir)
  dir = dir or M.buf_repo_dir()
  if not dir then
    return false
  end

  local result = run_git(dir, { 'rev-parse', '--verify', arg })
  return result.code == 0
end

function M.gh_cli_installed()
  if vim.fn.executable('gh') == 0 then
    vim.notify('gh-navigator requires the GitHub CLI to be installed', vim.log.levels.ERROR, { title = 'GH Navigator' })
    return false
  else
    return true
  end
end

function M.async_run(fn)
  local co = coroutine.create(fn)
  async_coroutines[co] = true
  safe_resume(co)
end

return M
