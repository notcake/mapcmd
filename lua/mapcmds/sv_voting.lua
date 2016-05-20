MapCmds.Voting = MapCmds.Voting or {}
local Voting = MapCmds.Voting
Voting.CurrentVote = nil

function Voting.IsVoteInProgress ()
	return Voting.CurrentVote ~= nil
end

local self = {}
self.__index = self
function MapCmds.CreateVote (...)
	local vote = {}
	setmetatable (vote, self)
	
	vote:ctor (...)
	return vote
end

function self:ctor ()
	self.Title = "Vote"
	self.Items = {}
	self.ItemsByID = {}
	self.PlayerVotes = {}
	self.Duration = 60
	
	self.TotalVotes = 0
	
	self.Menu = nil
	self.Callback = nil
end

function self:AddItem (id, text)
	if not id then
		ErrorNoHalt (debug.Trace ())
		return
	end
	if self.ItemsByID [id] then return end

	local item = {}
	item.ID = id
	item.Text = text
	item.VoteCount = 0
	
	self.Items [#self.Items + 1] = item
	self.ItemsByID [id] = item
end

function self:CheckVotes ()
	if self.TotalVotes >= #player.GetHumans () then
		self:EndVote ()
	end
end

function self:EndVote ()
	if Voting.CurrentVote ~= self then return end
	Voting.CurrentVote = nil
	
	if self.Menu then
		for _, v in ipairs (player.GetAll ()) do
			self.Menu:Hide (v)
		end
	end
	
	if self.Callback then
		self.Callback (self)
	end
	
	umsg.Start ("mapcmds_vote_results")
		umsg.String (self:GetTitle ())
		umsg.Char (self:GetItemCount ())
		for k, item in ipairs (self.Items) do
			umsg.Char (k)
			umsg.String (item.ID)
			umsg.String (item.Text)
			umsg.Long (item.VoteCount)
		end
	umsg.End ()
end

function self:GetDuration ()
	return self.Duration
end

function self:GetItem (index)
	return self.Items [index]
end

function self:GetItemCount ()
	return #self.Items
end

function self:GetTitle ()
	return self.Title
end

function self:GetVoteCount ()
	return self.TotalVotes
end

function self:GetWinningItem ()
	local maxcount = -1
	local winningitem = nil
	for _, item in pairs (self.Items) do
		if item.VoteCount >= maxcount then
			winningitem = item
			maxcount = item.VoteCount
		end
	end
	return winningitem
end

function self:OnPlayerVoted (ply, id)
	if not self.ItemsByID [id] then return end
	if self.PlayerVotes [ply] then return end
	
	self.PlayerVotes [ply] = id
	self.ItemsByID [id].VoteCount = self.ItemsByID [id].VoteCount + 1
	self.TotalVotes = self.TotalVotes + 1
	
	self:CheckVotes ()
end

function self:RemovePlayerVote (ply)
	if not self.PlayerVotes [ply] then return end
	self.ItemsByID [self.PlayerVotes [ply]].VoteCount = self.ItemsByID [self.PlayerVotes [ply]].VoteCount - 1
	self.PlayerVotes [ply] = nil
	self.TotalVotes = self.TotalVotes - 1
end

function self:SetCallback (callback)
	self.Callback = callback
end

function self:SetDuration (duration)
	self.Duration = duration
end

function self:SetTitle (title)
	self.Title = title
end

function self:StartVote ()
	self.Menu = MapCmds.CreateMenu ()
	self.Menu:SetTitle (self:GetTitle ())
	
	for _, item in ipairs (self.Items) do
		self.Menu:AddItem (item.ID, item.Text)
	end
	
	self.Menu:SetCallback (function (ply, id)
		self:OnPlayerVoted (ply, id)
	end)
	for _, v in ipairs (player.GetAll ()) do
		self.Menu:Show (v)
	end
	
	Voting.CurrentVote = self
	
	timer.Simple (self:GetDuration (), function ()
		self:EndVote ()
	end)
end

hook.Add ("PlayerDisconnected", function (ply)
	if not Voting.CurrentVote then return end
	Voting.CurrentVote:RemovePlayerVote (ply)
	timer.Simple (0.01, function ()
		Voting.CurrentVote:CheckVotes ()
	end)
end)