--- @class VolumeWrapper
local VolumeWrapper = {};
VolumeWrapper.__index = VolumeWrapper;

--- Creates a new Volume device.
--- @param name string The device name (e.g., "volume:system")
--- @param rootPath string The physical host path this volume represents (e.g., "/SystemVolume")
function VolumeWrapper.new(name, rootPath)
    local new = {
        type = "filesystem",
        root = rootPath,
        methods = {
            "list", "exists", "isDir", "isReadOnly",
            "getName", "getSize", "getFreeSpace", "makeDir",
            "move", "copy", "delete", "attributes", "open"
        },
    };

    local methodMap = {}
    for _, m in ipairs(new.methods) do methodMap[m] = true end
    new.methods = methodMap;

    setmetatable(new, VolumeWrapper);
    return new;
end

--- Resolves a virtual path to a physical path within the volume root.
local function resolve(root, path)
    local combined = fs.combine(root, path)

    if combined:sub(1, #root) ~= root then
        return root
    end

    return combined
end

--- Calls a method
function VolumeWrapper:call(method, ...)
    local args = {...};

    if type(args[1]) == "string" then
        args[1] = resolve(self.root, args[1]);
    end

    if (method == "copy" or method == "move") and type(args[2]) == "string" then
        args[2] = resolve(self.root, args[2]);
    end

    local result = table.pack(pcall(fs[method], table.unpack(args)));
    local success = table.remove(result, 1);
    if not success then
        error(result[1], 2);
    end

    return table.unpack(result);
end

return VolumeWrapper;