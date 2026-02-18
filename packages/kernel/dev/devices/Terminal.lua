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
    local _, h = term.getSize();
    term.write(tostring(data));

    local _, newY = term.getCursorPos();

    if newY < h then
        term.setCursorPos(1, newY + 1);
    else
        term.scroll(1)
        term.setCursorPos(1, h)
    end
end

function TerminalWrapper:ioctl(pcb, method, ...)
    if (term[method]) then
        return term[method](...);
    else
        error("EINVAL: Invalid ioctl method! " .. method);
    end
end

return TerminalWrapper;