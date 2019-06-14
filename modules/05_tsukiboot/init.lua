local comp = component or require("component")
local args = {...}
local envs = args[1]
envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "isDirectory", "boot/kernel")) then
			local subdir = comp.invoke(fs, "list", "boot/kernel")
			if (#subdir > 0) then
				for i=1, #subdir do
					if (comp.invoke(fs, "isDirectory", "boot/kernel/"..subdir[i])) then
						if (comp.invoke(fs, "exists", "boot/kernel/"..subdir[i].."kernel.lua")) then
							envs.boot[#env.boot+1] = {"Kernel "..subdir[i]:sub(1, #subdir[i]-1).." on "..(comp.invoke(fs, "getLabel") or fs:sub(1, 3)), "tsuki", fs, subdir[i]:sub(1, #subdir[i]-1), {"novbind", "nomodeset", "bootaddr="..fs}}
						end
					end
				end
			end
		end
	end
end

envs.hand["tsuki"] = function(fs, kern, args)
	return envs.loadfile(fs, "boot/kernel/"..kern.."/kernel.lua")(args)
end

local function boot(addr, dir, args)
	envs.cls()
	_G._BOOTDEV = addr
	return envs.loadfile(addr, "boot/kernel/"..dir.."kernel.lua")(args)
end
