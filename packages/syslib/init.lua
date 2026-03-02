local native = require("native");
local export = {};

-- libsystem.raw subpackages
export["libsystem.raw"] = {};
for k, v in pairs(native) do
    export["libsystem.raw"][k] = v;
end

export["libsystem.utils"] = require("utils");
export["libsystem.toml"] = require("toml");

return export;