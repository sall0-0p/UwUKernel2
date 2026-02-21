local term = call(106, "terminal");
call(74, term, 2);

--call(67, term, _G);
local raw = _G.require("raw");

--local l = 1;
--local result = "";
--for i, v in pairs(raw) do
--    result = result .. ", " .. i;
--    l = l + 1;
--end
--
--call(67, term, result);

raw.fs.write(term, "Hello World!");