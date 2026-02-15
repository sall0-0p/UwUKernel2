---@class MountRegistry
local MountRegistry = {};
local mounts = {};

---Registers a mount point.
---@param path string path to register mount point for.
---@param globalId number id pointing to the PORT messages should arrive at.
function MountRegistry.register(path, globalId)
    mounts[path] = globalId;
end

---Resolves port of a mount point with longest prefix.
---@param path string path to resolve path for.
---@return number|nil global id of a resolved PORT.
function MountRegistry.resolve(path)
    --- @type number|nil
    local bestMatch = nil;
    local longestLen = -1;

    for mountPath, portId in pairs(mounts) do
        if path:find(mountPath, 1, true) == 1 then
            local mountLen = #mountPath;
            local nextChar = path:sub(mountLen + 1, mountLen + 1);

            if nextChar == "" or nextChar == "/" then
                if mountLen > longestLen then
                    longestLen = mountLen;
                    bestMatch = portId;
                end
            end
        end
    end

    return bestMatch;
end

---Unregisters mount point.
---@param path string path to unregister mount for.
function MountRegistry.unregister(path)
    mounts[path] = nil;
end

return MountRegistry;