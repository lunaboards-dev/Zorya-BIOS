local component = component
local envs = ...

osdi = {}

local drive = {}

osdi.__drive_proto__ = drive

function osdi.wrap(device)
	if component.type(device) ~= "disk" then
		return nil, "component must be an unmanaged drive"
	end
	local dev = {
		dev = component.proxy(device)
	}
	return setmetatable(dev, {__index=drive})
end

function osdi.wrap_vdrive(vdrive)
	if (vdrive.type ~= "osdi_vdrive") then return nil, "not an osdi vdrive" end
	local dev = {
		dev = vdrive
	}
	return setmetatable(dev, {__index=drive})
end

function drive:is_osdi()
	local sec = self.dev.readSector(0)
	return (sec:sub(1, 16) == "OSDIPTBL\0\0\1\2\3\4\5\6")
end

function drive:create_partition_table()
	self.dev.writeSector(0, "OSDIPTBL\0\0\1\2\3\4\5\6_BOOTSEC\1\0\0\0\8\0\0\0\0")
	self.dev.writeSector(1, "--[[Blank boot sectors]]--")
end

function drive:get_geometry()
	return self.dev.getPlatterCount(), self.dev.getCapacity()/self.dev.getSectorSize(), self.dev.getSectorSize()
end

local function tobin(n)
	local s = ""
	for i=0, 3 do
		s = s .. string.char((n & (0xFF << i)) >> i)
	end
end

local function frombin(s, offset)
	local n = 0
	for i=0, 3 do
		n = n | (s:byte(offset+i) << (i*8))
	end
	return n
end

function drive:set_part_info(id, ptype, start, size)
	if (id < 2 or id > 31) then return nil, "Invalid partition ID." end
	ptype = ptype:sub(1, 8)
	ptype = ptype..string.char(0):rep(8-#ptype)
	local partinfo = self.dev.readSector(0)
	local before = partinfo:sub(1, 16*id)
	local after = partinfo:sub(16*(id+1)+1)
	self.dev.writeSector(0, before..ptype..tobin(start)..tobin(size)..after)
end

function drive:get_part_type(id)
	if (id < 2 or id > 31) then return nil, "Invalid partition ID."
	local partinfo = self.dev.readSector(0)
	local offset = id*16
	return partinfo:sub(offset, offset+8):match("[^%c]+")
end

function drive:get_part_start(id)
	if (id < 2 or id > 31) then return nil, "Invalid partition ID."
	local partinfo = self.dev.readSector(0)
	local offset=id*16
	return frombin(partinfo, offset+9)
end

function drive:get_part_size(id)
	if (id < 2 or id > 31) then return nil, "Invalid partition ID."
	local partinfo = self.dev.readSector(0)
	local offset=id*16
	return frombin(partinfo, offset+13)
end

function drive:get_virtual_drive(id)
	local offset = self:get_part_start(id)
	local size = self:get_part_size(id)
	local drv = {type = "osdi_vdrive"}
	function drv.readByte(offset)
		local sec = drv.readSector(offset // drv.getSectorSize())
		return sec:byte(offset % drv.getSectorSize())
	end
	function drv.writeByte(offset, value)
		local sec = drv.readSector(offset // drv.getSectorSize())
		local pos = offset % drv.getSectorSize()
		local before = sec:sub(1, pos-2)
		local after = sec:sub(pos-1)
		drv.writeSector(offset % drv.getSectorSize(), before..string.char(value)..after)
	end
	function drv.getSectorSize()
		return self.dev.getSectorSize()
	end
	function drv.getLabel()
		return "virtual_drive"
	end
	function drv.setLabel(value)
		return "virtual_drive"
	end
	function drv.readSector(sector)
		if (sector > size-1) then
			sector = size-1
		end
		if (sector < 0) then
			sector = 0
		end
		return self.drv.readSector(offset+sector)
	end
	function drv.writeSector(sector, value)
		if (sector > size-1) then
			sector = size-1
		end
		if (sector < 0) then
			sector = 0
		end
		return self.drv.writeSector(offset+sector, value)
	end
	function drv.getPlatterCount()
		return self.dev.getPlatterCount()
	end
	function drv.getCapacity()
		return self.getSectorSize()*size
	end
	return drv
end

function drv:get_boot_sect()
	local code = ""
	for i=1, 8 do
		code = code .. self.dev.readSector(i)
	end
	return code:match("[^%c]+") or ""
end

envs.scan[#envs.scan+1] = function()
	for d in component.list("drive") do
		local dv = osdi.wrap(d)
		if (dv:is_osdi()) then
			if (dv:get_boot_sect() ~= "") then
				envs.boot[#envs.boot+1] = {"OSDI("..d:sub(1, 3)..") - Unnamed Entry", "osdi", d, {}}
			end
		end
	end
end

envs.hand["osdi"] = function(fs, args)
	local di = osdi.wrap(fs)
	assert(load(di:get_boot_sect()))()
end
