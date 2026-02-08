local ObjectManager = require("objects.ObjectManager");
local IPCManager = require("IPCManager");

--- @class TimerManager
local TimerManager = {};
local timers = {};
local alarms = {};
local nextId = 1;

local function getNextId()
    local next = nextId;
    nextId = next + 1;
    return next;
end

---Creates a new timer;
---@param pcb Process
---@param duration number
---@param cookie any
function TimerManager.createTimer(pcb, fd, duration, cookie)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    --- @type ReceiveRight
    local receiveRight = ObjectManager.get(globalId).impl;
    if (ObjectManager.get(globalId).type ~= "RECEIVE_RIGHT") then
        error("EBADF: File descriptor is not a port right.");
    end

    ----- @type Port
    local native = os.startTimer(duration);
    local referenceId = getNextId();

    timers[native] = {
        port = receiveRight.portId,
        reference = referenceId,
        cookie = cookie,
    }

    return referenceId;
end

---Creates a new alarm;
---@param pcb Process
---@param time number
---@param cookie any
function TimerManager.createAlarm(pcb, fd, time, cookie)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    --- @type ReceiveRight
    local receiveRight = ObjectManager.get(globalId).impl;
    if (ObjectManager.get(globalId).type ~= "RECEIVE_RIGHT") then
        error("EBADF: File descriptor is not a port right.");
    end

    ----- @type Port
    local native = os.setAlarm(time);
    local referenceId = getNextId();

    alarms[native] = {
        port = receiveRight.portId,
        reference = referenceId,
        cookie = cookie,
    }

    return referenceId;
end

function TimerManager.handleEvent(type, id)
    if (type == "timer") then
        local timer = timers[id];
        if (not timer) then return end;

        local portId = timer.port
        local port = ObjectManager.get(portId);
        if (not port or port.type ~= "PORT") then return end;

        IPCManager.sendKernelMessage(portId, {
            id = timer.referenceId,
            cookie = timer.cookie,
        }, {
            type = "TIMER",
        })
    elseif (type == "alarm") then
        local alarm = alarms[id];
        if (not alarm) then return end;

        local portId = alarm.port;
        local port = ObjectManager.get(portId);
        if (not port or port.type ~= "PORT") then return end;

        IPCManager.sendKernelMessage(portId, {
            id = alarm.referenceId,
            cookie = alarm.cookie,
        }, {
            type = "ALARM",
        })
    end
end

function TimerManager.cancel(id)
    for native, value in pairs(timers) do
        if (value.referenceId == id) then
            os.cancelTimer(native);
            timers[native] = nil;
            break;
        end
    end

    for native, value in pairs(alarms) do
        if (value.referenceId == id) then
            os.cancelAlarm(native);
            alarms[native] = nil;
            break;
        end
    end
end

return TimerManager;