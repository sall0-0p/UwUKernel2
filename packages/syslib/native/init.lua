local library = {
    proc = {
        spawn = 0,
        exit = 1,
        wait = 2,
        kill = 3,
        info = 4,
        setattr = 5,
        limit = 6,
        list = 8,
    },

    thread = {
        create = 9,
        join = 10,
        id = 11,
        list = 12,
    },

    ipc = {
        create = 32,
        send = 33,
        receive = 34,
        close = 36,
        stat = 37,
    },

    fs = {
        open = 64,
        close = 65,
        read = 66,
        write = 67,
        seek = 68,
        stat = 69,
        list = 70,
        ioctl = 72,
        mount = 75,
        unmount = 76,
        setaddr = 77,
        rename = 78,
        copy = 79,
        remove = 80,
        mkdir = 81,
    },

    io = {
        pipe = 73,
        dup = 74,
    },

    sys = {
        epoch = 96,
        timer = 97,
        alarm = 98,
        cancel = 99,
        log = 100,
        info = 101,
        bind_event = 102,
        unbind_event = 103,
        shutdown = 104,
        reboot = 105,
        signal = 111,
    },

    dev = {
        open = 106,
        list = 108,
        type = 109,
        methods = 110,
    },

    sync = {
        create = 128,
        lock = 129,
        unlock = 130,
        wait = 131,
        notify = 132,
    }
};

local raw = {};

for module, methods in pairs(library) do
    raw[module] = {};
    for name, id in pairs(methods) do
        raw[module][name] = function(...)
            return call(id, ...);
        end
    end
end

return raw;