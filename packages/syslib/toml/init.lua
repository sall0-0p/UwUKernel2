-- TOML library for Lua/CC
-- From Phoenix libsystem serialization.toml
--
-- MIT License
--
-- Copyright (c) 2024 JackMacWindows
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- Thank you JackMacWindows :D
local toml = {}

-- From json.lua by rxi
-- MIT license

local escape_char_map = {
    [ "\\" ] = "\\",
    [ "\"" ] = "\"",
    [ "\b" ] = "b",
    [ "\f" ] = "f",
    [ "\n" ] = "n",
    [ "\r" ] = "r",
    [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end

local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[ select(i, ...) ] = true
    end
    return res
end

local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
    local n1 = tonumber( s:sub(1, 4),  16 )
    local n2 = tonumber( s:sub(7, 10), 16 )
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end


local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, "control character in string")

        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == "u" then
                local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                        or str:match("^%x%x%x%x", j + 1)
                        or decode_error(str, j - 1, "invalid unicode escape in string")
                res = res .. parse_unicode_escape(hex)
                j = j + #hex
            else
                if not escape_chars[c] then
                    decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                end
                res = res .. escape_char_map_inv[c]
            end
            k = j + 1

        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, "expected closing quote for string")
end

-- End json.lua

local keywords = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["goto"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
}

local function lua_serialize(val, stack, opts, level)
    if stack[val] then error("Cannot serialize recursive value", 0) end
    local tt = type(val)
    if tt == "table" then
        if not next(val) then return "{}" end
        stack[val] = true
        local res = opts.minified and "{" or "{\n"
        local num = {}
        for i, v in ipairs(val) do
            if not opts.minified then res = res .. ("    "):rep(level) end
            num[i] = true
            res = res .. lua_serialize(v, stack, opts, level + 1) .. (opts.minified and "," or ",\n")
        end
        for k, v in pairs(val) do if not num[k] then
            if not opts.minified then res = res .. ("    "):rep(level) end
            if type(k) == "string" and k:match "^[A-Za-z_][A-Za-z0-9_]*$" and not keywords[k] then res = res .. k
            else res = res .. "[" .. lua_serialize(k, stack, opts, level + 1) .. "]" end
            res = res .. (opts.minified and "=" or " = ") .. lua_serialize(v, stack, opts, level + 1) .. (opts.minified and "," or ",\n")
        end end
        if opts.minified then res = res:gsub(",$", "")
        else res = res .. ("    "):rep(level - 1) end
        stack[val] = nil
        return res .. "}"
    elseif tt == "function" and opts.allow_functions then
        local ok, dump = pcall(string.dump, val)
        if not ok then error("Cannot serialize C function", 0) end
        dump = ("%q"):format(dump):gsub("\\[%z\1-\31\127-\255]", function(c) return ("\\%03d"):format(string.byte(c)) end)
        local ups = {n = 0}
        stack[val] = true
        for i = 1, math.huge do
            local ok, name, value = pcall(debug.getupvalue, val, i)
            if not ok or not name then break end
            ups[i] = value
            ups.n = i
        end
        local name = "=(serialized function)"
        local ok, info = pcall(debug.getinfo, val, "S")
        if ok then name = info.source or name end
        local v = ("__function(%s,%q,%s)"):format(dump, name, lua_serialize(ups, stack, opts, level + 1))
        stack[val] = nil
        return v
    elseif tt == "nil" or tt == "number" or tt == "boolean" or tt == "string" then
        return ("%q"):format(val):gsub("\\\n", "\\n"):gsub("\\?[%z\1-\31\127-\255]", function(c) return ("\\%03d"):format(string.byte(c)) end)
    else
        error("Cannot serialize type " .. tt, 0)
    end
end

local function encodeTOMLArray(arr, opts, names)
    local int, str = false, false
    for l in pairs(arr) do
        if type(l) == "number" then int = true
        elseif type(l) == "string" then str = true
        else error("key " .. table.concat(names, ".") .. "." .. tostring(l) .. " is not a string") end
    end
    local e = #names + 1
    if not int and not str then return "[]"
    elseif int and str then error("invalid entry " .. table.concat(names, ".") .. " (contains both array and dictionary values)")
    elseif int then
        local retval = "["
        for i, v in ipairs(arr) do
            if type(v) == "table" then
                names[e] = tostring(i)
                retval = retval .. (retval == "[" and "" or ", ") .. encodeTOMLArray(v, opts, names)
                names[e] = nil
            else retval = retval .. (retval == "[" and "" or ", ") .. lua_serialize(v, {}, {}, #names) end
        end
        return retval .. "]"
    else
        local res = "{"
        for k, v in pairs(arr) do
            if res ~= "{" then res = res .. ", " end
            if type(k) == "string" and k:match "^[A-Za-z0-9_%-]+$" then res = res .. k
            else res = res .. lua_serialize(k, {}, {}, #names) end
            if type(v) == "table" then
                names[e] = k
                res = res .. " = " .. encodeTOMLArray(v, opts, names)
                names[e] = nil
            else res = res .. " = " .. lua_serialize(v, {}, {}, #names) end
        end
        return res .. "}"
    end
end

local function encodeTOML(tbl, opts, names)
    local retval = ""
    local indent = opts.indent == false and "" or ("    "):rep(#names)
    local tbls, arrs = {}, {}
    local e = #names + 1
    for k, v in pairs(tbl) do
        assert(type(k) == "string", "key " .. table.concat(names, ".") .. "." .. tostring(k) .. " is not a string")
        local key = k:match("^[A-Za-z0-9_%-]+$") and k or lua_serialize(k, {}, {}, 1)
        local t = type(v)
        if t == "table" then
            local int, str, tab = false, false, true
            for l, w in pairs(v) do
                if type(l) == "number" then int = true
                elseif type(l) == "string" then str = true
                else error("key " .. table.concat(names, ".") .. "." .. tostring(k) .. "." .. tostring(l) .. " is not a string") end
                if type(w) ~= "table" then tab = false
                else for m in pairs(w) do if type(m) ~= "string" then tab = false break end end end
            end
            if not int and not str then retval = retval .. indent .. key .. " = []\n"
            elseif int and str then error("invalid entry " .. table.concat(names, ".") .. "." .. tostring(k) .. " (contains both array and dictionary values)")
            elseif int then
                if tab then
                    arrs[k] = v
                else
                    names[e] = k
                    retval = retval .. indent .. key .. " = " .. encodeTOMLArray(v, opts, names)
                    names[e] = nil
                end
            else tbls[k] = v end
        else retval = retval .. indent .. key .. " = " .. lua_serialize(v, {}, {}, #names) .. "\n" end
    end
    for k, arr in pairs(arrs) do
        names[e] = k
        for _, v in ipairs(arr) do
            retval = retval .. ("%s[[%s]]\n"):format(indent, table.concat(names, ".")) .. encodeTOML(v, opts, names) .. "\n"
        end
    end
    for k, v in pairs(tbls) do
        names[e] = k
        retval = retval .. ("%s[%s]\n"):format(indent, table.concat(names, ".")) .. encodeTOML(v, opts, names) .. "\n"
    end
    names[e] = nil
    return retval
end

--- Encodes a table into TOML format. This table must only have integer or
-- string keys in itself and each subtable, and cannot mix strings and ints.
-- @tparam table tbl The table to encode
-- @tparam[opt] {indent=boolean} opts Any options to specify while encoding
-- @treturn string The encoded TOML data
function toml.encode(tbl, opts)
    assert(type(tbl) == "table", "Expected argument #1 as a table, got " .. type(tbl));
    assert((type(tbl) == "table") or (type(tbl) == "nil"), "Expected argument #2 as a table or nil, got " .. type(tbl));
    return encodeTOML(tbl, opts or {}, {})
end

local function traverse(tab, name, pos, ln, wantlast)
    local last, nm
    while pos < #name do
        if pos > 1 then
            pos = name:match("^%s*()", pos)
            if wantlast and name:sub(pos, pos) == "=" then return last, nm, pos + 1 end
            if name:sub(pos, pos) ~= "." then error("Expected . on line " .. ln, 3) end
            pos = name:match("^%s*()", pos + 1)
        end
        local key
        if name:match('^"', pos) then key, pos = parse_string(name, pos + 1)
        elseif name:match("^'", pos) then key, pos = name:match("'([^']*)'()", pos)
        else key, pos = name:match("^([A-Za-z0-9_%-]+)()", pos) end
        if not key then error("Invalid key name on line " .. ln, 3) end
        last, nm = tab, key
        if not tab[key] then tab[key] = {} end
        tab = tab[key]
    end
    if wantlast then error("Expected = on line " .. ln, 3) end
    return tab
end

local function next_token(line, pos, ln)
    pos = line:match("^%s*()", pos)
    while pos > #line or line:sub(pos, pos) == "#" do
        line = coroutine.yield()
        ln = ln + 1
        pos = line:match "^%s*()"
    end
    return line, pos, ln
end

local function toml_assign(tab, key, line, pos, ln)
    local op = line:sub(pos, pos)
    while op == "#" do
        line = coroutine.yield()
        ln = ln + 1
        pos = line:match "^%s*()"
        op = line:sub(pos, pos)
    end
    if op == "[" then
        local retval = {}
        local i = 1
        line, pos, ln = next_token(line, pos + 1, ln)
        while true do
            op = line:sub(pos, pos)
            if op == "]" then break end
            line, pos, ln = toml_assign(retval, i, line, pos, ln)
            line, pos, ln = next_token(line, pos, ln)
            op = line:sub(pos, pos)
            if op == "]" then break end
            if op ~= "," then error("Expected , on line " .. ln, 0) end
            line, pos, ln = next_token(line, pos + 1, ln)
            i = i + 1
        end
        tab[key] = retval
        return line, pos + 1, ln
    elseif op == "{" then
        local retval = {}
        line, pos, ln = next_token(line, pos + 1, ln)
        while true do
            op = line:sub(pos, pos)
            if op == "}" then break end
            local t, k
            t, k, pos = traverse(retval, line, pos, ln, true)
            line, pos, ln = next_token(line, pos, ln)
            line, pos, ln = toml_assign(t, k, line, pos, ln)
            line, pos, ln = next_token(line, pos, ln)
            op = line:sub(pos, pos)
            if op == "}" then break end
            if op ~= "," then error("Expected , on line " .. ln, 0) end
            line, pos, ln = next_token(line, pos + 1, ln)
        end
        tab[key] = retval
        return line, pos + 1, ln
    elseif op == "'" then
        if line:match("^'''", pos) then
            pos = pos + 3
            local str = ""
            while not line:find("'''", pos) do
                if not (str == "" and pos == #line) then
                    str = str .. line:sub(pos) .. "\n"
                end
                line = coroutine.yield()
                ln, pos = ln + 1, 1
            end
            str = str .. line:sub(pos, line:find("'''", pos) - 1)
            pos = line:match("'''()", pos)
            tab[key] = str
            return line, pos, ln
        else
            local str, pos = line:match("^'([^']*)'()", pos)
            if not str then error("Invalid literal string on line " .. ln, 0) end
            tab[key] = str
            return line, pos, ln
        end
    elseif op == '"' then
        if line:match('^"""', pos) then
            local s = ""
            while not line:find('"""', pos) do
                if not (s == "" and pos == #line) then
                    s = s .. line:sub(pos) .. "\n"
                end
                line = coroutine.yield()
                ln, pos = ln + 1, 1
            end
            s = s .. line:sub(pos, line:find('"""', pos) - 1)
            s = s:gsub("\\\r?\n", ""):gsub('"', '\\"') .. '"'
            tab[key] = parse_string(s, 1)
            pos = line:match('"""()', pos)
            return line, pos, ln
        else
            local str, pos = parse_string(line, pos)
            if not str then error("Invalid string on line " .. ln, 0) end
            tab[key] = str
            return line, pos, ln
        end
    elseif line:match("^%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d", pos) then
        -- TODO: Implement os.time alternative and return it.
        error("Time is not implemented.");
        --local y, M, d, h, m, s, pos = line:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[T ](%d%d):(%d%d):(%d%d)()", pos)
        --local date = {
        --    year = tonumber(y),
        --    month = tonumber(M),
        --    day = tonumber(d),
        --    hour = tonumber(h),
        --    min = tonumber(m),
        --    sec = tonumber(s)
        --}
        --local time = os.time(date)
        --if line:match("^%.%d+", pos) then
        --    local ss
        --    ss, pos = line:match("(%.%d+)()", pos)
        --    time = time + tonumber("0" .. ss)
        --end
        --local c = line:sub(pos, pos)
        --if c == "+" or c == "-" then
        --    local oh, om
        --    oh, om, pos = line:match("^[%+%-](%d%d):(%d%d)()", pos)
        --    if not oh then error("Invalid date format on line " .. ln, 0) end
        --    local offset = tonumber(oh) * 3600 + tonumber(om) * 60
        --    if c == "-" then offset = -offset end
        --    time = time + offset
        --elseif c == "Z" then pos = pos + 1 end
        --tab[key] = time
        --return line, pos, ln
    elseif line:match("^%d%d%d%d%-%d%d%-%d%d", pos) then
        --local y, M, d, pos = line:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)()", pos)
        --local date = {
        --    year = tonumber(y),
        --    month = tonumber(M),
        --    day = tonumber(d),
        --    hour = 0,
        --    min = 0,
        --    sec = 0
        --}
        --local time = os.time(date)
        --tab[key] = time
        --return line, pos, ln
        -- TODO: Implement os.time alternative and return it.
        error("Time is not implemented.");
    elseif line:match("^%d%d%:%d%d:%d%d", pos) then
        local h, m, s, pos = line:match("^(%d%d):(%d%d):(%d%d)()", pos)
        local time = h * 3600 + m * 60 * s
        if line:match("^%.%d+", pos) then
            local ss
            ss, pos = line:match("(%.%d+)()", pos)
            time = time + tonumber("0" .. ss)
        end
        tab[key] = time
        return line, pos, ln
    elseif op:match "%d" or op == "+" or op == "-" then
        if line:match("^%+inf", pos) then tab[key] = math.huge return line, pos + 4, ln
        elseif line:match("^%-inf", pos) then tab[key] = -math.huge return line, pos + 4, ln
        elseif line:match("^%+nan", pos) then tab[key] = -(0/0) return line, pos + 4, ln
        elseif line:match("^%-nan", pos) then tab[key] = 0/0 return line, pos + 4, ln
        elseif line:match("^[%+%-]?0o", pos) then
            local sign, num, pos = line:match("^([%+%-]?)0o([0-7_]+)()", pos):gsub("_", "")
            if not num then error("Invalid number on line " .. ln, 0) end
            num = tonumber(num, 8)
            if not num then error("Invalid number on line " .. ln, 0) end
            if sign == "-" then num = -num end
            tab[key] = num
            return line, pos, ln
        elseif line:match ("^[%+%-]?0b", pos) then
            local sign, num, pos = line:match("^([%+%-]?)0b([01_]+)()", pos):gsub("_", "")
            if not num then error("Invalid number on line " .. ln, 0) end
            num = tonumber(num, 2)
            if not num then error("Invalid number on line " .. ln, 0) end
            if sign == "-" then num = -num end
            tab[key] = num
            return line, pos, ln
        else
            local num, pos = line:match("^([%+%-]?[%d_]+%.?[%d_]*[Ee]?[%+%-]?[%d_]*)()", pos)
            num = num:gsub("_", "")
            num = tonumber(num)
            if not num then error("Invalid number on line " .. ln, 0) end
            tab[key] = num
            return line, pos, ln
        end
    elseif line:match("^true", pos) then tab[key] = true return line, pos + 4, ln
    elseif line:match("^false", pos) then tab[key] = false return line, pos + 5, ln
    elseif line:match("^nil", pos) then tab[key] = nil return line, pos + 3, ln -- extension
    elseif line:match("^inf", pos) then tab[key] = math.huge return line, pos + 3, ln
    elseif line:match("^nan", pos) then tab[key] = -(0/0) return line, pos + 3, ln
    else error("Unexpected " .. op .. " on line " .. ln, 0) end
end

--- Parses TOML data into a table.
-- @tparam string str The TOML data to decode
-- @tparam[opt] table opts Options (none available in this version)
-- @treturn table A table representing the TOML data
function toml.decode(str, opts)
    --expect(1, str, "string")
    assert(type(str) == "string", "Bad argument #1: Expected string, got " .. type(str));
    assert((type(opts) == "nil") or (type(opts) == "table"), "Bad argument #2, Expected table or nil, got " .. type(opts));
    opts = opts or {};
    local retval = {}
    local current = retval
    local ln = 1
    local coro
    for line in str:gmatch "([^\r\n]*)\r?\n" do
        if coro then
            -- continuation of multi-line value
            local ok, err = coroutine.resume(coro, line)
            if not ok then error(err, 3) end
            if coroutine.status(coro) == "dead" then coro = nil end
        else
            line = line:gsub("^%s+", "")
            if line:match "^#" or line == "" then -- nothing
            elseif line:match "^%[%[" then
                local tag = line:match "^%[(%b[])%]"
                if not tag then error("Expected ]] on line " .. ln, 2) end
                current = traverse(retval, tag:sub(2, -2), 1, ln)
                current[#current+1] = {}
                current = current[#current]
            elseif line:match "^%[" then
                local tag = line:match "^%b[]"
                if not tag then error("Expected ] on line " .. ln, 2) end
                current = traverse(retval, tag:sub(2, -2), 1, ln)
            else
                local last, key, pos = traverse(current, line, 1, ln, true)
                pos = line:match("^%s*()", pos)
                if not pos then error("Expected value on line " .. ln, 2) end
                coro = coroutine.create(toml_assign)
                local ok, err = coroutine.resume(coro, last, key, line, pos, ln)
                if not ok then error(err, 3) end
                if coroutine.status(coro) == "dead" then coro = nil end
            end
        end
        ln = ln + 1
    end
    if coro then error("Unfinished value at end of file", 2) end
    return retval
end

return toml