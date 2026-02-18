--- @class EnvironmentFactory
local EnvironmentFactory = {};
local Utils = require("misc.Utils");

function EnvironmentFactory.getEnvironment(pid, args)
    ---@type table
    local env;
    env = {
        arg = args or {},
        _G = env,

        package = {
            preload = {},
            loaded = {},
            -- TODO: Put path here
            path = "",
        },

        -- calling syscalls
        call = function(id, ...)
            local result, returns = coroutine.yield("SYSCALL", id, table.pack(...));
            if (result) then
                return table.unpack(returns);
            else
                error(returns, 2);
            end
        end,

        -- default print
        print = function(...)
            local args = { ... };
            local result = table.remove(args, 1);

            while (#args > 0) do
                local nextArg = table.remove(args, 1);
                result = result .. " " .. nextArg;
            end

            -- TODO: Remove this later, when there is actual TTY.
            print(...);

            return env.call(67, 2, result);
        end,

        read = function(number)
            return env.call(66, 1, number);
        end,

        sleep = function(duration)
            local port = env.call(32);
            env.call(97, port, duration);
            env.call(34);
        end,

        -- lua libraries
        table = Utils.deepcopy(table),
        coroutine = Utils.deepcopy(coroutine),
        bit = Utils.deepcopy(bit),
        bit32 = Utils.deepcopy(bit32),
        utf8 = Utils.deepcopy(utf8),
        vector = Utils.deepcopy(vector),

        -- debug library
        -- I decided to limit it, because half of it completely breaks the security and sandboxing.
        -- there is potential for its reintroduction later, but at current stage there is not much point
        -- and while writing debuggers is cool, implementing related functionality at this stage will take too long.
        debug = {
            traceback = debug.traceback,
            -- TODO: Maybe needs some wrapping for getinfo, as it will reveal underlying real file system..
            getinfo = debug.getinfo,
            serialize = debug.serialize,
        },

        -- lua functions
        assert = assert,
        error = error,
        ipairs = ipairs,
        next = next,
        pairs = pairs,
        pcall = pcall,
        xpcall = xpcall,
        select = select,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack,
        xpcall = xpcall,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        getmetatable = getmetatable,
        setmetatable = setmetatable,

        _VERSION = _VERSION,
        _HOST = _HOST,

        getfenv = function(level)
            local newEnv = getfenv(level or 1);

            if (newEnv == _G) then
                return nil;
            end
        end,

        setfenv = function(f, newEnv)
            local currentEnv = getfenv(f);
            if (currentEnv == _G) then
                error("EPERM: Cannot change environment of system function.");
            end
            return setfenv(f, newEnv);
        end,

        loadstring = function(str, name)
            local chunk, err = loadstring(str, name);
            if not chunk then return nil, err end;
            setfenv(chunk, env);
            return chunk;
        end,

        load = function(str, name)
            error("load() is not implemented yet. If you need it - make a PR :)")
        end,
    }

    return env;
end

return EnvironmentFactory;