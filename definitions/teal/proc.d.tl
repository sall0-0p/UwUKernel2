local record proc 
    enum ProcessLimit 
        "maxThreads"
        "maxProcesses"
        "maxFiles"
        "maxPorts"
    end

    record ProcessLimits 
        maxThreads: number
        maxProcesses: number
        maxFiles: number
        maxPorts: number
    end

    record SpawnAttributes 
        env: {string, string} | nil
        cwd: string | nil
        fds: {number, number} | nil
        uid: number | nil
        gid: number | nil
        groups: {number} | nil
        name: string | nil
        limits: ProcessLimits | nil
        blob: string | nil
        preload: {string, function} | nil
    end

    record WaitReturns 
        pid: number
        code: number
        usage: number
    end

    record ProcessInfo 
        pid: number
        ppid: number
        uid: number
        gid: number
        state: string
        groups: {number}
        name: string
        cpuTime: number
        children: {number}
        limits: ProcessLimits
    end

    record SettableAttributes 
        uid: number | nil
        gid: number | nil
        groups: {number} | nil
        cwd: string | nil
    end

    spawn: function(path: string, args?: {string}, attributes?: table): number
    exit: function(code: number): nil
    wait: function(pid: number, opts?: table): WaitReturns
    kill: function(pid: number, signal: number): nil
    info: function(pid?: number): ProcessInfo
    setaddr: function(attr: SettableAttributes): SettableAttributes
    limit: function(resource: string, value: number): nil
    list: function(): {number}
end

return proc;