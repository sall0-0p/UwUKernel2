local TimerManager = require("TimerManager");
local ProcessRegistry = require("process.ProcessRegistry");

local sys = {};

---Starts a system timer that fires after `duration` seconds.
---@param tcb Thread Thread calling the syscall.
---@param fd number File descriptor pointing to port, that timer should send message to.
---@param duration number Duration in seconds after which timer should fire.
---@param cookie any Optional payload.
function sys.timer(tcb, fd, duration, cookie)
    local pcb = ProcessRegistry.get(tcb.pid);

    return TimerManager.createTimer(pcb, fd, duration, cookie);
end

---Cancel timer or alarm based on file descriptor.
---@param tcb Thread Thread calling the syscall.
---@param id number Id of timer or alarm that we should cancel.
function sys.cancel(tcb, id)
    local pcb = ProcessRegistry.get(tcb.pid);

    return TimerManager.cancel(pcb, id);
end

return {
    [97] = sys.timer,
    [99] = sys.cancel,
}