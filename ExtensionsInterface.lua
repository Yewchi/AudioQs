-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ All extensions must register themselves with RegisterExtension(name, funcs)

local extensionFuncs = {}

function AUDIOQS.RegisterExtension(extName, funcs)
	if type(extName) ~= "string" or type(funcs) ~= "table" then
		AUDIOQS.HandleError({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.RegisterExtension(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
		return
	end
	
	extensionFuncs[extName:lower()] = funcs
end

function AUDIOQS.GetExtensionFuncs(extName)
	if extName == nil then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."nil passed as extension name to GetExtensionFuncs()") end
		return nil
	end
	
	local extNameToLower = extName:lower()
	
	if extensionFuncs[extNameToLower] == nil then
		return nil
	end
	return extensionFuncs[extNameToLower]
end

function AUDIOQS.GetRegisteredExtensionNames()
	local name_arr = {}
	local i = 1
	for extName,_ in pairs(extensionFuncs) do
		name_arr[i] = extName
		i = i + 1
	end
	return name_arr
end

function AUDIOQS.SpecAllowed(specToCheck, specsAllowed)
end
