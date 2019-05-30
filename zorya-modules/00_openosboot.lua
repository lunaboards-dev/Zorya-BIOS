--This is probably going to be the most common option.
local comp = component or require("component")
local args = {...}
local envs = args[1]

envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "exists", "init.lua")) then
			envs.boot[#envs.boot+1] = {"OpenOS or compatible on "..fs:sub(3), "openos", fs, {}}
		end
	end
end

envs.hand["openos"] = function(fs, args)
	computer.getBootAddress = function() return fs end
	return envs.loadfile(fs, "init.lua")(args)
end
