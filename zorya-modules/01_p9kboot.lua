--This is probably going to be the second most common option.
local comp = component or require("component")
local args = {...}
local envs = args[1]
envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "isDirectory", "boot/kernel")) then
			local subdir = comp.invoke(fs, "list", "boot/kernel")
			if (#subdir > 0) then
				for i=1, #subdir do
					if (not comp.invoke(fs, "isDirectory", "boot/kernel/"..subdir[i])) then
						envs.boot[#envs.boot+1] = {"(Plan9K) "..subdir[i].." on "..fs:sub(1,3), "p9k", fs, subdir[i], {}}
					end
				end
			end
		end
	end
end

envs.hand["p9k"] = function(fs, kern, args)
	computer.getBootAddress = function() return fs end
	return envs.loadfile(fs, "boot/kernel/"..kern)(args)
end
