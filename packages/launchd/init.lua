-- ==========================================
-- PARENT PROCESS
-- ==========================================
local terminal = call(106, "terminal")
call(74, terminal, 2)

local child_src = [[
    -- No need to dev.open()! The parent gave us the terminal capability as FD 2.
    -- print() works out of the box.

    local my_pid = call(4).pid       -- proc.info()
    local sig_port = call(32)        -- ipc.create()

    -- 1. Register to listen for SIGUSR1 on our port
    call(111, 1, sig_port)   -- sys.signal() (proposed syscall 111)

    -- 2. Send SIGUSR1 to ourselves
    print("[Child] Sending SIGUSR1 to myself...")
    call(3, my_pid, 1)       -- proc.kill()

    -- 3. Handle it!
    local msg = call(34, sig_port)   -- ipc.receive() blocks until signal arrives

    for i, v in pairs(msg) do print(i) end;
    local payload = msg.data
    if payload.type == "SIGNAL" and payload.signal == 1 then
        print("[Child] Caught SIGHUP! Still alive.")
    end

    -- 4. Send SIGTERM to ourselves (fatal)
    print("[Child] Sending SIGTERM to myself (fatal)...")
    call(3, my_pid, 15)

    print("[Child] ERROR: I should not be alive to print this.")
]]

print("[Parent] Spawning child process...")
local child_pid = call(0, "test_child", {}, {
    blob = child_src,
    fds = { [2] = 2 }
})

print("[Parent] Waiting for child (PID " .. child_pid .. ")...")
local result = call(2, child_pid) -- proc.wait()

print("[Parent] Child terminated.")
print("[Parent] Exit code: " .. tostring(result.code))