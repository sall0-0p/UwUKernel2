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

-- get launchd code
local launchd = fs.open("/SystemVolume/System/launchd/init.lua", "r");
local blob = launchd.readAll();
launchd.close();

local kernel = require(".SystemVolume.System.kernel");
kernel.createBoot(blob);
kernel.run();
