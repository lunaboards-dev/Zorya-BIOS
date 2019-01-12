local c,s,_x,d=component or require("component"),string,"%.2x",computer
local i,l,p,ps=c.invoke,c.list,c.proxy,d.pullSignal
local sr,sf,sb=s.rep,s.format,s.byte
_G._BOOT="Zorya"
_G._ZVER=0.1
local t=function(f,h)local b=""local d,r=i(f,"read",h,math.huge)if not d and r then e(r)end;b=d;while d do local d,r=i(f,"read",h,math.huge)b=b..(d or "")if(not d)then break end;end;i(f,"close",h)return b;end;
local ed=function(d, f)for c in l(d)do if f(c)then break end end;end
local function b2a(data)return sf(sf("%s-%s%s",sr(_x, 4),sr(_x.._x.."-",3),sr(_x,6)),sb(data, 1,#data))end
local function a2b(addr)
	addr=addr:gsub("%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. s.char(tonumber(addr:sub(i, i+1), 16))
	end
	return baddr
end
local zm="zorya-modules"
local eeprom=p(l("eeprom")())
local dat = eeprom.getData()
local addr
if (dat ~= "") then
	addr = b2a(dat)
else
	ed("filesystem", function(dev)
		if (i(dev, "isDirectory", "zorya-modules")) then
			addr = dev
			eeprom.setData(a2b(dev))
			return true
		end
	end)
	if not addr then
		ed("filesystem", function(dev)
			if (#i(dev, "list", "/") == 0 and i(dev, "getLabel") ~= "tmpfs") then
				addr = dev
				eeprom.setData(a2b(dev))
				local inet=p(l("internet")())
				if not inet then error("no net, can't setup") end
				local ih=inet.request("https://raw.githubusercontent.com/Adorable-Catgirl/Zorya-BIOS/master/update/setup.lua")
				if (ih.finishConnection()) then
					load(ih.read())(addr)
				else
					error("failed to connect")
				end
				return true
			end
		end)
		if not addr then
			error("unable to get a zorya-modules directory")
		end
	end
end
if (not i(addr, "exists", "zorya-modules/boot.lua")) then
	--Panic some, just try to bind the GPU and load OpenOS.
	local gpu = p(l("gpu")())
	local screen = l("screen")()
	gpu.bind(screen)
	local w, h = gpu.getResolution()
	gpu.setResolution(w, h)
	gpu.setBackground(0)
	gpu.setForeground(0xFFFFFF)
	gpu.fill(1, 1, w, h, " ")
	local cls = function()gpu.fill(1,1,w,h," ")end
	local y = 1
	local function status(msg)
	    if gpu and screen then
	    	gpu.set(1, y, msg)
	        if y == h then
	        	gpu.copy(1, 2, w, h-1, 0, -1)
	        	gpu.fill(1, h, w, 1, " ")
	        else
	            y = y + 1
	        end
	    end
	end
	status("Error: zorya-modules/boot.lua not found. Trying to load OpenOS...")
	return ed("filesystem", function(dev)
		if i(dev, "exists", "init.lua") then
			computer.getBootAddress = function()return dev end
			local h = i(dev, "open", "init.lua")
			return load(t(dev, h), "=init.lua")()
		end
	end)
else
	local h = i(addr, "open", "zorya-modules/boot.lua")
	local code = t(addr, h)
	return load(code, "=zorya-modules/boot.lua")(addr)
end
