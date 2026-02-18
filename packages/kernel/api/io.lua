local ProcessRegistry = require("proc.registry.ProcessRegistry");
local ObjectManager = require("core.ObjectManager");

local io = {};

function io.dup(tcb, oldFd, newFd)
    assert(type(oldFd) == "number", "EINVAL: Old FD must be a number");
    assert(type(newFd) == "number", "EINVAL: New FD must be a number");

    local pcb = ProcessRegistry.get(tcb.pid);
    ObjectManager.dup(pcb, oldFd, newFd);
    return { status = "OK", val = {} };
end

return {
    [73] = io.pipe,
    [74] = io.dup,
};