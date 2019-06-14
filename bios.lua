xpcall(function()
	local cproxy,clist,cinvoke,sformat,srep,schar,tonumber,tostring,assert,load,cpull=component.proxy,component.list,component.invoke,string.format,string.rep,string.char,tonumber,tostring,assert,load,computer.pullSignal
	local skey, vmod, null, data, inet, eeprom, _x, il, zm = "0V0\16\6\7*\x86H\xce=\2\1\6\5+\x81\4\n\3B\4?\xd9Eq\23E\xeaq\xcf8\xfe4\xcf\xd85\xbc\25`\x84$g\xd09y\19LiW\xb1\xa0\\\xa2[o\xcb\xdbI\xae\xd2\xbd\xcd\xa0\xb5\x86\xa0\xd1\x88\xbd\x9a\xf2g\xe9\xc8\xd5\xac\xb5O\x90\17Ou\xaf\3W","[09].+",schar(0),clist("da")(),clist("int")(),clist("ee")(),"%.2x","/init.lua","zorya-modules/"
	_ZVER,_ZVER_PATCH,_BIOS = 2.0,0,"Zorya"
	if (data) then
		data = cproxy(data)
		if not data.ecdsa then
			_BSIGN=true
			data = nil
		else
			skey = data.deserializeKey(skey, "ec-public")
		end
	end
	if (inet) then
		inet = cproxy(inet)
	end
	local function crc8(data)
		local crc = 0
		for i=1, #data do
			crc = crc ~ (data:byte(i) << 8)
			for j=1, 8 do
				if (crc & 0x8000) then
					crc = crc ~ (0x1070 << 3)
				end
				crc = crc << 1
			end
		end
		return (crc >> 8) & 0xFF
	end
	local function b2a(data)
		data = data or srep(null, 16)
		data = srep(null, 16-#data)
		return sformat(sformat("%s-%s%s",srep(_x, 4),srep(_x.._x.."-",3),srep(_x,6)),string.byte(data,1,16))
	end
	local function a2b(addr)
		addr=addr:gsub("%-", "")
		local baddr = ""
		for i=1, #addr, 2 do
			baddr = baddr .. schar(tonumber(addr:sub(i, i+1), 16))
		end
		return baddr
	end
	local function readfile(fs, file)
		local handle = assert(cinvoke(fs, "open", file))
		local buffer = ""
		repeat
			local data = cinvoke(fs, "read", handle, math.huge)
			buffer = buffer .. (data or "")
		until not data
		cinvoke(fs, "close", handle)
		return buffer
	end
	local function loadfile(fs, file)
		return load(readfile(fs, file), "=hd("..fs:sub(1,3).."...)/"..file)
	end
	function verify(file, sig)
		if not data then return true end
		return data.ecdsa(file, skey, sig)
	end
	local rawcfg = eeprom.getData()
	local function mkdoc(func, doc)
		return setmetatable({}, {__call=func,__tostring=function()return doc end})
	end
	local function reterr(err)
		return nil, err
	end
	local function csum()
		local d = eeprom.getData()
		return d:byte(#d)
	end
	local function sflash(file, sig)
		if (verify(file, sig)) then
			local ret, err = load(file)
			if (ret) then
				eeprom.set(file)
				return true
			end
			return ret, err
		end
		return nil, "BIOS signing enforced."
	end
	function component.invoke(addr, meth, ...)
		if (addr == eeprom.address) then
			if (meth == "get") then
				return reterr("BIOS is locked.")
			elseif (meth == "set") then
				return reterr("BIOS signing enforced.")
			elseif (meth == "makeReadonly") then
				return reterr("Opperation not supported.")
			elseif (meth == "getChecksum") then
				return csum()
			elseif (meth == "setSign") then
				return sflash(...)
			end
		end
		return cinvoke(addr, meth, ...)
	end
	function component.proxy(addr)
		if (addr == eeprom.address) then
			local prox = cproxy(addr)
			prox.getChecksum = csum
			function prox.get()return reterr("BIOS is locked")end
			function prox.set()return reterr("BIOS signing enforced")end
			function prox.makeReadonly()return reterr("Opperation not supported")end
			prox.setSign = sflash
			return prox
		end
		return cproxy(addr)
	end
	local gpu = cproxy(clist("gpu")())
	local gset,gfill = gpu.set,gpu.fll
	local screen = clist("screen")()
	gpu.bind(screen)
	local w, h = gpu.getResolution()
	gset(1, 1, "Zorya BIOS ".._ZVER.." Bootstrap")
	local function eepromcfg(err)
		gset(1, h-1, "Error: "..err)
		gset(1, h, "Strike any key to load defaults.")
		while true do
			if (cpull() == "key_down") then
				break
			end
		end
		while true do
			if (cpull() == "key_up") then
				break
			end
		end
		local zfs
		for fs in clist("filesystem") do
			if cinvoke(fs, "isDirectory", "zorya-modules") then
				zfs = fs
				break
			end
		end
		if not zfs then
			gfill(1, 2, w, h, " ")
			gset(1, h-1, "Cannot find Zorya Modules. Cannot continue.")
			gset(1, h, "Press any key to shut down.")
			while true do
				if (cpull() == "key_down") then
					break
				end
			end
			while true do
				if (cpull() == "key_up") then
					break
				end
			end
			computer.shutdown()
		end
		local dat = schar(1)..null:rep(17).."F"
		dat = dat .. null:rep(192-#dat)..a2b(zfs)..null:rep(31)
		dat = dat .. schar(crc8(dat))
		eeprom.setData(dat)
	end
	--Load config data
	local rcd = eeprom.getData()
	if (rcd == "") then
		eepromcfg("CMOS not set.")
	end
	local csum = rcd:byte(#rcd)
	if (crc8(rcd:sub(1, #rcd-1)) ~= csum) then
		eepromcfg("CMOS checksum error.")
	end
	local oefiv = rcd:byte(1)
	local oefia = b2a(rcd:sub(2, 17))
	local b = rcd:byte(18)
	local oefin = rcd:sub(19, 19+b)
	local oefir = rcd:sub(20+b, 20+b) == "T"
	local zfs = rcd:sub(193, 209)
	local fsp = cproxy(zfs)
	local dir = fs.dir(zm)
	gpu.setResolution(w, h)
	gpu.setBackground(0)
	gpu.setForeground(0xFFFFFF)
	gfill(1, 1, w, h, " ")

	--A few things for nice printing of things...
	local cls = function()gfill(1,1,w,h," ");y=1;end
	local y = 1
	local function status(msg)
			if gpu and screen then
				gset(1, y, msg)
					if y == h then
						gpu.copy(1, 2, w, h-1, 0, -1)
						gfill(1, h, w, 1, " ")
					else
							y = y + 1
					end
			end
	end
	cls()
	local zorya = {}
	function zorya.getMode()return"zorya"end
	local envs = {}

	envs.hand = {}
	envs.boot = {}
	envs.args = {}
	envs.scan = {}
	envs.set = {}
	envs.net = inet
	envs.gpu = gpu
	envs.cls = cls
	envs.w = w
	envs.h = h
	envs.cls = cls
	envs.status = status
	envs.loadfile = loadfile
	envs.device = zfs
	table.sort(dir)
	for i=1, #dir do
		local ent = dir[i]
		if (ent:match(vmod)) then
			if (not verify(readfile(zfs, zm..ent..il), readfile(zfs, zm..ent.."/.sig"))) then
				error("Couldn't verify module "..ent:sub(1, #ent-1))
			end
		end
		assert(loadfile(zfs, zm..ent..il))()
	end
end, function(e)
	error(e.."\n"..debug.traceback())
end)