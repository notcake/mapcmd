local MapCmds = MapCmds
MapCmds.RTV = MapCmds.RTV or {}
local RTV = MapCmds.RTV

local Voters = {}
local VoteCount = 0
local VotesNeeded = 0
local VoterCount = #player.GetHumans ()

-- convars
local PercentageNeeded = CreateConVar ("sm_rtv_needed", "0.60", FCVAR_NONE, "Fraction of players needed to rock the vote (default 60%)")
local MinPlayers = CreateConVar ("sm_rtv_minplayers", "0", FCVAR_NONE, "Number of players required before RTV will be enabled.")
local InitialDelay = CreateConVar ("sm_rtv_initialdelay", "30.0", FCVAR_NONE, "Time (in seconds) before first RTV can be held")
local Interval = CreateConVar ("sm_rtv_interval", "240.0", FCVAR_NONE, "Time (in seconds) after a failed RTV before another can be held")
local ChangeTime = CreateConVar ("sm_rtv_changetime", "0", FCVAR_NONE, "When to change the map after a succesful RTV: 0 - Instant, 1 - RoundEnd, 2 - MapEnd")
local RTVPostVoteAction = CreateConVar ("sm_rtv_postvoteaction", "0", FCVAR_NONE, "What to do with RTV's after a mapvote has completed. 0 - Allow, success = instant change, 1 - Deny")

local CanRTV = true
local RTVAllowed = CurTime () > InitialDelay:GetFloat ()
local InChange = false

if not RTVAllowed then
	timer.Simple (InitialDelay:GetFloat () - CurTime (), function ()
		RTVAllowed = true
	end)
end

function RTV.AttemptRTV (ply)
	if not ply or not ply:IsValid () then return end
	
	if not RTVAllowed or (RTVPostVoteAction:GetInt () == 1 and MapCmds.Voting.HasEndOfMapVoteFinished ()) then
		MapCmds.PrintToPlayer (ply, "Rock the Vote is not allowed yet.")
		return
	end
	
	if not MapCmds.Voting.CanMapChooserStartVote () then
		MapCmds.PrintToPlayer (ply, "Rock the Vote has already started.")
		return
	end
	
	if #player.GetHumans ()  < MinPlayers:GetFloat () then
		MapCmds.PrintToPlayer (ply, "The minimal number of players required has not been met.")
		return
	end
	
	if Voters [ply] then
		MapCmds.PrintToPlayer (ply, "You have already voted to Rock the Vote.")
		return
	end
	
	Voters [ply] = true
	VoteCount = VoteCount + 1
	
	MapCmds.PrintToAll (ply:Name () .. " wants to rock the vote. (" .. tostring (VoteCount) .." votes, " .. tostring (VotesNeeded) .. " required)")
	
	if VoteCount >= VotesNeeded then
		RTV.StartRTV ()
	end
end

function RTV.CalculateVotesNeeded ()
	VotesNeeded = math.floor (VoterCount * math.Clamp (PercentageNeeded:GetFloat (), 0.05, 1))
end

function RTV.ResetRTV ()
	Voters = {}
	VoteCount = 0
end

function RTV.StartRTV ()
	if InChange then return end
	
	if MapCmds.Voting.EndOfMapVoteEnabled () and MapCmds.Voting.HasEndOfMapVoteFinished () then
		local map = game.GetMapNext ()
		if map then
			MapCmds.PrintToAll ("Changing map to " .. map .. "! Rock the Vote has spoken!")
			timer.Simple (5, RTV.Timer_ChangeMap)
			InChange = true
			RTV.ResetRTV ()
			RTVAllowed = false
		end
		return
	end
	
	if MapCmds.Voting.CanMapChooserStartVote () then
		MapCmds.Voting.InitiateMapChooserVote (ChangeTime:GetInt ())
	
		RTV.ResetRTV ()
		RTVAllowed = false
		timer.Simple (InitialDelay:GetFloat (), function ()
			RTVAllowed = true
		end)
	end
end

function RTV.Timer_ChangeMap ()
	InChange = false
	
	local map = game.GetMapNext ()
	if map then
		RunConsoleCommand ("gamemode", GAMEMODE.FolderName)
		RunConsoleCommand ("changelevel", map)
	end
end

-- player counting
hook.Add ("PlayerInitialSpawn", "MapCmds.RTV", function (ply)
	VoterCount = #player.GetHumans ()
	RTV.CalculateVotesNeeded ()
end)

hook.Add ("PlayerDisconnected", "MapCmds.RTV", function (ply)
	if ply:IsBot () then return end
	
	if Voters [ply] then
		Voters [ply] = nil
		VoteCount = VoteCount - 1
	end

	VoterCount = VoterCount - 1
	RTV.CalculateVotesNeeded ()
	
	if VoteCount > 0 and VoteCount >= VotesNeeded and RTVAllowed then
		if RTVPostVoteAction:GetInt () == 1 and MapCmds.Voting.HasEndOfMapVoteFinished () then
			return
		end
		RTV.StartRTV ()
	end
end)

-- interface
hook.Add ("PlayerSay", "MapCmds.RTV", function (ply, text, team)
	local firstChar = text:sub (1, 1)
	if firstChar ~= "!" and firstChar ~= "/" then return end
	local cmd = text:sub (2):Trim ():lower ()
	if cmd == "rtv" or cmd == "rockthevote" then
		RTV.AttemptRTV (ply)
		return ""
	end
end)

concommand.Add ("sm_rtv", function (ply)
	RTV.AttemptRTV (ply)
end)

RTV.CalculateVotesNeeded ()