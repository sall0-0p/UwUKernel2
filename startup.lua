-- TODO: REMOVE THIS
local function sanitize(val, seen)
    seen = seen or {}
    local t = type(val)

    if t == "table" then
        if seen[val] then return "<recursion>" end
        seen[val] = true

        local newT = {}
        for k, v in pairs(val) do
            newT[tostring(k)] = sanitize(v, seen)
        end
        return newT
    elseif t == "function" then
        return "<function>"
    elseif t == "thread" then
        return "<thread>"
    elseif t == "userdata" then
        return "<userdata>"
    else
        return val
    end
end

function _G.debug.serialize(obj)
    return textutils.serialize(sanitize(obj))
end

-- boot
package.path = package.path .. ";/hdd1/kernel/?.lua;/hdd1/kernel/?/init.lua"

--- @type ProcessManager
local ProcessManager = require("ProcessManager")

--- @type ProcessRegistry
local ProcessRegistry = require("process.ProcessRegistry")

--- @type Scheduler
local Scheduler = require("Scheduler")

ProcessManager.spawn(0, "while (true) do end", {}, { blob = true });
ProcessManager.spawn(1, "local i = 1; while (i <= 20) do write('*'); i = i+1 end print()", {}, { blob = true });
ProcessManager.spawn(1, "local i = 1; while (i <= 20) do write('-'); i = i+1 end print()", {}, { blob = true });
Scheduler.run();