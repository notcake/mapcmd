function MapCmds.PrintToPlayer (ply, message)
	ply:PrintMessage (HUD_PRINTTALK, message)
end

function MapCmds.PrintToAll (message)
	for _, v in ipairs (player.GetAll ()) do
		v:PrintMessage (HUD_PRINTTALK, message)
	end
end