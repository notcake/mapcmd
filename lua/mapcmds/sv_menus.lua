local self = {}
self.__index = self

function MapCmds.CreateMenu (...)
	local menu = {}
	setmetatable (menu, self)
	menu:ctor (...)
	return menu
end

function self:ctor ()
	self.Title = "Title"
	self.Items = {}
	self.ItemsByID = {}
	
	self.Callback = nil
end

function self:AddItem (id, text)
	local item = {}
	item.ID = id
	item.Text = text
	
	self.Items [#self.Items + 1] = item
	self.ItemsByID [id] = item
end

function self:GetItemsPerPage ()
	if #self.Items <= 9 then
		return #self.Items
	end
	return 6
end

function self:GetPageCount ()
	return math.ceil (#self.Items / self:GetItemsPerPage ())
end

function self:GetTitle ()
	return self.Title
end

function self:Hide (ply)
	if ply.CurrentMenu ~= self then return end
	ply.CurrentMenu = nil
	umsg.Start ("mapcmds_menu_hide", ply)
	umsg.End ()
end

function self:OnItemSelected (ply, id)
	if not ply or not ply:IsValid () then return end
	if ply.CurrentMenu ~= self then return end
	ply.CurrentMenu = nil
	if not self.ItemsByID [id] then
		if id == "!next" then
			if ply.CurrentMenuPage < self:GetPageCount () then
				self:Show (ply, ply.CurrentMenuPage + 1)
			end
		elseif id == "!prev" then
			if ply.CurrentMenuPage > 1 then
				self:Show (ply, ply.CurrentMenuPage - 1)
			end
		elseif id == "!exit" then
		end
		return
	end
	
	if self.Callback then
		self.Callback (ply, id)
	end
end

function self:SetCallback (callback)
	self.Callback = callback
end

function self:SetTitle (title)
	self.Title = title
end

function self:Show (ply, page)
	page = page or 1
	ply.CurrentMenu = self
	ply.CurrentMenuPage = page
	
	umsg.Start ("mapcmds_menu_clear", ply)
	umsg.End ()
	
	local start = (page - 1) * self:GetItemsPerPage ()
	
	for i = 1, self:GetItemsPerPage () do
		if self.Items [start + i] then
			umsg.Start ("mapcmds_menu_item", ply)
				umsg.Char (i)
				umsg.String (self.Items [start + i].ID)
				umsg.String (self.Items [start + i].Text)
			umsg.End ()
		end
	end
	if self:GetPageCount () > 1 then
		if page > 1 then
			umsg.Start ("mapcmds_menu_item", ply)
				umsg.Char (8)
				umsg.String ("!prev")
				umsg.String ("Previous")
			umsg.End ()
		end
		if page < self:GetPageCount () then
			umsg.Start ("mapcmds_menu_item", ply)
				umsg.Char (9)
				umsg.String ("!next")
				umsg.String ("Next")
			umsg.End ()
		end
	end
	umsg.Start ("mapcmds_menu_item", ply)
		umsg.Char (0)
		umsg.String ("!exit")
		umsg.String ("Exit")
	umsg.End ()
	umsg.Start ("mapcmds_menu", ply)
		umsg.String (self:GetTitle ())
	umsg.End ()
end

concommand.Add ("mapcmds_menu", function (ply, _, args)
	if not ply or not ply:IsValid () then return end
	if not ply.CurrentMenu then return end
	if #args < 1 then return end
	
	local id = args [1]
	ply.CurrentMenu:OnItemSelected (ply, id)
end)