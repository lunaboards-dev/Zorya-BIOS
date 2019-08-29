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

local function isCpio(fs, path)
	fs = comp.proxy(fs)
	local handle = fs.open(path, "r")
	local function readint(amt, rev)
	    local tmp = 0
	    for i=(rev and amt) or 1, (rev and 1) or amt, (rev and -1) or 1 do
	    	tmp = bit32.bor(tmp, bit32.lshift(fs.read(handle, 1):byte(), ((i-1)*8)))
	    end
	    return tmp
	end
	local magic = readint(2)
	if (magic == tonumber("070707", 8)) then
		return true
	end
	return false
end

local function readCpio(fs, path) -- Read CPIO in memory
	fs = comp.proxy(fs)
	cpio = {}
	local handle = fs.open(path, "r")
	local dent = {
	    magic = 0,
	    dev = 0,
	    ino = 0,
	    mode = 0,
	    uid = 0,
	    gid = 0,
	    nlink = 0,
	    rdev = 0,
	    mtime = 0,
	    namesize = 0,
	    filesize = 0,
	}
	local function readint(amt, rev)
	    local tmp = 0
	    for i=(rev and amt) or 1, (rev and 1) or amt, (rev and -1) or 1 do
	    	tmp = bit32.bor(tmp, bit32.lshift(fs.read(handle, 1):byte(), ((i-1)*8)))
	    end
	    return tmp
	end
	while true do
		dent.magic = readint(2)
		local rev = false
	    if (dent.magic ~= tonumber("070707", 8)) then rev = true end
	    dent.dev = readint(2)
	    dent.ino = readint(2)
	    dent.mode = readint(2)
	    dent.uid = readint(2)
	    dent.gid = readint(2)
	    dent.nlink = readint(2)
	    dent.rdev = readint(2)
	    dent.mtime = bit32.bor(bit32.lshift(readint(2), 16), readint(2))
	    dent.namesize = readint(2)
	    dent.filesize = bit32.bor(bit32.lshift(readint(2), 16), readint(2))
	    local name = fs.read(handle, dent.namesize):sub(1, dent.namesize-1)
	    if (name == "TRAILER!!!") then break end
	    dent.name = name
	    if (dent.namesize % 2 ~= 0) then
	        fs.read(handle, 1) -- skip one byte
	    end
	    if bit32.band(dent.mode, 32768) ~= 0 then -- just wait for Lua 5.3 compatibility!
	        local dir = dent.name:match("(.+)/.*%.?.+")
	        if (dir) then
	        	cpio[dir] = true
	        end
	        cpio[dent.name] = fs.read(handle, dent.filesize) -- TODO: use better method to read files over 2KB
	    end
	    if (dent.filesize % 2 ~= 0) then
	        fs.read(handle, 1) -- skip one byte
	    end
	end
	fs.close(handle)
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
	
	readCpio(drive, path)
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
					if isCpio(fs, ".efi/" .. file) then
						readCpio(fs, ".efi/" .. file)
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
					end
				end
			end
		end
	end
end

envs.hand["oefi2"] = function(fs, file, args)
	oefi = oefi2
	oefi2 = nil -- clean oefi2

	oefi.execOEFIApp(fs, file, args)
end
