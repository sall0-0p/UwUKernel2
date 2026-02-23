print("Hello from rootfsd!");

local dev = _G.require("dev");
local fs = _G.require("fs");

local data = dev.open("volume:data");
local system = dev.open("volume:system");

local files = fs.ioctl(system, "list", "/");

for i, v in pairs(files) do
    print(v);
end