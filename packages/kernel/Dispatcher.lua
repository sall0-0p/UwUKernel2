--- @class Dispatcher
local Dispatcher = {};
local syscalls = {};

local modules = {
    require("syscalls.proc"),
    require("syscalls.thread"),
    require("syscalls.ipc"),
    -- require("syscalls.fs"),
    -- require("syscalls.io"),
     require("syscalls.sys"),
    -- require("syscalls.dev"),
    -- require("syscalls.sync"),
};

for _, module in pairs(modules) do
    for i, v in pairs(module) do
        syscalls[i] = v;
    end
end

---Execute syscall that comes from specific process.
---Must return a table `{ status = "OK", val = {...} }` if thread should be resumed
---or return a `{ status = "BLOCK", reason = "Some debug reason", target = some_pid }` if it should be blocked
---@param tcb Thread thread syscall originates from
---@param syscallId number
---@param syscallArguments table
---@return table
function Dispatcher.dispatch(tcb, syscallId, syscallArguments)
    if (not syscalls[syscallId]) then
        return { status = "ERROR", error = "ENOSYS: Unknown syscall" .. syscallId }
    end

    local results = table.pack(pcall(syscalls[syscallId], tcb, table.unpack(syscallArguments)));
    local success = table.remove(results, 1);

    -- return if errored;
    if (not success) then
        return { status = "ERROR", error = results[1] };
    end

    if (#results == 0) then
        return { status = "DROP" };
    end

    -- return if block
    if (type(results[1]) == "table" and results[1].status == "BLOCK") then
        return results[1];
    end

    -- return normally
    return { status = "OK", val = results };
end

return Dispatcher;