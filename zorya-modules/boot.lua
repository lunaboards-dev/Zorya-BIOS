--boot.lua
--Zorya Init Modules
--REQUIRED to start the computer. Not having this file will
--cause the init to fail and go into fallback mode. Not fun.

local component = component or require("component")
local proxy, list=component.proxy, component.list
local args = {...}

local invoke = component.invoke
local function loadfile(addr, file)
	local handle = assert(invoke(addr, "open", file))
	local buffer = ""
	repeat
		local data = invoke(addr, "read", handle, math.huge)
		buffer = buffer .. (data or "")
	until not data
	invoke(addr, "close", handle)
	return load(buffer, "=" .. file, "bt", _G)
end
debug_print("test")
--Also, we need to load all our components here.
local zorya = proxy(args[1])
local inet = list("internet")() --We don't *need* internet.
inet = inet and proxy(inet)

--Time to actually get some display, thanks to our trusty GPU.
local gpu = proxy(list("gpu")())
local screen = list("screen")()

gpu.bind(screen)
--And now we have output.

--Some GPU setup code...
local w, h = gpu.getResolution()
gpu.setResolution(w, h)
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")

--A few things for nice printing of things...
local cls = function()gpu.fill(1,1,w,h," ");y=1;end
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

local envs = {}

envs.hand = {}
envs.boot = {}
envs.args = {}
envs.net = inet
envs.gpu = gpu
envs.cls = cls
envs.w = w
envs.h = h
envs.cls = cls
envs.status = status
envs.loadfile = loadfile
envs.device = zorya.address
debug_print(#zorya.list("zorya-modules"))
for _, file in ipairs(zorya.list("zorya-modules")) do
	status("Loading zorya-modules/"..file)
	debug_print("Loading zorya-modules/"..file)
	if (file ~= "zorya_menu.lua" and file ~= "boot.lua" and file ~= "config.lua") then
		local func, err = loadfile(zorya.address, "zorya-modules/"..file)
		if not func then debug_print(err);status(err) else func(envs)end
	end
end
local func, err = loadfile(zorya.address, "zorya-modules/config.lua")
if not func then debug_print(err);status(err) else func(envs)end

local func, err = loadfile(zorya.address, "zorya-modules/zorya_menu.lua")
if not func then debug_print(err);status(err) else func(envs)end
