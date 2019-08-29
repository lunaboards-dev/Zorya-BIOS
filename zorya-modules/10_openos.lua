--This is probably going to be the most common option.
local comp = component or require("component")
local args = {...}
local envs = args[1]

envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "exists", "init.lua")) then
			envs.boot[#envs.boot+1] = {"OpenOS or compatible on "..fs:sub(1,3), "openos", fs, {}}
		end
	end
end

envs.hand["openos"] = function(fs, args)
  	function zorya.getMode()return"compat"end
	computer.getBootAddress = function() return fs end
	local _oefi = oefi
	oefi = nil
	local _zorya = zorya
	zorya = nil
	envs.loadfile(fs, "init.lua")(args)
	oefi = _oefi
	zorya = _zorya
end
