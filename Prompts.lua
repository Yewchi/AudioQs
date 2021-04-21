-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Table generation; PromptTicker and segment interpretation

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
local SEGT_CONDITIONALS =	1
local SEGT_FIRST = 2
local SEGT_CONDITIONALS_START = 1
local SEGT_CONDITIONALS_STOP = 2

local PROMPT_TIMESTAMP = 1
local PROMPT_CURR_STAGE = 2
local PROMPT_SEGMENT_KEY = 3
local PROMPT_SEGMENT_TABLE_INDEX = 4

local PROMPTSEG_LENGTH = 1
local PROMPTSEG_SOUND = 2
local PROMPTSEG_HANDLE = 3
local PROMPTSEG_CONDITIONAL = 4

local REG_PROMPT_INDEX = 1
local REG_SEGMENT_KEY = 2
local REG_SEGMENT_INDEX = 3
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

local TICKER_SKIP_FRAMES = 2 -- TODO Cheap optimisation, should be evaluates n = [1,2,3]; n = n+3 of prompts per frame.
--
------ /Static vals --

------- AddOn variables --
local AUDIO_CHANNEL = "DIALOG"
--
local segments = {}

local spellsLookUp = {}

local unitsIncluded = {}

local promptsTable = {}
local segmentPromptIndex = {}

local tickerStep = 0

local registered = {} -- Prompts are registered when they're being checked in the prompt ticker, allows for extensions to edit their own prompt data.

local Frame_PromptTicker = CreateFrame("Frame", "Prompt Ticker")
--
------ /AddOn variables --
--

-- /Initialization --

--- Funcs --
--
local AttemptStartPrompts
local PromptTicker

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
	do
		local i = 1
		for k,array in pairs(segments) do
			segmentPromptIndex[k] = {}
			for n=1,#array,1 do
				if #array[n] >= SEGT_FIRST then -- Is this a true set of segments for a prompt? Not an initialization function?
					-- promptsTable
					promptsTable[i] = {	0, AUDIOQS.PROMPT_STAGE_OFF, k, n } -- PROMPT_TIMESTAMP, PROMPT_CURR_STAGE, PROMPT_SEGMENT_KEY, PROMPT_SEGMENT_TABLE_INDEX
					-- segmentPromptIndex
					segmentPromptIndex[k][n] = i
					i = i + 1
				end
			end
		end
	end
	-- unitsIncluded
	for n=1,#promptsTable,1 do
		local thisSegmentKey = promptsTable[n][PROMPT_SEGMENT_KEY]
		local thisSegmentArrayIndex = promptsTable[n][PROMPT_SEGMENT_TABLE_INDEX]
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
local function PlaySoundGetHandle(id, segment)
	if AUDIOQS.hushMode ~= AUDIOQS.HUSHMODE_OFF or segment == nil then
		return nil
	end

	local eval = AUDIOQS.SEGLIB_EvaluateSound(id, segment, PROMPTSEG_SOUND)
	
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
	error({code=AUDIOQS.ERR_INVALID_SOUND_DATA, func="PlaySoundGetHandle(segment="..(segment~=nil and segment or "nil")..")"})
end

-------------- StopAllSegmentsSounds()
local function StopAllSegmentsSounds(segmentsArray)
	for n=SEGT_FIRST,#segmentsArray,1 do
		local soundHandle = segmentsArray[n][PROMPTSEG_HANDLE]
		if type(soundHandle) == "number" then
			StopSound(soundHandle)
			segmentsArray[n][PROMPTSEG_HANDLE] = nil
		end
	end
end

-------------- SetSegmentSoundHandle()
local function SetSegmentSoundHandle(segment, handle)
	if segment[PROMPTSEG_HANDLE] ~= AUDIOQS.STOP_SOUND_DISALLOWED then
		segment[PROMPTSEG_HANDLE] = handle
	end
end
-------------- CheckStopSegments()
local function CheckStopSegments(id, segmentsArray, prompt, allowContinuationOfPlay, forceStop)
	if prompt[PROMPT_CURR_STAGE] < SEGT_FIRST then
		return false
	end
	if AUDIOQS.SEGLIB_EvaluateConditional(id, segmentsArray[SEGT_CONDITIONALS], SEGT_CONDITIONALS_STOP) or forceStop == true then
		if allowContinuationOfPlay == false then
			StopAllSegmentsSounds(segmentsArray)
		end
		prompt[PROMPT_TIMESTAMP] = 0
		prompt[PROMPT_CURR_STAGE] = AUDIOQS.PROMPT_STAGE_OFF
		return true
	end
	return false
end

-------------- GetNextTrueSegment()
local function GetNextTrueSegment(id, segmentsArray, nextPromptStage)
	if nextPromptStage > #segmentsArray and nextPromptStage > SEGT_FIRST then
		if segmentsArray[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER then
			return nextPromptStage-1 -- Go back, repeat previous (probably until stop conditional is met)
		elseif segmentsArray[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART then
			return SEGT_FIRST -- Restart the prompts from Prompt 1
		end
		return AUDIOQS.PROMPT_STAGE_OFF
	end
	
	local skippingFalseConditionalSet = false
	for n=nextPromptStage,#segmentsArray,1 do -- Search downards for true conditionals
		local conditional = segmentsArray[n][PROMPTSEG_CONDITIONAL]
		if type(conditional) == "string" then
			if AUDIOQS.SEGLIB_EvaluateConditional(id, segmentsArray[n], PROMPTSEG_CONDITIONAL) then
				return n
			end
			skippingFalseConditionalSet = true
		elseif conditional == AUDIOQS.PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
			if skippingFalseConditionalSet == false then
				for p=n-1,SEGT_FIRST,-1 do -- search upwards for this conditional set's validity
					local prevPrompt = segmentsArray[p]
					local prevConditional = prevPrompt[PROMPTSEG_CONDITIONAL]
					if prevConditional == nil then 
						return AUDIOQS.PROMPT_STAGE_OFF -- TODO if p ~= SEGT_FIRST then error(SEGT_MALFORMED_SEGMENT_TABLE) ?
					end
					
					if prevConditional ~= AUDIOQS.PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
						if AUDIOQS.SEGLIB_EvaluateConditional(id, prevPrompt, PROMPTSEG_CONDITIONAL) then
							return n
						end
						skippingFalseConditionalSet = true
						break
					end
				end
			end
		elseif conditional == AUDIOQS.PROMPTSEG_CONDITIONAL_USE_STOP then 
			if AUDIOQS.SEGLIB_EvaluateConditional(id, segmentsArray[SEGT_CONDITIONALS], SEGT_CONDITIONALS_STOP) then
				return n
			end
			skippingFalseConditionalSet = true
		elseif conditional == AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION and skippingFalseConditionalSet == false then
			return n
		elseif conditional == AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER then
			return max(SEGT_FIRST, n-1)
		elseif conditional == AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART then
			return n
		else
			if AUDIOQS.SEGLIB_EvaluateConditional(id, segmentsArray[n], PROMPTSEG_CONDITIONAL) then
				return n
			end
			skippingFalseConditionalSet = true
		end
		if segmentsArray[n][PROMPTSEG_LENGTH] == nil and type(segmentsArray[n+1]) ~= "table" then
			break
		end
	end
	return AUDIOQS.PROMPT_STAGE_OFF
end

-- TODO Prompt Registration funcs are a confusing design decision, you would think the way they were used in HealthMonitor would be apparent and implemented in Prompts, implied by their "RESTART" behaviour.
-- TODO Also I don't want to repeatedly register these for each segment check that is running to more quickly access data inside the GSI FunctionEval, because it's redundant and the only issue right now is event/spellIds needed to be known for SegmentLib.lua
-------------- RegisterPrompt()
local function RegisterPrompt(promptsTableIndex)
	if type(promptsTableIndex) ~= "number" then if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."invalid access request to promptsTable in RegisterPrompt(promptsTableIndex = ", promptsTableIndex, ")") end return nil end
	local prompt = promptsTable[promptsTableIndex]
	if prompt == nil then if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."invalid access request to promptsTable in RegisterPrompt(promptsTableIndex = ", promptsTableIndex, ")") end return nil end

	registered[REG_PROMPT_INDEX] = promptsTableIndex
	registered[REG_SEGMENT_KEY] = promptsTable[PROMPT_SEGMENT_KEY]
	registered[REG_SEGMENT_INDEX] = promptsTable[PROMPT_SEGMENT_TABLE_INDEX]
		
	return unpack(promptsTable[promptsTableIndex])
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

-------- AUDIOQS.SetPromptTimestamp()
function AUDIOQS.SetPromptTimestamp(timestamp)
	promptsTable[registered[REG_PROMPT_INDEX]][PROMPT_TIMESTAMP] = timestamp
end

-------- AUDIOQS.GetPromptStage()
function AUDIOQS.GetPromptStage()
	return promptsTable[registered[REG_PROMPT_INDEX]][PROMPT_CURR_STAGE]
end

----- Continues the running of PromptTicker if any prompts are in-progress.
-------- AUDIOQS.CheckPrompts()
function AUDIOQS.CheckPrompts()
	for n=#promptsTable,1,-1 do
		if promptsTable[n][PROMPT_CURR_STAGE] ~= AUDIOQS.PROMPT_STAGE_OFF then
			if Frame_PromptTicker:GetScript("OnUpdate") == nil then
				Frame_PromptTicker:SetScript("OnUpdate", function() tickerStep = tickerStep + 1 if tickerStep < TICKER_SKIP_FRAMES then return else tickerStep = 0 end local success, err = pcall(PromptTicker) if not success then AUDIOQS.HandleError(err, "[OnUpdate]", "PromptTicker()") end end)
			end
			return
		end
	end
	if Frame_PromptTicker:GetScript("OnUpdate") ~= nil then
		Frame_PromptTicker:SetScript("OnUpdate", nil)
	end
end

-------- AUDIOQS.AttemptStartPrompt()
function AUDIOQS.AttemptStartPrompt(id, runCheckPrompts)
	local segmentPromptsArray = segmentPromptIndex[id]
	if segmentPromptsArray == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AUDIOQS.AttemptStartPrompt(id="..(id~=nil and id or "nil").." runCheckPrompts="..(runCheckPrompts~=nil and runCheckPrompts or "nil")..")"})
	end

	for n=1,#segmentPromptsArray,1 do -- For each set of segments pertaining to this id
		local thisSegments = segments[id][n]

		local thisSegmentsPrompt = promptsTable[segmentPromptsArray[n]]
		if AUDIOQS.SEGLIB_EvaluateConditional(id, thisSegments[SEGT_CONDITIONALS], SEGT_CONDITIONALS_START) then
			CheckStopSegments(id, thisSegments, thisSegmentsPrompt, false, true) -- TODO--Design decis. Always stop if the spell has been updated?
			local startingSegment = GetNextTrueSegment(id, thisSegments, SEGT_FIRST)
			
			thisSegmentsPrompt[PROMPT_TIMESTAMP] = GetTime()
			thisSegmentsPrompt[PROMPT_CURR_STAGE] = startingSegment
			 
			SetSegmentSoundHandle(thisSegments[startingSegment], PlaySoundGetHandle(id, thisSegments[startingSegment])) -- Play sound of this segment
		else
			CheckStopSegments(id, thisSegments, thisSegmentsPrompt, false)
		end
		if runCheckPrompts ~= false then 
			AUDIOQS.CheckPrompts()
		end
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

-------- AUDIOQS.WipePrompts()
function AUDIOQS.WipePrompts()
	wipe(promptsTable or {})
	wipe(segmentPromptIndex or {})
	wipe(spellsLookUp or {})
	wipe(unitsIncluded or {})

	AUDIOQS.CheckPrompts()
end

-------- AUDIOQS.InitializePrompts()
function AUDIOQS.InitializePrompts()	
	if not segments[1] then -- First attempt to load a spec?
		-- Set saved audio channel
		for i=1,#VALID_AUDIO_CHANNELS_LIST do
			VALID_AUDIO_CHANNELS[VALID_AUDIO_CHANNELS_LIST[i]] = VALID_AUDIO_CHANNELS_LIST[i]
		end
		if SV_Specializations and SV_Specializations.AUDIO_CHANNEL then
			AUDIO_CHANNEL = VALID_AUDIO_CHANNELS[string.upper(SV_Specializations.AUDIO_CHANNEL)] or AUDIO_CHANNEL
		end
	end
	
	AUDIOQS.WipePrompts()

	segments = AUDIOQS.GSI_GetSegmentsTable()
	if segments == nil then
		AUDIOQS.HandleError({code=AUDIOQS.ERR_INVALID_ARGS}, nil, "AUDIOQS.InitializePrompts(specIdToLoad="..(specIdToLoad ~= nil and specIdToLoad or "nil"))
		return nil
	end

	return GenerateTablesAndIndices()
end

--
-- /Funcs --

--- Event Funcs --
--
-- Should register prompts instead of iteration over promptsTable. Regardless, CPU utilization still low.
-------------- PromptTicker()
PromptTicker = function()
	local currTime = GetTime()
	
	for promptsTableIndex=1,#promptsTable,1 do
		if promptsTable[promptsTableIndex][PROMPT_CURR_STAGE] > AUDIOQS.PROMPT_STAGE_OFF then
			local promptTimestamp, promptStage, segmentKey, segmentsArrayIndex = RegisterPrompt(promptsTableIndex)
			local thisSegments = segments[segmentKey][segmentsArrayIndex]
			if not CheckStopSegments(segmentKey, thisSegments, promptsTable[promptsTableIndex], false) then
				local promptLength = AUDIOQS.SEGLIB_EvaluateLength(segmentKey, thisSegments[promptStage], PROMPTSEG_LENGTH)
				if currTime > promptLength + promptTimestamp then
					local nextPromptStage = GetNextTrueSegment(segmentKey, thisSegments, promptStage+1)
					local stopSegments = nextPromptStage == AUDIOQS.PROMPT_STAGE_OFF
					local nextSegment = thisSegments[nextPromptStage]
				
					if not stopSegments then
						local segmentSound = nextSegment[PROMPTSEG_SOUND]
						if segmentSound == AUDIOQS.PROMPTSEG_SOUND_STOP then
							StopAllSegmentsSounds(thisSegments)
						else  -- TODO: elseif segmentSound ~= nil ??
							SetSegmentSoundHandle(nextSegment, PlaySoundGetHandle(segmentKey, nextSegment)) -- Play this segment sound
						end
						
						promptsTable[promptsTableIndex][PROMPT_TIMESTAMP] = currTime
						
						if nextSegment[PROMPTSEG_LENGTH] ~= nil then
							promptsTable[promptsTableIndex][PROMPT_CURR_STAGE] = nextPromptStage
						else
							stopSegments = true -- TODO: Won't this cancel a sound played above?
						end
					end
					
					if stopSegments then
						CheckStopSegments(segmentKey, thisSegments, promptsTable[promptsTableIndex], true, true)
						AUDIOQS.CheckPrompts()
					end
				end
			end
		end
	end
end
--
-- /Event Funcs
