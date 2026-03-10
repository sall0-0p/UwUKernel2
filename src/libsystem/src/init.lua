local raw = require("libsystem.raw");
local export = {};

-- libsystem.raw subpackages
export["libsystem.raw"] = raw;
for k, v in pairs(raw) do
    export["libsystem.raw." .. k] = v;
end

export["libsystem.utils"] = require("utils");
export["libsystem.toml"] = require("toml");
export["libsystem.vfs"] = require("vfs");

return export;