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
--- @field handles VFSHandlers handlers for a server.
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
                if (not self.handles.onOpen) then error("ENOSYS") end
                local fileId = self.handles.onOpen(payload.path, payload.mode, payload.user)
                raw.ipc.send(reply, { status = "OK", data = { fileId = fileId } })

            elseif (msgType == "VFS_CLOSE") then
                if (not self.handles.onClose) then error("ENOSYS") end
                self.handles.onClose(payload.fileId)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_READ") then
                if (not self.handles.onRead) then error("ENOSYS") end
                local data = self.handles.onRead(payload.fileId, payload.bytes, payload.offset, payload.user)
                raw.ipc.send(reply, { status = "OK", data = data })

            elseif (msgType == "VFS_WRITE") then
                if (not self.handles.onWrite) then error("ENOSYS") end
                local written = self.handles.onWrite(payload.fileId, payload.data, payload.offset, payload.user)
                raw.ipc.send(reply, { status = "OK", data = written })

            elseif (msgType == "VFS_STAT") then
                if (not self.handles.onStat) then error("ENOSYS") end
                -- Handle VFS_STAT being called with path OR fileId (for seek end)
                local metadata = self.handles.onStat(payload.path or payload.fileId, payload.user)
                raw.ipc.send(reply, { status = "OK", data = metadata })

            elseif (msgType == "VFS_LIST") then
                if (not self.handles.onList) then error("ENOSYS") end
                local entries = self.handles.onList(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK", data = entries })

            elseif (msgType == "VFS_MKDIR") then
                if (not self.handles.onMkdir) then error("ENOSYS") end
                self.handles.onMkdir(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_REMOVE") then
                if (not self.handles.onRemove) then error("ENOSYS") end
                self.handles.onRemove(payload.path, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_RENAME") then
                if (not self.handles.onRename) then error("ENOSYS") end
                self.handles.onRename(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_COPY") then
                if (not self.handles.onCopy) then error("ENOSYS") end
                self.handles.onCopy(payload.path, payload.destination, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_SETATTR") then
                if (not self.handles.onSetattr) then error("ENOSYS") end
                self.handles.onSetattr(payload.path, payload.attr, payload.user)
                raw.ipc.send(reply, { status = "OK" })

            elseif (msgType == "VFS_IOCTL") then
                if (not self.handles.onIoctl) then error("ENOSYS") end
                local result = self.handles.onIoctl(payload.fileId, payload.cmd, payload.args, payload.user)
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

        -- just in case
        raw.ipc.close(reply)
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