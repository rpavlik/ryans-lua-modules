#!/usr/bin/env lua

local kvpairs = require "kvpairs"

data = {
	"hats",
	"elephants",
	5,
	abc = 123,
	cat = "hat",
	"more hats",
	[-1] = 10,
	[2.5] = "noninteger"
}

print "ipairs:"

for i, v in ipairs(data) do
	print("-", i, v)
end

print "kvpairs:"

for k, v in kvpairs(data) do
	print("-", k, v)
end
