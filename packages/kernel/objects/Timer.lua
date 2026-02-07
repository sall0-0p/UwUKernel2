--- @class Timer
local Timer = {};
Timer.__index = Timer;

function Timer.new(nativeId, cookie)
    local new = {
        nativeId = nativeId,
        cookie = cookie,
    };

    setmetatable(new, Timer);
    return new;
end

return Timer;