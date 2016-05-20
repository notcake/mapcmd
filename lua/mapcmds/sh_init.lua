MapCmds = MapCmds or {}

if SERVER then
	AddCSLuaFile ("mapcmds/sh_init.lua")
	include ("mapcmds/sv_init.lua")
elseif CLIENT then
	include ("mapcmds/cl_init.lua")
end