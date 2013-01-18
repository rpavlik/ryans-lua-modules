#!/usr/bin/env lua
local p = require "persist"

-- Some complicated data - note the mix of "array" and "key-value" stuff
local testData = {
	data = {
		"hats",
		"elephants",
		5,
		abc = 123,
		cat = "hat",
		"more hats",
		[-1] = 10
	}
}

-- Make it more complicated: indirect self-reference (cycle of 2)
testData.data["recurse"] = testData

-- Make it even more complicated: direct self-reference (cycle of 1)
testData.reallyrecurse = testData

-- Serialize/persist to string
local testString = p.persist(testData)
print(testString)
print("--------------")

-- restore will return nil and the error if there's a problem, so this
-- works perfectly with this assert pattern.
local restored = assert(p.restore(testString))

-- Now print it serialized again. Not necessarily identical, due to unspecified
-- order of iteration through key-value pairs, but must be equivalent, and
-- typically is equal.
print(p.persist(restored))


print("-------------- Now Minified:")
-- Same thing, but minified
do
	local testString = p.persist(testData, {minified=true})
	print(testString)
	print("--------------")
	local restored = assert(p.restore(testString))

	-- Show non-minified output from round trip.
	print(p.persist(restored))
end
