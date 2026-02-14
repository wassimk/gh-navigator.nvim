local M = {}

local _originals = {}
local _system_patterns = {}

--- Program vim.system to return `response` when command contains `pattern` (plain substring match).
---@param pattern string plain substring to match against the command string
---@param response string value vim.system should return as stdout
---@param exit_code? number optional exit code (default 0)
function M.set_system_response(pattern, response, exit_code)
  table.insert(_system_patterns, { pattern = pattern, response = response, exit_code = exit_code or 0 })
end

--- Remove all programmed system responses so the next test can start fresh.
function M.clear_system_responses()
  _system_patterns = {}
end

--- Install mocks for vim.system, vim.fn.executable, vim.fn.setreg,
--- vim.fn.expand, vim.ui.open, vim.ui.select, and vim.notify.
function M.setup_mocks()
  _system_patterns = {}

  _originals = {
    system = vim.system,
    ui_open = vim.ui.open,
    ui_select = vim.ui.select,
    notify = vim.notify,
  }

  -- Pattern-matched vim.system mock (supports optional on_exit callback)
  vim.system = function(cmd, _, on_exit)
    local cmd_str = table.concat(cmd, ' ')
    local result = { stdout = '', stderr = '', code = 0 }
    for _, entry in ipairs(_system_patterns) do
      if cmd_str:find(entry.pattern, 1, true) then
        result = { stdout = entry.response, stderr = '', code = entry.exit_code or 0 }
        break
      end
    end
    if on_exit then
      on_exit(result)
    end
    return {
      wait = function()
        return result
      end,
    }
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

  M.expand_results = {}
  M.expand_result = nil
  vim.fn.expand = function(expr)
    if M.expand_results[expr] ~= nil then
      return M.expand_results[expr]
    end
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
  rawset(vim.fn, 'executable', nil)
  rawset(vim.fn, 'setreg', nil)
  rawset(vim.fn, 'expand', nil)

  if _originals.system then
    vim.system = _originals.system
  end
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
  M.expand_results = {}
end

return M
