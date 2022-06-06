AddCSLuaFile("client/cl_init_death_model.lua")
AddCSLuaFile()

include("server/sv_init_death_model.lua")

sound.Add( {
		name = "L4D2_Defibrillator_StartSound",
		channel = CHAN_WEAPON,
		volume = 1,
		level = 85,
		pitch = 100,
		sound = "weapons/defibrillator/defibrillator_use_start.wav"
} )
util.PrecacheSound("weapons/defibrillator/defibrillator_use_start.wav")

--wOS = wOS or {}
--wOS.LastStand = wOS.LastStand or {}

--if CLIENT then
	--hook.Add("PlayerSpawn", "L4D2_DeathModel_Camera_RemoveHook", function( player )
	--	hook.Remove("CalcView","L4D2_DeathModel_Camera")
	--end)
--end