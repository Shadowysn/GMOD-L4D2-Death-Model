if (CLIENT) then return end

util.AddNetworkString( "L4D2_DeathModel_GetPlayerColor" )
util.AddNetworkString( "L4D2_DeathModel_SetUnlivingOwnerToPosition" )
util.AddNetworkString( "L4D2_DeathModel_BeginRemoveRagdoll" )
util.AddNetworkString( "L4D2_DeathModel_RemoveEntity" )
util.AddNetworkString( "L4D2_DeathModel_SnapCameraToGetUp" )
util.AddNetworkString( "L4D2_DeathModel_SetClientSideAnimation" )

if !ConVarExists("sv_l4d2_death_model") then -- 1
   CreateConVar("sv_l4d2_death_model", '1', (FCVAR_ARCHIVE), "Use L4D2 death animation replacement for player ragdolls?", 0, 1)
end

if !ConVarExists("sv_l4d2_npc_death_model") then
	CreateConVar("sv_l4d2_npc_death_model", '0', (FCVAR_ARCHIVE), "UNFINISHED; Use L4D2 standing death animation replacement for NPCs?", 0, 1)
end

if !ConVarExists("sv_l4d2_respawn_remove_body") then -- 2
   CreateConVar("sv_l4d2_respawn_remove_body", '1', (FCVAR_ARCHIVE), "Remove L4D2 death animation bodies on respawn?", 0, 1)
end

if !ConVarExists("sv_l4d2_body_ragdoll_timer") then -- 3
   CreateConVar("sv_l4d2_body_ragdoll_timer", '0', (FCVAR_ARCHIVE), 
   "Set the timer in seconds for doing the animation before ragdolling. This will disable defibbing. 0 = Disable, 100 = Max Limit", 0, 100)
end

if !ConVarExists("sv_l4d2_bonus_features") then -- 4
   CreateConVar("sv_l4d2_bonus_features", '0', (FCVAR_ARCHIVE), 
   "Set whether to enable bonus features not found in the original game.", 0, 1)
end

cvars.AddChangeCallback( "sv_l4d2_body_ragdoll_timer", function( convar_name, value_old, value_new )
	local new = tonumber(value_new)
	if new > 100 and ConVarExists(convar_name) then
		GetConVar(convar_name):SetInt(100)
	end
end)

if !ConVarExists("sv_l4d2_body_keepvelocity") then -- 4
   CreateConVar("sv_l4d2_body_keepvelocity", '0', (FCVAR_ARCHIVE), "Keep player velocity from player into dead body?", 0, 1)
end

if !ConVarExists("sv_l4d2_defib_time") then -- 5
   CreateConVar("sv_l4d2_defib_time", '3', (FCVAR_ARCHIVE), "Prevent defibrillators from reviving a body of an alive player? 0 = Instant, 100 = Max Limit", 0, 100)
end

cvars.AddChangeCallback( "sv_l4d2_defib_time", function( convar_name, value_old, value_new )
	local new = tonumber(value_new)
	if new > 100 and ConVarExists(convar_name) then
		GetConVar(convar_name):SetInt(100)
	end
end)

if !ConVarExists("sv_l4d2_defib_alive_prevent") then -- 6
   CreateConVar("sv_l4d2_defib_alive_prevent", '1', (FCVAR_ARCHIVE), "Prevent defibrillators from reviving a body of an alive player?", 0, 1)
end

if !ConVarExists("sv_l4d2_physgun_pickup") then -- 7
   CreateConVar("sv_l4d2_physgun_pickup", '0', (FCVAR_ARCHIVE), "Allow bodies to be picked up by physgun?", 0, 1)
end

if !ConVarExists("sv_l4d2_body_burn") then -- 8
   CreateConVar("sv_l4d2_body_burn", '1', (FCVAR_ARCHIVE), "Ignite dead bodies which will turn them unrevivable?", 0, 1)
end

if !ConVarExists("sv_l4d2_death_scream") then -- 9
   CreateConVar("sv_l4d2_death_scream", '0', (FCVAR_ARCHIVE), "Should players do a death scream on death? Seperate from sv_l4d2_death_model.", 0, 1)
end

local dmg_exclude_tbl = {}

--[[local dmg_tbl = {
	DMG_GENERIC = "DMG_GENERIC",
	DMG_CRUSH = "DMG_CRUSH",
	DMG_BULLET = "DMG_BULLET",
	DMG_SLASH = "DMG_SLASH",
	DMG_BURN = "DMG_BURN",
	DMG_VEHICLE = "DMG_VEHICLE",
	DMG_FALL = "DMG_FALL",
	DMG_BLAST = "DMG_BLAST",
	DMG_CLUB = "DMG_CLUB",
	DMG_SHOCK = "DMG_SHOCK",
	DMG_SONIC = "DMG_SONIC",
	DMG_ENERGYBEAM = "DMG_ENERGYBEAM",
	DMG_PREVENT_PHYSICS_FORCE = "DMG_PREVENT_PHYSICS_FORCE",
	DMG_NEVERGIB = "DMG_NEVERGIB",
	DMG_ALWAYSGIB = "DMG_ALWAYSGIB",
	DMG_DROWN = "DMG_DROWN",
	DMG_PARALYZE = "DMG_PARALYZE",
	DMG_NERVEGAS = "DMG_NERVEGAS",
	DMG_POISON = "DMG_POISON",
	DMG_RADIATION = "DMG_RADIATION",
	DMG_DROWNRECOVER = "DMG_DROWNRECOVER",
	DMG_ACID = "DMG_ACID",
	DMG_SLOWBURN = "DMG_SLOWBURN",
	DMG_REMOVENORAGDOLL = "DMG_REMOVENORAGDOLL",
	DMG_PHYSGUN = "DMG_PHYSGUN",
	DMG_PLASMA = "DMG_PLASMA",
	DMG_AIRBOAT = "DMG_AIRBOAT",
	DMG_DISSOLVE = "DMG_DISSOLVE",
	DMG_BLAST_SURFACE = "DMG_BLAST_SURFACE",
	DMG_DIRECT = "DMG_DIRECT",
	DMG_BUCKSHOT = "DMG_BUCKSHOT",
	DMG_SNIPER = "DMG_SNIPER",
	DMG_MISSILEDEFENSE = "DMG_MISSILEDEFENSE"
}--]]

local function TableBlacklistDamage(cmd, stringargs)
	local con_dmg_tbl = {
	string.format("%s DMG_GENERIC", cmd),
	string.format("%s DMG_CRUSH", cmd),
	string.format("%s DMG_BULLET", cmd),
	string.format("%s DMG_SLASH", cmd),
	string.format("%s DMG_BURN", cmd),
	string.format("%s DMG_VEHICLE", cmd),
	string.format("%s DMG_FALL", cmd),
	string.format("%s DMG_BLAST", cmd),
	string.format("%s DMG_CLUB", cmd),
	string.format("%s DMG_SHOCK", cmd),
	string.format("%s DMG_SONIC", cmd),
	string.format("%s DMG_ENERGYBEAM", cmd),
	string.format("%s DMG_PREVENT_PHYSICS_FORCE", cmd),
	string.format("%s DMG_NEVERGIB", cmd),
	string.format("%s DMG_ALWAYSGIB", cmd),
	string.format("%s DMG_DROWN", cmd),
	string.format("%s DMG_PARALYZE", cmd),
	string.format("%s DMG_NERVEGAS", cmd),
	string.format("%s DMG_POISON", cmd),
	string.format("%s DMG_RADIATION", cmd),
	string.format("%s DMG_DROWNRECOVER", cmd),
	string.format("%s DMG_ACID", cmd),
	string.format("%s DMG_SLOWBURN", cmd),
	string.format("%s DMG_REMOVENORAGDOLL", cmd),
	string.format("%s DMG_PHYSGUN", cmd),
	string.format("%s DMG_PLASMA", cmd),
	string.format("%s DMG_AIRBOAT", cmd),
	string.format("%s DMG_DISSOLVE", cmd),
	string.format("%s DMG_BLAST_SURFACE", cmd),
	string.format("%s DMG_DIRECT", cmd),
	string.format("%s DMG_BUCKSHOT", cmd),
	string.format("%s DMG_SNIPER", cmd),
	string.format("%s DMG_MISSILEDEFENSE", cmd)
	}
	return con_dmg_tbl
end

local check_dmg_tbl = {
["DMG_GENERIC"] = DMG_GENERIC,
["DMG_CRUSH"] = DMG_CRUSH,
["DMG_BULLET"] = DMG_BULLET,
["DMG_SLASH"] = DMG_SLASH,
["DMG_BURN"] = DMG_BURN,
["DMG_VEHICLE"] = DMG_VEHICLE,
["DMG_FALL"] = DMG_FALL,
["DMG_BLAST"] = DMG_BLAST,
["DMG_CLUB"] = DMG_CLUB,
["DMG_SHOCK"] = DMG_SHOCK,
["DMG_SONIC"] = DMG_SONIC,
["DMG_ENERGYBEAM"] = DMG_ENERGYBEAM,
["DMG_PREVENT_PHYSICS_FORCE"] = DMG_PREVENT_PHYSICS_FORCE,
["DMG_NEVERGIB"] = DMG_NEVERGIB,
["DMG_ALWAYSGIB"] = DMG_ALWAYSGIB,
["DMG_DROWN"] = DMG_DROWN,
["DMG_PARALYZE"] = DMG_PARALYZE,
["DMG_NERVEGAS"] = DMG_NERVEGAS,
["DMG_POISON"] = DMG_POISON,
["DMG_RADIATION"] = DMG_RADIATION,
["DMG_DROWNRECOVER"] = DMG_DROWNRECOVER,
["DMG_ACID"] = DMG_ACID,
["DMG_SLOWBURN"] = DMG_SLOWBURN,
["DMG_REMOVENORAGDOLL"] = DMG_REMOVENORAGDOLL,
["DMG_PHYSGUN"] = DMG_PHYSGUN,
["DMG_PLASMA"] = DMG_PLASMA,
["DMG_AIRBOAT"] = DMG_AIRBOAT,
["DMG_DISSOLVE"] = DMG_DISSOLVE,
["DMG_BLAST_SURFACE"] = DMG_BLAST_SURFACE,
["DMG_DIRECT"] = DMG_DIRECT,
["DMG_BUCKSHOT"] = DMG_BUCKSHOT,
["DMG_SNIPER"] = DMG_SNIPER,
["DMG_MISSILEDEFENSE"] = DMG_MISSILEDEFENSE,
}

local function BlacklistDamage(ply, cmd, args, args_str)
	local hasvalue = nil
	for _,arg in ipairs(args) do
		local arg_str = tostring(arg)
		if check_dmg_tbl[arg] then
			hasvalue = true
			--print(dmg_exclude_tbl[arg_str])
			--if not dmg_exclude_tbl[arg_str] then
			--print(table.HasValue(dmg_exclude_tbl, arg_str))
			if not table.HasValue(dmg_exclude_tbl, arg_str) then
			local temp_tbl = { check_dmg_tbl[arg] } --PrintTable(temp_tbl)
			table.Add(dmg_exclude_tbl, temp_tbl)
			ply:PrintMessage(HUD_PRINTCONSOLE, string.format("Successfully added %s to the excluding list!", arg_str))
			else
			ply:PrintMessage(HUD_PRINTCONSOLE, string.format("%s is already in the list!", arg_str))
			end
			--print("gotit: ", check_dmg_tbl[arg_str])
		end
	end
	if !hasvalue then ply:PrintMessage(HUD_PRINTCONSOLE, "That is not a valid damage type!") end
end
concommand.Add("sv_con_l4d2_add_exclude_damage", BlacklistDamage, TableBlacklistDamage )

local function RemoveBlacklistDamage(ply, cmd, args, args_str)
	local hasvalue = nil
	for _,arg in ipairs(args) do
		local arg_str = tostring(arg)
		if check_dmg_tbl[arg] then
			hasvalue = true
			--print(dmg_exclude_tbl[arg_str])
			--if dmg_exclude_tbl[arg_str] then
			if table.HasValue(dmg_exclude_tbl, arg_str) then
			local temp_tbl = { arg = arg_str }
			table.remove(dmg_exclude_tbl, temp_tbl[arg_str])
			ply:PrintMessage(HUD_PRINTCONSOLE, string.format("Successfully removed %s from the excluding list!", arg_str))
			else
			ply:PrintMessage(HUD_PRINTCONSOLE, string.format("%s is not in the list!", arg_str))
			end
			--print("gotit: ", check_dmg_tbl[arg_str])
		end
	end
	if !hasvalue then ply:PrintMessage(HUD_PRINTCONSOLE, "That is not a valid damage type!") end
end
concommand.Add("sv_con_l4d2_remove_exclude_damage", RemoveBlacklistDamage, TableBlacklistDamage )

local function ViewBlacklistDamage(ply, cmd, args)
	ply:PrintMessage(HUD_PRINTCONSOLE, table.ToString(dmg_exclude_tbl, "Damage Blacklist", true))
end
concommand.Add("sv_con_l4d2_view_exclude_damage", ViewBlacklistDamage )

local function ClearBlacklistDamage(ply, cmd, args)
	dmg_exclude_tbl = {}
	ply:PrintMessage(HUD_PRINTCONSOLE, "The damage excluding table has been cleared!")
end
concommand.Add("sv_con_l4d2_wipe_exclude_damage", ClearBlacklistDamage )

hook.Add("PhysgunPickup", "L4D2_DeathModel_PhysgunPickup", function(ply, ent)
	if ent:GetClass() == "survivor_death_model" and 
	(!ConVarExists("sv_l4d2_physgun_pickup") or GetConVar("sv_l4d2_physgun_pickup"):GetInt() <= 0) then
		return false
	end
end)

hook.Add("PlayerSwitchWeapon", "L4D2_DeathModel_Hide_Viewmodel", function( player )
	if IsValid(player) and player:Alive() and player.DeathModelPreventDrawViewModel then
		timer.Simple(0.01, function()
		player:DrawViewModel(false)
		end)
	end
end)

hook.Add("Tick", "L4D2_DeathModel_CheckIncap_Think", function()
	if (!ConVarExists("sv_l4d2_death_model") or GetConVar("sv_l4d2_death_model"):GetInt() > 0) then
	for _,ent in pairs(player.GetAll()) do
		if IsValid(ent) and ent:Alive() then
			if IsValid(ent.DeathModelGetUp) then
			if ent.WOS_InLastStand == true then
				ent.DeathModelGetUp:Remove()
				if ent:GetNoDraw() then 
				ent:SetNoDraw(false)
				end
				ent.DeathModelOwnerNoDraw = nil
				return
			end
			ent.DeathModelGetUp:SetPos(ent:GetPos())
			local p_ang = ent:GetAngles()
			ent.DeathModelGetUp:SetAngles( Angle(0, p_ang.y, p_ang.r) )
			end
			if IsValid(ent.DeathModelDefibAnim) then
			ent.DeathModelDefibAnim:SetPos(ent:GetPos())
			local p_ang = ent:GetAngles()
			ent.DeathModelDefibAnim:SetAngles( Angle(0, p_ang.y, p_ang.r) )
			end
		end
		if IsValid(ent) and ent:Alive() and ent.WOS_InLastStand == true and ent.DeathModelIncapDeath != true then
			ent.DeathModelIncapDeath = true
			--print("yes")
		elseif IsValid(ent) and (!ent:Alive() or ent.WOS_InLastStand != true) and ent.DeathModelIncapDeath == true then
			ent.DeathModelIncapDeath = nil
			--print("no")
		end
	end
	end
end)

hook.Add("DoPlayerDeath", "L4D2_DeathModel_Ignite_Mark", function( player, attacker, dmg )
	if (!ConVarExists("sv_l4d2_body_burn") or GetConVar("sv_l4d2_body_burn"):GetInt() > 0) then
		if player:IsOnFire() then
			--print("OnFire")
			player.DeathModelBurningDeath = true
		end
	end
	player.DeathModelStoredDmgInfo = dmg
	if (!ConVarExists("sv_l4d2_death_scream") or GetConVar("sv_l4d2_death_scream"):GetInt() > 0) then
		local cvar_snd_num = player:GetInfoNum("cl_l4d2_death_scream", -1)
		if cvar_snd_num > 7 then
		cvar_snd_num = table.Random({0,1,2,3,4,5,6,7})
		end
		if cvar_snd_num == 0 then
		player:EmitSound(string.format("player/survivor/voice/Gambler/HurtCritical0%i.wav",table.Random({1,2,3,4,5,6,7})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 1 then
		player:EmitSound(string.format("player/survivor/voice/Producer/HurtCritical0%i.wav",table.Random({1,2,3,4})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 2 then
		player:EmitSound(string.format("player/survivor/voice/Coach/HurtCritical0%i.wav",table.Random({1,2,3,4,5,6,7,8})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 3 then
		player:EmitSound(string.format("player/survivor/voice/Mechanic/HurtCritical0%i.wav",table.Random({1,2,3,4,5,6})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 4 then
		player:EmitSound(string.format("player/survivor/voice/NamVet/HurtCritical0%i.wav",table.Random({1,2,3,4,5,6,7,8,9})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 5 then
		player:EmitSound(string.format("player/survivor/voice/TeenGirl/HurtCritical0%i.wav",table.Random({1,2,3,4,5,6,7})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 6 then
		player:EmitSound(string.format("player/survivor/voice/Biker/HurtCritical%02d.wav",table.Random({1,2,3,4,5,6,7,8,9,10,11})), 75, 100, 1, CHAN_AUTO)
		elseif cvar_snd_num == 7 then
		player:EmitSound(string.format("player/survivor/voice/Manager/HurtCritical0%i.wav",table.Random({1,2,3,4,5})), 75, 100, 1, CHAN_AUTO)
		end
	end
end)

local LatestBody = nil

hook.Add("PostPlayerDeath", "L4D2_DeathModel_Replace", function( player )
	if (!ConVarExists("sv_l4d2_death_model") or GetConVar("sv_l4d2_death_model"):GetInt() > 0) then
	local prevent_spawn = nil
	if player.DeathModelStoredDmgInfo != nil and !table.IsEmpty(dmg_exclude_tbl) then
		for _,key in ipairs(dmg_exclude_tbl) do
			--print(key)
			if player.DeathModelStoredDmgInfo:IsDamageType(key) then
				prevent_spawn = true
				--print("prevent_spawn")
				break
			end
		end
	end
	local rag = player:GetRagdollEntity()
		if IsValid(rag) and !prevent_spawn then
		rag:Remove()
		if util.IsValidModel(player:GetModel()) and util.IsValidRagdoll(player:GetModel()) then
		local deathmdl = ents.Create("survivor_death_model")
			deathmdl:SetPos( player:GetPos() )
			local p_ang = player:GetAngles()
			deathmdl:SetAngles( Angle(0, p_ang.y, p_ang.r) )
			deathmdl.DeathModelString = player:GetModel()
			deathmdl.DeathModelOwner = player
			if player.DeathModelIncapDeath == true then
			deathmdl.DeathModelAnimType = 1
			else
			deathmdl.DeathModelAnimType = 0
			end
			player.DeathModelIncapDeath = nil
			if (!ConVarExists("sv_l4d2_body_burn") or GetConVar("sv_l4d2_body_burn"):GetInt() > 0) then
				if player.DeathModelBurningDeath == true then
					deathmdl.DeathModelBurningDeath = true
					deathmdl.DeathModelCannotRevive = true
				end
			end
			player.DeathModelBurningDeath = nil
			if IsValid(LatestBody) then
				LatestBody.DeathModelIsLatest = nil
			end
			LatestBody = deathmdl
			deathmdl.DeathModelIsLatest = true
			deathmdl:Spawn()
			deathmdl:Activate()
		end
		end
	end
	if IsValid(player.DeathModelGetUp) then
		player.DeathModelGetUp:Remove()
	end
	if IsValid(player.DeathModelDefibAnim) then
		player.DeathModelDefibAnim:Remove()
	end
end)

hook.Add("OnNPCKilled", "L4D2_DeathModel_Replace_NPC", function( npc, attacker, inflictor )
	if (ConVarExists("sv_l4d2_npc_death_model") and GetConVar("sv_l4d2_npc_death_model"):GetBool()) then
		if util.IsValidModel(npc:GetModel()) and util.IsValidRagdoll(npc:GetModel()) then
		local deathmdl = ents.Create("survivor_death_model")
			deathmdl:SetPos( npc:GetPos() )
			local p_ang = npc:GetAngles()
			deathmdl:SetAngles( Angle(0, p_ang.y, p_ang.r) )
			deathmdl.DeathModelString = npc:GetModel()
			deathmdl.DeathModelOwner = npc
			deathmdl.DeathModelNPCString = npc:GetClass()
			--deathmdl.DeathModelNPC_Velocity = npc:GetVelocity()
			npc.DeathModelIncapDeath = nil
			npc.NPC_SpawnedDeathModel = true
			--[[if GetConVar("sv_l4d2_body_burn"):GetInt() > 0 then
				if npc.DeathModelBurningDeath == true then
					deathmdl.DeathModelBurningDeath = true
					deathmdl.DeathModelCannotRevive = true
				end
			end--]]
			deathmdl:Spawn()
			deathmdl:Activate()
		end
	end
end)
hook.Add("CreateEntityRagdoll", "L4D2_DeathModel_Replace_NPC", function( npc, ragdoll )
	if (!ConVarExists("sv_l4d2_npc_death_model") or GetConVar("sv_l4d2_npc_death_model"):GetInt() > 0) then
		if IsValid(ragdoll) and npc.NPC_SpawnedDeathModel then
			ragdoll:Remove()
		end
	end
end)

hook.Add("PlayerSpawn", "L4D2_DeathModel_Remove", function( player )
	if (!ConVarExists("sv_l4d2_death_model") or GetConVar("sv_l4d2_death_model"):GetInt() > 0) and 
	(!ConVarExists("sv_l4d2_respawn_remove_body") or GetConVar("sv_l4d2_respawn_remove_body"):GetInt() > 0) then
	for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetClass() == "survivor_death_model" and ent.DeathModelOwner == player then
			ent:Remove()
		end
	end
	end
	for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and (ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_dynamic_override") and --ent.DeathModelLeftOvers and 
		ent.DeathModelOwner == player then
			ent:Remove()
		end
	end
	--[[for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent.DeathModelBurningDeath == true and ent.DeathModelOwner == player and ent:GetClass() == "survivor_death_model" then
			ent:Remove()
		end
	end--]]
	if (!ConVarExists("sv_l4d2_body_burn") or GetConVar("sv_l4d2_body_burn"):GetInt() > 0) then
	net.Start("L4D2_DeathModel_BeginRemoveRagdoll")
	net.WriteEntity(player)
	net.Broadcast()
	end
end)

hook.Add("PlayerDisconnected", "L4D2_DeathModel_Disconnect_Remove", function( player )
	if (!ConVarExists("sv_l4d2_death_model") or GetConVar("sv_l4d2_death_model"):GetInt() > 0) and 
	(!ConVarExists("sv_l4d2_respawn_remove_body") or GetConVar("sv_l4d2_respawn_remove_body"):GetInt() > 0) then
	for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetClass() == "survivor_death_model" and ent.DeathModelOwner == player then
			ent:Remove()
		end
	end
	end
	for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and (ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_dynamic_override") and --ent.DeathModelLeftOvers and 
		ent.DeathModelOwner == player then
			ent:Remove()
		end
	end
	if (!ConVarExists("sv_l4d2_body_burn") or GetConVar("sv_l4d2_body_burn"):GetInt() > 0) then
	net.Start("L4D2_DeathModel_BeginRemoveRagdoll")
	net.WriteEntity(player)
	net.Broadcast()
	end
end)

net.Receive("L4D2_DeathModel_RemoveEntity", function() 
	local ent = net.ReadEntity()
	if IsValid(ent) and (ent:GetClass() == "survivor_death_model" 
	--or (ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_dynamic_override")
	) then
		ent:Remove()
	end
end)

net.Receive("L4D2_DeathModel_SetUnlivingOwnerToPosition", function() 
	local ent = net.ReadEntity()
	local owner = ent.DeathModelOwner
	if IsValid(ent) and ent:GetClass() == "survivor_death_model" and 
	IsValid(owner) and owner:IsPlayer() and !owner:Alive() then
		if owner:GetInfoNum("cl_l4d2_body_camera", 0) > 0 then
		owner:SetPos(ent:GetPos())
		end
		if IsValid(ent.VisModel) and --!ent.VisModel.DeathModelLeftOvers and 
		(ent.VisModel:GetClass() == "prop_dynamic" or ent.VisModel:GetClass() == "prop_dynamic_override") then
			ent.VisModel:Remove()
			--[[ent.VisModel.DeathModelOwner = owner
			ent.VisModel.DeathModelLeftOvers = true
			timer.Simple(0.2, function() 
				if IsValid(ent) and IsValid(ent.VisModel) then 
				ent.VisModel:Extinguish() ent.VisModel:SetParent(nil) ent:Remove() ent.VisModel:SetNoDraw(true)
				end
			end)--]]
		end
		timer.Simple(0.2, function() 
			if IsValid(ent) then 
			ent:Remove()
			end
		end)
	end
end)
