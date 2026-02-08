local info = call(101);
term.clear();
term.setCursorPos(1, 1);
term.setTextColor(colors.magenta);
print(info.version);
term.setTextColor(colors.white);
print("");

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

--local port = call(32);
--local timerId = call(97, port, 1, { "HELLO WORLD 1!" });
--local timerId = call(97, port, 3, { "HELLO WORLD 2!" });
--local timerId = call(97, port, 5, { "HELLO WORLD 3!" });
--print("Created timer with id:", timerId);
--local data = call(34, port);
--print("Received timer: ")
--print(textutils.serialize(data));
--
--print("Creating second timer!");
--local timerId = call(97, port, 1, { "HELLO WORLD!" });
--print("Cancelling second timer!");
--call(99, timerId);
--call(34, port);
--print("This should not be written!");

--local port = call(32); -- ipc.create()
--print("Ordering timers!");
--call(97, port, 1, "Hello from 1s timer!"); -- sys.timer(port, 1, "cookie");
--call(97, port, 3, "Hello from 3s timer!"); -- sys.timer(port, 3, "cookie");
--call(97, port, 5, "Hello from 5s timer!"); -- sys.timer(port, 5, "cookie");
--
--while true do
--    local message = call(34, port); -- ipc.receive(port);
--    if (message.type == "TIMER") then
--        print(message.data.cookie);
--    else
--        print(textutils.serialize(message));
--    end
--end

-- something gemini made
--local function test_cpu_metrics()
--    print("--- CPU METRICS TEST ---")
--
--    -- 1. Get initial kernel stats
--    local start_info = call(101)
--    print("Start Uptime: " .. start_info.uptime)
--    print("Start Running: " .. start_info.runningTime)
--
--    -- 2. Define the heavy lifter
--    -- We use a local function here, but we pass it to the thread.
--    -- (The kernel environment copying handles upvalues or pure functions logic)
--    local function calculate_pi(iterations)
--        local pi = 0
--        local sign = 1
--        for i = 0, iterations do
--            -- Leibniz formula: 4 * (1 - 1/3 + 1/5 - ...)
--            pi = pi + sign * (4 / (2 * i + 1))
--            sign = -sign
--        end
--        return pi
--    end
--
--    -- 3. Run it in a separate thread (Syscall 9)
--    -- 1,000,000 iterations should take a second or two on CraftOS-PC
--    local iters = 1000000
--    print("Spawning thread to calculate Pi (" .. iters .. " iters)...")
--    local tid = call(9, calculate_pi, { iters })
--
--    -- 4. Wait for it to finish (Syscall 10)
--    local result = call(10, tid)
--    print("Calculation complete!")
--    print("Result: ", result)
--
--    -- 5. Get final stats and compare
--    local end_info = call(101)
--
--    local run_delta = end_info.runningTime - start_info.runningTime
--    local sys_delta = end_info.systemTime - start_info.systemTime
--    local up_delta = end_info.uptime - start_info.uptime
--
--    print("\n--- RESULTS ---")
--    print(string.format("Wall Time (Uptime): %.3fs", up_delta))
--    print(string.format("User Time (Running): %.3fs", run_delta))
--    print(string.format("Kernel Time (System): %.3fs", sys_delta))
--    print("----------------")
--end
--
--test_cpu_metrics();

local inputPort = call(32);
call(102, "key", inputPort);
print("Called bind, starting to listen!");
print("HELLO WORLD!");
local data = call(34, inputPort);
print(data);
print("Received key!");
print(textutils.serialize(data));

local exitPort = call(32);
local exitTimer = call(97, exitPort, 10);
call(34, exitPort);
call(104);