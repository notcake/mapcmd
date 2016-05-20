if MapCmds.VoteResults then
	MapCmds.VoteResults:Remove ()
	MapCmds.VoteResults = nil
end

local ItemColors = {}
ItemColors [1] = Color (128, 0, 0, 255)
ItemColors [2] = Color (0, 128, 0, 255)
ItemColors [3] = Color (0, 0, 128, 255)
ItemColors [4] = Color (128, 128, 0, 255)
ItemColors [5] = Color (128, 0, 128, 255)
ItemColors [6] = Color (0, 128, 128, 255)
ItemColors [7] = Color (255, 255, 255, 255)
ItemColors [8] = Color (128, 128, 128, 255)
ItemColors [9] = Color (128, 0, 128, 255)

local function CreateVoteResults ()
	if MapCmds.VoteResults then return MapCmds.VoteResults end
	
	MapCmds.VoteResults = vgui.Create ("DPanel")
	local VoteResults = MapCmds.VoteResults

	VoteResults.TitleLabel = vgui.Create ("DLabel", VoteResults)
	VoteResults.TitleLabel:SetText ("Vote Results")
	VoteResults.TitleLabel:SetFont ("DefaultBold")
	
	VoteResults.ShowTime = CurTime ()
	VoteResults.Total = 0
	VoteResults.Items = {}
	
	function VoteResults:AddItem (number, id, text, count)
		local item = {}
		item.Number = number
		item.ID = id
		item.Text = text
		item.Count = count
		item.Control = vgui.Create ("DLabel", self)
		item.Control:SetText (tostring (number) .. ". " .. text)
		item.Control:SetFont ("DefaultBold")
		item.Color = ItemColors [number]
		
		self.Total = self.Total + count
		
		if self.Items [number] then
			self.Items [number].Control:Remove ()
		end
		self.Items [number] = item
		self:InvalidateLayout ()
	end
	
	function VoteResults:ClearItems ()
		for i = 0, 9 do
			if self.Items [i] then
				self.Items [i].Control:Remove ()
				self.Items [i] = nil
			end
		end
	end
	
	function VoteResults:GetTitle ()
		return self.TitleLabel:GetText ()
	end
	
	function VoteResults:GetItemID (number)
		if not self.Items [number] then return nil end
		return self.Items [number].ID
	end
	
	function VoteResults:Paint (w, h)
		draw.RoundedBoxEx (8, 0, 0, w, h, Color (64, 64, 64, 192), false, true, false, true)
	end
	
	function VoteResults:PerformLayout ()
		local w = 32
		local y = 32
		local maxy = y
		local count = 0
		
		self.TitleLabel:SetPos (8, 8)
		self.TitleLabel:SizeToContents ()
		w = self.TitleLabel:GetWide () + 16
		
		for i = 1, 9 do
			if self.Items [i] then
				self.Items [i].Control:SizeToContents ()
				self.Items [i].Control:SetPos (16, y)
				
				if self.Items [i].Control:GetWide () + 24 > w then
					w = self.Items [i].Control:GetWide () + 24
				end
				count = count + 1
				maxy = y + 14
			end
			y = y + 14
		end
		if self.Items [0] then
			self.Items [0].Control:SizeToContents ()
			self.Items [0].Control:SetPos (16, y)
			
			if self.Items [0].Control:GetWide () + 24 > w then
				w = self.Items [0].Control:GetWide () + 24
			end
			y = y + 14
			maxy = y
			count = count + 1
		end
		
		self:SetSize (w, maxy + 8)
		self:SetPos (0, (ScrH () - self:GetTall ()) * 0.5)
	end
	
	function VoteResults:Remove ()
		self:SetVisible (false)
		debug.getregistry ().Panel.Remove (self)
	end
	
	function VoteResults:SetTitle (title)
		self.TitleLabel:SetText ("Vote Results: " .. title)
	end
	
	function VoteResults:SetVisible (visible)
		debug.getregistry ().Panel.SetVisible (self, visible)
		
		if visible then
			self.ShowTime = CurTime ()
			hook.Add ("HUDPaint", "MapCmds.VoteResults", function ()
				local delta = CurTime () - self.ShowTime
				if delta > 1 then 
					delta = 1
				end
				
				for _, item in pairs (self.Items) do
					if item.Count > 0 or true then
						local x, y = self:GetPos ()
						local cx, cy = item.Control:GetPos ()
						y = y + cy
						x = x + self:GetWide ()
						local h = item.Control:GetTall ()
						local w = item.Count / self.Total * 100
						
						
						w = w * delta
						local round = 4
						if w < round * 2 then
							round = math.floor (w * 0.25) * 2
						end
						
						draw.RoundedBoxEx (round, x, y, w, h, item.Color, false, true, false, true)
					end
				end
			end)
		else
			hook.Remove ("HUDPaint", "MapCmds.VoteResults")
		end
	end
	
	VoteResults:SetVisible (false)
	return VoteResults
end

usermessage.Hook ("mapcmds_vote_results", function (umsg)
	if not MapCmds.VoteResults or not MapCmds.VoteResults:IsValid () then
		CreateVoteResults ()
	end
	MapCmds.VoteResults:ClearItems ()
	
	MapCmds.VoteResults:SetTitle (umsg:ReadString ())
	local count = umsg:ReadChar ()
	for i = 1, count do
		MapCmds.VoteResults:AddItem (umsg:ReadChar (), umsg:ReadString (), umsg:ReadString (), umsg:ReadLong ())
	end
	
	MapCmds.VoteResults:SetVisible (true)
	
	timer.Simple (15, function ()
		if not MapCmds.VoteResults or not MapCmds.VoteResults:IsValid () then return end
		MapCmds.VoteResults:SetVisible (false)
	end)
end)