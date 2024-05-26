--
-- utils.lua
--

local M = {}

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

function M.open_repo()
  local gh_cmd = 'gh repo view --json url'
  local result = vim.fn.system(gh_cmd)

  if not string.find(result, 'no git remotes found') then
    vim.ui.open(vim.json.decode(result).url)
  else
    vim.notify('Not in a GitHub hosted repository', vim.log.ERROR, { title = 'gh-navigator' })
  end
end

function M.open_pr_by_number(number)
  local gh_cmd = 'gh pr view ' .. number .. ' --json url'
  local result = vim.fn.system(gh_cmd)

  if not string.find(result, 'Could not resolve') then
    vim.ui.open(vim.json.decode(result).url)
  else
    vim.notify('PR #' .. number .. ' not found', vim.log.INFO, { title = 'GHPR' })
  end
end

function M.open_pr_by_search(query)
  local gh_cmd = 'gh pr list --search "' .. query .. '" --state merged --json number,title,author,url'
  local results = vim.json.decode(vim.fn.system(gh_cmd))

  if vim.tbl_count(results) == 1 then
    vim.ui.open(results[1].url)
  elseif vim.tbl_count(results) > 1 then
    M.ui_select_pr(results)
  else
    vim.notify('No PR found for: ' .. query, vim.log.INFO, { title = ':OpenInGHPR' })
  end
end

function M.select_pr(prs)
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
      return vim.ui.open(choice.url)
    end
  end)
end

return M
