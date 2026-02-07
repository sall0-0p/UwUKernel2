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
--local port = call(32);
--
--call(9, function()
--    while true do
--        local message = call(34, port);
--        print("Received message: ");
--        print(textutils.serialize(message));
--
--        if (message.reply) then
--            call(33, message.reply, { "Hello bro!" });
--        end
--
--        if (message.handles and message.handles[1]) then
--            local newPort = message.handles[1];
--
--            call(0, "/sender2", {}, {
--                blob = "local replyPort = call(32); call(33, 1, { 'Hello from transferred handle!' }, { reply_port = replyPort, handles = { somePort } }); local message = call(34, replyPort); print('Received reply:'); print(textutils.serialize(message));",
--                name = "Sender",
--                fds = {
--                    [1] = newPort;
--                },
--            });
--
--            local message = call(34, newPort);
--            print("Received another message: ");
--            print(textutils.serialize(message));
--        end
--    end
--end)
--
--local sender2 = call(0, "/sender1", {}, {
--    blob = "local replyPort = call(32); local somePort = call(32); call(33, 1, { 'Hello World!' }, { reply_port = replyPort }); local message = call(34, replyPort); print('Received reply:'); print(textutils.serialize(message)); call(33, 1, { 'Take a handle bro!' }, { transfer = { somePort } })",
--    name = "Sender",
--    fds = {
--        [1] = port;
--    },
--});
--
--print(textutils.serialize(call(37, port)));

--
--print(textutils.serialize(call(8)));
--print(textutils.serialize(call(4, 0)));

local timer1 = call(97, 1, "HELLO WORLD!");
print("Created timer 1 with id:", timer1);
local event = call(34, timer1);
print("Received timer: ")
print(textutils.serialize(event));

local timer2 = call(97, 1, "HELLO BOBERS!");
print("Created timer 2 with id:", timer2);
call(99, timer2);
print("Cancelled timer 2!");
print("Trying to listen to non existant timer 2!");
local event = call(34, timer2);
print(textutils.serialize(event));