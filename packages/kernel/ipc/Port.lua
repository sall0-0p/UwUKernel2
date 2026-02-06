--- @class Port
--- @field queue table messages in a queue
--- @field capacity number capacity of a queue
--- @field senders number[] processes with send right
--- @field receivers number[] threads waiting for messages
--- @field temporarySenders number[] threads that have receive right, but only for once
--- @field blockedSenders number[] threads that are blocked by attempting to send when queue is full
--- @field ownerPid number pid of a process that port belongs to
local Port = {}
Port.__index = Port;

function Port.new(ownerPid)
    local new = {
        queue = {},
        capacity = 16,
        receivers = {},
        ownerPid = ownerPid,
        senders = {},

        temporarySenders = {},
        blockedSenders = {},
    }

    setmetatable(new, Port);
    return new;
end

---@param by number pid of a process we are transferred to
function Port:onAcquire(by)
    if (self.ownerPid == nil) then
        self.ownerPid = by;

        for i, v in pairs(self.senders) do
            if (v == by) then
                table.remove(self.senders, i);
                break;
            end
        end
    else
        table.insert(self.senders, by);
    end
end

---@param from number pid of a process we are transferred from
function Port:onRelease(from)
    if (from == self.ownerPid) then
        self.ownerPid = nil;
    else
        for i, v in pairs(self.senders) do
            if (v == by) then
                table.remove(self.senders, i);
                break;
            end
        end
    end
end

return Port;