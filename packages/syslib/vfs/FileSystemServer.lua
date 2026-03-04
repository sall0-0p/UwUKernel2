local raw = require("native");

--- @class UserContext
--- @field uid number
--- @field gid number
--- @field groups number[]

--- @class VFSHandlers
--- @field onOpen function(path: string, mode: string, user: UserContext) -> fileId: number
--- @field onClose function(fileId: number) -> void
--- @field onRead function(fileId: number, bytes: number, offset: number, user: UserContext) -> data: string
--- @field onWrite function(fileId: number, data: string, offset: number, user: UserContext) -> written: number
--- @field onSeek function(fileId: number, offset: number, whence: number) -> position: number
--- @field onStat function(path: string, user: UserContext) -> metadata: table
--- @field onList function(path: string, user: UserContext) -> entries: string[]
--- @field onMkdir function(path: string, user: UserContext) -> void
--- @field onRemove function(path: string, user: UserContext) -> void
--- @field onRename function(path: string, destination: string, user: UserContext) -> void
--- @field onCopy function(path: string, destination: string, user: UserContext) -> void
--- @field onSetattr function(path: string, attr: table, user: UserContext) -> void
--- @field onIoctl function(fileId: number, cmd: string, args: any[], user: UserContext) -> result: any

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
                if (not self.handlers.onOpen) then error("ENOSYS: Operation open is not available.") end
                local fileId = self.handlers.onOpen(payload.path, payload.mode, payload.user)
                raw.ipc.send(reply, { status = "OK", data = { fileId = fileId } })

            elseif (msgType == "VFS_CLOSE") then
                if (not self.handlers.onClose) then error("ENOSYS: Operation close is not available.") end
                self.handlers.onClose(payload.fileId)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_READ") then
                if (not self.handlers.onRead) then error("ENOSYS: Operation read is not available.") end
                local data = self.handlers.onRead(payload.fileId, payload.bytes, payload.offset, payload.user)
                raw.ipc.send(reply, { status = "OK", data = data })

            elseif (msgType == "VFS_WRITE") then
                if (not self.handlers.onWrite) then error("ENOSYS: Operation write is not available.") end
                local written = self.handlers.onWrite(payload.fileId, payload.data, payload.offset, payload.user)
                raw.ipc.send(reply, { status = "OK", data = written })

            elseif (msgType == "VFS_STAT") then
                if (not self.handlers.onStat) then error("ENOSYS: Operation stat is not available.") end
                -- Handle VFS_STAT being called with path OR fileId (for seek end)
                local metadata = self.handlers.onStat(payload.path or payload.fileId, payload.user)
                raw.ipc.send(reply, { status = "OK", data = metadata })

            elseif (msgType == "VFS_LIST") then
                if (not self.handlers.onList) then error("ENOSYS: Operation list is not available.") end
                local entries = self.handlers.onList(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK", data = entries })

            elseif (msgType == "VFS_MKDIR") then
                if (not self.handlers.onMkdir) then error("ENOSYS: Operation mkdir is not available.") end
                self.handlers.onMkdir(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_REMOVE") then
                if (not self.handlers.onRemove) then error("ENOSYS: Operation remove is not available.") end
                self.handlers.onRemove(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_RENAME") then
                if (not self.handlers.onRename) then error("ENOSYS: Operation rename is not available.") end
                self.handlers.onRename(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_COPY") then
                if (not self.handlers.onCopy) then error("ENOSYS: Operation copy is not available.") end
                self.handlers.onCopy(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_SETATTR") then
                if (not self.handlers.onSetattr) then error("ENOSYS: Operation setattr is not available.") end
                self.handlers.onSetattr(payload.path, payload.attr, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_IOCTL") then
                if (not self.handlers.onIoctl) then error("ENOSYS: Operation ioctl is not available.") end
                local result = self.handlers.onIoctl(payload.fileId, payload.cmd, payload.args, payload.user)
                raw.ipc.send(reply, { status = "OK", data = result })

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