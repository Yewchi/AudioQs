-- All code written and maintained by Yewchi
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

AUDIOQS.DELIM_NO_CONCAT = ""

local DELIMITER_FIND = "%%%%%d+"
local DELIMITER_MATCH = "(%%%%%d+)"
-- Save fast delimiter hashses
local func_string_delims = {}
AUDIOQS.MAX_FUNC_STRING_DELIMS = 64

AUDIOQS.DELIM_I_FUNCS = 1
AUDIOQS.DELIM_I_PARAMS = 2
local DELIMS_I_FUNCS = AUDIOQS.DELIM_I_FUNCS
local DELIMS_I_PARAMS = AUDIOQS.DELIM_I_PARAMS

local PROMPT_I_EXT_REF = AUDIOQS.PROMPT_I_EXT_REF

local T_NUMBER = AUDIOQS.TYPE_NUMBER
local T_STRING = AUDIOQS.TYPE_STRING
local T_BOOLEAN = AUDIOQS.TYPE_BOOLEAN
local T_FUNCTION = AUDIOQS.TYPE_FUNCTION

local DEFAULT_I_PROMPT_KEY = 1
local DEFAULT_I_PROMPT_INDEX = 2
local DEFAULT_I_SEGMENT_INDEX = 3
local DEFAULT_I_SEGMENT_VALUE_INDEX = 4 -- TODO /clap. You finally named your prompt-table layout.
local DEFAULT_I_STRING = 5
local DEFAULT_I_NEXT_DEFAULT = 6

--- Generic Segment Functions --
--
local l_saved_prompt_defaults

local ext_delimiters_info = {}

local t_segval_recyclables = {}
local function delete_segval_string(prevData, delData) -- the list is only totally iterated or removed from.
	-- why delete? It's already done?: Now that the user has reconfigured an extension, any uncompiled strings with delimiters are not in the defaults list, and we do not know 1) if it will at any time be triggered for compilation 2) that it was not in the list unless we iterate over all the segval string defaults already saved and confirm the indexing against it when it is compiled 3) that a string is not the same as any other string (we cannot make a [default string Lua hash]->&{default string metadata} reference table). Recycling the previous segval default string data means no extra checks need to be made, and a large, 4D look-up table does not need to be constructed to confirm a segment value default string was not already recorded, also the tables are recycled nicely, and we often have about exactly as many spare recycle tables ready as we would ever need for the recompilation of the now-reset string.
	if prevData then
		prevData[DEFAULT_I_NEXT_DEFAULT] = delData[DEFAULT_I_NEXT_DEFAULT]
	else
		l_saved_prompt_defaults = delData[DEFAULT_I_NEXT_DEFAULT]
	end
	local nextData = delData[DEFAULT_I_NEXT_DEFAULT]
	delData[DEFAULT_I_NEXT_DEFAULT] = false
	table.insert(t_segval_recyclables, delData)
	return prevData, nextData
end
local function save_segval_default_string(defaultString, id, pIndex, sIndex, sValueIndex) -- This requires that Prompts.lua implement help by calling AUDIOQS.SEGLIB_InformIndexDataForDefaultString(...) to inform the location of a segval default str if they ever receive result==X, needsFullIndexData==true from SEGLIB_EvaluateFunc(). Not my best work. Alternatives are redundantly communicating all indexes along with the segment table, or setting the current-working-table in the prompts system when being worked on, requestable by a function. This solution is 1 needsIndexData==false check per result basline.
	local newDefault = table.remove(t_segval_recyclables) or {}
	-- Copy indices for this string from the prompts.lua working table
	local currIndices = current_working_indices
	newDefault[1], newDefault[2], 
	newDefault[3], newDefault[4] = 
			id, pIndex, sIndex, sValueIndex
	newDefault[DEFAULT_I_STRING] = defaultString

	if l_saved_prompt_defaults then
		local prevFirst = l_saved_prompt_defaults
		newDefault[DEFAULT_I_NEXT_DEFAULT] = prevFirst
	end
	l_saved_prompt_defaults = newDefault
end

local function replace_delimiters(funcString, delimiterInfo) -- Called once-per-session, and configuration change for an extension.
	local delimStart, delimEnd
	local tblSize = 0
	local newStrTbl = {} -- on string creation benching, table concat ~238ms, string format ~266ms on 100000 iterations (editing the first 33 letters of a per-chance 128 char string, random rotational lower-case decrement forcing a new string to always be created after splitting and subbing the decremented letter)
	local workingIndex = 1
	local delimFuncs = delimiterInfo[DELIMS_I_FUNCS]
	local delimParams = delimiterInfo[DELIMS_I_PARAMS]
	
	while(1) do
		delimStart, delimEnd = string.find(funcString, DELIMITER_FIND, workingIndex)
		if delimStart == nil then break; end
		local delim = funcString:match(DELIMITER_MATCH, delimStart) -- Note this second str search is necc. because we also need to know where it is.
		tblSize = tblSize + 1
		newStrTbl[tblSize] = funcString:sub(workingIndex, delimStart-1)
		tblSize = tblSize + 1
		local delimResult = delimFuncs[delim](delimParams[delim])
		local delimType = type(delimResult)
		if delimType ~= "string" then
			return delimResult, delimType-- The segment conditional will be set to the boolean (often, kill prompt with false start, true stop)
		end
		newStrTbl[tblSize] = delimResult
		workingIndex = delimEnd+1
	end
	newStrTbl[tblSize+1] = funcString:sub(workingIndex)
	return table.concat(newStrTbl), "string" -- .'. we are loading and storing the func string
	-- approx. 1/40th of a mili-second for 1 delim
end

function AUDIOQS.SEGLIB_ReloadExtDefaults(extRef)
	local prevDefaultSaved
	local thisDefaultSaved = l_saved_prompt_defaults
	local prompts = AUDIOQS.GSI_GetPromptsTable()
	while(thisDefaultSaved) do
		local thisPrompt = prompts[thisDefaultSaved[1]] [thisDefaultSaved[2]]
		-- if thisPrompt == nil then
			-- print(thisDefaultSaved[1], thisDefaultSaved[2], thisDefaultSaved[3], thisDefaultSaved[4], thisDefaultSaved[5], thisDefaultSaved[6])
		-- end
		if thisPrompt[PROMPT_I_EXT_REF] == extRef then
			thisPrompt[thisDefaultSaved[3]] [thisDefaultSaved[4]] = thisDefaultSaved[DEFAULT_I_STRING]
			prevDefaultSaved, thisDefaultSaved = delete_segval_string(prevDefaultSaved, thisDefaultSaved)
		else
			prevDefaultSaved = thisDefaultSaved
			thisDefaultSaved = thisDefaultSaved[DEFAULT_I_NEXT_DEFAULT]
		end
	end
end

function AUDIOQS.SEGLIB_InformWorkingDataRef(currIndices)
	current_working_indices = currIndices
	AUDIOQS.SEGLIB_InformWorkingDataRef = nil
end

function AUDIOQS.SEGLIB_GENERIC_SPELL_COOLDOWN(spellId) 
	return AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_EXPIRATION] > 0
end
function AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN(spellId)
	if AUDIOQS.ChargeCooldownsAllowed ~= nil and AUDIOQS.ChargeCooldownsAllowed then 
		local charges = GetSpellCharges(spellId)
		-- TODO snapshotSpellExpiration - GetTime() > 0 (the "- GetTime()"part) was a hotfix for extremely low ICD spells, like shimmer (imperceptibly small ICD). Not thoroughly tested.
		return ( AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_EXPIRATION]-GetTime() > 0 )
				or ( charges ~= nil and charges > AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_CHARGES] ) 
	end 
	return false
end

---- Generators
function AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT(shortFilePath) -- CAPITOLS_UNDERSCORED are incorrectly used (unlike above, which, when designing prompts, may be imagined as flags, even though they are not), but much easier to mentally process when scrolling down a list of spells which, e.g. as here, may or may not have charges
	return 
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_COOLDOWN,
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT..shortFilePath,		nil,	true }
		}
end

function AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_CHARGES_COOLDOWN_SEGMENT(shortFilePath)
	return 
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN,
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT..shortFilePath,		nil,	true }
		}
end
--
-- /Generic Segment Functions --

local function FunctionEval(extRef, id, cond)
	local f
	local neededLoad
	local resultType
	if type(cond) == "string" then
		neededLoad = true
		local delimiter_info = ext_delimiters_info[extRef]
		if delimiter_info then
			cond, resultType = replace_delimiters(cond, delimiter_info)
			if resultType ~= "string" then
				return cond, cond -- return the now-static segment value (It no longer needs to be evaluated, nor called)
			end
		end
		f = loadstring(cond)
	elseif type(cond) == "function" then
		neededLoad = false
		f = cond
	end
	local success, result = pcall(f, id)
	if not success then
if AUDIOQS.VERBOSE then print("Error in conditional string: '", (type(cond) == "string" and cond or result), "'") end 
		AUDIOQS.LogError({code=AUDIOQS.ERR_CUSTOM_FUNCTION_RUNTIME}, "FunctionEval()", "", (type(cond) == "string" and cond or result) )
		result = nil
	end
	
	if neededLoad then
		return result, f
	else
		return result
	end
end

-------- AUDIOQS.SEGLIB_EvaluateLength()
function AUDIOQS.SEGLIB_EvaluateLength(id, pIndex, sIndex, sValueIndex, prompt)
	if prompt == nil or sValueIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func=string.format("AUDIOQS.GSI_EvaluateLength(id=%s, pIndex=%s, sIndex=%s, sValueIndex=%s, prompt=%s)", AUDIOQS.Printable(id), AUDIOQS.Printable(pIndex), AUDIOQS.Printable(sIndex), AUDIOQS.Printable(sValueIndex), AUDIOQS.Printable(prompt))})
	end
	
	local segment = prompt[sIndex]
	local length = segment[sValueIndex]
	
	local t = type(length)
	if t == "function" then
		local eval = FunctionEval(prompt[PROMPT_I_EXT_REF], id, length)
		return (eval ~= nil and eval or 0.0)
	elseif t == "number" then
		return length
	elseif t == "string" then
		local eval, newSegmentValue = FunctionEval(prompt[PROMPT_I_EXT_REF], id, length)
		segment[sValueIndex] = newSegmentValue
		if newSegmentValue ~= nil then -- it may be a valid false
			save_segval_default_string(length, id, pIndex, sIndex, sValueIndex)
		end
		if type(eval) == "number" then
			return eval
		else
			return 0.0
		end
	elseif t == "nil" then
		return 0.0
	else
		error({code=AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT, func=string.format("AUDIOQS.GSI_EvaluateLength(id=%s, pIndex=%s, sIndex=%s, sValueIndex=%s, prompt=%s)", AUDIOQS.Printable(id), AUDIOQS.Printable(pIndex), AUDIOQS.Printable(sIndex), AUDIOQS.Printable(sValueIndex), AUDIOQS.Printable(prompt))})
	end
end

-------- AUDIOQS.SEGLIB_EvaluateSound()
function AUDIOQS.SEGLIB_EvaluateSound(id, pIndex, sIndex, sValueIndex, prompt)
	if prompt == nil or sValueIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func=string.format("AUDIOQS.GSI_EvaluateSound(id=%s, pIndex=%s, sIndex=%s, sValueIndex=%s, prompt=%s)", AUDIOQS.Printable(id), AUDIOQS.Printable(pIndex), AUDIOQS.Printable(sIndex), AUDIOQS.Printable(sValueIndex), AUDIOQS.Printable(prompt))})
	end

	local segment = prompt[sIndex]
	local sound = segment[sValueIndex]

	local t = type(sound)
	if t == "function" then
		return FunctionEval(prompt[PROMPT_I_EXT_REF], id, sound)
	elseif t == "number" then
		return sound
	elseif t == "string" then 
		local split = AUDIOQS.SplitString(sound, "::")
		if #split == 1 then
			return sound
		elseif #split == 2 then
			local afterDirectiveStr = split[2]
			if split[1] == AUDIOQS.SOUND_PATH and afterDirectiveStr ~= nil then
				return afterDirectiveStr
			elseif split[1] == AUDIOQS.SOUND_FUNC and afterDirectiveStr ~= nil then
				local eval, newSegmentValue = FunctionEval(prompt[PROMPT_I_EXT_REF], id, afterDirectiveStr)
				segment[sValueIndex] = newSegmentValue
				if newSegmentValue ~= nil then -- it may be a valid false
					save_segval_default_string(sound, id, pIndex, sIndex, sValueIndex)
				end
				return eval
			end
		end
	end
	return nil
end

-------- AUDIOQS.SEGLIB_EvaluateConditional()
function AUDIOQS.SEGLIB_EvaluateConditional(id, pIndex, sIndex, sValueIndex, prompt)
	if prompt == nil or sValueIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func=string.format("AUDIOQS.GSI_EvaluateConditional(id=%s, pIndex=%s, sIndex=%s, sValueIndex=%s, prompt=%s)", AUDIOQS.Printable(id), AUDIOQS.Printable(pIndex), AUDIOQS.Printable(sIndex), AUDIOQS.Printable(sValueIndex), AUDIOQS.Printable(prompt))})
	end
	
	-- if type(prompt) == "number" then print("eval cond", id, pIndex, sIndex, sValueIndex, prompt) end

	local segment = prompt[sIndex]
	local conditional = segment[sValueIndex]

	if type(conditional) == "function" then 
		return FunctionEval(prompt[PROMPT_I_EXT_REF], id, conditional)
	elseif type(conditional) == "string" then
		local eval, newSegmentValue = FunctionEval(prompt[PROMPT_I_EXT_REF], id, conditional)
		segment[sValueIndex] = newSegmentValue
		if newSegmentValue ~= nil then -- it may be a valid false
			save_segval_default_string(conditional, id, pIndex, sIndex, sValueIndex)
		end
		return eval
	end
	return conditional == true
end

-------- AUDIOQS.SEGLIB_LoadDelims()
function AUDIOQS.SEGLIB_LoadDelims(extRef, getDelimsInfo)
	if getDelimsInfo then
		ext_delimiters_info[extRef] = getDelimsInfo()
	else
		ext_delimiters_info[extRef] = false -- optimize to array
	end
	if func_string_delims[1] then
		return
	end
	-- save all delimiters into a stored table to avoid colour changes / collect and remake
	for i=1,AUDIOQS.MAX_FUNC_STRING_DELIMS do
		func_string_delims[i] = string.format("%%%%%d", i) -- "%%1", ..., "%%64"
	end
end