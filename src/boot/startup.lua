-- get launchd code
local launchd = fs.open("/System/System/launchd/init.lua", "r");
local blob = launchd.readAll();
launchd.close();

local syslib = fs.open("/System/Library/syslib/init.lua", "r");
local syslibBlob = syslib.readAll();
syslib.close();

local ccfsd = fs.open("/System/System/ccfsd/init.lua", "r");
local ccfsdBlob = ccfsd.readAll();
ccfsd.close();

local rootfsd = fs.open("/System/System/rootfsd/init.lua", "r");
local rootfsdBlob = rootfsd.readAll();
rootfsd.close();

local bootFs = {
    preload = {
        ["syslib"] = syslibBlob;
    },
    args = {
        ["rootfsd"] = rootfsdBlob;
        ["ccfsd"] = ccfsdBlob;
    },
}

print(package.path);
local kernel = require(".System.System.kernel");
kernel.createBoot(blob, bootFs);
kernel.run();
