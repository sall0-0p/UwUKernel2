--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]

local ____modules = {}
local ____moduleCache = {}
local ____originalRequire = require
local function require(file, ...)
    if ____moduleCache[file] then
        return ____moduleCache[file].value
    end
    if ____modules[file] then
        local module = ____modules[file]
        local value = nil
        if (select("#", ...) > 0) then value = module(...) else value = module(file) end
        ____moduleCache[file] = { value = value }
        return value
    else
        if ____originalRequire then
            return ____originalRequire(file)
        else
            error("module '" .. file .. "' not found")
        end
    end
end
____modules = {
["src.main"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local task = require("task")
local proc = require("proc")
task.create(function()
    while true do
    end
end)
task.create(function()
    local i = 0
    while i < 20 do
        print("*")
        i = i + 1
    end
end)
task.create(function()
    local i = 0
    while i < 20 do
        print("-")
        i = i + 1
    end
end)
print(task.list())
proc.exit(0)
return ____exports
 end,
}
return require("src.main", ...)
