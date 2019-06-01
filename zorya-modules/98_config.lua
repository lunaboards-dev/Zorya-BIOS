local args = {...}
local envs = args[1]

local component = component or require("component")
local json, err = envs.loadfile(envs.device, "zorya-cfg/json.lua")
local pretty, err = envs.loadfile(envs.device, "zorya-cfg/pretty.lua")
if not json then error(err) else json = json() end
if not pretty then error(err) else pretty = pretty() end

local fs = component.proxy(envs.device)

--envs.boot[#envs.boot+1] = {"Zorya BIOS configuration", "cfg", {}}

function scan()
	for i=1, #envs.scan do
		envs.scan[i]()
	end
end

envs.hand["cfg"] = function(args)
	
end

envs.hand["rescan"] = function(args)
	envs.boot = {}
	scan()
	envs.boot[#envs.boot+1] = {"Update Zorya and Init Modules", "netboot", "https://raw.githubusercontent.com/Adorable-Catgirl/Zorya-BIOS/master/update/setup.lua", {envs.device}}
	envs.boot[#envs.boot+1] = {"Rescan for OSes", "rescan", ""}
	local hand = fs.open("zorya-cfg/.zoryarc", "w")
	local str = pretty(envs.cfg, "\n", "    ", " ", json.encode)
	fs.write(hand, str)
	fs.close(hand)
end

--Just check for our config files. Also, this file is loaded second to
--last, so we can both make a .zoryarc and/or replace the boot list.

if (not fs.exists("zorya-cfg/.zoryarc")) then
	scan()
	envs.boot[#envs.boot+1] = {"Update Zorya and Init Modules", "netboot", "https://raw.githubusercontent.com/Adorable-Catgirl/Zorya-BIOS/master/update/install.lua", {envs.device}}
	envs.boot[#envs.boot+1] = {"Rescan for OSes", "rescan", ""}
	local hand = fs.open("zorya-cfg/.zoryarc", "w")
	local str = pretty({boot_entries=envs.boot,timeout=10,default=1,bgcolor=0,fgcolor=0xFFFFFF}, "\n", "    ", " ", json.encode)
	fs.write(hand, str)
	fs.close(hand)
else
	local hand = fs.open("zorya-cfg/.zoryarc", "r")
	local dat = fs.read(hand, math.huge)
	local cfg = json.decode(dat)
	envs.cfg = cfg
	envs.boot = cfg.boot_entries
	fs.close(hand)
end
