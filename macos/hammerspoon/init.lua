-- Hammerspoon entry point. Loads the overlay modules and one reload binding.

require("apps")
require("windows")
require("cheatsheet")

local bindings = require("bindings")

bindings.bind("System", bindings.hyper, "r", "Reload Hammerspoon", function()
  hs.reload()
end)

if type(hs) == "table" and hs.alert then
  hs.alert.show("Hammerspoon config loaded")
end
