local args = {...}
local envs = args[1]

local component = component or require("component")

--envs.boot[#envs.boot+1] = {"Zorya BIOS configuration", "cfg", {}}

envs.hand["cfg"] = function(args)
	
end

--Just check for our config files. Also, this file is loaded second to
--last, so we can both make a .zoryarc and/or replace the boot list.
local json, err = envs.loadfile(envs.device, "zorya-cfg/json.lua")
local pretty, err = envs.loadfile(envs.device, "zorya-cfg/pretty.lua")
if not json then error(err) else json = json() end
if not pretty then error(err) else pretty = pretty() end

local fs = component.proxy(envs.device)

if (not fs.exists("zorya-cfg/.zoryarc")) then
	envs.boot[#envs.boot+1] = {"Update Zorya and Init Modules", "netboot", "https://raw.githubusercontent.com/Adorable-Catgirl/Zorya-BIOS/master/update/setup.lua", {envs.device}}
	local hand = fs.open("zorya-cfg/.zoryarc", "w")
	local str = pretty(envs.boot, "\n", "\t", " ", json.encode)
	fs.write(hand, str)
	fs.close(hand)
else
	local hand = fs.open("zorya-cfg/.zoryarc", "r")
	local dat = fs.read(hand, math.huge)
	envs.boot = json.decode(dat)
	fs.close(hand)
end
