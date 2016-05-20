if SERVER then
	AddCSLuaFile ("autorun/mapcmds.lua")
	concommand.Add ("mapcmds_reload", function (ply)
		if ply and ply:IsValid () and not ply:IsSuperAdmin () then return end
		
		include ("autorun/mapcmds.lua")
		
		for _, v in ipairs (player.GetAll ()) do
			v:SendLua ("include (\"autorun/mapcmds.lua\")")
		end
	end)
end

include ("mapcmds/sh_init.lua")