local args = {...}
local envs = args[1]
envs.boot[#envs.boot+1] = {"Network Boot", "netboot", "", {}}

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
		status("Trying connect (Try "..i.." of 3)")
		local req, err = dev.request(...)
		if not dev and err then status("E: "..err) else return req end
	end
	error("couldn't connect", 0)
end

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
	local req = establish_connection(envs.net, svc)
	local dat = get_data(req)
	local func, err = load(dat, "=netboot.lua")
	if not func and err then
		envs.gpu.set(1, 1, "ERROR: "..err)
		while true do computer.pullSignal() end
	else
		return func(table.unpack(args))
	end
end
