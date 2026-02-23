print("Hello from rootfsd!");

local dev = _G.require("dev");
local fs = _G.require("fs");
local ipc = _G.require("ipc");

local data = dev.open("volume:data");
local system = dev.open("volume:system");

local port = ipc.create();
fs.mount("/", port);

local message = ipc.receive(port);
for i, v in pairs(message) do
    print(i, v);
end