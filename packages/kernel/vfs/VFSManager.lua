--- @class VFSManager
local VFSManager = {};

---Opens a file, returns file descriptor.
---@param pcb Process
---@param path string
---@param mode string
---@param options table
function VFSManager.open(pcb, path, mode, options) end

---Closes open file descriptor.
---@param pcb Process
---@param fd number
function VFSManager.close(pcb, fd) end

---Reads file from file descriptor.
---@param pcb Process
---@param fd number
---@param number number
---@param offset number
function VFSManager.read(pcb, fd, number, offset) end

---Writes to file using file descriptor.
---@param pcb Process
---@param fd number
---@param data string
---@param offset number
function VFSManager.write(pcb, fd, data, offset) end

---ioctl
---@param pcb Process
---@param fd number
---@param cmd string
function VFSManager.ioctl(pcb, fd, cmd, ...) end

---seek
---@param pcb Process
---@param fd number
---@param offset number
---@param whence number
function VFSManager.seek(pcb, fd, offset, whence) end

---stat
---@param pcb Process
---@param path string
---@param opts table
function VFSManager.stat(pcb, path, opts) end

---list
---@param pcb Process
---@param path table
function VFSManager.list(pcb, path) end

---modify
---@param pcb Process
---@param cmd string
---@param path string
---@param arg string
function VFSManager.modify(pcb, cmd, path, arg) end

---setattr
---@param pcb Process
---@param path string
---@param attr table
function VFSManager.setattr(pcb, path, attr) end

---mount
---@param pcb Process
---@param path string
---@param port number
function VFSManager.mount(pcb, path, port) end

---unmount
---@param pcb Process
---@param path string
function VFSManager.unmount(pcb, path) end

return VFSManager;