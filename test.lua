local childPid = call(0, "/kid.lua", {}, { blob = "coroutine.yield() call(1, 0)", name = "kid" });

print("Process list:")
local list = call(8);
print(textutils.serialize(list));

print("Our process: ");
local info = call(4);
print(textutils.serialize(info));

print("Child process: ");
local info = call(4, childPid);
print(textutils.serialize(info));

local data = call(2, -1);
print(data.pid, data.code, data.usage);

print("Child process (cleaned, should error prob): ");
local info = call(4, childPid);
print(textutils.serialize(info));