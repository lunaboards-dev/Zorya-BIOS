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
--Also, we need to load all our components here.
local zy = proxy(args[1])
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

function zorya.getMode()return"zorya"end
local envs = {}

envs.hand = {}
envs.boot = {}
envs.args = {}
envs.scan = {}
envs.net = inet
envs.gpu = gpu
envs.cls = cls
envs.w = w
envs.h = h
envs.cls = cls
envs.status = status
envs.loadfile = loadfile
envs.device = zy.address
for _, file in ipairs(zy.list("zorya-modules")) do
	status("Loading zorya-modules/"..file)
	if (file ~= "boot.lua") then
		local func, err = loadfile(zy.address, "zorya-modules/"..file)
		if not func then status(err) else func(envs)end
	end
end
