local M = {}

local _originals = {}
local _system_patterns = {}

--- Program vim.fn.system to return `response` when command contains `pattern` (plain substring match).
---@param pattern string plain substring to match against the command string
---@param response string value vim.fn.system should return
function M.set_system_response(pattern, response)
  table.insert(_system_patterns, { pattern = pattern, response = response })
end

--- Remove all programmed system responses so the next test can start fresh.
function M.clear_system_responses()
  _system_patterns = {}
end

--- Install mocks for vim.fn.system, vim.fn.executable, vim.fn.setreg,
--- vim.fn.expand, vim.ui.open, vim.ui.select, and vim.notify.
function M.setup_mocks()
  _system_patterns = {}

  _originals = {
    ui_open = vim.ui.open,
    ui_select = vim.ui.select,
    notify = vim.notify,
  }

  -- Pattern-matched system mock
  vim.fn.system = function(cmd)
    local cmd_str = type(cmd) == 'table' and table.concat(cmd, ' ') or cmd
    for _, entry in ipairs(_system_patterns) do
      if cmd_str:find(entry.pattern, 1, true) then
        return entry.response
      end
    end
    return ''
  end

  vim.fn.executable = function(_)
    return 1
  end

  M.last_register = nil
  M.last_register_value = nil
  vim.fn.setreg = function(reg, value)
    M.last_register = reg
    M.last_register_value = value
  end

  M.expand_result = nil
  vim.fn.expand = function(expr)
    return M.expand_result or expr
  end

  M.opened_url = nil
  vim.ui.open = function(url)
    M.opened_url = url
  end

  M.select_items = nil
  vim.ui.select = function(items, _, on_choice)
    M.select_items = items
    if #items > 0 then
      on_choice(items[1])
    end
  end

  M.notifications = {}
  vim.notify = function(msg, level, opts)
    table.insert(M.notifications, { msg = msg, level = level, opts = opts })
  end
end

--- Revert all stubs installed by setup_mocks().
function M.teardown_mocks()
  -- Remove direct entries from vim.fn so the metatable __index resumes
  rawset(vim.fn, 'system', nil)
  rawset(vim.fn, 'executable', nil)
  rawset(vim.fn, 'setreg', nil)
  rawset(vim.fn, 'expand', nil)

  if _originals.ui_open then
    vim.ui.open = _originals.ui_open
  end
  if _originals.ui_select then
    vim.ui.select = _originals.ui_select
  end
  if _originals.notify then
    vim.notify = _originals.notify
  end

  _originals = {}
  _system_patterns = {}
  M.last_register = nil
  M.last_register_value = nil
  M.opened_url = nil
  M.select_items = nil
  M.notifications = {}
  M.expand_result = nil
end

return M
