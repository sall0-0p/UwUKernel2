-- random stuff
local io = _G.require("io");
local dev = _G.require("dev");
local sys = _G.require("sys");
local ipc = _G.require("ipc");

local term = dev.open("terminal");
io.dup(term, 2);

local fs = _G.require("fs");
fs.write(term, "Hello World from stdout!");
print("Hello World from print!");

-- create rootfsd
local rootfsBlob = arg.rootfsd;

local proc = _G.require("proc");
proc.spawn("/System/rootfsd/init.lua", {}, {
    name = "rootfsd",
    blob = rootfsBlob,
    preload = package.preload,
    fds = {
        [2] = 2,
    }
});

local port = ipc.create();
sys.timer(port, 5);
ipc.receive(port);

fs.list("/");