-- All code written and maintained by Yewchi
-- zyewchi@gmail.com

--- Generic Segment Functions --
--
function AUDIOQS.SEGLIB_GENERIC_SPELL_COOLDOWN(spellId) 
	return AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_EXPIRATION] > 0
end

function AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN(spellId)
	if AUDIOQS.ChargeCooldownsAllowed ~= nil and AUDIOQS.ChargeCooldownsAllowed then 
		local charges = GetSpellCharges(spellId) 
		
		return ( AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_EXPIRATION] > 0 ) 
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

local function FunctionEval(id, cond)
	local f
	local neededLoad
	if type(cond) == "string" then
		neededLoad = true
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
function AUDIOQS.SEGLIB_EvaluateLength(id, prompt, promptIndex)
	if prompt == nil or promptIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateSound(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local length = prompt[promptIndex]
	
	local t = type(length)
	if t == "function" then
		local eval = FunctionEval(id, length)
		return (eval ~= nil and eval or 0.0)
	elseif t == "number" then
		return length
	elseif t == "string" then
		local eval, func = FunctionEval(id, length)
		prompt[promptIndex] = func 
		if type(eval) == "number" then
			return eval
		else
			return 0.0
		end
	elseif t == "nil" then
		return 0.0
	else
		error({code=AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT, func="GSI_EvaluateLength(length = "..(length == nil and "nil" or length).." type:"..type(length)..")"})
	end
end

-------- AUDIOQS.SEGLIB_EvaluateSound()
function AUDIOQS.SEGLIB_EvaluateSound(id, prompt, promptIndex) -- TODO Memoize soundPaths[(sounds_root_cut)"folder/folder/.../filename"(extension cut)] = "full/file/path.ogg"
	if prompt == nil or promptIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateSound(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local sound = prompt[promptIndex]

	local t = type(sound)
	if t == "function" then
		return FunctionEval(id, sound)
	elseif t == "number" then
		return sound
	elseif t == "string" then 
		local split = AUDIOQS.SplitString(sound, "::")
		if #split == 1 then
			return sound
		elseif #split == 2 then		
			if split[1] == AUDIOQS.SOUND_PATH and split[2] ~= nil then
				return split[2]
			elseif split[1] == AUDIOQS.SOUND_FUNC and split[2] ~= nil then
				local eval, func = FunctionEval(id, split[2])
				prompt[promptIndex] = func 
				return eval
			end
		end
	end
	return nil
end

-------- AUDIOQS.SEGLIB_EvaluateConditional()
function AUDIOQS.SEGLIB_EvaluateConditional(id, prompt, promptIndex)
	if prompt == nil or promptIndex == nil then
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateConditional(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local conditional = prompt[promptIndex]

	if type(conditional) == "function" then 
		return FunctionEval(id, conditional)
	elseif type(conditional) == "string" then
		local eval, func = FunctionEval(id, conditional)
		prompt[promptIndex] = func
		return eval
	end
	return conditional == true
end