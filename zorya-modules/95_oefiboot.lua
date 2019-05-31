local comp = component or require("component")
local args = {...}
local envs = args[1]
envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "isDirectory", ".efi")) then
			for file in comp.invoke(fs, "list", ".efi") do
				if (file:match("%.efi$")) then
					envs.boot[#envs.boot+1] = {"OEFI("..fs:sub(3).."):"..file, "oefi", fs, file, {}}
				end
			end
		end
	end
end

envs.hand["oefi"] = function(fs, file)

    function zorya.getMode()return"oefi"end
	local c = coroutine.create(oefi.execOEFIApp﻿)
	coroutine.start(fs, file)
	while true do
		local sig = {computer.pullSignal()}
		if (sig[0] == "__ZORYA_RETURN") then
			return coroutine.yield(c)
		end
		computer.pushSignal(table.unpack(sig))
	end
end