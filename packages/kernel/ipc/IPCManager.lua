local ObjectManager = require("core.ObjectManager");
local KernelObject = require("core.KernelObject");
local Port = require("ipc.classes.Port");
local ReceiveRight = require("ipc.classes.ReceiveRight");
local SendRight = require("ipc.classes.SendRight");
local Scheduler = require("core.Scheduler");
local ProcessRegistry = require("proc.registry.ProcessRegistry");

--- @class IPCManager
local IPCManager = {};

---Creates new port.
---Calling process gets receive right by default, by owning the process.
---@param pcb Process process that creates new port.
---@param temporary boolean if port should be one time use (automatically cleaned up afterwards).
---@return number file descriptor of created port.
function IPCManager.createPort(pcb, temporary)
    -- create port
    local port = Port.new();
    local portObj = KernelObject.new("PORT", port);
    local portId = ObjectManager.register(portObj);

    -- create rights
    local receiveRight = ReceiveRight.new(portId);
    local receiveRightObj = KernelObject.new("RECEIVE_RIGHT", receiveRight);
    local receiveRightId = ObjectManager.register(receiveRightObj);

    local sendRight = SendRight.new(portId);
    local sendRightObj = KernelObject.new("SEND_RIGHT", sendRight);
    local sendRightId = ObjectManager.register(sendRightObj);

    -- link rights to port
    port.receiveRight = receiveRightId;
    port.sendRight = sendRightId;

    ObjectManager.retain(sendRightId);

    port.onDestroy = function()
        ObjectManager.release(sendRightId);
    end

    port.temporary = temporary or false;

    -- link fd
    return ObjectManager.link(pcb, receiveRightId);
end

---Sends a message to the specific port.
---@param pcb Process sending process.
---@param fd number file descriptor pointing to the port.
---@param payload table message payload that is sent to another process.
---@param opts table optional table with optional options.
---@return boolean returns `true` if queue is full, `false` if not.
---Options table contains:
---`timeout: number` - time to wait if queue is full;
---`reply_port: number` - port to send reply to;
---`transfer: number[]` - handles to transfer;
function IPCManager.send(pcb, fd, payload, opts)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    local rightObj = ObjectManager.get(globalId);
    if (not rightObj) then error("EBADF: Invalid file descriptor.") end -- <-- errors here

    local portId;
    if (rightObj.type == "SEND_RIGHT" or rightObj.type == "RECEIVE_RIGHT") then
        portId = rightObj.impl.portId;
    else
        error("EBADF: File descriptor is not a port right.");
    end

    local portObj = ObjectManager.get(portId);
    if (not portObj) then error("EINTERNAL: Right points to invalid port") end

    --- @type Port
    local port = portObj.impl;
    local recipient = ProcessRegistry.get(port.ownerPid);
    if (not recipient) then
        error("EINTERNAL: Port cannot be orphaned.");
    end

    if (#port.receivers == 0 and #port.queue >= port.capacity) then
        return true, port, recipient;
    end

    -- build the message object (reply)
    local localReplyPort = (opts or {}).reply_port;
    local globalReplyPort;
    if (localReplyPort) then
        -- CHANGED: Use migrateRight logic to ensure we send a SendRight
        local originalGlobalId = pcb.handles[localReplyPort];
        if (not originalGlobalId) then error("EBADF: Invalid reply port") end

        globalReplyPort = IPCManager.migrateRight(originalGlobalId);

        -- Retain it because it's now referenced by the message in transit
        ObjectManager.retain(globalReplyPort);

        -- Add temporary sender tracking logic if needed (simplified here)
        local replyPortObj = ObjectManager.get(ObjectManager.get(globalReplyPort).impl.portId);
        if replyPortObj then
            table.insert(replyPortObj.impl.temporarySenders, recipient.pid);
        end
    end

    local message = {
        pid = pcb.pid,
        globalReply = globalReplyPort,
        data = payload,
        type = (opts or {}).type or "IPC",
    }

    -- build the message object (handles)
    if (opts and opts.transfer) then
        message.globalHandles = {};
        for _, v in pairs(opts.transfer) do
            local gId = pcb.handles[v];
            if (not gId or not ObjectManager.get(gId)) then
                error("EBADF: Trying to transfer invalid file descriptor.");
            end

            -- If user wants to give a Send Right from a Receive Right, they should
            -- duplicate it first.

            ObjectManager.retain(gId);
            table.insert(message.globalHandles, gId);
            ObjectManager.close(pcb, v);
        end
    end

    -- send it
    if (#port.receivers > 0) then
        -- parse globalHandles and insert them into the handles.
        if (message.globalHandles) then
            message.handles = {};
            for _, gId in pairs(message.globalHandles) do
                local newFd = ObjectManager.link(recipient, gId);
                table.insert(message.handles, newFd);

                -- release transferred objects as they were already added back.
                local gObject = ObjectManager.get(gId);
                gObject:release();
            end
            message.globalHandles = nil;
        end

        -- add reply handle
        if (message.globalReply) then
            message.reply = ObjectManager.link(recipient, message.globalReply);
            ObjectManager.get(message.globalReply):release();
            message.globalReply = nil;
        end

        -- remove thread send rights if it was temporary sender
        local oneTimeUse = false;
        for i, v in pairs(port.temporarySenders) do
            if (v == pcb.pid) then
                oneTimeUse = true;
                table.remove(port.temporarySenders, i);
                break;
            end
        end

        if (oneTimeUse) then
            ObjectManager.close(pcb, fd);
        end

        -- close temporary port
        if (port.temporary) then
            IPCManager.close(pcb, fd);
        end

        -- wake thread
        local receiver = table.remove(port.receivers, 1);
        Scheduler.wake(receiver, { true, { message } });
        return false;
    end

    -- remove thread send rights if it was temporary sender
    local oneTimeUse = false;
    for i, v in pairs(port.temporarySenders) do
        if (v == pcb.pid) then
            oneTimeUse = true;
            table.remove(port.temporarySenders, i);
            break;
        end
    end

    if (oneTimeUse) then
        ObjectManager.close(pcb, fd);
    end

    table.insert(port.queue, message);
    return false;
end

---Bypasses local handle lookups and permissions.
---@param globalPortId number The target port's global registry ID.
---@param payload table The data to send.
---@param opts table|nil Options: { reply_global_id = number, transfer_global_ids = number[] }
function IPCManager.sendKernelMessage(globalPortId, payload, opts)
    local portObj = ObjectManager.get(globalPortId);

    if portObj and (portObj.type == "RECEIVE_RIGHT" or portObj.type == "SEND_RIGHT") then
        local realPortId = portObj.impl.portId
        portObj = ObjectManager.get(realPortId)
    end

    if not portObj or portObj.type ~= "PORT" then
        return false, "EINTERNAL: Invalid kernel target port";
    end

    --- @type Port
    local port = portObj.impl;
    local recipient = ProcessRegistry.get(port.ownerPid);

    if not recipient then
        return false, "EINTERNAL: Port owner is dead";
    end

    if (#port.receivers == 0 and #port.queue >= port.capacity) then
        return false, "EINTERNAL: Queue full";
    end

    local message = {
        pid = 0,
        data = payload,
        type = (opts or {}).type or "IPC",
    }

    if opts and opts.reply_global_id then
        local replyObj = ObjectManager.get(opts.reply_global_id);
        if replyObj and replyObj.type == "PORT" then
            replyObj:retain();
            message.globalReply = opts.reply_global_id;

            table.insert(replyObj.impl.temporarySenders, recipient.pid);
        end
    end

    if opts and opts.transfer_global_ids then
        message.globalHandles = {};
        for _, gId in ipairs(opts.transfer_global_ids) do
            local obj = ObjectManager.get(gId);
            if obj then
                obj:retain();
                table.insert(message.globalHandles, gId);
            end
        end
    end

    if (#port.receivers > 0) then
        if (message.globalHandles) then
            message.handles = {};
            for _, gId in ipairs(message.globalHandles) do
                local newFd = ObjectManager.link(recipient, gId);
                table.insert(message.handles, newFd);

                ObjectManager.get(gId):release();
            end
            message.globalHandles = nil;
        end

        if (message.globalReply) then
            message.reply = ObjectManager.link(recipient, message.globalReply);
            ObjectManager.get(message.globalReply):release();
            message.globalReply = nil;
        end

        -- close temporary port
        if (port.temporary) then
            local process = ProcessRegistry.get(port.ownerPid)
            local fd;

            for i, v in pairs(process.handles) do
                if (v == port.receiveRight) then
                    fd = i;
                end
            end

            if (process and fd) then
                IPCManager.close(process, fd);
            else
                error("EINTERNAL: Failed to close temporary handler!");
            end
        end

        local receiver = table.remove(port.receivers, 1);
        Scheduler.wake(receiver, { true, { message } });
        return true;
    else
        table.insert(port.queue, message);
        return true;
    end
end

---Blocks until a message arrives on specific port.
---@param pcb Process waiting process.
---@param fd number file descriptor pointing to the port.
---@return table|nil message received
---@return string status - "OK" or "EMPTY"
---@return number|nil id of a port to subscribe for, in case its empty
function IPCManager.receive(pcb, fd)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    local rightObj = ObjectManager.get(globalId);
    if (not rightObj or rightObj.type ~= "RECEIVE_RIGHT") then
        error("EPERM: Descriptor is not a receive right.");
    end

    local portObj = ObjectManager.get(rightObj.impl.portId);

    --- @type Port
    local port = portObj.impl;

    if port.ownerPid ~= pcb.pid then
        error("EPERM: Only port owner can receive messages.");
    end

    -- if there is already something in a queue
    -- we return immediately
    if #port.queue > 0 then
        local message = table.remove(port.queue, 1);

        -- turn handles from global to local
        if message.globalHandles then
            message.handles = {};
            for _, gId in pairs(message.globalHandles) do
                local newFd = ObjectManager.link(pcb, gId);
                table.insert(message.handles, newFd);
                ObjectManager.get(gId):release();
            end
            message.globalHandles = nil;
        end

        -- handle reply port
        if message.globalReply then
            message.reply = ObjectManager.link(pcb, message.globalReply);
            ObjectManager.get(message.globalReply):release();
            message.globalReply = nil;
        end

        -- revive blocked senders
        if (#port.blockedSenders > 0) then
            local senderTid = table.remove(port.blockedSenders, 1);
            Scheduler.wake(senderTid, { true, { }});
        end

        -- close temporary port
        if (port.temporary) then
            IPCManager.close(pcb, fd);
        end

        return message, "OK";
    end

    local tid = Scheduler.getCurrentTid();
    table.insert(port.receivers, tid);

    return nil, "EMPTY", globalId
end

--- Closes port.
--- @param pcb Process process to close port for.
--- @param fd number specific file descriptor pointing to port, to get metadata for.
function IPCManager.close(pcb, fd)
    ObjectManager.close(pcb, fd);
end

--- Returns some debug data about port.
--- @param pcb Process process to get metadata for.
--- @param fd number specific file descriptor pointing to port, to get metadata for.
function IPCManager.stat(pcb, fd)
    local globalId = pcb.handles[fd];
    if (not globalId) then
        error("EBADF: Invalid file descriptor.");
    end

    local rightObj = ObjectManager.get(globalId);
    if (not rightObj) then error("EBADF: Invalid file descriptor.") end

    local portId;
    if (rightObj.type == "SEND_RIGHT" or rightObj.type == "RECEIVE_RIGHT") then
        portId = rightObj.impl.portId;
    else
        error("EBADF: File descriptor is not a port right.");
    end

    local portObj = ObjectManager.get(portId);
    if (not portObj) then error("EINTERNAL: Right points to invalid port") end

    local port = portObj.impl;

    return {
        messages = #port.queue,
        capacity = port.capacity,
        receivers = #port.receivers,
        senders = #port.senders
    }
end

---Migrates right, if receives send right - returns pointer to same send right, if gets receive right - returns pointer to send right.
---@param rightId number id of a kernel object corresponding to specific right.
---@return number id of migrated kernel object.
function IPCManager.migrateRight(rightId)
    local kernelObject = ObjectManager.get(rightId);
    if (not kernelObject) then return rightId end

    if (kernelObject.type == "SEND_RIGHT") then
        return rightId;
    elseif (kernelObject.type == "RECEIVE_RIGHT") then
        --- @type ReceiveRight
        local right = kernelObject.impl;
        local portId = right.portId;

        --- @type Port
        local port = ObjectManager.get(portId).impl;
        return port.sendRight;
    else
        return rightId
    end
end

return IPCManager;