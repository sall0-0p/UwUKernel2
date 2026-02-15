local VFSProtocol = {};

VFSProtocol.Methods = {
    OPEN = "VFS_OPEN",
    CLOSE = "VFS_CLOSE",
    READ = "VFS_READ",
    WRITE = "VFS_WRITE",
    SEEK = "VFS_SEEK",
    STAT = "VFS_STAT",
    LIST = "VFS_LIST",
    MKDIR = "VFS_MKDIR",
    DELETE = "VFS_DELETE",
    RENAME = "VFS_RENAME",
    COPY = "VFS_COPY",
    SET = "VFS_SET",
}

VFSProtocol.Status = {
    OK = "OK",
    ERROR = "ERROR",
}

return VFSProtocol;