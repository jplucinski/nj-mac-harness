-- Registry keys are unique, and cheat-sheet categories match the bindings.

local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  source = source:sub(2)
end
if source:sub(1, 1) ~= "/" then
  local handle = io.popen("pwd")
  local cwd = handle:read("*l")
  handle:close()
  source = cwd .. "/" .. source
end
local tests_dir = source:match("^(.*)/[^/]+$")
local root = tests_dir:match("^(.*)/tests$")
if not root or root == "" then
  io.stderr:write("could not locate repo root from " .. source .. "\n")
  os.exit(1)
end
package.path = root .. "/macos/hammerspoon/?.lua;" .. package.path

require("init")

local bindings = require("bindings")
local cheatsheet = require("cheatsheet")

local function fail(message)
  io.stderr:write(message .. "\n")
  os.exit(1)
end

local hyper = bindings.hyper
local hyperShift = { "ctrl", "alt", "cmd", "shift" }

local expected = {}
local function expect(category, mods, key)
  local id = bindings.keyId(mods, key)
  if expected[id] then
    fail("test listed " .. id .. " twice")
  end
  expected[id] = category
end

expect("Apps", hyper, "i")
expect("Apps", hyper, "t")
expect("Apps", hyper, "b")
expect("Apps", hyper, "o")
expect("Windows", hyper, "left")
expect("Windows", hyper, "right")
expect("Windows", hyper, "up")
expect("Windows", hyper, "tab")
expect("Windows", hyperShift, "tab")
expect("Windows", hyper, "[")
expect("Windows", hyper, "]")
expect("Dev", hyper, "space")
expect("Dev", hyper, "g")
expect("Dev", hyper, "d")
expect("Dev", hyper, "k")
expect("Dev", hyper, "h")
expect("System", hyper, "/")
expect("System", hyper, "r")

local found = {}
local found_count = 0
for _, entry in ipairs(bindings.registry) do
  if found[entry.id] then
    fail("duplicate registry key: " .. entry.id)
  end
  if type(entry.action) ~= "function" then
    fail("binding " .. entry.id .. " has no action")
  end
  if type(entry.description) ~= "string" or entry.description == "" then
    fail("binding " .. entry.id .. " has no description")
  end
  found[entry.id] = entry
  found_count = found_count + 1
end

local expected_count = 0
for id, category in pairs(expected) do
  expected_count = expected_count + 1
  local entry = found[id]
  if not entry then
    fail("missing binding " .. id .. " (" .. category .. ")")
  end
  if entry.category ~= category then
    fail("binding " .. id .. " category is " .. entry.category .. ", expected " .. category)
  end
end

for id in pairs(found) do
  if not expected[id] then
    fail("unexpected binding " .. id .. " in category " .. found[id].category)
  end
end

if found_count ~= expected_count then
  fail("registry size " .. found_count .. " != expected " .. expected_count)
end

local buckets = cheatsheet.groups()
local listed = {}
local listed_count = 0
local binding_categories = {}
local sheet_categories = {}

for _, entry in ipairs(bindings.registry) do
  binding_categories[entry.category] = true
end

for category, list in pairs(buckets) do
  sheet_categories[category] = true
  for _, entry in ipairs(list) do
    if entry.category ~= category then
      fail("cheat sheet listed " .. entry.id .. " under " .. category)
    end
    if listed[entry.id] then
      fail("cheat sheet listed " .. entry.id .. " twice")
    end
    listed[entry.id] = true
    listed_count = listed_count + 1
  end
end

if listed_count ~= found_count then
  fail("cheat sheet lists " .. listed_count .. " bindings, registry has " .. found_count)
end

for id in pairs(found) do
  if not listed[id] then
    fail("cheat sheet omitted " .. id)
  end
end

for category in pairs(binding_categories) do
  if not sheet_categories[category] then
    fail("cheat sheet missing category " .. category)
  end
end

for category in pairs(sheet_categories) do
  if not binding_categories[category] then
    fail("cheat sheet category " .. category .. " has no bindings")
  end
end

local ordered = cheatsheet.orderedCategories(buckets)
if #ordered ~= 4 or ordered[1] ~= "Apps" or ordered[2] ~= "Windows" or ordered[3] ~= "Dev" or ordered[4] ~= "System" then
  fail("cheat sheet category order is not Apps, Windows, Dev, System")
end

local overlay = cheatsheet.text()
for _, category in ipairs(ordered) do
  if not string.find(overlay, string.upper(category), 1, true) then
    fail("cheat sheet text missing " .. category)
  end
end
for _, entry in ipairs(bindings.registry) do
  if not string.find(overlay, entry.description, 1, true) then
    fail("cheat sheet text missing description " .. entry.description)
  end
end

local apps = require("apps")
local function shellQuote(value)
  return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

local function assertScript(command)
  local script = apps.launchScript(command)
  local quoted = shellQuote(command)
  if not string.find(script, 'eval "$(/opt/homebrew/bin/brew shellenv)"', 1, true) then
    fail("launch script for " .. command .. " missing Homebrew shellenv")
  end
  if not string.find(script, 'elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi;', 1, true) then
    fail("launch script for " .. command .. " missing Intel Homebrew shellenv")
  end
  if not string.find(script, '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc";', 1, true) then
    fail("launch script for " .. command .. " does not source ~/.bashrc")
  end
  if not string.find(script, "; " .. quoted, 1, true) or script:sub(-#quoted) ~= quoted then
    fail("launch script for " .. command .. " does not end with a quoted command")
  end
end

for _, command in ipairs({ "gtask", "lazygit", "lazydocker", "k9s", "herdr" }) do
  assertScript(command)
end

print("ok: " .. found_count .. " unique bindings; cheat sheet categories match")
