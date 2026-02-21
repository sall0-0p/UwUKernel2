local io = _G.require("io");
local dev = _G.require("dev");

local term = dev.open("terminal");
io.dup(term, 2);

local fs = _G.require("fs");
fs.write(term, "Hello World from stdout!");
print("Hello World from print!");


