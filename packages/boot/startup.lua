-- get launchd code
local launchd = fs.open("/SystemVolume/System/launchd/init.lua", "r");
local blob = launchd.readAll();
launchd.close();

local kernel = require(".SystemVolume.System.kernel");
kernel.createBoot(blob);
kernel.run();
