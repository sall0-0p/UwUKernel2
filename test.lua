--PROCESS TESTS (proc)

--local childPid = call(0, "/kid.lua", {}, { blob = "coroutine.yield() call(1, 0)", name = "kid" });
--
--print("Process list:")
--local list = call(8);
--print(textutils.serialize(list));
--
--print("Our process: ");
--local info = call(4);
--print(textutils.serialize(info));
--
--print("Child process: ");
--local info = call(4, childPid);
--print(textutils.serialize(info));
--
--local data = call(2, -1);
--print(data.pid, data.code, data.usage);
--
--print("Child process (cleaned, should error prob): ");
--local info = call(4, childPid);
--print(textutils.serialize(info));

-- THREAD TESTS (thread)
--local helloThread = call(9, function(arg1, arg2)
--    print(arg1 .. " " .. arg2);
--end, { "Hello", "World!" })
--
--call(10, helloThread);
--
--local currentTid = call(11);
--print(currentTid);
--
--local function printSymbols(symbol, length)
--    local i = 0;
--    while i < (length or 20) do
--        write(symbol);
--        i = i + 1;
--    end
--    print();
--end
--
--local threadA = call(9, printSymbols, { "*" });
--local threadB = call(9, printSymbols, { "-" });
--
--local threadList = call(12);
--print(textutils.serialize(threadList));
--
--call(10, threadA);
--call(10, threadB);
--
--local ThreadC = call(9, printSymbols, { "/", 40 });
--
--call(10, ThreadC);
--print("Thread C finished!!!");
--
--local threadList = call(12);
--print(textutils.serialize(threadList));

-- IPC tests
--[32] = ipc.create,
--[33] = ipc.send,
--[34] = ipc.receive,
local port = call(32);

call(9, function()
    while true do
        local message = call(34, port);
        print(textutils.serialize(message));
    end
end)

local sender = call(0, "/procA", {}, {
    blob = "call(33, 1, { 'Hello World!' })",
    name = "Sender" ,
    fds = {
        [1] = port;
    },
});