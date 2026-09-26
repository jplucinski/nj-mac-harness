-- Single hotkey registrar. Other modules call bind() and do not call hs.hotkey.bind.

local M = {}

M.registry = {}
M.hyper = { "ctrl", "alt", "cmd" }

local MOD_ORDER = { ctrl = 1, alt = 2, shift = 3, cmd = 4 }

local function copyList(list)
  local copy = {}
  for i = 1, #list do
    copy[i] = list[i]
  end
  return copy
end

function M.keyId(mods, key)
  local names = {}
  for i = 1, #mods do
    names[i] = string.lower(tostring(mods[i]))
  end
  table.sort(names, function(a, b)
    return (MOD_ORDER[a] or 100) < (MOD_ORDER[b] or 100)
  end)
  return table.concat(names, "+") .. "+" .. string.lower(tostring(key))
end

function M.bind(category, mods, key, description, action)
  if type(category) ~= "string" or category == "" then
    error("bind: category is required")
  end
  if type(mods) ~= "table" then
    error("bind: mods must be a table")
  end
  if type(key) ~= "string" or key == "" then
    error("bind: key is required")
  end
  if type(description) ~= "string" or description == "" then
    error("bind: description is required")
  end
  if type(action) ~= "function" then
    error("bind: action must be a function")
  end

  local id = M.keyId(mods, key)
  for _, entry in ipairs(M.registry) do
    if entry.id == id then
      error("duplicate hotkey: " .. id)
    end
  end

  local entry = {
    id = id,
    category = category,
    mods = copyList(mods),
    key = key,
    description = description,
    action = action,
  }
  M.registry[#M.registry + 1] = entry

  if type(hs) == "table" and hs.hotkey and hs.hotkey.bind then
    hs.hotkey.bind(entry.mods, entry.key, entry.action)
  end

  return entry
end

-- Escape while the cheat sheet is open. Not stored in the registry, so it
-- does not become a global shortcut and does not appear as a second source
-- of bindings.
function M.bindTemporary(mods, key, action)
  if type(hs) ~= "table" or not hs.hotkey or not hs.hotkey.bind then
    return nil
  end
  return hs.hotkey.bind(mods, key, action)
end

return M
