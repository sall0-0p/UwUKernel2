local native = require("native");
local export = {};

-- libsystem.raw subpackages
export["libsystem.raw"] = native;
for k, v in pairs(native) do
    export["libsystem.raw." .. k] = v;
end

export["libsystem.utils"] = require("utils");
export["libsystem.toml"] = require("toml");
export["libsystem.vfs"] = require("vfs");

return export;