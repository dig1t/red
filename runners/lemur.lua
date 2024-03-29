--!nocheck

-- This makes sure we can load Lemur and other libraries that depend on init.lua
package.path = package.path .. ";?/init.lua"

-- If this fails, make sure you've cloned all Git submodules of this repo!
local lemur = require("modules.lemur")

-- Create a virtual Roblox tree
local habitat = lemur.Habitat.new()

-- We'll put all of our library code and dependencies here
local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

local packages = lemur.Instance.new("Folder")
packages.Name = "Packages"
packages.Parent = ReplicatedStorage

local LOAD_MODULES = {
	-- we run lua5.1/lemur post-darklua with Luau types stripped
	{"src", "red", packages},
	{"modules/testez/src", "TestEZ", ReplicatedStorage}
}

-- Load all of the modules specified above
for _, module in ipairs(LOAD_MODULES) do
	local container = habitat:loadFromFs(module[1])
	container.Name = module[2]
	container.Parent = module[3]
end

-- When Lemur implements a proper scheduling interface, we'll use that instead.
local runTests = habitat:loadFromFs("runners/test.lua")
habitat:require(runTests)
