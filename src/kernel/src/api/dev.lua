local DeviceManager = require("dev.DeviceManager");
local ProcessRegistry = require("proc.registry.ProcessRegistry");

local dev = {};

---Wraps a native ComputerCraft peripheral or virtual device into a kernel handle.
---@param tcb table Thread calling the syscall.
---@param name string The network / side name of a peripheral.
function dev.open(tcb, name)
    assert(type(name) == "string", "EINVAL: Bad argument #1: Name must be a string.");
    local pcb = ProcessRegistry.get(tcb.pid);
    return DeviceManager.open(pcb, name);
end

---Returns a list of all attached peripheral names.
---@param tcb table Thread calling the syscall.
function dev.list(tcb)
    -- TODO: Add permissions check (Root only?)
    return DeviceManager.list();
end

---Returns type of attached peripheral.
---@param tcb table Thread calling the syscall.
---@param name string Name of the peripheral.
function dev.type(tcb, name)
    return DeviceManager.type(name);
end

---Returns the list of methods available on the peripheral.
---@param tcb table Thread calling the syscall.
---@param name string Name of the peripheral.
function dev.methods(tcb, name)
    return DeviceManager.methods(name);
end

return {
    [106] = dev.open,
    [107] = dev.call,
    [108] = dev.list,
    [109] = dev.type,
    [110] = dev.methods,
}