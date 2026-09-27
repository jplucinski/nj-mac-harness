-- Window halves, maximize, window cycle, and screen moves.
-- Geometry uses each screen's frame so more than one monitor works.

local bindings = require("bindings")

local M = {}

local hyper = bindings.hyper
local hyperShift = { "ctrl", "alt", "cmd", "shift" }

function M.standardWindows(app)
  local windows = {}
  if not app or not app.allWindows then
    return windows
  end
  for _, win in ipairs(app:allWindows()) do
    if win:isStandard() then
      windows[#windows + 1] = win
    end
  end
  table.sort(windows, function(a, b)
    return (a:id() or 0) < (b:id() or 0)
  end)
  return windows
end

function M.cycleApp(app, direction)
  local windows = M.standardWindows(app)
  local count = #windows
  if count == 0 then
    return false
  end

  local focused = hs.window.focusedWindow()
  local index = 0
  for i, win in ipairs(windows) do
    if focused and win:id() == focused:id() then
      index = i
      break
    end
  end

  local nextIndex
  if index == 0 then
    nextIndex = (direction < 0) and count or 1
  else
    nextIndex = ((index - 1 + direction) % count) + 1
  end
  windows[nextIndex]:focus()
  return true
end

local function withFocusedWindow(apply)
  return function()
    local win = hs.window.focusedWindow()
    if not win then
      return
    end
    apply(win)
  end
end

local function place(rectFor)
  return withFocusedWindow(function(win)
    local frame = win:screen():frame()
    win:setFrame(rectFor(frame), 0)
  end)
end

local function screensInLayoutOrder()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b)
    local left = a:frame()
    local right = b:frame()
    if left.x ~= right.x then
      return left.x < right.x
    end
    return left.y < right.y
  end)
  return screens
end

local function moveToAdjacentScreen(direction)
  return withFocusedWindow(function(win)
    local screens = screensInLayoutOrder()
    if #screens < 2 then
      return
    end

    local current = win:screen()
    local index = nil
    for i, screen in ipairs(screens) do
      if screen:id() == current:id() then
        index = i
        break
      end
    end
    if not index then
      return
    end

    local target = screens[((index - 1 + direction) % #screens) + 1]
    local from = current:frame()
    local to = target:frame()
    if from.w <= 0 or from.h <= 0 or to.w <= 0 or to.h <= 0 then
      return
    end
    local wf = win:frame()
    win:setFrame({
      x = to.x + ((wf.x - from.x) / from.w) * to.w,
      y = to.y + ((wf.y - from.y) / from.h) * to.h,
      w = (wf.w / from.w) * to.w,
      h = (wf.h / from.h) * to.h,
    }, 0)
  end)
end

local function cycleFocused(direction)
  return withFocusedWindow(function(win)
    M.cycleApp(win:application(), direction)
  end)
end

bindings.bind("Windows", hyper, "left", "Left half", place(function(frame)
  return { x = frame.x, y = frame.y, w = frame.w / 2, h = frame.h }
end))

bindings.bind("Windows", hyper, "right", "Right half", place(function(frame)
  return { x = frame.x + (frame.w / 2), y = frame.y, w = frame.w / 2, h = frame.h }
end))

bindings.bind("Windows", hyper, "up", "Maximize", place(function(frame)
  return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
end))

bindings.bind("Windows", hyper, "tab", "Next window", cycleFocused(1))
bindings.bind("Windows", hyperShift, "tab", "Previous window", cycleFocused(-1))
bindings.bind("Windows", hyper, "[", "Previous screen", moveToAdjacentScreen(-1))
bindings.bind("Windows", hyper, "]", "Next screen", moveToAdjacentScreen(1))

return M
