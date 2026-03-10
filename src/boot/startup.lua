local bootFs = {
    preload = {},
    args = {}
}

local function loadPreloads(baseDir, prefix)
    if not fs.exists(baseDir) then return end

    for _, file in ipairs(fs.list(baseDir)) do
        local fullPath = fs.combine(baseDir, file)

        if fs.isDir(fullPath) then
            local nextPrefix = prefix == "" and file or (prefix .. "." .. file)
            loadPreloads(fullPath, nextPrefix)
        else
            if file:match("%.lua$") then
                local modName
                if file == "init.lua" then
                    modName = prefix
                else
                    local name = file:gsub("%.lua$", "")
                    modName = prefix == "" and name or (prefix .. "." .. name)
                end

                if modName and modName ~= "" then
                    local f = fs.open(fullPath, "r")
                    bootFs.preload[modName] = f.readAll()
                    f.close()
                end
            end
        end
    end
end

loadPreloads("/System/Library/libsystem", "libsystem")

local function loadBlob(path)
    local f = fs.open(path, "r")
    local data = f.readAll()
    f.close()
    return data
end

bootFs.args["rootfsd"] = loadBlob("/System/Core/rootfsd/init.lua")
bootFs.args["ccfsd"] = loadBlob("/System/Core/ccfsd/init.lua")
local launchdBlob = loadBlob("/System/Core/launchd/init.lua")

print(package.path)
local kernel = require(".System.Core.kernel");
kernel.createBoot(launchdBlob, bootFs);
kernel.run();