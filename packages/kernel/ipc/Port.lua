--- @class Port
--- @field queue table messages in a queue
--- @field capacity number capacity of a queue
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

        temporarySenders = {},
        blockedSenders = {},
    }

    setmetatable(new, Port);
    return new;
end

return Port;