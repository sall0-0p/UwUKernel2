--- @class PeripheralWrapper
local PeripheralWrapper = {};
PeripheralWrapper.__index = PeripheralWrapper;

function PeripheralWrapper.new(name, type)
    local new = {
        name = name,
        type = type,
        methods = {},
    };

    -- Cache available methods
    local methods = peripheral.getMethods(name);
    if methods then
        for _, m in ipairs(methods) do
            new.methods[m] = true;
        end
    end

    setmetatable(new, PeripheralWrapper);
    return new;
end

function PeripheralWrapper:ioctl(pcb, method, ...)
    return peripheral.call(self.name, method, ...);
end

return PeripheralWrapper;