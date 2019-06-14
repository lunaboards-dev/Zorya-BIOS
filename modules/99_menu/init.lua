local args = {...}
local envs = args[1]

local border_chars = {
	"┌", "─", "┐", "│", "└", "┘"
}
local w, h = envs.gpu.getViewport()
envs.gpu.setBackground(envs.cfg.bgcolor)
envs.gpu.setForeground(envs.cfg.fgcolor)
envs.cls()
--Draw some things
envs.gpu.set((w/2)-5, 1, "Zorya BIOS")
envs.gpu.set(1, 2, border_chars[1])
envs.gpu.set(2, 2, border_chars[2]:rep(w-2))
envs.gpu.set(w, 2, border_chars[3])
for i=1, h-6 do
	envs.gpu.set(1, i+2, border_chars[4])
	envs.gpu.set(w, i+2, border_chars[4])
end
envs.gpu.set(1, h-3, border_chars[5])
envs.gpu.set(2, h-3, border_chars[2]:rep(w-2))
envs.gpu.set(w, h-3, border_chars[6])
envs.gpu.set(1, h-1, "Use ↑ and ↓ keys to select which entry is highlighted.")
envs.gpu.set(1, h, "Use ENTER to boot the selected entry.")
local stime = computer.uptime()
local autosel = true
local ypos = 1
local sel = 1
local function redraw()
	envs.gpu.setBackground(envs.cfg.bgcolor)
	envs.gpu.setForeground(envs.cfg.fgcolor)
	envs.gpu.fill(1, h-2, w, 1, " ")
	if (autosel) then
		envs.gpu.set(1, h-2, "Automatically booting in "..math.floor(envs.cfg.timeout-(computer.uptime()-stime)).."s.")
	end
	for i=1, h-6 do
		local entry = envs.boot[ypos+i-1]
		if not entry then break end
		local name = entry[1]
		if not name then break end
		local short = name:sub(1, w-2)
		if (short ~= name) then
			short = short:sub(1, #sub-3).."..."
		end
		if (#short < w-2) then
			short = short .. string.rep(" ", w-2-#short)
		end
		if (sel == ypos+i-1) then
			envs.gpu.setBackground(envs.cfg.fgcolor)
			envs.gpu.setForeground(envs.cfg.bgcolor)
		else
			envs.gpu.setBackground(envs.cfg.bgcolor)
			envs.gpu.setForeground(envs.cfg.fgcolor)
		end
		envs.gpu.set(2, i+2, short)
	end
end
redraw()
sel = envs.cfg.default
while true do
	local sig, _, key, code = computer.pullSignal(0.01)
	if (sig == "key_down") then
		autosel = false
		if (key == 0 and code == 200) then
			sel = sel - 1
			if (sel < 1) then
				sel = 1
			end
			if (sel < ypos) then
				ypos = ypos - 1
			end
		elseif (key == 0 and code == 208) then
			sel = sel + 1
			if (sel > #envs.boot) then
				sel = #envs.boot
			end
			if (sel > ypos+h-7) then
				ypos = ypos+1
			end
		elseif (key == 13 and code == 28) then
			envs.gpu.setBackground(0)
			envs.gpu.setForeground(0xFFFFFF)
			envs.start(sel)
		end
	end
	if (((computer.uptime()-stime) >= envs.cfg.timeout) and autosel) then
		envs.start(sel)
	end
	redraw()
end
