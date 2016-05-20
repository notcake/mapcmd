MapCmds.Voting = MapCmds.Voting or {}
local Voting = MapCmds.Voting

local CHANGETIME_INSTANT = 0
local CHANGETIME_ROUNDEND = 1
local CHANGETIME_MAPEND = 2

local HasVoteStarted = false
local WaitingForVote = false
local MapVoteCompleted = false
local ChangeMapAtRoundEnd = false
local ChangeMapInProgress = false
local NominateCount = 0

local NextMap = nil
local Extends = 0
local ChangeTime = 0

local DontChange = CreateConVar ("sm_mapvote_dontchange", "1", FCVAR_NONE, "Specifies if a 'Don't Change' option should be added to early votes")
local Extend = CreateConVar ("sm_mapvote_extend", "0", FCVAR_NONE, "Number of extensions allowed each map.")
local EndOfMapVote = CreateConVar ("sm_mapvote_endvote", "1", FCVAR_NONE, "Specifies if MapChooser should run an end of map vote")
local VoteDuration = CreateConVar ("sm_mapvote_voteduration", "20", FCVAR_NONE, "Specifies how long the mapvote should be available for.")

local Maps = {}
for _, map in ipairs (string.Explode ("\n", (file.Read ("data/mapcycle.txt", "GAME") or ""):Trim ())) do
	map = map:Trim ()
	if map ~= "" then
		Maps [#Maps + 1] = map
	end
end
if #Maps == 0 then
	for _, map in ipairs (file.Find ("maps/*.bsp", "GAME")) do
		Maps [#Maps + 1] = map:sub (1, -5)
	end
end

MapCmds.NextMaps = {}
local NextMaps = MapCmds.NextMaps
local CurrentMapIndex = 1
for i = 1, #Maps do
	if Maps [i]:lower () == game.GetMap ():lower () then
		CurrentMapIndex = i
		break
	end
end
for i = CurrentMapIndex + 1, #Maps do
	NextMaps [#NextMaps + 1] = Maps [i]
end
for i = 1, CurrentMapIndex do
	NextMaps [#NextMaps + 1] = Maps [i]
end

function Voting.CanVoteStart ()
	if WaitingForVote or HasVoteStarted then return false end
	return true
end

function Voting.InitiateVote (when, input)
	WaitingForVote = true
	
	if Voting.IsVoteInProgress () then
		timer.Simple (5, function ()
			Voting.InitiateVote (when, input)
		end)
	end
	
	if MapVoteCompleted and ChangeMapInProgress then return end
	
	ChangeTime = when
	WaitingForVote = false
	HasVoteStarted = true
	
	local Vote = MapCmds.CreateVote ()
	Vote:SetTitle ("Vote for the next map!")
	
	if not input then
		local voteSize = MapCmds.IncludeMaps:GetInt ()
	
		for map, _ in pairs (MapCmds.Nominate.NominatedMaps) do
			Vote:AddItem (map, map)
		end
		
		MapCmds.Nominate.ClearNominations ()
		
		local toAdd = voteSize - Vote:GetItemCount ()
		if toAdd > 0 then
			if #NextMaps < toAdd then
				toAdd = #NextMaps
			end
			for i = 1, toAdd do
				Vote:AddItem (NextMaps [i], NextMaps [i])
			end
		end
	else
		for _, map in ipairs (input) do
			Vote:AddItem (map, map)
		end
	end
	
	if (when == CHANGETIME_INSTANT or when == CHANGETIME_ROUNDEND) and DontChange:GetBool () then
		Vote:AddItem ("!dontchange", "Don't Change")
	elseif Extend:GetBool () and Extends < Extend:GetInt () then
		Vote:AddItem ("!extend", "Extend Map")
	end
	
	MapCmds.PrintToAll ("Voting for the next map has started.")
	
	Vote:SetDuration (VoteDuration:GetFloat ())
	Vote:SetCallback (Voting.OnMapVoteFinished)
	Vote:StartVote ()
end

function Voting.OnMapVoteFinished (vote)
	WaitingForVote = false
	HasVoteStarted = false
	if vote:GetVoteCount () == 0 then
		return
	end
	
	local item = vote:GetWinningItem ()
	if item.ID == "!extend" then
		Extends = Extends + 1
	elseif item.ID == "!dontchange" then
		MapCmds.PrintToAll ("Current map continues! The Vote has spoken! (Received " .. math.floor (item.VoteCount / vote:GetVoteCount () * 100) .. "% of " .. tostring (vote:GetVoteCount ()) .. " votes)")		
		HasVoteStarted = false
	else
		if ChangeTime == CHANGETIME_MAPEND then
		elseif ChangeTime == CHANGETIME_INSTANT then
			timer.Simple (10, function ()
				RunConsoleCommand ("gamemode", GAMEMODE.FolderName)
				RunConsoleCommand ("changelevel", item.ID)
			end)
			ChangeMapInProgress = false
		else
			NextMap = item.ID
			ChangeMapAtRoundEnd = true
		end
		
		HasVoteStarted = false
		MapVoteCompleted = true
		
		MapCmds.PrintToAll ("Map voting has finished. The next map will be " .. item.ID .. ". (Received " .. math.floor (item.VoteCount / vote:GetVoteCount () * 100) .. "% of " .. tostring (vote:GetVoteCount ()) .. " votes)")
	end
end

-- hooks
hook.Add ("OnRoundEnd", "MapCmds.MapChooser", function (roundNumber)
	timer.Simple (20, function ()
		if ChangeMapAtRoundEnd then
			RunConsoleCommand ("gamemode", GAMEMODE.FolderName)
			RunConsoleCommand ("changelevel", NextMap or NextMaps [1])
		end
	end)
end)

-- interface
function Voting.CanMapChooserStartVote ()
	return Voting.CanVoteStart ()
end
	
function Voting.EndOfMapVoteEnabled ()
	return EndOfMapVote:GetBool ()
end

function Voting.HasEndOfMapVoteFinished ()
	return MapVoteCompleted
end

function Voting.InitiateMapChooserVote (when, input)
	Voting.InitiateVote (when, input)
end