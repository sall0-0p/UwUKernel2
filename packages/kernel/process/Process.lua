---@class Process
---@field pid number Unique Process ID
---@field ppid number Parent Process ID
---@field name string Debug name (e.g. "shell")
---@field uid number Real User ID
---@field euid number Effective User ID
---@field gid number Primary Group ID
---@field groups number[] Supplementary Group IDs
---@field state "ALIVE"|"ZOMBIE"|"STOPPED"
---@field exitCode number|nil Exit status
---@field children number[] List of child PIDs
---@field threads number[] List of Thread IDs owned by this process
---@field handles table<number, number> Map of local file descriptors to global objects
---@field cwd string Current Working Directory
---@field env table<string, string> Environment Variables
---@field limits table Resource limits
---@field cpuTime number Accumulated CPU usage
---@field startTime number Timestamp of creation
---@field threadsWaitingForChildren number[] Threads waiting for children. Internal.
local Process = {};
Process.__index = Process;

function Process.new(pid, ppid, name, uid, gid)
    local new = {
        pid = pid,
        name = name or "unknown",

        ppid = ppid,
        children = {},

        uid = uid or 0,
        euid = uid or 0,
        gid = gid or 0,
        groups = {},

        state = "ALIVE",
        exitCode = nil,

        threads = {},

        handles = {},
        cwd = "/",
        env = {},

        cpuTime = 0,
        startTime = os.epoch("utc"),

        limits = {
            maxFiles = 0,
            maxPorts = 0,
            maxProcesses = 0,
            maxThreads = 0,
        },

        threadsWaitingForChildren = {},
    };

    setmetatable(new, Process);
    return new;
end

return Process;