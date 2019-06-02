local characters = {
	"╔", "╗", "═", "║", "╚", "╝"
}
local args = {...}
local component = component or require("component")
local computer = computer or require("computer")
local proxy, list = component.proxy, component.list
local gpu = proxy(list("gpu")())
if (not gpu.getScreen()) then
	gpu.bind(list("screen")())
end
--Load palette
gpu.setPaletteColor(0, 0x000000)
gpu.setPaletteColor(1, 0xFFFFFF)
gpu.setPaletteColor(2, 0x4444FF)
gpu.setPaletteColor(3, 0xFF7F44)
gpu.setPaletteColor(4, 0x00007F)
gpu.setPaletteColor(5, 0x7F00FF)
gpu.setPaletteColor(6, 0x595959)
gpu.setBackground(0, true)
local w, h = gpu.getViewport()
gpu.fill(1, 2, w, h-1, " ")
gpu.setBackground(5, true)
gpu.fill(1, 1, w, 1, " ")
local title = "Zorya Installer v1.0"
local spos = (w/2)-(#title/2)
gpu.setForeground(1, true)
gpu.set(spos, 1, title)
gpu.setForeground(1, true)
gpu.setBackground(5, true)
gpu.fill(6,6,w-12,h-12, " ")
gpu.set(6,6,characters[1])
gpu.set(w-6,6,characters[2])
gpu.set(6,h-6,characters[5])
gpu.set(w-6,h-6,characters[6])
gpu.fill(7,6,w-13,1,characters[3])
gpu.fill(7,h-6,w-13,1,characters[3])
gpu.fill(6,7,1,h-13,characters[4])
gpu.fill(w-6,7,1,h-13,characters[4])
function setStatus(stat)
	gpu.setBackground(5, true)
	gpu.setForeground(1, true)
	gpu.fill(7,(h/2)-3, w-13, 1, " ")
	gpu.set((w/2)-(#stat/2), (h/2)-3, stat)
end
function setBar(pos)
	gpu.setBackground(6, true)
	gpu.fill(8, (h/2)+1, w-16, 1, " ")
	gpu.setBackground(2, true)
	gpu.fill(8, (h/2)+1, ((w-16)/100)*pos, 1, " ")
end

setStatus("Setting up internet...")
setBar(50)
local files = {
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/boot.lua", "zorya-modules/boot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/00_oefi.lua", "zorya-modules/00_oefi.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/00_openosboot.lua", "zorya-modules/00_openosboot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/01_p9kboot.lua", "zorya-modules/01_p9kboot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/02_tsukiboot.lua", "zorya-modules/02_tsukiboot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/95_oefiboot.lua", "zorya-modules/95_oefiboot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/97_netboot.lua", "zorya-modules/97_netboot.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/98_config.lua", "zorya-modules/98_config.lua"},
	{"Adorable-Catgirl/Zorya-BIOS/master/zorya-modules/99_menu.lua", "zorya-modules/99_menu.lua"},
	{"rxi/json.lua/master/json.lua", "zorya-cfg/json.lua"},
	{"bungle/lua-resty-prettycjson/master/lib/resty/prettycjson.lua", "zorya-cfg/pretty.lua"},
}
local inet = proxy(list("internet")())

function writeFile(fs, path, data)
	local hand = fs.open(path, "w")
	fs.write(hand, data)
	fs.close(hand)
end

function mkdir(fs, path)
	fs.makeDirectory(path)
end

local function get_data(req)
	local code = ""
	while true do
		local data, reason = req.read()
		if not data then req.close(); if reason then error(reason, 0) end break end
		code = code .. data
	end
	return code
end

local function establish_connection(dev, ...)
	for i=1, 3 do
		--setStatus("Trying connect (Try "..i.." of 3)")
		local req, err = dev.request(...)
		if not dev and err then  else return req end
	end
	error("couldn't connect", 0)
end

function getGithub(path)
	local con = establish_connection(inet, "https://raw.githubusercontent.com/"..path)
	local dat = get_data(con)
	return dat
end

setStatus("Setting up directories...")
setBar(100)

local fs = proxy(computer.getBootAddress())
mkdir(fs,"zorya-modules")
mkdir(fs,"zorya-cfg")

setStatus("Downloading files...")
setBar(0)
for i=1, #files do
	setStatus("Downloading "..files[i][2].." (file "..i.." of "..#files..")")
	local dat = getGithub(files[i][1])
	writeFile(fs, files[i][2], dat)
	setBar((100/#files)*i)
end

setStatus("Downloading BIOS...")
setBar(0)
local bios = getGithub("Adorable-Catgirl/Zorya-BIOS/master/bios.lua")
setStatus("Flashing EEPROM...")
setBar(33)
local eeprom = proxy(list("eeprom")())
eeprom.set(bios)
setStatus("Writing configuration data...")
setBar(66)
function hexid_to_binid(addr)
  addr=addr:gsub("%-", "")
  local baddr = ""
  for i=1, #addr, 2 do
    baddr = baddr .. string.char(tonumber(addr:sub(i, i+1), 16))
  end
  return baddr
end
eeprom.setData(string.char(2)..string.char(0):rep(17)..hexid_to_binid(fs.address).."F"..string.char(0):rep(64-16))
eeprom.setLabel("Zorya BIOS v1.0")
setBar(100)
setStatus("Rebooting in 5 seconds...")
computer = computer or require("computer")
local stime = computer.uptime()
while true do
	if (computer.uptime()-stime > 5) then
		computer.shutdown(true)
	end
	computer.pullSignal(0.01)
	setBar((computer.uptime()-stime)*20)
end