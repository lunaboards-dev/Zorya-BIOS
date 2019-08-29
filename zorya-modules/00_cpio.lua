zorya.cpio = {}
local comp = component or require("component")

--- Returns true if the file is a CPIO. False otherwises
function zorya.cpio.validate(fs, path)
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

--- Load the cpio into a table. If value is true, then key is a directory, otherwise value is a string and key corresponds
--- to a file
function zorya.cpio.load(fs, path)
	fs = comp.proxy(fs)
	local cpio = {}
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
	return cpio
end
