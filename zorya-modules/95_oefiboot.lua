local comp = component or require("component")
local args = {...}
local envs = args[1]
envs.scan[#envs.scan+1] = function()
	for fs in comp.list("filesystem") do
		if (comp.invoke(fs, "isDirectory", ".efi")) then
			for _,file in ipairs(comp.invoke(fs, "list", ".efi")) do
				if (file:match("%.efi$")) then
					envs.boot[#envs.boot+1] = {"OEFI("..fs:sub(3).."):"..file, "oefi", fs, ".efi/"..file, {}}
				end
			end
		end
	end
end

envs.hand["oefi"] = function(fs, file, args)
	function computer.getBootAddress()return fs end
	function computer.setBootAddress()end
    function zorya.getMode()return"oefi"end
	oefi.execOEFIApp(fs, file, args)
end