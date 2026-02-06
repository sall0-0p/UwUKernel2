local ObjectManager = require("objects.ObjectManager");
local KernelObject = require("objects.KernelObject");
local Port = require("ipc.Port");
local Scheduler = require("Scheduler");
local ProcessRegistry = require("process.ProcessRegistry");

--- @class IPCManager
local IPCManager = {};

---Creates new port.
---Calling process gets receive right by default, by owning the process.
---@param pcb Process process that creates new port.
---@return number file descriptor of created port.
function IPCManager.createPort(pcb)
    local port = Port.new(pcb.pid);

    local fd = ObjectManager.createHandle(pcb, KernelObject.new("PORT", port));
    return fd;
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

    local portObj = ObjectManager.get(globalId);
    if (not portObj or portObj.type ~= "PORT") then
        error("EBADF: File descriptor is not a port.");
    end

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
        globalReplyPort = pcb.handles[localReplyPort];

        if (not globalReplyPort) then
            error("EBADF: Invalid reply file descriptor");
        end

        local globalReplyPortObject = ObjectManager.get(globalReplyPort);
        if (not globalReplyPortObject or globalReplyPortObject.type ~= "PORT") then
            error("EBADF: Reply file descriptor is not a port!");
        end

        -- retain it so noone does something evil and crashes the kernel
        globalReplyPortObject:retain();

        --- @type Port
        local replyPort = globalReplyPortObject.impl;
        table.insert(replyPort.temporarySenders, recipient.pid);
    end

    local message = {
        pid = pcb.pid,
        globalReply = globalReplyPort,
        data = payload,
    }

    -- build the message object (handles)
    if (opts and opts.transfer) then
        message.globalHandles = {};
        for _, v in pairs(opts.transfer) do
            local gId = pcb.handles[v];
            if (not gId or not ObjectManager.get(gId)) then
                error("EBADF: Trying to transfer invalid file descriptor.");
            end

            -- temporary retain objects so they are not cleaned up in .close()
            local gObject = ObjectManager.get(gId);
            gObject:retain();

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

    local portObj = ObjectManager.get(globalId);
    if (not portObj or portObj.type ~= "PORT") then
        error("EBADF: File descriptor is not a port.");
    end

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

        return message, "OK";
    end

    local tid = Scheduler.getCurrentTid();
    table.insert(port.receivers, tid);

    return nil, "EMPTY", globalId
end

function IPCManager.close(pcb, fd)

end

function IPCManager.stat(pcb, fd)

end

return IPCManager;