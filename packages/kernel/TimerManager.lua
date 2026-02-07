local ObjectManager = require("objects.ObjectManager");
local IPCManager = require("IPCManager");
local Timer = require("objects.Timer");

--- @class TimerManager
local TimerManager = {};
local timers = {};

---Creates a new timer;
---@param pcb Process
---@param duration number
---@param cookie any
function TimerManager.createTimer(pcb, duration, cookie)
    local nativeId = os.startTimer(duration);
    local portId = IPCManager.createPort(pcb, true);

    timers[nativeId] = {
        pid = pcb.pid,
        globalId = pcb.handles[portId],
        cookie = cookie,
    };

    return portId;
end

function TimerManager.handleEvent(id)
    print("Received timer event inside .handleEvent!", id);
    local timer = timers[id];
    if (timer) then
        print("Trying to send kernel message!");
        IPCManager.sendKernelMessage(timer.globalId, {
            type = "TIMER",
            cookie = timer.cookie,
        })
    end
end

function TimerManager.cancel(pcb, fd)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    local nativeId;
    local timer;
    for native, object in pairs(timers) do
        if (object.globalId == globalId) then
            nativeId = native;
            timer = object;
            break;
        end
    end

    timers[nativeId] = nil;

    IPCManager.close(pcb, fd);
end

return TimerManager;