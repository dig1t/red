--[[
@name dLib
@author dig1t
]]

local Util = require(script.Util)

local loadedModules = {
	Util = Util -- We already required the Util module
}

local function import(path)
	assert(typeof(path) == 'string', 'dLib.import - Path is not a string')

	-- Return module if it was already used
	if loadedModules[path] then
		return loadedModules[path]
	end

	local modulePath = Util.treePath(script, path, '/')

	assert(modulePath, 'dLib.import - Missing module ' .. path)
	--[[assert(
		modulePath:IsA('ModuleScript'),
		string.format('dLib.import - %s is not a ModuleScript instance', path)
	)]]

	if modulePath and modulePath:IsA('ModuleScript') then
		local success, res = pcall(function()
			return require(modulePath)
		end)

		if not success then
			error('dLib.import - ' .. res)
		end

		loadedModules[path] = res

		return res
	end
end

return {
	import = import
}