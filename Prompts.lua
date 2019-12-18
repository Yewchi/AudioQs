-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Table generation; PromptTicker and segment interpretation

--- Initialization --
--

------- Flags --
--
AQ.PROMPT_STAGE_OFF = 									0x0

AQ.PROMPTSEG_CONDITIONAL_USE_PREVIOUS =					0xFFF0
AQ.PROMPTSEG_CONDITIONAL_USE_STOP =						0xFFF1
AQ.PROMPTSEG_CONDITIONAL_CONTINUATION =					0xFFF2
AQ.PROMPTSEG_CONDITIONAL_REPEATER =						0xFFF3
AQ.PROMPTSEG_CONDITIONAL_RESTART =						0xFFF4

AQ.PROMPTSEG_SOUND_STOP =								0xEFF0
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
local AUDIO_CHANNEL = "DIALOG"

local TICKER_SKIP_FRAMES = 5 -- TODO Cheap optimisation, should be evaluates n = [1,2,3]; n = n+3 of prompts per frame.
--
------ /Static vals --

------- AddOn variables --
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
	local spells = AQ.GSI_GetSpellsTable()
	local abilityTable = {}
	local auraTable = {}
	
	do
		local i = 1
		local j = 1
		for spellId,spell in pairs(spells) do
			-- spellsLookUp
			spellsLookUp[spell[AQ.SPELL_SPELL_NAME]] = spellId
			-- abilityTable
			local previousAbilitySpellId = (#abilityTable > 0 and abilityTable[i-1] or nil)
			if spell[AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_ABILITY and previousAbilitySpellId ~= spellId then
				abilityTable[i] = spellId
				i = i + 1
			end
			-- auraTable
			local previousAuraSpellId = (#auraTable > 0 and auraTable[j-1] or nil)
			if spell[AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_AURA and previousAuraSpellId ~= spellId then
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
					promptsTable[i] = {	0, AQ.PROMPT_STAGE_OFF, k, n } -- PROMPT_TIMESTAMP, PROMPT_CURR_STAGE, PROMPT_SEGMENT_KEY, PROMPT_SEGMENT_TABLE_INDEX
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
				local thisUnit = spells[thisSegmentKey][AQ.SPELL_UNIT_ID]
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
local function PlaySoundGetHandle(segment)
	if AQ.hushMode ~= AQ.HUSHMODE_OFF or segment == nil then
		return nil
	end

	local eval = AQ.GSI_EvaluateSound(segment, PROMPTSEG_SOUND)
	
	if eval == nil then
		return nil
	end
	
	if type(eval) == "number" then
if AQ.VERBOSE then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Playing \""..eval.."\"") end
		return select(2, PlaySound(eval, AUDIO_CHANNEL))
	elseif type(eval) == "string" then
if AQ.VERBOSE then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Playing \""..eval.."\"") end
		return select(2, PlaySoundFile(eval, AUDIO_CHANNEL))
	end
	error({code=AQ.ERR_INVALID_SOUND_DATA, func="PlaySoundGetHandle(segment="..(segment~=nil and segment or "nil")..")"})
end

-------------- StopAllSegmentsSounds()
local function StopAllSegmentsSounds(segmentsArray)
	for n=SEGT_FIRST,#segmentsArray,1 do
		local soundHandle = segmentsArray[n][PROMPTSEG_HANDLE]
		if soundHandle ~= nil then
			StopSound(soundHandle)
			segmentsArray[n][PROMPTSEG_HANDLE] = nil
		end
	end
end

-------------- CheckStopSegments()
local function CheckStopSegments(segmentsArray, prompt, allowContinuationOfPlay, forceStop)
	if prompt[PROMPT_CURR_STAGE] < SEGT_FIRST then
		return false
	end
	if AQ.GSI_EvaluateConditional(segmentsArray[SEGT_CONDITIONALS], SEGT_CONDITIONALS_STOP) or forceStop == true then
		if allowContinuationOfPlay == false then
			StopAllSegmentsSounds(segmentsArray)
		end
		prompt[PROMPT_TIMESTAMP] = 0
		prompt[PROMPT_CURR_STAGE] = AQ.PROMPT_STAGE_OFF
		return true
	end
	return false
end

-------------- GetNextTrueSegment()
local function GetNextTrueSegment(segmentsArray, nextPromptStage)
	if nextPromptStage > #segmentsArray and nextPromptStage > SEGT_FIRST then
		if segmentsArray[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == AQ.PROMPTSEG_CONDITIONAL_REPEATER then
			return nextPromptStage-1 -- Go back, repeat previous (probably until stop conditional is met)
		elseif segmentsArray[nextPromptStage-1][PROMPTSEG_CONDITIONAL] == AQ.PROMPTSEG_CONDITIONAL_RESTART then
			return SEGT_FIRST -- Restart the prompts from Prompt 1
		end
		return AQ.PROMPT_STAGE_OFF
	end
	
	local skippingFalseConditionalSet = false
	for n=nextPromptStage,#segmentsArray,1 do -- Search downards for true conditionals
		local conditional = segmentsArray[n][PROMPTSEG_CONDITIONAL]
		if type(conditional) == "string" then
			if AQ.GSI_EvaluateConditional(segmentsArray[n], PROMPTSEG_CONDITIONAL) then
				return n
			end
			skippingFalseConditionalSet = true
		elseif conditional == AQ.PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
			if skippingFalseConditionalSet == false then
				for p=n-1,SEGT_FIRST,-1 do -- search upwards for this conditional set's validity
					local prevPrompt = segmentsArray[p]
					local prevConditional = prevPrompt[PROMPTSEG_CONDITIONAL]
					if prevConditional == nil then 
						return AQ.PROMPT_STAGE_OFF -- TODO if p ~= SEGT_FIRST then error(SEGT_MALFORMED_SEGMENT_TABLE) ?
					end
					
					if prevConditional ~= AQ.PROMPTSEG_CONDITIONAL_USE_PREVIOUS then
						if AQ.GSI_EvaluateConditional(prevPrompt, PROMPTSEG_CONDITIONAL) then
							return n
						end
						skippingFalseConditionalSet = true
						break
					end
				end
			end
		elseif conditional == AQ.PROMPTSEG_CONDITIONAL_USE_STOP then 
			if AQ.GSI_EvaluateConditional(segmentsArray[SEGT_CONDITIONALS], SEGT_CONDITIONALS_STOP) then
				return n
			end
			skippingFalseConditionalSet = true
		elseif conditional == AQ.PROMPTSEG_CONDITIONAL_CONTINUATION and skippingFalseConditionalSet == false then
			return n
		elseif conditional == AQ.PROMPTSEG_CONDITIONAL_REPEATER then
			return max(SEGT_FIRST, n-1)
		elseif conditional == AQ.PROMPTSEG_CONDITIONAL_RESTART then
			return n
		else
			if AQ.GSI_EvaluateConditional(segmentsArray[n], PROMPTSEG_CONDITIONAL) then
				return n
			end
			skippingFalseConditionalSet = true
		end
		if segmentsArray[n][PROMPTSEG_LENGTH] == nil and type(segmentsArray[n+1]) ~= "table" then
			break
		end
	end
	return AQ.PROMPT_STAGE_OFF
end

-------------- RegisterPrompt()
local function RegisterPrompt(promptsTableIndex)
	if type(promptsTableIndex) ~= "number" then if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."invalid access request to promptsTable in RegisterPrompt(promptsTableIndex = ", promptsTableIndex, ")") end return nil end
	local prompt = promptsTable[promptsTableIndex]
	if prompt == nil then if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."invalid access request to promptsTable in RegisterPrompt(promptsTableIndex = ", promptsTableIndex, ")") end return nil end

	registered[REG_PROMPT_INDEX] = promptsTableIndex
	registered[REG_SEGMENT_KEY] = promptsTable[PROMPT_SEGMENT_KEY]
	registered[REG_SEGMENT_INDEX] = promptsTable[PROMPT_SEGMENT_TABLE_INDEX]
		
	return unpack(promptsTable[promptsTableIndex])
end

-------- AQ.SetPromptTimestamp()
function AQ.SetPromptTimestamp(timestamp)
	promptsTable[registered[REG_PROMPT_INDEX]][PROMPT_TIMESTAMP] = timestamp
end

-------- AQ.GetPromptStage()
function AQ.GetPromptStage()
	return promptsTable[registered[REG_PROMPT_INDEX]][PROMPT_CURR_STAGE]
end

----- Continues the running of PromptTicker if any prompts are in-progress.
-------- AQ.CheckPrompts()
function AQ.CheckPrompts()
	for n=#promptsTable,1,-1 do
		if promptsTable[n][PROMPT_CURR_STAGE] ~= AQ.PROMPT_STAGE_OFF then
			if Frame_PromptTicker:GetScript("OnUpdate") == nil then
				Frame_PromptTicker:SetScript("OnUpdate", function() tickerStep = tickerStep + 1 if tickerStep < TICKER_SKIP_FRAMES then return else tickerStep = 0 end local success, err = pcall(PromptTicker) if not success then AQ.HandleError(err, "[OnUpdate]", "PromptTicker()") end end)
			end
			return
		end
	end
	if Frame_PromptTicker:GetScript("OnUpdate") ~= nil then
		Frame_PromptTicker:SetScript("OnUpdate", nil)
	end
end

-------- AQ.AttemptStartPrompt()
function AQ.AttemptStartPrompt(id, runCheckPrompts)
	local segmentPromptsArray = segmentPromptIndex[id]
	if segmentPromptsArray == nil then
		error({code=AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AQ.AttemptStartPrompt(id="..(id~=nil and id or "nil").." runCheckPrompts="..(runCheckPrompts~=nil and runCheckPrompts or "nil")..")"})
	end

	for n=1,#segmentPromptsArray,1 do -- For each set of segments pertaining to this id
		local thisSegments = segments[id][n]

		local thisSegmentsPrompt = promptsTable[segmentPromptsArray[n]]
		if AQ.GSI_EvaluateConditional(thisSegments[SEGT_CONDITIONALS], SEGT_CONDITIONALS_START) then
			--print("Start will stop")
			CheckStopSegments(thisSegments, thisSegmentsPrompt, false, true) -- TODO--Design decis. Always stop if the spell has been updated?
			local startingSegment = GetNextTrueSegment(thisSegments, SEGT_FIRST)
			
			thisSegmentsPrompt[PROMPT_TIMESTAMP] = GetTime()
			thisSegmentsPrompt[PROMPT_CURR_STAGE] = startingSegment
			 
			thisSegments[startingSegment][PROMPTSEG_HANDLE] = PlaySoundGetHandle(thisSegments[startingSegment])
		else
			CheckStopSegments(thisSegments, thisSegmentsPrompt, false)
		end
		if runCheckPrompts ~= false then 
			AQ.CheckPrompts()
		end
	end
end

-------- AQ.UnitIsIncluded()
function AQ.UnitIsIncluded(unitId)
	for n=1,#unitsIncluded,1 do
		if unitsIncluded[n] == unitId then
			return true
		end
	end
	return false
end

-------- AQ.WipePrompts()
function AQ.WipePrompts()
	wipe(promptsTable or {})
	wipe(segmentPromptIndex or {})
	wipe(spellsLookUp or {})
	wipe(unitsIncluded or {})

	AQ.CheckPrompts()
end

-------- AQ.InitializePrompts()
function AQ.InitializePrompts()
	AQ.WipePrompts()

	segments = AQ.GSI_GetSegmentsTable()
	if segments == nil then
		AQ.HandleError({code=AQ.ERR_INVALID_ARGS}, nil, "AQ.InitializePrompts(specIdToLoad="..(specIdToLoad ~= nil and specIdToLoad or "nil"))
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
		if promptsTable[promptsTableIndex][PROMPT_CURR_STAGE] > AQ.PROMPT_STAGE_OFF then
			local promptTimestamp, promptStage, segmentKey, segmentsArrayIndex = RegisterPrompt(promptsTableIndex)
			local thisSegments = segments[segmentKey][segmentsArrayIndex]
			if not CheckStopSegments(thisSegments, promptsTable[promptsTableIndex], false) then
				local promptLength = AQ.GSI_EvaluateLength(thisSegments[promptStage], PROMPTSEG_LENGTH)
				if currTime > promptLength + promptTimestamp then
					local nextPromptStage = GetNextTrueSegment(thisSegments, promptStage+1)
					local stopSegments = nextPromptStage == AQ.PROMPT_STAGE_OFF
					local nextSegment = thisSegments[nextPromptStage]
				
					if not stopSegments then
						local segmentSound = nextSegment[PROMPTSEG_SOUND]
						if segmentSound == AQ.PROMPTSEG_SOUND_STOP then
							StopAllSegmentsSounds(thisSegments)
						else  -- TODO: elseif segmentSound ~= nil ??
							nextSegment[PROMPTSEG_HANDLE] = PlaySoundGetHandle(nextSegment)
						end
						
						promptsTable[promptsTableIndex][PROMPT_TIMESTAMP] = currTime
						
						if nextSegment[PROMPTSEG_LENGTH] ~= nil then
							promptsTable[promptsTableIndex][PROMPT_CURR_STAGE] = nextPromptStage
						else
							stopSegments = true -- TODO: Won't this cancel a sound played above?
						end
					end
					
					if stopSegments then
						CheckStopSegments(thisSegments, promptsTable[promptsTableIndex], true, true)
						AQ.CheckPrompts()
					end
				end
			end
		end
	end
end
--
-- /Event Funcs
