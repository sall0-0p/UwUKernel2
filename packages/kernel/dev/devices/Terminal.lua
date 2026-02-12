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

function TerminalWrapper:call(method, ...)
    return term[method](...);
end

return TerminalWrapper;