local args = {...}
local envs = args[1]
envs.scan[#envs.scan+1] = function(envs)
	envs.cfg.gpuset = {}
	envs.cfg.gpuset.x, envs.cfg.gpuset.y = envs.gpu.getViewport()
end

envs.set[#envs.set+1] = function(envs)
	envs.gpu.setViewport(envs.cfg.gpuset.x, envs.cfg.gpuset.y)
end