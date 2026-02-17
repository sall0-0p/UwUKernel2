--- @class FileDescriptor
--- @field driverPort number globalId of port
--- @field fileId number id of a file inside driver to identify it
--- @field mode string The mode file is open in
--- @field cursor number position of cursor at open file
local FileDescriptor = {};
FileDescriptor.__index = FileDescriptor;

---Creates new file descriptor
---@param driverPort number
---@param fileId number
---@param mode string
function FileDescriptor.new(driverPort, fileId, mode)
    local new = {
        driverPort = driverPort,
        fileId = fileId,
        mode = mode,
        cursor = 0,
    };

    setmetatable(new, FileDescriptor);
    return new;
end

---Returns if file descriptor can be read from.
function FileDescriptor:canRead()
    return self.mode:find("r") ~= nil;
end

---Returns if file descriptor can be written to.
function FileDescriptor:canWrite()
    return self.mode:find("w") ~= nil or self.mode:find("a") ~= nil;
end

function FileDescriptor:onDestroy()
    if self.closed then return end

    local VFSProtocol = require("vfs.classes.Protocol");
    local IPCManager = require("ipc.IPCManager");

    IPCManager.sendKernelMessage(self.driverPort, {
        type = VFSProtocol.Methods.CLOSE;
        data = { field = self.fileId };
    });
end

return FileDescriptor;