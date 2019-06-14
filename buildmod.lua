#!/usr/bin/env lua

local sigstore = io.open(arg[1].."/sigstore.bin", "wb")
local lines = {}
local dir = io.popen("cd "..arg[1].."; find * -depth", "r")
for line in dir:lines() do
	sigstore:write(string.char(#line)..line)
	local ossl = io.popen("openssl dgst -sha256 -sign "..arg[2].." "..line, "r")
end