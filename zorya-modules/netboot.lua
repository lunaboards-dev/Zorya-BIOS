local args = {...}
local envs = args[1]
envs.boot[#envs.boot+1] = {"Network Boot", "netboot", "", {}}

envs.hand["netboot"] = function(svc, args)
	if svc == "" then
		while true do
			envs.cls()
			envs.gpu.set(1, 1, "Enter a url to netboot to: "..(svc or ""))
			local sig, _, key, code = computer.pullSignal()
			if (sig == "key_down") then
				if (key ~= 0 and key ~= 8 and key ~= 13) then
					svc = (svc or "") .. string.char(key)
				elseif (key == 8) then
					svc = svc:sub(1, #svc-1)
				elseif (key == 13) then
					break
				end
			end
		end
	end
	local req = envs.net.request(svc)
	if (req.finishConnect()) then
		local dat = req.read()
		local func, err = load(dat, "=netboot.lua")
		if not func and err then
			envs.gpu.set(1, 1, "ERROR: "..err)
			while true do computer.pullSignal() end
		else
			return func()
		end
	end
end
