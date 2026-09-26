-- App launch, focus, and window cycle, plus Ghostty launchers for harness TUIs.
-- Hammerspoon does not pick projects, branches, containers, or Herdr sessions.

local bindings = require("bindings")
local windows = require("windows")

local hyper = bindings.hyper

-- Browser name lives here so the rest of the overlay does not hardcode it.
local config = {
  browser = "Google Chrome",
}

local APP_NAMES = {
  intellij = "IntelliJ IDEA",
  ghostty = "Ghostty",
  obsidian = "Obsidian",
}

local function launchFocusCycle(appName)
  return function()
    local app = hs.application.get(appName)
    if not app or not app:isRunning() then
      if not hs.application.launchOrFocus(appName) then
        hs.alert.show("Could not open " .. appName)
      end
      return
    end
    if not app:isFrontmost() then
      app:activate()
      return
    end
    if not windows.cycleApp(app, 1) then
      hs.application.launchOrFocus(appName)
    end
  end
end

local function shellQuote(value)
  return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

-- bash -lc does not read ~/.bashrc, and Homebrew is often only on the zsh PATH.
-- The wrapper stays bash -lc. The command string enables brew, then sources bashrc.
local function launchScript(command)
  return table.concat({
    'if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)";',
    'elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi;',
    '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc";',
    command,
  }, " ")
end

local function launchInGhostty(command)
  return function()
    local line = "open -na Ghostty --args -e bash -lc " .. shellQuote(launchScript(command))
    local _, ok, _, rc = hs.execute(line, true)
    if not ok then
      hs.alert.show("Could not open Ghostty (" .. tostring(rc) .. ")")
    end
  end
end

bindings.bind("Apps", hyper, "i", "IntelliJ IDEA", launchFocusCycle(APP_NAMES.intellij))
bindings.bind("Apps", hyper, "t", "Ghostty", launchFocusCycle(APP_NAMES.ghostty))
bindings.bind("Apps", hyper, "b", "Browser", launchFocusCycle(config.browser))
bindings.bind("Apps", hyper, "o", "Obsidian", launchFocusCycle(APP_NAMES.obsidian))

bindings.bind("Dev", hyper, "space", "gtask", launchInGhostty("gtask"))
bindings.bind("Dev", hyper, "g", "lazygit", launchInGhostty("lazygit"))
bindings.bind("Dev", hyper, "d", "lazydocker", launchInGhostty("lazydocker"))
bindings.bind("Dev", hyper, "k", "k9s", launchInGhostty("k9s"))
-- Herdr stays a normal CLI in Ghostty. No session, pane, or attach handling.
bindings.bind("Dev", hyper, "h", "herdr", launchInGhostty("herdr"))

return {
  config = config,
  launchScript = launchScript,
}
