-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ All extensions must register themselves with RegisterExtension(name, funcs)

local AUDIOQS = AUDIOQS_4Q5

local number_extensions_registered = 0

local t_ext_funcs = {}
local t_ext_name_to_ref = {}
local required_func_names = {
	"GetName",
	"GetNameDetailed",
	"GetShortNames",
	"GetVersion",
	"GetSpells",
	"GetEvents",
	"GetPrompts",
	"GetExtension",
	"SpecAllowed"
}

local function ExtensionBasicRequirementsMet(extName, extRef, funcs)
	for _,funcName in pairs(required_func_names) do
		if type(funcs[funcName]) ~= "function" then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Required function \""..funcName.."()\" missing in function table passed to ExtensionsInterface for \""..extName.."\".") end
			AUDIOQS.HandleError({code=AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS, func="AUDIOQS.ExtensionBasicRequirementsMet(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
			return false
		end
	end
	
	local prompts = funcs["GetPrompts"]()
	local spells = funcs["GetSpells"]()
	local events = funcs["GetEvents"]()
	for k,_ in pairs(prompts) do
		if not spells or not events or not (spells[k] or events[k]) then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Segment key "..(type(k) == "number" and "#"..k or "\""..k.."\"").." does not have a corresponding spell/event table entry for extension \""..extName.."\"") end
			AUDIOQS.HandleError({code=AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS, func="AUDIOQS.ExtensionBasicRequirementsMet(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
			return false
		end
	end
	
	AUDIOQS.SEGLIB_LoadDelims(extRef, funcs["GetDelimInfo"])
	
	return true
end

function AUDIOQS.RegisterExtension(extName, funcs)
	local thisExtReferenceNumber = number_extensions_registered + 1
	if type(extName) ~= "string" or type(funcs) ~= "table" then
		AUDIOQS.HandleError({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.RegisterExtension(extName = "..(extName == nil and "nil" or extName)..", funcs = t_"..type(funcs)..")"})
		return
	end
	
	if not ExtensionBasicRequirementsMet(extName, thisExtReferenceNumber, funcs) then
		return nil
	end
	local shortNames = funcs["GetShortNames"]()
	
	t_ext_funcs[thisExtReferenceNumber] = funcs
	
	for substr in shortNames:gmatch("[%a]+") do
		t_ext_name_to_ref[substr] = thisExtReferenceNumber
	end
	t_ext_name_to_ref[extName:lower()] = thisExtReferenceNumber
	number_extensions_registered = thisExtReferenceNumber
	return thisExtReferenceNumber
end

function AUDIOQS.GetNumberRegisteredExtensions()
	return numerical_extension_reference
end

function AUDIOQS.GetExtensionNameFuncs(extNameSearch)
	if type(extNameSearch) ~= "string" then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."invalid extension name passed to GetExtensionNameFuncs(extNameSearch="..AUDIOQS.Printable(extNameSearch)..")") end
		return nil
	end

	return t_ext_funcs[t_ext_name_to_ref[extNameSearch:lower()]]
end

function AUDIOQS.EXT_GetDelimInfoForReference(extRefNum)
	local extFuncs = t_ext_funcs[extRefNum]
	return extFuncs and extFuncs["GetDelimFuncInfo"]
end

function AUDIOQS.GetRegisteredExtensionNames()
	local nameArray = {}
	local i = 1
	for i=1,#t_ext_funcs do
		nameArray[i] = t_ext_funcs[i]["GetName"]()
		i = i + 1
	end
	return nameArray
end

function AUDIOQS.SpecAllowed(specToCheck, specsAllowed)
end