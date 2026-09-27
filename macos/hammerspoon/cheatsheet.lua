-- Cheat sheet drawn from the binding registry. Hyper+/ shows it. Escape closes it.

local bindings = require("bindings")

local M = {}

local CATEGORY_ORDER = { "Apps", "Windows", "Dev", "System" }

local KEY_LABELS = {
  left = "Left",
  right = "Right",
  up = "Up",
  down = "Down",
  tab = "Tab",
  space = "Space",
  escape = "Escape",
}

local canvas = nil
local escapeHotkey = nil

function M.groups()
  local buckets = {}
  for _, entry in ipairs(bindings.registry) do
    local list = buckets[entry.category]
    if not list then
      list = {}
      buckets[entry.category] = list
    end
    list[#list + 1] = entry
  end
  return buckets
end

function M.orderedCategories(buckets)
  local seen = {}
  local ordered = {}
  for _, category in ipairs(CATEGORY_ORDER) do
    if buckets[category] then
      ordered[#ordered + 1] = category
      seen[category] = true
    end
  end

  local extras = {}
  for category in pairs(buckets) do
    if not seen[category] then
      extras[#extras + 1] = category
    end
  end
  table.sort(extras)
  for _, category in ipairs(extras) do
    ordered[#ordered + 1] = category
  end
  return ordered
end

local function keyLabel(key)
  local named = KEY_LABELS[string.lower(key)]
  if named then
    return named
  end
  if #key == 1 then
    return string.upper(key)
  end
  return key
end

function M.shortcutLabel(entry)
  local order = { ctrl = 1, alt = 2, shift = 3, cmd = 4 }
  local mods = {}
  for i = 1, #entry.mods do
    mods[i] = string.lower(entry.mods[i])
  end
  table.sort(mods, function(a, b)
    return (order[a] or 100) < (order[b] or 100)
  end)
  mods[#mods + 1] = keyLabel(entry.key)
  return table.concat(mods, "+")
end

function M.text()
  local buckets = M.groups()
  local rows = {}
  local width = 0
  for _, category in ipairs(M.orderedCategories(buckets)) do
    for _, entry in ipairs(buckets[category]) do
      local label = M.shortcutLabel(entry)
      if #label > width then
        width = #label
      end
      rows[#rows + 1] = { category = category, label = label, description = entry.description }
    end
  end

  local lines = { "MacHarness", "" }
  local current = nil
  for _, row in ipairs(rows) do
    if row.category ~= current then
      if current then
        lines[#lines + 1] = ""
      end
      lines[#lines + 1] = string.upper(row.category)
      current = row.category
    end
    local pad = string.rep(" ", width - #row.label)
    lines[#lines + 1] = "  " .. row.label .. pad .. "  " .. row.description
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "escape  Close"
  return table.concat(lines, "\n")
end

local function hide()
  if canvas then
    canvas:delete()
    canvas = nil
  end
  if escapeHotkey then
    escapeHotkey:delete()
    escapeHotkey = nil
  end
end

local function show()
  hide()

  local body = M.text()
  local lineCount = 1
  for _ in string.gmatch(body, "\n") do
    lineCount = lineCount + 1
  end

  local focused = hs.window.focusedWindow()
  local screen = (focused and focused:screen()) or hs.screen.mainScreen()
  local frame = screen:frame()
  local width = math.min(720, frame.w - 80)
  local height = math.min(math.max(200, 48 + (lineCount * 20)), frame.h - 80)
  local rect = {
    x = frame.x + ((frame.w - width) / 2),
    y = frame.y + ((frame.h - height) / 2),
    w = width,
    h = height,
  }

  canvas = hs.canvas.new(rect)
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:appendElements({
    {
      type = "rectangle",
      action = "fill",
      fillColor = { red = 0.11, green = 0.11, blue = 0.12, alpha = 0.96 },
      roundedRectRadii = { xRadius = 14, yRadius = 14 },
    },
    {
      type = "text",
      text = body,
      textColor = { red = 0.96, green = 0.96, blue = 0.97, alpha = 1 },
      textFont = "Menlo",
      textSize = 13,
      frame = { x = 24, y = 18, w = width - 48, h = height - 36 },
    },
  })
  canvas:show()
  escapeHotkey = bindings.bindTemporary({}, "escape", hide)
end

bindings.bind("System", bindings.hyper, "/", "Cheat sheet", show)

return M
