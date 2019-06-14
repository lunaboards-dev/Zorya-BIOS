local comp = component or require("component")
local args = {...}
local envs = args[1]
--envs.boot[#envs.boot+1] = {"OEFI Terminal", "oefiterm", "", {}}

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

function binid_to_hexid(id)
	local f, r = string.format, string.rep
	return f(f("%s-%s%s", r("%.2x", 4), r("%.2x%.2x-", 3), r("%.2x", 6)), id:byte(1, 16))
end

function hexid_to_binid(id)
	local lasthex = 0
	local match = ""
	local bstr = ""
	for i=1, 16 do
		match, lasthex = id:match("%x%x", lasthex)
		bstr = bstr .. string.char(tostring(match, 16))
	end
	return bstr
end

local function lastboot()
	local eeprom = component.list("eeprom")()
	local dat = component.invoke(eeprom, "readData")
	local data = dat:sub(2, 17)
	local id = binid_to_hexid(data)
	local exec = dat:sub(19, 19+dat:byte(18))
	local canret = dat:sub(20+dat:byte(18), 20+dat:byte(18)) == "T"
	status("OEFI("..id.."):"..exec)
	status("Can return to OS: "..tostring(canret))
end

envs.hand["oefiterm"] = function(wd, coms)
	
end