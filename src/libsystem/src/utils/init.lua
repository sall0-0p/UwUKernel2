local utils = {};

function utils.deepcopy(orig)
    local copies = {};

    local origType = type(orig);
    if origType ~= 'table' then
        return orig;
    end

    if copies[orig] then
        return copies[orig];
    end

    local copy = {};
    copies[orig] = copy;

    for origKey, origValue in next, orig, nil do
        copy[utils.deepcopy(origKey, copies)] = utils.deepcopy(origValue, copies);
    end

    setmetatable(copy, utils.deepcopy(getmetatable(orig), copies));
    return copy;
end

function utils.parseArguments(args, schema, opts)
    local result = {};
    opts = opts or {};
    args = utils.deepcopy(args);

    -- parse arguments sequentially
    while (#args > 0) do
        local argument = table.remove(args, 1);

        if (argument == "--") then
            -- consider everything else - positional
            break;
        end

        -- this is start of new argument
        if (string.sub(argument, 1, 1) == "-") then
            --- @type string
            local key;
            if (string.sub(argument, 1, 2) == "--") then
                -- this is double dash argument
                key = string.sub(argument, 3);
            else
                -- this is single dash argument
                key = string.sub(argument, 2);
            end

            -- find expected argument from schema
            local expected = schema[key];
            if (not expected) then
                error("Unexpected argument " .. argument, 2);
            end

            -- resolve alias
            if (type(expected) == "string" and string.sub(expected, 1, 1) == "@") then
                local target = string.sub(expected, 2);
                if (schema[target]) then
                    expected = schema[target];
                    key = target;
                else
                    error("Tried to alias to non existing argument.");
                end
            end

            if (expected == false) then
                -- this is a flag
                result[key] = true;
            elseif (expected == true or expected == "number") then
                if (result[key]) then
                    error("Argument was passed multiple times, yet application expected it once.");
                end

                -- this expects next argument to be a value
                local nextArg = table.remove(args, 1);
                if (not nextArg) then
                    error("Missing required parameter for argument: " .. key, 2);
                end

                if (expected == "number") then
                    local num = tonumber(nextArg)
                    if not num then
                        error("Failed to cast argument " .. argument .. " with value " .. nextArg .. " to number", 2)
                    end
                    nextArg = num
                end

                result[key] = nextArg;
            elseif (expected == "multiple" or expected == "multiple number") then
                local nextArg = table.remove(args, 1);
                if (not nextArg) then
                    error("Missing required parameter for argument: " .. key, 2);
                end

                -- enforce existance of table
                if (not result[key]) then
                    result[key] = {};
                end

                if (expected == "multiple number") then
                    local num = tonumber(nextArg)
                    if not num then
                        error("Failed to cast argument " .. argument .. " with value " .. nextArg .. " to number", 2)
                    end
                    nextArg = num
                end

                table.insert(result[key], nextArg);
            end
        else
            -- this is positional argument
            table.insert(result, argument);
            if (opts.stopProcessingOnPositionalArgument) then
                break;
            end
        end
    end

    -- put everything that is left in case of break, into positional args
    while (#args > 0) do
        table.insert(result, table.remove(args, 1));
    end

    return result;
end

return utils;