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
    local str = tostring(data);
    local _, h = term.getSize();

    local pos = 1;
    while pos <= #str do
        local next_nl = string.find(str, "\n", pos, true);
        local chunk = string.sub(str, pos, next_nl and (next_nl - 1) or #str);
        term.write(chunk);

        if next_nl then
            local _, currentY = term.getCursorPos();

            if currentY < h then
                term.setCursorPos(1, currentY + 1)
            else
                term.scroll(1)
                term.setCursorPos(1, h)
            end

            pos = next_nl + 1
        else
            break;
        end
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