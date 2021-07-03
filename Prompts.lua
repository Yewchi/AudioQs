-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Table generation; PromptTicker and segment interpretation

local AUDIOQS = AUDIOQS_4Q5

--- Initialization --
--

------- Flags --
--
AUDIOQS.PROMPT_STAGE_OFF = 							0x0

AUDIOQS.PROMPTSEG_CONDITIONAL_USE_PREVIOUS =		0xFFF0
AUDIOQS.PROMPTSEG_CONDITIONAL_USE_STOP =			0xFFF1
AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION =		0xFFF2
AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER =			0xFFF3
AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART =				0xFFF4

AUDIOQS.PROMPTSEG_SOUND_STOP =						0xEFF0

AUDIOQS.STOP_SOUND_DISALLOWED =						false
--
------ /Flags --


------- Table key Reference --
--
AUDIOQS.PROMPT_I_EXT_REF = 0 -- fast-easy extRef look-up, prompt array still operates at array speeds
local PROMPT_I_EXT_REF = AUDIOQS.PROMPT_I_EXT_REF

local SEGT_CONDITIONALS =	1
local SEGT_FIRST = 2
local SEGT_CONDITIONALS_START = 1
local SEGT_CONDITIONALS_STOP = 2

local PROMPT_TIMESTAMP = 1
local PROMPT_CURR_STAGE = 2
local PROMPT_SEGMENT_KEY = 3
local PROMPT_SEGMENT_TABLE_INDEX = 4
local PROMPT_NEXT_PROMPT_TRACKED = 5
local PROMPT_PREV_PROMPT_TRACKED = 6

local PROMPTSEG_LENGTH = 1
local PROMPTSEG_SOUND = 2
local PROMPTSEG_HANDLE = 3
local PROMPTSEG_CONDITIONAL = 4
--
------ /Table key Reference --

------- Static vals --
--
local VALID_AUDIO_CHANNELS_LIST = {
		"MASTER",
		"SFX",
		"MUSIC",
		"AMBIENCE",
		"DIALOG",
		"TALKING HEAD"
	}

local VALID_AUDIO_CHANNELS = {} -- {["MASTER"] = "MASTER, ["SFX"] = "SFX", ...}

local TICKER_SKIP_FRAMES = 3 -- TODO Cheap optimisation, should be evaluates n = [1,2,3]; n = n+3 of prompts per frame.
--
------ /Static vals --

------- Module variables --
local AUDIO_CHANNEL = "DIALOG"
--
local prompts = {}

local spellsLookUp = {} -- [spellId]

local unitsIncluded = {}

local promptStates = {}
local segmentPromptIndex = {}

local registered_prompt -- Prompts are registered when they're being checked in the prompt ticker, allows for extensions to edit their own prompt data.

local Frame_PromptTicker = CreateFrame("Frame", "AUDIOQS_FRAME_PROMPT_TICKER")

local configuration_changed_ext_refs = {} -- Must be an array incase many extensions are effected / the user is going ham or used a configuration macro.
local batch_job_current_index = 0 -- where the batch is up to
local batch_job_ends_index = 0 -- the index to finish the batch after a full circuit.
local MAX_BATCH_PROCESS_PER_FRAME = 16
local Frame_SetDefaultFuncStringsBatch = CreateFrame("Frame", "AUDIOQS_FRAME_DEFAULT_FSTR_BATCH")

local check_prompt_ticker_state = false
--
------ /Module variables --
--

local EVAL_LENGTH
local EVAL_SOUND
local EVAL_COND

local HUSHMODE_OFF = AUDIOQS.HUSHMODE_OFF

local PROMPT_STAGE_OFF = AUDIOQS.PROMPT_STAGE_OFF

local PROMPTSEG_CONDITIONAL_USE_PREVIOUS = AUDIOQS.PROMPTSEG_CONDITIONAL_USE_PREVIOUS
local PROMPTSEG_CONDITIONAL_USE_STOP = AUDIOQS.PROMPTSEG_CONDITIONAL_USE_STOP
local PROMPTSEG_CONDITIONAL_CONTINUATION = AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
local PROMPTSEG_CONDITIONAL_REPEATER = AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
local PROMPTSEG_CONDITIONAL_RESTART = AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART

local PROMPTSEG_SOUND_STOP = PROMPTSEG_SOUND_STOP

local STOP_SOUND_DISALLOWED = STOP_SOUND_DISALLOWED

local type = type
-- /Initialization --

--- Funcs --
--
local AttemptStartPrompts
local PromptTicker

local l_prompts_tracked
local function l_insert_active_prompt(promptState)
	if promptState[PROMPT_NEXT_PROMPT_TRACKED] or promptState[PROMPT_PREV_PROMPT_TRACKED] then
		-- Assert clean, not-inserted but now-active promptState
		error({code=AUDIOQS.ERR_UNKNOWN, func="l_insert_active_prompt() attempted to re-insert."})
	end
	if l_prompts_tracked == nil then
		l_prompts_tracked = promptState
		promptState[PROMPT_NEXT_PROMPT_TRACKED] = nil
		promptState[PROMPT_PREV_PROMPT_TRACKED] = nil
	else
		l_prompts_tracked[PROMPT_PREV_PROMPT_TRACKED] = promptState
		promptState[PROMPT_NEXT_PROMPT_TRACKED] = l_prompts_tracked
		l_prompts_tracked = promptState
	end
	checkPromptTickerState = true
end
local function l_remove_inactive_prompt(promptState)
	local nextPromptState = promptState[PROMPT_NEXT_PROMPT_TRACKED]
	local prevPromptState = promptState[PROMPT_PREV_PROMPT_TRACKED]
	promptState[PROMPT_NEXT_PROMPT_TRACKED] = nil
	promptState[PROMPT_PREV_PROMPT_TRACKED] = nil
	if nextPromptState then
		nextPromptState[PROMPT_PREV_PROMPT_TRACKED] = prevPromptState
		if prevPromptState then
			prevPromptState[PROMPT_NEXT_PROMPT_TRACKED] = nextPromptState
		else
			l_prompts_tracked = nextPromptState
		end
	elseif prevPromptState then -- but no nextPromptState
		prevPromptState[PROMPT_NEXT_PROMPT_TRACKED] = nil
	else
		l_prompts_tracked = nil
	end
	checkPromptTickerState = true
end

-------------- GenerateTablesAndIndices()
local function GenerateTablesAndIndices()
	local spells = AUDIOQS.GSI_GetSpellsTable()
	local abilityTable = {}
	local auraTable = {}
	
	do
		local i = 1
		local j = 1
		for spellId,spell in pairs(spells) do
			-- spellsLookUp
			spellsLookUp[spell[AUDIOQS.SPELL_SPELL_NAME]] = spellId

			local previousAbilitySpellId = (#abilityTable > 0 and abilityTable[i-1] or nil)
			local previousAuraSpellId = (#auraTable > 0 and auraTable[j-1] or nil)
			if spell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_ABILITY and previousAbilitySpellId ~= spellId then -- abilityTable
				abilityTable[i] = spellId
				i = i + 1
			elseif spell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_AURA and previousAuraSpellId ~= spellId then -- auraTable
				auraTable[j] = spellId
				j = j + 1
			end
		end
	end
	-- Create the promptStates (metadata about prompt running states), and create the segmentPromptIndex (a reference table for a 
	--- prompt key (spellId or event) and array-index-prompt (often 1 of them) to the corresponding index of metadata in the promptStates)
	do
		local i = 1
		for k,array in pairs(prompts) do
			segmentPromptIndex[k] = {}
			for n=1,#array,1 do
				if #array[n] >= SEGT_FIRST then -- Is this a true set of segments for a prompt? Not an initialization function?
					-- promptStates
					promptStates[i] = {	0, AUDIOQS.PROMPT_STAGE_OFF, k, n } -- PROMPT_TIMESTAMP, PROMPT_CURR_STAGE, PROMPT_SEGMENT_KEY, PROMPT_SEGMENT_TABLE_INDEX
					-- segmentPromptIndex
					segmentPromptIndex[k][n] = i
					i = i + 1
				end
			end
		end
	end
	-- unitsIncluded
	for n=1,#promptStates,1 do
		local thisSegmentKey = promptStates[n][PROMPT_SEGMENT_KEY]
		local thisSegmentArrayIndex = promptStates[n][PROMPT_SEGMENT_TABLE_INDEX]
		if thisSegmentArrayIndex == 1 then
			if type(thisSegmentKey) == "number" then
				local thisUnit = spells[thisSegmentKey][AUDIOQS.SPELL_UNIT_ID]
				if thisUnit ~= nil then
					if #unitsIncluded == 0 then
						unitsIncluded[#unitsIncluded+1] = thisUnit
					else
						local insert = true
						for j=1,#unitsIncluded,1 do
							if unitsIncluded[j] == thisUnit then
								insert = false
								break
							end
						end
						if insert then
							unitsIncluded[#unitsIncluded+1] = thisUnit
						end
					end
				end
			end
		end
	end
	
	return abilityTable, auraTable
end

-- Needs confirmation, error thrown on missing file
-------------- PlaySoundGetHandle()
local function PlaySoundGetHandle(id, pIndex, sIndex, prompt)
	if AUDIOQS.hushMode ~= HUSHMODE_OFF or prompt == nil then
		return nil
	end

	local eval = EVAL_SOUND(id, pIndex, sIndex, PROMPTSEG_SOUND, prompt)
	
	if eval == nil then
		return nil
	end
	
	if type(eval) == "number" then
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Playing \""..eval.."\"") end
		return select(2, PlaySound(eval, AUDIO_CHANNEL))
	elseif type(eval) == "string" then
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Playing \""..eval.."\"") end
		return select(2, PlaySoundFile(eval, AUDIO_CHANNEL))
	end
	error({code=AUDIOQS.ERR_INVALID_SOUND_DATA, func=string.format("PlaySoundGetHandle(id=%s, pIndex=%s, sIndex=%s, prompt=%s)", AUDIOQS.Printable(id), AUDIOQS.Printable(pIndex), AUDIOQS.Printable(sIndex), AUDIOQS.Printable(prompt))})
end

-------------- StopAllSegmentsSounds()
local function StopAllSegmentsSounds(prompt)
	for sIndex=SEGT_FIRST,#prompt,1 do
		local soundHandle = prompt[sIndex][PROMPTSEG_HANDLE]
		if type(soundHandle) == "number" then
			StopSound(soundHandle)
			prompt[sIndex][PROMPTSEG_HANDLE] = nil
		end
	end
end

-------------- SetSegmentSoundHandle()
local function SetSegmentSoundHandle(segment, handle)
	if segment[PROMPTSEG_HANDLE] ~= STOP_SOUND_DISALLOWED then
		segment[PROMPTSEG_HANDLE] = handle
	end
end
-------------- CheckStopSegments()
local function CheckStopSegments(id, pIndex, promptState, prompt, allowContinuationOfPlay, forceStop)
	if promptState[PROMPT_CURR_STAGE] < SEGT_FIRST then -- Is it currently off?
		return false
	end
	if EVAL_COND(id, pIndex, SEGT_CONDITIONALS, SEGT_CONDITIONALS_STOP, prompt) or forceStop == true then
		if allowContinuationOfPlay == false then
			StopAllSegmentsSounds(prompt)
		end
		promptState[PROMPT_TIMESTAMP] = 0
		promptState[PROMPT_CURR_STAGE] = AUDIOQS.PROMPT_STAGE_OFF
		l_remove_inactive_prompt(promptState)
		check_prompt_ticker_state = true
		return true
	end
	return false
end

-------------- GetNextTrueSegment()
local function GetNextTrueSegment(id, pIndex, prompt, nextPromptStage)
	if nextPromptStage > #prompt and nextPromptStage > SEGT_FIRST then
		if prompt[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == PROMPTSEG_CONDITIONAL_REPEATER then
			return nextPromptStage-1 -- Go back, repeat previous (probably until stop conditional is met)
		elseif prompt[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == PROMPTSEG_CONDITIONAL_RESTART then
			return SEGT_FIRST -- Restart the prompts from Prompt 1
		end
		return PROMPT_STAGE_OFF
	end
	
	local skippingFalseConditionalSet = false
	for sI=nextPromptStage,#prompt,1 do -- Search downards for true conditionals
		local conditional = prompt[sI][PROMPTSEG_CONDITIONAL]
		if type(conditional) == "string" then
			if EVAL_COND(id, pIndex, sI, PROMPTSEG_CONDITIONAL, prompt) then
				return sI
			end
			skippingFalseConditionalSet = true
		elseif conditional == PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
			if skippingFalseConditionalSet == false then
				for backSearchI=sI-1,SEGT_FIRST,-1 do -- search upwards for this conditional set's validity
					local prevSeg = prompt[backSearchI]
					local prevConditional = prevSeg[PROMPTSEG_CONDITIONAL]
					if prevConditional == nil then 
						return PROMPT_STAGE_OFF -- TODO if backSearchI ~= SEGT_FIRST then error(SEGT_MALFORMED_SEGMENT_TABLE) ?
					end
					
					if prevConditional ~= PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
						if EVAL_COND(id, pIndex, backSearchI, PROMPTSEG_CONDITIONAL, prompt) then
							return sI
						end
						skippingFalseConditionalSet = true
						break
					end
				end
			end
		elseif conditional == PROMPTSEG_CONDITIONAL_USE_STOP then 
			if EVAL_COND(id, pIndex, sI, SEGT_CONDITIONALS_STOP, prompt) then
				return sI
			end
			skippingFalseConditionalSet = true
		elseif conditional == PROMPTSEG_CONDITIONAL_CONTINUATION and skippingFalseConditionalSet == false then
			return sI
		elseif conditional == PROMPTSEG_CONDITIONAL_REPEATER then
			return max(SEGT_FIRST, sI-1)
		elseif conditional == PROMPTSEG_CONDITIONAL_RESTART then
			return sI
		else
			if EVAL_COND(id, pIndex, sI, PROMPTSEG_CONDITIONAL, prompt) then
				return sI
			end
			skippingFalseConditionalSet = true
		end
		if prompt[sI][PROMPTSEG_LENGTH] == nil and type(prompt[sI+1]) ~= "table" then
			break
		end
	end
	return PROMPT_STAGE_OFF
end

-------- AUDIOQS.SetPromptTimestamp()
function AUDIOQS.SetPromptTimestamp(timestamp)
	registered_prompt[PROMPT_TIMESTAMP] = timestamp
end

-------- AUDIOQS.GetPromptStage()
function AUDIOQS.GetPromptStage()
	return registered_prompt[PROMPT_CURR_STAGE]
end

-------- AUDIOQS.ChangeAudioChannel()
function AUDIOQS.ChangeAudioChannel(channel)
	local channelNumber = tonumber(channel)
	if channelNumber then
		if channelNumber < #VALID_AUDIO_CHANNELS_LIST then
			AUDIO_CHANNEL = VALID_AUDIO_CHANNELS_LIST[channelNumber]
		else
			print(string.format("%s%sAudio channel provided '%d' is invalid. Try using a number from 1 to %d. Current channel is %s", AUDIOQS.audioQsSpecifier, AUDIOQS.errSpecifier, channelNumber, #VALID_AUDIO_CHANNELS_LIST, AUDIO_CHANNEL))
			return
		end
	elseif type(channel) == "string" then
		if VALID_AUDIO_CHANNELS[string.upper(channel)] then
			AUDIO_CHANNEL = VALID_AUDIO_CHANNELS[string.upper(channel)]
		else
			print(string.format("%s%sAudio channel provided '%s' is invalid. Try using any of \"master,sfx,music,ambience,dialog,talking head\". Current channel is %s", AUDIOQS.audioQsSpecifier, AUDIOQS.errSpecifier, channel, AUDIO_CHANNEL))
			return
		end
	end
	print(string.format("%s%sAudioQs using audio channel: '%s'.", AUDIOQS.audioQsSpecifier, AUDIOQS.infoSpecifier, AUDIO_CHANNEL))
	SV_Specializations.AUDIO_CHANNEL = AUDIO_CHANNEL
end

local tickerStep = 0
local function run_prompt_ticker()
	tickerStep = tickerStep + 1 
	if tickerStep < TICKER_SKIP_FRAMES then 
		return else tickerStep = 0 
	end
	AUDIOQS.PerformanceStart("prompts", false)
	local success, err = pcall(PromptTicker) 
	if not success then 
		AUDIOQS.HandleError(err, "[OnUpdate]", "PromptTicker()") 
	end
	AUDIOQS.PerformanceEnd("prompts")
end
----- Continues the running of PromptTicker if any prompts are in-progress.
-------- AUDIOQS.CheckPrompts()
function AUDIOQS.CheckPrompts()
	if l_prompts_tracked then
		if Frame_PromptTicker:GetScript("OnUpdate") == nil then
			Frame_PromptTicker:SetScript("OnUpdate", run_prompt_ticker)
		end
	elseif Frame_PromptTicker:GetScript("OnUpdate") ~= nil then
		Frame_PromptTicker:SetScript("OnUpdate", nil)
	end
	check_prompt_ticker_state = false
end

-------- AUDIOQS.AttemptStartPrompt()
function AUDIOQS.AttemptStartPrompt(id, runCheckPrompts)
	local segmentPromptsArray = segmentPromptIndex[id]
	if segmentPromptsArray == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AUDIOQS.AttemptStartPrompt(id="..(id~=nil and id or "nil").." runCheckPrompts="..(runCheckPrompts~=nil and runCheckPrompts or "nil")..")"})
	end

	for n=1,#segmentPromptsArray,1 do -- For each set of prompts pertaining to this id
		local thisPrompt = prompts[id][n]
		local thisPromptState = promptStates[segmentPromptsArray[n]]
		
		if thisPromptState[PROMPT_CURR_STAGE] == PROMPT_STAGE_OFF then
			if EVAL_COND(id, n, SEGT_CONDITIONALS, SEGT_CONDITIONALS_START, thisPrompt) then
				if not CheckStopSegments(id, n, thisPromptState, thisPrompt, false, true) then -- TODO--Design decis. Always stop if the spell has been updated?
					check_prompt_ticker_state = true
					l_insert_active_prompt(thisPromptState)
				end
				local startingSegment = GetNextTrueSegment(id, n, thisPrompt, SEGT_FIRST)
				
				thisPromptState[PROMPT_TIMESTAMP] = GetTime()
				thisPromptState[PROMPT_CURR_STAGE] = startingSegment
				
				SetSegmentSoundHandle(
						thisPrompt[startingSegment],
						PlaySoundGetHandle(id, n, startingSegment, thisPrompt)
					)
			end
		else
			CheckStopSegments(id, n, thisPromptState, thisPrompt, false, false)
		end
	end
	if check_prompt_ticker_state ~= false then 
		AUDIOQS.CheckPrompts()
	end
end

-------- AUDIOQS.UnitIsIncluded()
function AUDIOQS.UnitIsIncluded(unitId)
	for n=1,#unitsIncluded,1 do
		if unitsIncluded[n] == unitId then
			return true
		end
	end
	return false
end

function AUDIOQS.GetPromptsMeta()
	return promptStates
end

-------- AUDIOQS.WipePrompts()
function AUDIOQS.WipePrompts()
	wipe(promptStates or {})
	wipe(segmentPromptStateIndex or {})
	wipe(spellsLookUp or {})
	wipe(unitsIncluded or {})
	
	l_prompts_tracked = nil

	AUDIOQS.CheckPrompts()
end

-------- AUDIOQS.InitializePrompts()
function AUDIOQS.InitializePrompts()	
	if not prompts or not prompts[1] then -- First load?
		-- Set saved audio channel
		for i=1,#VALID_AUDIO_CHANNELS_LIST do
			VALID_AUDIO_CHANNELS[VALID_AUDIO_CHANNELS_LIST[i]] = VALID_AUDIO_CHANNELS_LIST[i]
		end
		if SV_Specializations and SV_Specializations.AUDIO_CHANNEL then
			AUDIO_CHANNEL = VALID_AUDIO_CHANNELS[string.upper(SV_Specializations.AUDIO_CHANNEL)] or AUDIO_CHANNEL
		end
		EVAL_LENGTH = AUDIOQS.SEGLIB_EvaluateLength
		EVAL_SOUND = AUDIOQS.SEGLIB_EvaluateSound
		EVAL_COND = AUDIOQS.SEGLIB_EvaluateConditional
	end
	
	AUDIOQS.WipePrompts()

	prompts = AUDIOQS.GSI_GetPromptsTable()
	if prompts == nil then
		AUDIOQS.HandleError({code=AUDIOQS.ERR_INVALID_ARGS}, nil, "AUDIOQS.InitializePrompts(specIdToLoad="..(specIdToLoad ~= nil and specIdToLoad or "nil"))
		return nil
	end

	return GenerateTablesAndIndices()
end
--
-- /Funcs --

--- Event Funcs --
--
local GetTime = GetTime
-------------- PromptTicker()
PromptTicker = function()
	local currTime = GetTime()
	
	local thisPromptState = l_prompts_tracked
	while(thisPromptState) do
		local nextPromptState = thisPromptState[PROMPT_NEXT_PROMPT_TRACKED]
		if thisPromptState[PROMPT_CURR_STAGE] > PROMPT_STAGE_OFF then
			registered_prompt = thisPromptState
			local promptTimestamp, promptStage, promptKey, promptIndex = 
					thisPromptState[1], thisPromptState[2], thisPromptState[3], thisPromptState[4]
			local thisPrompt = prompts[promptKey][promptIndex]
			local extRef = thisPrompt[PROMPT_I_EXT_REF]

			if not CheckStopSegments(
					promptKey, promptIndex, thisPromptState, thisPrompt, false, false) then
				local promptLength = EVAL_LENGTH(
						promptKey, promptIndex, promptStage, PROMPTSEG_LENGTH, thisPrompt
					)
				if currTime > promptLength + promptTimestamp then
					local nextPromptStage = GetNextTrueSegment(promptKey, promptIndex, thisPrompt, promptStage+1)
					local stopSegments = nextPromptStage == PROMPT_STAGE_OFF
					local nextSegment = thisPrompt[nextPromptStage]
				
					if not stopSegments then
						local segmentSound = nextSegment[PROMPTSEG_SOUND]
						if segmentSound == PROMPTSEG_SOUND_STOP then
							StopAllSegmentsSounds(thisPrompt)
						else  -- TODO: elseif segmentSound ~= nil ??
							SetSegmentSoundHandle(
									nextSegment, 
									PlaySoundGetHandle(promptKey, promptIndex, nextPromptStage, thisPrompt)
								) -- Play this segment sound
						end
						
						thisPromptState[PROMPT_TIMESTAMP] = currTime
						
						if nextSegment[PROMPTSEG_LENGTH] ~= nil then
							thisPromptState[PROMPT_CURR_STAGE] = nextPromptStage
						else
							stopSegments = true -- TODO: Won't this cancel a sound played above?
						end
					end
					
					if stopSegments then
						CheckStopSegments(
								promptKey, promptIndex, thisPromptState, thisPrompt, true, true
							)
					end
				end
			end
		end
		thisPromptState = nextPromptState
	end
	if checkPromptTickerState then
		AUDIOQS.CheckPrompts()
		checkPromptTickerState = false
	end
end
--
-- /Event Funcs
