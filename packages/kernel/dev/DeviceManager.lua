local DeviceRegistry = require("dev.DeviceRegistry");
local ObjectManager = require("core.ObjectManager");

local PeripheralWrapper = require("dev.devices.Peripheral");
local TerminalWrapper = require('dev.devices.Terminal');
local VolumeWrapper = require("dev.devices.Volume");

--- @class DeviceManager
local DeviceManager = {};

--- Scan available computercraft devices, as well as virtual devices and populate the registry.
function DeviceManager.onStartup()
    local nativeNames = peripheral.getNames();
    for _, name in ipairs(nativeNames) do
        local type = peripheral.getType(name);
        local wrapper = PeripheralWrapper.new(name, type);
        DeviceRegistry.register(name, wrapper);
    end

    local termDevice = TerminalWrapper.new();
    DeviceRegistry.register("terminal", termDevice);

    if not fs.exists("/SystemVolume") then fs.makeDir("/SystemVolume") end
    if not fs.exists("/DataVolume") then fs.makeDir("/Data") end

    local sysVol = VolumeWrapper.new("system", "/SystemVolume");
    DeviceRegistry.register("volume:system", sysVol);

    local dataVol = VolumeWrapper.new("data", "/DataVolume");
    DeviceRegistry.register("volume:data", dataVol);
end

function DeviceManager.open(pcb, name)
    local device = DeviceRegistry.get(name);
    if not device then
        error("ENOENT: Device not found: " .. tostring(name));
    end
    
    device.onAcquire = function(self, pid)
        if self.claimedBy and self.claimedBy ~= pid then
            error("EBUSY: Device is claimed by PID " .. self.claimedBy);
        end
        self.claimedBy = pid;
    end

    device.onDestroy = function(self)
        self.claimedBy = nil;
    end

    local kObj = KernelObject.new("DEVICE", device);
    return ObjectManager.link(pcb, ObjectManager.register(kObj));
end

function DeviceManager.call(pcb, fd, method, ...)
    local globalId = pcb.handles[fd];
    if not globalId then
        error("EBADF: Invalid file descriptor.");
    end

    local kObj = ObjectManager.get(globalId);
    if not kObj or kObj.type ~= "DEVICE" then
        error("EBADF: Handle is not a device.");
    end

    local device = kObj.impl;

    if not device.methods[method] then
        error("ENOSYS: Method " .. tostring(method) .. " not found on device.");
    end

    return device:call(method, ...);
end

function DeviceManager.list()
    return DeviceRegistry.getAll();
end

function DeviceManager.type(name)
    local device = DeviceRegistry.get(name);
    if not device then return nil end;
    return device.type;
end

function DeviceManager.methods(name)
    local device = DeviceRegistry.get(name);
    if not device then return nil end;

    local mList = {};
    for k, _ in pairs(device.methods) do
        table.insert(mList, k);
    end
    return mList;
end

--- On events like peripheral and peripheral_detach - update the registry.
function DeviceManager.onEvent(event, data)
    if event == "peripheral" then
        local name = data[1];
        local type = peripheral.getType(name);
        local wrapper = PeripheralWrapper.new(name, type);
        DeviceRegistry.register(name, wrapper);
    elseif event == "peripheral_detach" then
        -- TODO: Send signal to process.
        local name = data[1];
        DeviceRegistry.remove(name);
    end
end

return DeviceManager;