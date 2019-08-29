oefi2 = {}

local comp = component or require("component")
local envs = ...
local cpio = {}

function oefi2.getAPIVersion()
	return 2.1
end

function oefi2.getExtensions()
	return {
		["ZoryaBIOS_GetEntries_1"] = zorya.getEntries,
		["ZoryaBIOS_AddEntry_1"] = zorya.addEntry,
		["ZoryaBIOS_RemoveEntry_1"] = zorya.removeEntry
	}
end

function oefi2.setApplications(apps)
	-- TODO with zorya entries but only for OEFI
end

local function readCfg(cfg)
	local c = {}
	for line in string.gmatch(cfg, "([^\n]+)") do
		local seps, sepe = string.find(line, "=")
		local key = string.sub(line, 1, seps-2)
		local val = string.sub(line, sepe+2, string.len(line))
		c[key] = val
	end
	return c
end

local function getLuaVersion()
	return tonumber(_VERSION:sub(5, _VERSION:len()))
end

function oefi2.getImplementationName()
	return "Zorya BIOS"
end

function oefi2.getImplementationVersion()
	return zorya.getVersion()
end

function oefi2.returnToOEFI()
	computer.shutdown(true)
end

function oefi2.loadInternalFile(path)
	return cpio[path]
end

local boot
function oefi2.execOEFIApp(drive, path, args)
	boot = drive

	cpio = zorya.cpio.load(drive, path)
	local chunk = load(cpio["app.exe"])()
	chunk(args)
end

function oefi2.getApplications()
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

function oefi2.getBootAddress()
	return boot
end

function oefi2.loadfile(path)
	return envs.loadfile(boot, path)
end

envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "isDirectory", ".efi")) then
			for _,file in ipairs(comp.invoke(fs, "list", ".efi")) do
				if (file:match("%.efi$") or file:match("%.efi2$")) then
					if zorya.cpio.validate(fs, ".efi/" .. file) then
						cpio = zorya.cpio.load(fs, ".efi/" .. file)
						if cpio["app.cfg"] and cpio["app.exe"] then
							local cfg = readCfg(cpio["app.cfg"])
							if cfg.arch == "Lua" then
								local min = tonumber(cfg.archMinVer)
								local max = tonumber(cfg.archMaxVer)
								local curr = getLuaVersion()
								if curr >= min and curr <= max then
									envs.boot[#envs.boot+1] = {cfg["name"] .. " on " .. fs:sub(1,3) .. " (OEFI2)", "oefi2", fs, ".efi/"..file, {}}
								end
							end
						end
						cpio:close()
					end
				end
			end
		end
	end
end

envs.hand["oefi2"] = function(fs, file, args)
	local _oefi = oefi
	local _oefi2 = oefi2
	oefi = oefi2
	oefi2 = nil -- clean oefi2
	function zorya.getMode()return "oefi2"end
	oefi.execOEFIApp(fs, file, args)
	oefi = _oefi
	oefi2 = _oefi2
end
