local native = require("native");
local export = {};

for k, v in pairs(native) do
    export[k] = v;
end

return export;