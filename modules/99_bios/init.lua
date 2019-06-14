local envs = ...
local cls, gpu = envs.cls, envs.gpu
cls()
local info = computer.getDeviceInfo()
local procinfo = ""
local meminfo = {}
for k, v in pairs(info) do
	if (v.class == "processor") then
		procinfo = string.format("%s @ %dkHz", v.product, v.clock)
	elseif (v.description == "Memory bank") then
		meminfo[#meminfo+1] = string.format("%dkHz", v.clock)
	end
end
gpu.set(1, 1, string.format("Zorya BIOS v%.1d", _ZVER))
gpu.set(1, 2, "CPU: "..procinfo)
gpu.set(1, 3, string.format("%ikB", computer.totalMemory()//1024))
for i=1, #meminfo do
	gpu.set(1, 3+i, "     Bank "..i.." @ "..meminfo[i])
end
local w, h = gpu.getResolution()
gpu.set(1, h, "C - Config Menu")

local stime = computer.uptime()
while true do
	local evt = {computer.pullSignal(2-(computer.uptime()-stime))}
	if (evt[1] == "key_down" and evt[2] == 99 and evt[3] == 46) then
		--Configuration
	elseif (evt[1] == "key_down" and evt[2] == 98 and evt[3] == 48) then
		--Boot menu
	end
end
envs.start(envs.cfg.default)