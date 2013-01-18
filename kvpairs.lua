--[[
kvpairs.lua

Written in 2013 by Ryan Pavlik <rpavlik@iastate.edu> <abiryan@ryand.net> <http://academic.cleardefinition.com>

Copyright 2013 Iowa State University, Virtual Reality Applications Center

License: MIT (same as Lua itself)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]

-- kvpairs is the counterpart to ipairs: it iterates over those key, value
-- pairs that ipairs does not iterate over. (Essentially, it does the "named"
-- values, or the "hash-part" of the table: the elements iterated by pairs
-- excluding those iterated by ipairs)
-- Looping with ipairs, then with kvpairs, you'll get the "array-part" in
-- integer order, then the "hash-part" in undefined order (but same as you'd
-- get with just pairs)

-- This function is to kvpairs as "next" is to pairs. Not sure whether
-- this should be exported: I hadn't used next before, but some might,
-- so this might be handy.
local nextNamed = function(t, k)
	local k = k
	local v
	repeat
		k, v = next(t, k)
	until
		k == nil --[[end of table]]
		or type(k) ~= "number" --[[found a non-number key]]
		or k < 1 --[[below array start at 1]]
		or k > #t --[[above array end]]
		or math.floor(k) ~= k --[[key is a number but not an integer - easy case to forget!]]
	return k, v
end

-- This is the actual iterator factory - works just like pairs is described in PIL:
-- http://www.lua.org/pil/7.3.html
-- Stateless iterator, so not creating a closure, etc.
local kvpairs = function(t)
	return nextNamed, t, nil
end

return kvpairs

