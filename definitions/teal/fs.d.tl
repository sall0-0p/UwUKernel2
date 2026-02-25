local record fs 
    enum OpenMode 
        "r"
        "w"
        "a"
        "r+" -- I forgor what this does
    end

    enum SeekWhence 
        "set"
        "cur"
        "end"
    end

    record PermissionBlock 
        read: boolean
        write: boolean
        execute: boolean
    end

    record FilePermissions
        raw: number
        string: string

        user: PermissionBlock
        group: PermissionBlock
        other: PermissionBlock
        
        setuid: boolean
        setgid: boolean
        sticky: boolean
    end

    record FileMetadata
        uid: number
        gid: number
        size: number
        isDir: boolean
        isLink: boolean
        created: number
        modified: number
        accessed: number
        linkTarget: string | nil
        permissions: FilePermissions
    end

    record SettableAttributes
        mode: number
        uid: number
        gid: number
        modified: number
        created: number
        accessed: number
    end

    open: function(path: string, mode: OpenMode): number
    close: function(fd: number): nil
    read: function(fd: number, count: number, offset?: number): string | nil
    write: function(fd: number, data: string, offset?: number): number
    seek: function(fd: number, offset: number, whence: SeekWhence): number
    stat: function(path: string): FileMetadata
    ioctl: function(fd: number, cmd: string, any...): any
    mount: function(path: string, port: number): nil
    unmount: function(path: string): nil
    setaddr: function(path: string, attr: SettableAttributes): nil
    rename: function(path: string, destinaton: string): nil
    copy: function(path: string, destination: string): nil
    remove: function(path: string): nil
    mkdir: function(path: string): nil
end

return fs