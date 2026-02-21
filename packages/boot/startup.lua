-- get launchd code
local launchd = fs.open("/SystemVolume/System/launchd/init.lua", "r");
local blob = launchd.readAll();
launchd.close();

local syslib = fs.open("/SystemVolume/Library/syslib/init.lua", "r");
local syslibBlob = syslib.readAll();
syslib.close();

local preload = {
    ["syslib"] = syslibBlob;
};

local kernel = require(".SystemVolume.System.kernel");
kernel.createBoot(blob, preload);
kernel.run();
