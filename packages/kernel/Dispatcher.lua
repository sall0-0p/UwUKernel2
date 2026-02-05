--- @class Dispatcher
local Dispatcher = {};

---Execute syscall that comes from specific process.
---Must return a table `{ status = "OK", val = {...} }` if thread should be resumed
---or return a `{ status = "BLOCK", reason = "Some debug reason", target = some_pid }` if it should be blocked
---@param tcb Thread thread syscall originates from
---@param syscallId number
---@param syscallArguments table
---@return table
function Dispatcher.dispatch(tcb, syscallId, syscallArguments)
    return { status = "OK", val = "Hello World!" };
end

return Dispatcher;