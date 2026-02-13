--
-- utils.lua
--

local M = {}

local function copy_to_clipboard(url)
  vim.fn.setreg('+', url)
  vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO, { title = 'gh-navigator' })
end

local function git_cmd(dir, args)
  if dir then
    return 'git -C ' .. vim.fn.shellescape(dir) .. ' ' .. args
  end
  return 'git ' .. args
end

local function gh_cmd(dir, args)
  if dir then
    return 'cd ' .. vim.fn.shellescape(dir) .. ' && gh ' .. args
  end
  return 'gh ' .. args
end

local function current_branch(dir)
  return vim.trim(vim.fn.system(git_cmd(dir, 'branch --show-current')))
end

local function repo_url(dir)
  local cmd = gh_cmd(dir, 'repo view --json url')
  local result = vim.fn.system(cmd)

  return vim.json.decode(result).url
end

local function blame_url(filename, dir)
  return repo_url(dir) .. '/blame/' .. current_branch(dir) .. '/' .. filename
end

local function not_in_repo_notify()
  vim.notify('Not in a Git repository', vim.log.levels.ERROR, { title = 'gh-navigator' })
end

local function ui_select_pr(prs, bang)
  vim.ui.select(prs, {
    prompt = 'Select a PR:',
    format_item = function(pr)
      local author = ''
      if pr.author.name then
        author = pr.author.name
      else
        author = 'Unknown Author'
      end

      return '#' .. tostring(pr.number) .. ' ' .. pr.title .. ' - ' .. author
    end,
  }, function(choice)
    if choice ~= nil then
      if bang then
        return copy_to_clipboard(choice.url)
      else
        return vim.ui.open(choice.url)
      end
    end
  end)
end

local function open_pr_by_number(number, bang, dir)
  local cmd = gh_cmd(dir, 'pr view ' .. number .. ' --json url')
  local result = vim.fn.system(cmd)

  if not string.find(result, 'Could not resolve') then
    local url = vim.json.decode(result).url
    if bang then
      copy_to_clipboard(url)
    else
      vim.ui.open(url)
    end
  else
    vim.notify('PR #' .. number .. ' not found', vim.log.INFO, { title = 'GHPR' })
  end
end

local function open_pr_by_search(query, bang, dir)
  local cmd = gh_cmd(dir, 'pr list --search "' .. query .. '" --state merged --json number,title,author,url')
  local results = vim.json.decode(vim.fn.system(cmd))

  if vim.tbl_count(results) == 1 then
    if bang then
      copy_to_clipboard(results[1].url)
    else
      vim.ui.open(results[1].url)
    end
  elseif vim.tbl_count(results) > 1 then
    ui_select_pr(results, bang)
  else
    vim.notify('No PR found for: ' .. query, vim.log.INFO, { title = ':OpenInGHPR' })
  end
end

function M.buf_repo_dir()
  local buf_dir = vim.fn.expand('%:p:h')
  if buf_dir == '' then
    return nil
  end

  local result = vim.trim(vim.fn.system('git -C ' .. vim.fn.shellescape(buf_dir) .. ' rev-parse --show-toplevel'))
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return result
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

function M.open_compare(bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  local url = repo_url(dir) .. '/compare/' .. current_branch(dir)

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_blame(filename, bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  local url = blame_url(filename, dir)

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_commit(sha, bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  local cmd = gh_cmd(dir, 'browse ' .. sha .. ' -n')
  local url = vim.trim(vim.fn.system(cmd))

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_file(filename, bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  local cmd = gh_cmd(dir, 'browse ' .. filename .. ' -n')
  local url = vim.trim(vim.fn.system(cmd))

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_pr(number_or_query, bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  if tonumber(number_or_query) then
    open_pr_by_number(number_or_query, bang, dir)
  else
    open_pr_by_search(number_or_query, bang, dir)
  end
end

function M.open_repo(path, bang)
  local dir = M.buf_repo_dir()
  if not dir then
    return not_in_repo_notify()
  end

  local cmd = gh_cmd(dir, 'repo view --json url')
  local result = vim.fn.system(cmd)

  if not string.find(result, 'no git remotes found') then
    local url = repo_url(dir) .. '/' .. path
    if bang then
      copy_to_clipboard(url)
    else
      vim.ui.open(url)
    end
  else
    vim.notify('Not in a GitHub hosted repository', vim.log.ERROR, { title = 'gh-navigator' })
  end
end

function M.is_commit(arg)
  local dir = M.buf_repo_dir()
  if not dir then
    return false
  end

  local result = vim.fn.system(git_cmd(dir, 'rev-parse --verify ' .. arg))

  if string.find(result, 'fatal') then
    return false
  else
    return true
  end
end

function M.gh_cli_installed()
  if vim.fn.executable('gh') == 0 then
    vim.notify('gh-navigator requires the GitHub CLI to be installed', vim.log.ERROR, { title = 'gh-navigator' })
    return false
  else
    return true
  end
end

return M
