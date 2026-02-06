local ThreadRegistry = require("process.ThreadRegistry");

-- Preemption
local QUANTUM_TIME = 0.05
local QUANTUM_INSTRUCTIONS = 10000
local deadline = 0

local function hook()
    if (os.epoch("utc") > deadline) then
        coroutine.yield("PREEMPT");
    end
end

-- Actual scheduler

---@class Scheduler
local Scheduler = {}
---@type number[]
local readyThreads = {}
---@type number
local currentTid;

--- Add a thread to the execution queue.
---@param tid number id of a thread to be added.
function Scheduler.schedule(tid)
    table.insert(readyThreads, tid);
end

--- Wakes a blocked thread and prepares it to run.
---@param tid number id of a thread to wake.
---@param args table|nil values to pass to the thread.
function Scheduler.wake(tid, args)
    ---@type Thread
    local tcb = ThreadRegistry.get(tid);
    if (tcb and tcb.state == "WAITING" or tcb.state == "BLOCKED") then
        tcb.state = "READY";
        tcb.resumeArgs = args or {};
        tcb.waitingReason = nil;
        tcb.waitingFor = nil;

        table.insert(readyThreads, tid);
    end
end

--- Returns id of a thread that is currently running.
--- @return number id of a thread.
function Scheduler.getCurrentTid()
    return currentTid;
end

--- Starts the scheduler.
function Scheduler.run()
    local ThreadManager = require("ThreadManager");
    local Dispatcher = require("Dispatcher");
    local delayedThreads = {};

    while (true) do
        local tid = table.remove(readyThreads, 1);
        if (tid) then
            currentTid = tid;

            ---@type Thread
            local tcb = ThreadRegistry.get(tid);
            if (tcb and tcb.state == "READY") then
                -- change thread state and set up a hook.
                tcb.state = "RUNNING";
                deadline = os.epoch("utc") + QUANTUM_TIME;
                debug.sethook(tcb.co, hook, "", QUANTUM_INSTRUCTIONS);

                -- resume coroutine
                local args = tcb.resumeArgs or {};
                tcb.resumeArgs = nil;

                local returns = table.pack(coroutine.resume(tcb.co, table.unpack(args)));
                local ok = table.remove(returns, 1);
                local trap = table.remove(returns, 1);

                -- handle traps
                if (not ok) then
                    -- crash
                    print("Thread " .. tid .. " crashed!");
                    print("Message: " .. trap);
                    ThreadManager.terminate(tid, trap);
                elseif (coroutine.status(tcb.co) == "dead") then
                    -- adequate exit
                    print("Thread " .. tid .. " exited!");
                    local results = { trap, returns[1] }
                    ThreadManager.terminate(tid, results)
                elseif (trap == "PREEMPT") then
                    -- preempted
                    tcb.state = "READY";
                    table.insert(delayedThreads, tid);
                elseif (trap == "SYSCALL") then
                    -- syscall called
                    -- returns[1] here corresponds to syscall id;
                    -- returns[2] here corresponds to syscall arguments table;
                    local instr = Dispatcher.dispatch(tcb, returns[1], returns[2]);

                    if instr.status == "OK" then
                        tcb.state = "READY";
                        tcb.resumeArgs = { true, instr.val };
                        table.insert(readyThreads, tid);
                    elseif (instr.status == "BLOCK") then
                        tcb.state = "WAITING";
                        tcb.waitingReason = instr.reason;
                        tcb.waitingFor = instr.target;
                    elseif (instr.status == "ERROR") then
                        tcb.state = "READY"
                        tcb.resumeArgs = { false, instr.error }
                        print("Error in " .. tid .. "!!!");
                        print("Message: " .. instr.error);
                    elseif (instr.status == "DROP") then
                        -- do nothing
                    else
                        ThreadManager.terminate(tid, "Unknown error in Dispatcher!");
                    end
                else
                    -- regular yield
                    -- may cause problems in future,
                    -- I assume that sometimes user can call coroutine.yield without arguments.
                    -- Or something like that.
                    tcb.state = "READY";
                    tcb.resumeArgs = { true };
                    table.insert(delayedThreads, tid);
                end
            end
        else
            -- merge delayed threads
            if (#delayedThreads > 0) then
                for _, v in pairs(delayedThreads) do
                    table.insert(readyThreads, v);
                end

                os.queueEvent("kernel_yield");
                delayedThreads = {};
            end

            -- process events
            local eventData = { os.pullEventRaw() };
            local type = eventData[1];
            local param1 = eventData[2];

            if type == "terminate" then
                print("Terminating!");
                break;
            end

            if type ~= "kernel_yield" then
                -- TODO: Process event.
            end
        end
    end
end

return Scheduler;