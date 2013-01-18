--[[
persist.lua

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

-- Persistence modules are not new, but I think this one is pretty slick.
--
-- It can handle not just values and tree-shaped table structures, but also
-- acyclic and cyclic graphs, handling self-references, etc. no problem.
--
-- It also takes pains to restore tables in an efficient manner, filling
-- first the "array" part then the "hash" part.

-- Limitations:
-- - Because of being generic enough to handle any table-based graph,
--   doesn't output particularly beautiful constructor syntax or attractive
--   tree markup.  Still works fine, just not as pretty as human-written
--   could be.
--
-- - Functions, userdata, threads (coroutines) are not saved. (TODO: allow
--   user to provide means of serializing these?)
--
-- - Metatables are not saved. (TODO: this should be fixable, but is of
--   arguable benefit without function saving.)

local kvpairs = require "kvpairs"

local registerTable = function(t, context)
	if context.tableIdConversion[t] == nil then
		table.insert(context.tableIdConversion, t)
		context.tableIdConversion[t] = #(context.tableIdConversion)
		return true
	end
end

-- Depth-first, pre-order traversal
-- This means we can't simplify to direct in-line definitions, but it allows
-- for circular references.
local registerTablesRecursively
registerTablesRecursively = function(t, context)
	local newRegistration = registerTable(t, context)
	if newRegistration then
		for k, v in pairs(t) do
			if type(k) == "table" then registerTablesRecursively(k, context) end
			if type(v) == "table" then registerTablesRecursively(v, context) end
		end
	end
end

local universeName = "t"
local universeFormatString = universeName .. "[%d]"

local serializers = {}
serializers["nil"] = tostring
serializers["number"] = tostring
serializers["boolean"] = tostring
serializers["string"] = function(s) return ("%q"):format(s) end
serializers["table"] = function(t, context)
	return (universeFormatString):format(context.tableIdConversion[t])
end

serializers["__index"] = function(varType)
	local message = ("nil --[[%s - could not serialize]]"):format(varType)
	return function() return message end
end
setmetatable(serializers, serializers)

local simpleSerialize = function(val, context)
	return serializers[type(val)](val, context)
end

local persist = function(val)
	if type(val) ~= "table" then
		return simpleSerialize(val)
	end

	local context = {
		tableIdConversion = {}
	}
	registerTablesRecursively(val, context)
	local stringBuild = {}
	local append = function(s)
		table.insert(stringBuild, s)
	end

	-- Set up universe table
	append("do\n")
	append("local ")
	append(universeName)
	append(" = {}\n")

	-- Create each registered table in universe: can't populate them
	-- yet because the graph we're given might not be a tree, or might
	-- even be cyclic. Creating a table (an object) creates its identity.
	for tableNum = 1, #(context.tableIdConversion) do
		local t = context.tableIdConversion[tableNum]
		append(simpleSerialize(t, context))
		append(" = {}\n")
	end

	-- Populate each registered table in universe
	for tableNum = 1, #(context.tableIdConversion) do
		local t = context.tableIdConversion[tableNum]
		local tablename = simpleSerialize(t, context)
		-- for optimal memory usage, we'll output this table's elements
		-- in a specific order

		-- first the array-part in order
		for i, v in ipairs(t) do
			append(tablename)
			append("[")
			append(tostring(i))
			append("] = ")
			append(simpleSerialize(v, context))
			append("\n")
		end

		-- then the hash-part
		for k, v in kvpairs(t) do
			append(tablename)
			append("[")
			append(simpleSerialize(k, context))
			append("] = ")
			append(simpleSerialize(v, context))
			append("\n")
		end
	end

	-- now return the top level table.
	append("return ")
	append(simpleSerialize(val, context))
	append("\nend\n")
	return table.concat(stringBuild)
end

-- Simple function to somewhat-cautiously load the data.
-- Could be improved by removing access to the global environment (sandbox it)
-- but this at least will catch errors.
local restore = function(s)
	local f, err = loadstring(s, "persistString")
	if not f then return nil, err end
	local success, retval = pcall(f)
	if success then
		return retval
	else
		return nil, retval
	end
end

-- Only export these functions.
local module = {
	["persist"] = persist; -- Returns a string that, when run as Lua code (as "restore" does), returns a duplicate of the original structure.
	["restore"] = restore; -- Wrapper for loading and running a string specialized for use in assert() with a string from "persist"
}

return module
