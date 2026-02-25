local record sys 
    enum EpochLocale 
        "ingame"
        "utc"
        "local"
    end

    record SystemInfo 
        uptime: number
        version: string
        build: number
        craftos_version: string
        idleTime: number
        runningTime: number
        host: string
        startEpoch: number
    end

    epoch: function(locale: EpochLocale): number
    timer: function(port: number, duration: number, cookie?: any): number
    alarm: function(time: number): number
    cancel: function(id: number): nil
    log: function(level: string, msg: string): nil
    info: function(): SystemInfo
    bind_event: function(event: string, port: number): nil
    unbind_event: function(event: string): nil
    shutdown: function(): nil
    reboot: function(): nil
    signal: function(signal: number, port: number): nil
end

return sys