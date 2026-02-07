local TimerManager = require("TimerManager");
local ProcessRegistry = require("process.ProcessRegistry");

local sys = {};

---Starts a system timer that fires after `duration` seconds.
---@param tcb Thread Thread calling the syscall.
---@param duration number Duration in seconds after which timer should fire.
function sys.timer(tcb, duration, cookie)
    local pcb = ProcessRegistry.get(tcb.pid);

    return TimerManager.createTimer(pcb, duration, cookie);
end

---Cancel timer or alarm based on file descriptor.
---@param tcb Thread Thread calling the syscall.
---@param fd number File descriptor timer is assigned to.
function sys.cancel(tcb, fd)
    local pcb = ProcessRegistry.get(tcb.pid);

    return TimerManager.cancel(pcb, fd);
end

return {
    [97] = sys.timer,
    [99] = sys.cancel,
}