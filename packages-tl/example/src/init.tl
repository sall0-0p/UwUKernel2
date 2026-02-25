print("Hello from rootfsd!")

-- local task = _G.require("task");
-- print(task.id());

local proc = _G.require("proc");
local sys = _G.require("sys");
for i, v in pairs(sys.info() as {string: any}) do
    print(i, v);
end

proc.exit("string");