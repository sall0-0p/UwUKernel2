local raw = require("native");

--- @class UserContext
--- @field uid number
--- @field gid number
--- @field groups number[]

--- @class FileHandle
--- @field read function(bytes: number, offset: number, user: UserContext): string
--- @field write function(data: string, offset: number, user: UserContext): number
--- @field ioctl function(cmd: string, args: any[], user: UserContext): any
--- @field close function(): nil

--- @class VFSHandlers
--- @field onOpen function(path: string, mode: string, user: UserContext): FileHandle
--- @field onSeek function(fileId: number, offset: number, whence: number): number
--- @field onStat function(path: string, user: UserContext): table
--- @field onList function(path: string, user: UserContext): string[]
--- @field onMkdir function(path: string, user: UserContext): nil
--- @field onRemove function(path: string, user: UserContext): nil
--- @field onRename function(path: string, destination: string, user: UserContext): nil
--- @field onCopy function(path: string, destination: string, user: UserContext): nil
--- @field onSetattr function(path: string, attr: table, user: UserContext): nil

--- @class FileSystemServer
--- @field port number port messages are being sent to.
--- @field handlers VFSHandlers handlers for a server.
--- @field running boolean if server is running.
local FileSystemServer = {};
FileSystemServer.__index = FileSystemServer;

---Constructs new filesystem server, yay.
---@param handlers VFSHandlers
function FileSystemServer.new(handlers)
    local server = setmetatable({}, FileSystemServer);
    server.port = raw.ipc.create();
    server.handlers = handlers;
    server.running = false;
    server.openFiles = {};
    server.nextFileId = 1;
    return server;
end

function FileSystemServer:start()
    self.running = true
    while (self.running) do
        local message = raw.ipc.receive(self.port)
        local msgType = message.type
        local payload = message.data
        local reply = message.reply

        local ok, err = pcall(function()
            if (msgType == "VFS_OPEN") then
                if (not self.handlers.onOpen) then error("ENOSYS: Operation open is not available.", 2) end
                local fileHandle = self.handlers:onOpen(payload.path, payload.mode, payload.user);
                local fileId = self.nextFileId;
                self.nextFileId = self.nextFileId + 1;
                self.openFiles[fileId] = fileHandle;

                raw.ipc.send(reply, { status = "OK", data = { fileId = fileId } });

            elseif (msgType == "VFS_CLOSE") then
                local handle = self.openFiles[payload.fileId];
                if handle and handle.close then handle:close() end;
                self.openFiles[payload.fileId] = nil;
                raw.ipc.send(reply, { status = "OK" });

            elseif (msgType == "VFS_READ") then
                local handle = self.openFiles[payload.fileId];
                if (not handle) then error("EBADF: Invalid file descriptor passed to driver.", 2) end;
                if (not handle.read) then error("ENOSYS: Operation read is not supported.", 2) end;
                local data = handle:read(payload.bytes, payload.offset, payload.user);
                raw.ipc.send(reply, { status = "OK", data = data })

            elseif (msgType == "VFS_WRITE") then
                local handle = self.openFiles[payload.fileId];
                if (not handle) then error("EBADF: Invalid file descriptor passed to driver.", 2) end;
                if (not handle.write) then error("ENOSYS: Operation write is not supported.", 2) end;
                local written = handle:write(payload.data, payload.offset, payload.user);
                raw.ipc.send(reply, { status = "OK", data = written })

            elseif (msgType == "VFS_STAT") then
                if (not self.handlers.onStat) then error("ENOSYS: Operation stat is not available.", 2) end
                -- Handle VFS_STAT being called with path OR fileId (for seek end)
                local metadata = self.handlers:onStat(payload.path or payload.fileId, payload.user)
                raw.ipc.send(reply, { status = "OK", data = metadata })

            elseif (msgType == "VFS_LIST") then
                if (not self.handlers.onList) then error("ENOSYS: Operation list is not available.", 2) end
                local entries = self.handlers:onList(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK", data = entries })

            elseif (msgType == "VFS_MKDIR") then
                if (not self.handlers.onMkdir) then error("ENOSYS: Operation mkdir is not available.", 2) end
                self.handlers:onMkdir(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_REMOVE") then
                if (not self.handlers.onRemove) then error("ENOSYS: Operation remove is not available.", 2) end
                self.handlers:onRemove(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_RENAME") then
                if (not self.handlers.onRename) then error("ENOSYS: Operation rename is not available.", 2) end
                self.handlers:onRename(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_COPY") then
                if (not self.handlers.onCopy) then error("ENOSYS: Operation copy is not available.", 2) end
                self.handlers:onCopy(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_SETATTR") then
                if (not self.handlers.onSetattr) then error("ENOSYS: Operation setattr is not available.", 2) end
                self.handlers:onSetattr(payload.path, payload.attr, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_IOCTL") then
                local handle = self.openFiles[payload.fileId];
                if (not handle) then error("EBADF: Invalid file descriptor passed to driver.", 2) end;
                if (not handle.ioctl) then error("ENOSYS: Operation ioctl is not supported.", 2) end;
                local result = handle:ioctl(payload.cmd, payload.args, payload.user);
                raw.ipc.send(reply, { status = "OK", data = result });

            elseif (msgType == "VFS_SHUTDOWN") then
                self.running = false
                raw.ipc.send(reply, { status = "OK" })

            else
                error("ENOSYS: Unknown VFS method: " .. tostring(msgType))
            end
        end)

        if not ok then
            raw.ipc.send(reply, { status = "ERROR", data = err })
        end

        pcall(raw.ipc.close, reply);
    end
end

function FileSystemServer:stop()
    self.running = false;
    raw.ipc.send(self.port, {}, { type = "VFS_SHUTDOWN" });
end

function FileSystemServer:getPortId()
    return self.port;
end

return FileSystemServer;