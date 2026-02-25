local record ipc
    record SendOptions 
        timeout: number | nil -- unavailable
        reply_port: number | nil
        transfer: {number} | nil
        type: string | nil
    end

    record ReceiveOptions
        
    end

    record IpcMessage 
        pid: number
        reply: number | nil
        handles: {number} | nil
        data: table
    end

    record IpcStat 
        messages: number
        capacity: number
        receivers: number -- wont it be always 1?
        senders: number
    end

    create: function(): number
    send: function(port: number, msg: table, opts?: SendOptions): nil
    receive: function(port: number, opts?: ReceiveOptions): IpcMessage
    close: function(port: number): nil
    stat: function(port: number): IpcStat
end

return ipc