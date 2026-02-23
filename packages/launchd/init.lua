-- random stuff
local io = _G.require("io");
local dev = _G.require("dev");

local term = dev.open("terminal");
io.dup(term, 2);

local fs = _G.require("fs");
fs.write(term, "Hello World from stdout!");
print("Hello World from print!");

-- create rootfsd
local args = arg[1];
local rootfsBlob = args.rootfsd;

local proc = _G.require("proc");
proc.spawn("/System/rootfsd/init.lua", {}, {
    name = "rootfsd",
    blob = rootfsBlob,
    preload = package.preload,
    fds = {
        [2] = 2,
    }
});