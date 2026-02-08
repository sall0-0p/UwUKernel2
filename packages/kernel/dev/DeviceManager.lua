--- @class DeviceManager
local DeviceManager = {};

--- Scan available computercraft devices, as well as virtual devices and populate the registry.
function DeviceManager.onStartup()

end

function DeviceManager.open(pcb, name)

end

function DeviceManager.invoke(pcb, fd, method, ...)

end

--- On events like peripheral and peripheral_detach - update the registry.
function DeviceManager.onEvent(event, data)

end

return DeviceManager;