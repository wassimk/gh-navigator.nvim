--
-- utils.lua
--

local M = {}

local function copy_to_clipboard(url)
  vim.fn.setreg('+', url)
  vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO, { title = 'gh-navigator' })
end

local function current_branch()
  return vim.trim(vim.fn.system('git branch --show-current'))
end

local function repo_url()
  local gh_cmd = 'gh repo view --json url'
  local result = vim.fn.system(gh_cmd)

  return vim.json.decode(result).url
end

local function blame_url(filename)
  return repo_url() .. '/blame/' .. current_branch() .. '/' .. filename
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

local function open_pr_by_number(number, bang)
  local gh_cmd = 'gh pr view ' .. number .. ' --json url'
  local result = vim.fn.system(gh_cmd)

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

local function open_pr_by_search(query, bang)
  local gh_cmd = 'gh pr list --search "' .. query .. '" --state merged --json number,title,author,url'
  local results = vim.json.decode(vim.fn.system(gh_cmd))

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

function M.open_blame(filename, bang)
  local url = blame_url(filename)

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_commit(sha, bang)
  local gh_cmd = 'gh browse ' .. sha .. ' -n'
  local url = vim.trim(vim.fn.system(gh_cmd))

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_file(filename, bang)
  local gh_cmd = 'gh browse ' .. filename .. ' -n'
  local url = vim.trim(vim.fn.system(gh_cmd))

  if bang then
    copy_to_clipboard(url)
  else
    vim.ui.open(url)
  end
end

function M.open_pr(number_or_query, bang)
  if tonumber(number_or_query) then
    open_pr_by_number(number_or_query, bang)
  else
    open_pr_by_search(number_or_query, bang)
  end
end

function M.open_repo(path, bang)
  local gh_cmd = 'gh repo view --json url'
  local result = vim.fn.system(gh_cmd)

  if not string.find(result, 'no git remotes found') then
    local url = repo_url() .. '/' .. path
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
  local result = vim.fn.system('git rev-parse --verify ' .. arg)

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

function M.in_github_repo()
  if vim.fn.system('gh repo view --json url 2>/dev/null') == '' then
    vim.notify('gh-navigator expects to be in a GitHub repository', vim.log.ERROR, { title = 'gh-navigator' })
    return false
  else
    return true
  end
end
return M
