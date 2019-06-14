local component = require("component")
local eeprom = component.eeprom()
local bios, key, sig = ...
local function read(path)
	local h = io.open(path, "rb")
	local d = h:read("*a")
	h:close()
	return d
end
eeprom.setSign(read(bios), read(key), read(sig))