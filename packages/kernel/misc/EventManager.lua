local TimerManager = require("misc.TimerManager");
local IPCManager = require("ipc.IPCManager");
local ObjectManager = require("core.ObjectManager");

--- @class EventManager
local EventManager = {};

--- @type table maps event type to global id
local binds = {};

---Handle event.
---@param event string
---@param args table
function EventManager.handleEvent(event, args)
    if (event == "timer" or event == "alarm") then
        TimerManager.handleEvent(event, args[1]);
        return;
    end

    local globalId = binds[event];
    if (globalId) then
        IPCManager.sendKernelMessage(globalId, {
            type = event,
            args = args,
        }, {
            type = "ROUTED_EVENT",
        })
    end
end

---Bind event towards certain ipc, it will route every event of this type towards it.
---@param pcb Process
---@param fd number
---@param type string
function EventManager.bindEvent(pcb, fd, type)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    local rightObj = ObjectManager.get(globalId);
    if (not rightObj or rightObj.type ~= "RECEIVE_RIGHT") then
        error("EPERM: Descriptor is not a receive right.");
    end

    local portId = rightObj.impl.portId;
    binds[type] = portId;
end

---Unbind event.
---@param pcb Process
---@param type string
function EventManager.unbindEvent(pcb, type)
    local portId = binds[type];
    if (portId) then
        --- @type Port;
        local port = (ObjectManager.get(portId) or {}).impl;
        if (not port) then return end;

        if (port.ownerPid ~= pcb.pid) then
            error("EPERM: No permission.");
        end

        binds[type] = nil;
    end
end

return EventManager;