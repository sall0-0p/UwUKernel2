--- @class Utils
local Utils = {};

--- Creates a deep copy of a table
--- @param orig table table to copy
function Utils.deepcopy(orig)
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
        copy[Utils.deepcopy(origKey, copies)] = Utils.deepcopy(origValue, copies);
    end

    setmetatable(copy, Utils.deepcopy(getmetatable(orig), copies));
    return copy;
end

return Utils;