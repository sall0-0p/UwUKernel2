local DeviceRegistry = require("dev.DeviceRegistry");
local ProcessRegistry = require("proc.registry.ProcessRegistry");
local ObjectManager = require("core.ObjectManager");
local KernelObject = require("core.KernelObject");
local SignalManager = require("proc.SignalManager");
local Signal = require("proc.classes.Signal");

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

    if device.claimedBy and device.claimedBy ~= pcb.pid then
        error("EBUSY: Device is claimed by PID " .. device.claimedBy);
    end
    device.claimedBy = pcb.pid;

    device.onDestroy = function(self)
        self.claimedBy = nil;
    end

    local kObj = KernelObject.new("DEVICE", device);
    return ObjectManager.link(pcb, ObjectManager.register(kObj));
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
        local name = data[1];
        local device = DeviceRegistry.get(name);
        if (device.claimedBy) then
            local kernel = ProcessRegistry.get(0);
            local process = ProcessRegistry.get(device.claimedBy);

            local handle = 0;
            for fd, globalId in pairs(process.handles) do
                if (ObjectManager.get(globalId).impl.name == name) then
                    handle = fd;
                end
            end

            SignalManager.send(kernel, device.claimedBy, Signal.SIGHUP, {
                fd = handle;
            });
        end
        DeviceRegistry.remove(name);
    end
end

return DeviceManager;