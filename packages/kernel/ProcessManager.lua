local ProcessRegistry = require("process.ProcessRegistry");
local Process = require("process.Process");
local ObjectManager = require("obj.ObjectManager");
local ThreadManager = require("ThreadManager");
local Scheduler = require("Scheduler");

--- @class ProcessManager
local ProcessManager = {};

---Spawn a new process.
---@param ppid number parent pid.
---@param path string path to the executable.
---@param args string[] command-line arguments to the application.
---@param attr table table of attributes.
---@return number pid of a newly created process.
function ProcessManager.spawn(ppid, path, args, attr)
    -- Check parent and validate permissions.
    local parent = ProcessRegistry.get(ppid);
    if (not parent and ProcessRegistry.get(1)) then error("ESRSH: Invalid parent.") end;
    attr = attr or {};

    local currentUid = parent and parent.uid or 0
    if (attr.uid and attr.uid ~= currentUid and currentUid ~= 0) then
        error("EPERM: No permission.");
    end

    -- Create new PCB.
    local newPid = ProcessRegistry.getNextPid();
    local targetUid = attr.uid or currentUid;
    local targetGid = attr.gid or (parent and parent.gid or 0);
    local child = Process.new(
            newPid,
            ppid,
            path,
            targetUid, targetGid
    );

    -- Inherit working directory and environment.
    child.cwd = parent and parent.cwd or "/";

    -- TODO: Copy environment.

    -- File descriptor inheritance / passing.
    if (parent and attr.fds) then
        for childFd, parentFd in pairs(attr.fds) do
            local globalId = parent.handles[parentFd];
            if (not globalId) then
                error("EBADF: Parent handle " .. tostring(parentFd) .. " is invalid");
            end

            child.handles[childFd] = globalId

            local kernelObject = ObjectManager.get(globalId);
            kernelObject:retain()
        end
    elseif (parent) then
        for localFd, globalId in pairs(parent.handles) do
            child.handles[localFd] = globalId

            local kernelObject = ObjectManager.get(globalId)
            kernelObject:retain()
        end
    else
        -- TODO: Create some basic handles for our lovely launchd.
    end

    ProcessRegistry.register(newPid, child);
    if (parent) then parent.children[#parent.children + 1] = newPid end;

    -- get environment,
    -- TODO: replace with separate factory
    local processEnv = {
        arg = args or {};
        sys = function(id, ...)
            local result, returns = coroutine.yield("SYSCALL", id, table.pack(...));
            if (result) then
                return table.unpack(returns);
            else
                error(returns, 2);
            end
        end,
        print = function(...)
            local returns = print(...);
            coroutine.yield();
            return returns;
        end,
        write = function(...)
            local returns = term.write(...);
            coroutine.yield();
            return returns;
        end
    }

    -- temporary and shitty
    -- TODO: REMOVE THIS.
    setmetatable(processEnv, { __index = _G, __tostring = "env" });
    child.env = processEnv;

    -- get source
    local blob = path;
    if (not attr.blob) then
        -- TODO: REPLACE WITH VFS
        local file = fs.open(path, "r");
        blob = file.readAll();
        file.close();
    end

    if (not blob) then
        ProcessRegistry.remove(newPid);
        error("ENOENT: Executable not found: " .. path);
    end

    -- load source
    local chunkName = (attr.blob and (attr.name or "unknown")) or path;
    local chunk, syntaxErr = loadstring(blob, chunkName);
    if (not chunk) then
        ProcessRegistry.remove(newPid);
        error("ENOEXEC: Syntax error: " .. tostring(syntaxErr));
    end

    -- execute source
    local mainTid = ThreadManager.create(newPid, chunk, args);
    child.threads[1] = mainTid;

    return newPid;
end

---Exit the process.
---@param pid number process to exit.
---@param exitCode number exit code, defaults to 0.
function ProcessManager.exit(pid, exitCode)
    local pcb = ProcessRegistry.get(pid);
    if (not pcb) then error("ESRSH: Process not found.") end;

    -- Terminate threads.
    for _, tid in ipairs(pcb.threads) do
        ThreadManager.terminate(tid);
    end

    -- Close handles.
    for fd, _ in pairs(pcb.handles) do
        ObjectManager.close(pcb, fd);
    end
    pcb.handles = {};

    -- Move orphans to launchd.
    if #pcb.children > 0 then
        local launchd = ProcessRegistry.get(1);
        for _, childPid in ipairs(pcb.children) do
            local childPcb = ProcessRegistry.get(childPid);
            if childPcb then
                childPcb.ppid = 1;
                table.insert(launchd.children, childPid);
            end
        end
        pcb.children = {};
    end

    pcb.state = "ZOMBIE";
    pcb.exitCode = exitCode or 0;
    pcb.endTime = os.epoch("utc");

    local parent = ProcessRegistry.get(pcb.ppid)
    if parent then
        for i = #parent.threadsWaitingForChildren, 1, -1 do
            local waiter = parent.threadsWaitingForChildren[i];
            if waiter.target == -1 or waiter.target == pid then
                table.remove(parent.threadsWaitingForChildren, i);
                Scheduler.wake(waiter.tid);
            end
        end
    end
end

---Wait until child process exits.
---@param callingProcess Process process that is supposed to wait.
---@param targetPid number pid of a child to wait for, -1 for any.
---@param opts table table of options.
function ProcessManager.wait(callingProcess, targetPid, opts)
    opts = opts or {};

    if (#callingProcess.children == 0) then
        error("ECHILD: No child processes.");
    end

    -- Search for a zombie process among children.
    local foundMatch = false;
    for i, childPid in ipairs(callingProcess.children) do
        if (targetPid == -1) or (targetPid == childPid) then
            foundMatch = true;
            local child = ProcessRegistry.get(childPid);

            if (child and child.state == "ZOMBIE") then
                local result = {
                    pid = child.pid,
                    code = child.exitCode,
                    usage = child.cpuTime or 0
                }

                ProcessRegistry.remove(childPid);
                table.remove(callingProcess.children, i);
                return result;
            end
        end
    end

    if targetPid ~= -1 and not foundMatch then
        error("ECHILD: PID " .. targetPid .. " is not a child of this process.")
    end

    local callerTid = Scheduler.getCurrentTid();
    table.insert(callingProcess.threadsWaitingForChildren, {
        tid = callerTid,
        target = targetPid,
    });

    return {
        status = "BLOCK",
        reason = "CHILD",
        target = targetPid,
    }
end

return ProcessManager;
