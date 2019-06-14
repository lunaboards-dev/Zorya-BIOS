local envs = ...
local component = component
local modem = component.list("modem")()
if (modem) then
	modem = component.proxy(modem)
	envs.scan[#envs.scan+1] = function()
		envs.boot[#envs.boot+1] = {"Zorya LAN Boot", "lan", "", {}}
		envs.cfg.wifi = {}
		envs.cfg.power = 32
	end

	envs.hand["lan"] = function(svc, args)
		envs.cls()
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
		else
			envs.gpu.set(1, 1, "Requesting: "..svc)
		end
		envs.gpu.set(1, 2, "Broadcasting connect request...")
		if (modem.isWireless())
			modem.setPower(envs.cfg.power)
		end
		modem.open(9900)
		modem.broadcast(9900, app)
		local dat = {}
		while true do
			local evt = {computer.pullSignal()}
			if (evt[1] == "modem_message" and evt[3] == 9900) then
				local mdat = evt[5]
				local msg_num = mdat:byte(1)
				local msg_max = mdat:byte(2)
				dat[msg_num+1] = mdat:sub(3)
				if (#dat == msg_max-1) then
					return assert(load(table.concat(dat, "")))()
				end
			end
		end
	end
end