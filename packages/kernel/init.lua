-- patch package.path
package.path = package.path .. ";/System/System/kernel/?.lua;/System/System/kernel/?/init.lua";

local Kernel = {};

function Kernel.run()
    local Scheduler = require("core.Scheduler");
    local DeviceManager = require("dev.DeviceManager");
    DeviceManager.onStartup();

    Scheduler.run();
end

function Kernel.createBoot(blob, bootFs)
    local ProcessManager = require("proc.ProcessManager");
    ProcessManager.spawn(0, '/System/launchd/init.lua', { bootFs.args }, {
        preload = bootFs.preload,
        blob = blob,
        name = 'launchd',
        limits = {
            maxThreads = math.huge,
            maxProcesses = math.huge,
            maxFiles = math.huge,
            maxPorts = math.huge,
        }
    });
end

return Kernel;