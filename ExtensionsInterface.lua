-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ All extensions must register themselves with RegisterExtension(name, funcs)

local extensionFuncs = {}
local shortNameExtensionFuncs = {} -- Store a table ref, instead of a (slow) string
local requiredFuncNames = {
	"GetName",
	"GetNameDetailed",
	"GetShortNames",
	"GetVersion",
	"GetSpells",
	"GetEvents",
	"GetSegments",
	"GetExtension",
	"SpecAllowed"
}

local function ExtensionBasicRequirementsMet(extName, funcs)
	for _,funcName in pairs(requiredFuncNames) do
		if type(funcs[funcName]) ~= "function" then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Required function \""..funcName.."()\" missing in function table passed to ExtensionsInterface for \""..extName.."\".") end
			AUDIOQS.HandleError({code=AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS, func="AUDIOQS.ExtensionBasicRequirementsMet(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
			return false
		end
	end
	
	local segments = funcs["GetSegments"]()
	local spells = funcs["GetSpells"]()
	local events = funcs["GetEvents"]()
	for k,_ in pairs(segments) do
		if not (spells[k] or events[k]) then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Segment key "..(type(k) == "number" and "#"..k or "\""..k.."\"").." does not have a corresponding spell/event table entry for extension \""..extName.."\"") end
			AUDIOQS.HandleError({code=AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS, func="AUDIOQS.ExtensionBasicRequirementsMet(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
			return false
		end
	end
	
	return true
end

function AUDIOQS.RegisterExtension(extName, funcs)
	if type(extName) ~= "string" or type(funcs) ~= "table" then
		AUDIOQS.HandleError({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.RegisterExtension(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
		return
	end
	
	if not ExtensionBasicRequirementsMet(extName, funcs) then
		return nil
	end
	
	extensionFuncs[extName:lower()] = funcs
	
	local shortNames = funcs["GetShortNames"]()
	for substr in shortNames:gmatch("[%a]+") do
		shortNameExtensionFuncs[substr] = funcs
	end
end

function AUDIOQS.GetExtensionFuncs(extNameSearch)
	if extNameSearch == nil then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."nil passed as extension name to GetExtensionFuncs()") end
		return nil
	end
	
	local extNameSearchToLower = extNameSearch:lower()
	return extensionFuncs[extNameSearch:lower()] or shortNameExtensionFuncs[extNameSearch:lower()]
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
