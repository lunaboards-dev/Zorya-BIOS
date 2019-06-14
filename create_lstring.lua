local f = io.open(arg[1], "rb")
local dat = f:read("*a")
f:close()
io.stdout:write("\"")
local escapes = {
	[10] = "\\n",
	[13] = "\\r",
	[12] = "\\f"
}
for i=1, #dat do
	local c = dat:sub(i, i):byte()
	if (c >= 32 and c ~= 34 and c ~= 92 and c < 127) then
		io.stdout:write(dat:sub(i, i))
	elseif (c == 34 or c == 92) then
		io.stdout:write("\\", dat:sub(i,i))
	elseif (escapes[c]) then
		io.stdout:write(escapes[c])
	elseif (c == 0) then
		io.stdout:write("\x00") --Safety
	elseif (c < 100) then
		io.stdout:write("\\", c)
	else
		io.stdout:write(string.format("\\x%.2x", c))
	end
end
io.stdout:write("\"\n")