--- @class TerminalWrapper
local TerminalWrapper = {};
TerminalWrapper.__index = TerminalWrapper;

function TerminalWrapper.new()
    local new = {
        type = "terminal",
        methods = {
            "write", "clear", "clearLine", "getCursorPos", "setCursorPos",
            "setCursorBlink", "isColor", "isColour", "setTextColor",
            "setTextColour", "setBackgroundColor", "setBackgroundColour",
            "getSize", "scroll", "blit", "getPaletteColor", "getPaletteColour",
            "setPaletteColor", "setPaletteColour", "getBackgroundColor",
            "getBackgroundColour", "getTextColor", "getTextColour"
        },
    };

    local methodMap = {}
    for _, m in ipairs(new.methods) do methodMap[m] = true end
    new.methods = methodMap;

    setmetatable(new, TerminalWrapper);
    return new;
end

function TerminalWrapper:write(pcb, data)
    term.write(data);
end

function TerminalWrapper:ioctl(pcb, method, ...)
    if (term[method]) then
        return term[method](...);
    else
        error("EINVAL: Invalid ioctl method! " .. method);
    end
end

return TerminalWrapper;