-- get launchd code
local launchd = fs.open("/System/System/launchd/init.lua", "r");
local blob = launchd.readAll();
launchd.close();

local syslib = fs.open("/System/Library/syslib/init.lua", "r");
local syslibBlob = syslib.readAll();
syslib.close();

local rootfsd = fs.open("/System/System/rootfsd/init.lua", "r");
local rootfsdBlob = rootfsd.readAll();
rootfsd.close();

local bootFs = {
    preload = {
        ["syslib"] = syslibBlob;
    },
    args = {
        ["rootfsd"] = rootfsdBlob;
    },
}

local kernel = require(".System.System.kernel");
kernel.createBoot(blob, bootFs);
kernel.run();
