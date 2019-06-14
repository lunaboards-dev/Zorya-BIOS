--This simply adds OEFI support where there wasn't before. Also adds our zorya lib.
local component = component
local computer = computer
local envs = ...

local oefi = {}

function oefi.getApplications()
	local apps = {}
	for fs in component.list("filesystem") do
		if component.invoke(fs, "isDirectory", ".efi") then
			for _, file in ipairs(component.invoke(fs, "list", ".efi")) do
				apps[#apps+1] = {
					drive = fs,
					path = ".efi/"..file
				}
			end
		end
	end
	return apps
end

function oefi.getAPIVersion()
	return 1
end

function oefi.getImplementationName()
	return "Zorya BIOS"
end

function oefi.getImplementationVersion()
	return zorya.getVersion()
end

function oefi.returnToOEFI()
	computer.shutdown(true)
end

function oefi.execOEFIApp(fs, path, args)
	return envs.loadfile(fs,path)(oefi, args)
end

function zorya.getVersion()
	return _ZVER
end

local json = envs.loadfile(envs.device, "zorya-cfg/json.lua")()
local pretty = envs.loadfile(envs.device, "zorya-cfg/pretty.lua")()

function zorya.getEntries()
	local hand = component.invoke(envs.device, "open", "zorya-cfg/.zoryarc", "r")
	local dat = component.invoke(envs.device, "read", hand, math.huge)
	component.invoke(envs.device, "close", hand)
	return json.decode(dat).boot_entries
end

function zorya.addEntry(name, handler, fs, ...)
	--Check types
	if (type(name) ~= "string") then
		error("type error: argument #1, expected string but got "..type(name))
	end
	if (type(handler) ~= "string") then
		error("type error: argument #2, expected string but got "..type(handler))
	end
	if (type(fs) ~= "string") then
		error("type error: argument #3, expected string but got "..type(fs))
	end
	local hand = component.invoke(envs.device, "open", "zorya-cfg/.zoryarc", "r")
	local dat = component.invoke(envs.device, "read", hand, math.huge)
	component.invoke(envs.device, "close", hand)
	local cfg = json.decode(dat)
	cfg.boot_entries[#cfg.boot_entries+1] = {name, handler, fs, ...}
	local str = pretty(cfg, "\n", "\t", " ", json.encode)
	hand = component.invoke(envs.device, "open", "zorya-cfg/.zoryarc", "w")
	component.invoke(envs.device, "write", hand, str)
	component.invoke(envs.device, "close", hand)
end

function zorya.removeEntry(id)
	if (type(id) ~= "string") then
		error("type error: argument #1, expected number but got "..type(id))
	end
	local hand = component.invoke(envs.device, "open", "zorya-cfg/.zoryarc", "r")
	local dat = component.invoke(envs.device, "read", hand, math.huge)
	component.invoke(envs.device, "close", hand)
	local cfg = json.decode(dat)
	table.remove(cfg.boot_entries, id)
	local str = pretty(cfg, "\n", "\t", " ", json.encode)
	hand = component.invoke(envs.device, "open", "zorya-cfg/.zoryarc", "w")
	component.invoke(envs.device, "write", hand, str)
	component.invoke(envs.device, "close", hand)
end

oefi.zorya = {}

function oefi.zorya.loadfile(path)
	return envs.loadfile(computer.getBootAddress(), path)
end

--oefi.loadfile = oefi.loadfile

function zorya.rescanEntries()
	envs.hands["rescan"]()
end

envs.scan[#envs.scan+1] = function()
	for fs in component.list("filesystem") do
		if (component.invoke(fs, "isDirectory", ".efi")) then
			for _,file in ipairs(component.invoke(fs, "list", ".efi")) do
				if (file:match("%.efi$")) then
					envs.boot[#envs.boot+1] = {"OEFI("..fs:sub(3).."):"..file, "oefi", fs, ".efi/"..file, {}}
				end
			end
		end
	end
end

envs.hand["oefi"] = function(fs, file, args)
	function computer.getBootAddress()return fs end
	function computer.setBootAddress()end
    function zorya.getMode()return"oefi"end
	oefi.execOEFIApp(fs, file, args)
end