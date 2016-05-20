if MapCmds.Menu then
	MapCmds.Menu:Remove ()
	MapCmds.Menu = nil
end

local function CreateMenu ()
	if MapCmds.Menu then return MapCmds.Menu end
	
	MapCmds.Menu = vgui.Create ("DPanel")
	local Menu = MapCmds.Menu

	Menu.TitleLabel = vgui.Create ("DLabel", Menu)
	Menu.TitleLabel:SetText ("Menu")
	Menu.TitleLabel:SetFont ("DefaultBold")
	
	Menu.Items = {}
	
	function Menu:AddItem (number, id, text)
		local item = {}
		item.Number = number
		item.ID = id
		item.Text = text
		item.Control = vgui.Create ("DLabel", self)
		item.Control:SetText (tostring (number) .. ". " .. text)
		item.Control:SetFont ("DefaultBold")
		
		if self.Items [number] then
			self.Items [number].Control:Remove ()
		end
		self.Items [number] = item
		self:InvalidateLayout ()
	end
	
	function Menu:ClearItems ()
		for i = 0, 9 do
			if self.Items [i] then
				self.Items [i].Control:Remove ()
				self.Items [i] = nil
			end
		end
	end
	
	function Menu:GetTitle ()
		return self.TitleLabel:GetText ()
	end
	
	function Menu:GetItemID (number)
		if not self.Items [number] then return nil end
		return self.Items [number].ID
	end
	
	function Menu:Paint (w, h)
		draw.RoundedBoxEx (8, 0, 0, w, h, Color (64, 64, 64, 192), false, true, false, true)
	end
	
	function Menu:PerformLayout ()
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
	
	function Menu:SetTitle (title)
		self.TitleLabel:SetText (title)
	end
	
	Menu:SetVisible (false)
	return Menu
end

hook.Add ("PlayerBindPress", "MapCmds.Menu", function (ply, bind, pressed)
	if not pressed then return end
	if not MapCmds.Menu or not MapCmds.Menu:IsVisible () then return end
	
	bind = bind:lower ()
	if bind:len () ~= 5 or bind:sub (1, 4) ~= "slot" then return end
	
	local number = tonumber (bind:sub (5))
	
	local id = MapCmds.Menu:GetItemID (number)
	if not id then return end
	
	RunConsoleCommand ("mapcmds_menu", id)
	MapCmds.Menu:SetVisible (false)
	return true
end)

usermessage.Hook ("mapcmds_menu", function (umsg)
	if not MapCmds.Menu or not MapCmds.Menu:IsValid () then
		CreateMenu ()
	end
	MapCmds.Menu:SetTitle (umsg:ReadString ())
	MapCmds.Menu:SetVisible (true)
end)

usermessage.Hook ("mapcmds_menu_clear", function (umsg)
	if not MapCmds.Menu or not MapCmds.Menu:IsValid () then
		CreateMenu ()
	end
	MapCmds.Menu:ClearItems ()
end)

usermessage.Hook ("mapcmds_menu_item", function (umsg)
	if not MapCmds.Menu or not MapCmds.Menu:IsValid () then
		CreateMenu ()
	end
	
	MapCmds.Menu:AddItem (umsg:ReadChar (), umsg:ReadString (), umsg:ReadString ())
end)

usermessage.Hook ("mapcmds_menu_hide", function (umsg)
	if not MapCmds.Menu or not MapCmds.Menu:IsValid () then return end
	MapCmds.Menu:SetVisible (false)
end)