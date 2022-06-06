if (SERVER) then return end
	AddCSLuaFile()
	
	CreateClientConVar( "cl_l4d2_body_camera", 0, true, true, -- 1
		"Which camera mode should be used for dead bodies? 0 = Default, 1 = Third-Person Follow, 2 = First-Person Eyes" )
	CreateClientConVar( "cl_l4d2_defib_body_camera", 0, true, true, -- 2
		"Which camera mode should be used for defib-related actions? 0 = Default, 1 = First-Person Eyes" )
	CreateClientConVar( "cl_l4d2_defib_flash", 0, true, false, -- 3
		"Do the white flash effect upon being revived?" )
	CreateClientConVar( "cl_l4d2_body_animation", 0, true, true, -- 4
		"Which survivor to use for animation? 0 = Nick, 1 = Rochelle, 2 = Coach, 3 = Ellis, 4 = Bill, 5 = Zoey, 6 = Francis, 7 = Louis", 
		-1, 7)
	CreateClientConVar( "cl_l4d2_death_scream", 0, true, true, -- 5
		"Death hurt sound to use? -1 = None, 0 = Nick, 1 = Rochelle, 2 = Coach, 3 = Ellis, 4 = Bill, 5 = Zoey, 6 = Francis, 7 = Louis", 
		-1, 7)
	
	local GetBody = {}
	local bodyent = nil

	net.Receive( "L4D2_DeathModel_GetPlayerColor", function() 
		local body = net.ReadInt(32)
		local ply = net.ReadInt(32)
		local col = net.ReadVector()
		bodyent = ents.GetByIndex(net.ReadInt(32))
		local decal_ent = net.ReadEntity()
		local decal_source_ent = net.ReadEntity()
		--local do_for_ply = net.ReadBool()
		local ply_ent = ents.GetByIndex(ply)
		if IsValid(decal_ent) and IsValid(decal_source_ent) and decal_ent:GetModel() == decal_source_ent:GetModel() then
			decal_ent:SnatchModelInstance(decal_source_ent)
		end
		--if do_for_ply == true and IsValid(decal_ent) and IsValid(ply_ent) and ply_ent:IsPlayer() 
		--and decal_ent:GetModel() == ply_ent:GetModel() then
		--	ply_ent:SnatchModelInstance(decal_ent)
		--end
		if !ply or ply == nil then return end
		if !col or col == nil then return end
		GetBody = {body=body,ply=ply,col=col}
	end )
	
	net.Receive( "L4D2_DeathModel_SetClientSideAnimation", function()
		local body = ents.GetByIndex(net.ReadInt(32))
		if IsValid(body) and body:GetClass() == "survivor_death_model" then
			body:UseClientSideAnimation()
		end
	end)
	
	hook.Add("NetworkEntityCreated","L4D2_DeathModel_SetPlayerColor",function(ent)
		if not GetBody.body then return end
		if GetBody.body==ent:EntIndex() then
			local getcol = GetBody.col
			Entity(GetBody.body).GetPlayerColor = function(self) return getcol end
			GetBody = {}
		end
	end)
	
	hook.Add("DrawPhysgunBeam", "L4D2_DeathModel_DrawPhysgunBeam", function( ply ) 
		if IsValid(ply:GetNWEntity("L4D2_DeathModel_GettingUpEntity")) then
		return false
		end
	end)
	
	hook.Add("CreateClientsideRagdoll","L4D2_DeathModel_BecomeRagdoll",function(entity, ragdoll)
		--print(entity, ragdoll)
		--PrintTable(entity:GetSaveTable(true))
		if !IsValid(entity) or !IsValid(ragdoll) then return end
		if entity:GetClass() == "survivor_death_model" then
			ragdoll:Remove()
			for _,vismdl in pairs(entity:GetChildren()) do
				if IsValid(vismdl) and (vismdl:GetClass() == "prop_dynamic" or vismdl:GetClass() == "prop_dynamic_override") then
				vismdl:BecomeRagdollOnClient()
				net.Start("L4D2_DeathModel_SetUnlivingOwnerToPosition")
				net.WriteEntity(entity)
				net.SendToServer()
				--ragdoll.GetPlayerColor = function(self) return getcol end
				return
				end
			end
		end
		if IsValid(entity:GetParent()) and entity:GetParent():GetClass() == "survivor_death_model" then
			local bodyent_real = entity:GetParent()
			ragdoll.DeathModelClientRemove = true
			if IsValid(bodyent_real:GetNWEntity("L4D2_DeathModel_SharedOwner", nil)) then
			ragdoll.DeathModelOwnerIndex = bodyent_real:GetNWEntity("L4D2_DeathModel_SharedOwner", nil)
			ragdoll.GetPlayerColor = entity.GetPlayerColor
			end
			ragdoll.DeathModelEntity = bodyent_real
			ragdoll.DeathModelColorEnt = entity
		end
		if (!ConVarExists("sv_l4d2_npc_death_model") or GetConVar("sv_l4d2_npc_death_model"):GetInt() > 0) and entity:IsNPC() and util.IsValidModel(entity:GetModel()) and util.IsValidRagdoll(entity:GetModel()) then
			ragdoll:Remove()
		end
	end)
	
	net.Receive("L4D2_DeathModel_BeginRemoveRagdoll", function() 
		local player = net.ReadEntity()
		if !IsValid(player) then return end
		for _,rag in ipairs(ents.FindByClass("class C_ClientRagdoll")) do
			local index_ply = nil
			if IsValid(rag.DeathModelOwnerIndex) then
			index_ply = rag.DeathModelOwnerIndex
			end
			--print("rag.DeathModelClientRemove:", rag.DeathModelClientRemove)
			--print("index_ply:", index_ply)
			if rag.DeathModelClientRemove == true and IsValid(index_ply) and index_ply:IsPlayer() and index_ply == player then
			rag:Remove()
			end
			if IsValid(rag.DeathModelEntity) then
			net.Start("L4D2_DeathModel_RemoveEntity")
			net.WriteEntity(rag.DeathModelEntity)
			net.SendToServer()
			end
		end
	end)
	
	local colormodify_bloom = 0
	local colormodify_glow = 0
	
	hook.Add("RenderScreenspaceEffects", "L4D2_DeathModel_ScreenspaceEffects", function()
		if IsValid(LocalPlayer()) and LocalPlayer():IsPlayer() then
		if (!ConVarExists("cl_l4d2_defib_flash") or GetConVar("cl_l4d2_defib_flash"):GetInt() > 0) and IsValid(LocalPlayer():GetNWEntity("L4D2_DeathModel_GettingUpEntity")) then
			if colormodify_bloom < 1.5 then
			colormodify_bloom = colormodify_bloom + 0.01
			end
			if colormodify_glow < 0.20 then
			colormodify_glow = colormodify_glow + 0.01
			end
		else
			if colormodify_bloom > 0 then
			colormodify_bloom = colormodify_bloom - 0.01
			end
			if colormodify_glow > 0 then
			colormodify_glow = colormodify_glow - 0.01
			end
		end
			if colormodify_bloom > 0 then
			DrawBloom(
			0, -- Darken
			colormodify_bloom, -- Multiply
			4, -- Horizontal Blur
			4, -- Vertical Blur
			4, -- Passes
			1, -- Color Multiply
			1, -- Red
			1, -- Green
			1 -- Blue
			)
			end
			if colormodify_glow > 0 then
			local colormodify_table = {
			[ "$pp_colour_addr" ] = 0.01,
			[ "$pp_colour_addg" ] = 0.02,
			[ "$pp_colour_addb" ] = 0.02,
			[ "$pp_colour_brightness" ] = colormodify_glow,
			[ "$pp_colour_contrast" ] = 1.20,
			[ "$pp_colour_colour" ] = 1.00,
			[ "$pp_colour_mulr" ] = 0.00,
			[ "$pp_colour_mulg" ] = 0.01,
			[ "$pp_colour_mulb" ] = 0.01
			}
			DrawColorModify( colormodify_table )
			end
		end
	end)
	
	--[[hook.Add( "PreDrawHalos", "L4D2_DeathModel_AddHalos", function()
		if GetViewEntity()==LocalPlayer() and LocalPlayer():Alive() and LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon():GetClass()=="weapon_l4d_defibrillator" then
		for _,ent in pairs(ents.FindByClass("prop_dynamic*")) do
			if IsValid(ent) then
				if IsValid(ent:GetParent()) and ent:GetParent():GetClass() == "survivor_death_model" and !ent.HasDeathModelHalo then
				halo.Add( {ent}, Color( 255, 0, 0 ), 0, 0, 0, true, true )
				ent.HasDeathModelHalo == true
				ent:DrawModel()
				elseif IsValid(ent:GetParent()) and ent:GetParent():GetClass() == "survivor_death_model" and ent.HasDeathModelHalo then
				ent.HasDeathModelHalo == false
				end
			end
		end
		--halo.Add( {ents.FindByClass("prop_dynamic*")}, Color( 255, 0, 0 ), 2, 2, 0, true, true )
		end
	end)--]]
	
	local cam_visbody = nil
	net.Receive("L4D2_DeathModel_SnapCameraToGetUp", function()
		cam_visbody = net.ReadEntity()
		hook.Add("CalcView","L4D2_DeathModel_DefibGetUpCamera",function(ply, pos, angles, fov)
			local ent = GetViewEntity()
			if IsValid(ply) and ply:IsPlayer() and ply:Alive() and LocalPlayer()==ply and ent==ply and 
			IsValid(cam_visbody) and !cam_visbody:GetNoDraw() then
			if (!ConVarExists("cl_l4d2_defib_flash") or GetConVar("cl_l4d2_defib_body_camera"):GetInt() > 0) then
				local get_eyes = cam_visbody:LookupAttachment("eyes")
				if get_eyes > 0 then
				local getattachment = cam_visbody:GetAttachment(get_eyes)
				return {origin=getattachment.Pos,angles=getattachment.Ang,fov=fov,znear=znear}
				end
			else
				local hullbottom, hulltop = ply:GetHull()
				local rd = util.TraceLine({start=ply:GetPos(),endpos=ply:GetPos()-angles:Forward()*105,filter={ply,LocalPlayer()}})
				return {origin=Vector(ply:GetPos().x,ply:GetPos().y,ply:GetPos().z+hulltop.z)-angles:Forward()*(50*rd.Fraction),angles=angles,fov=fov,znear=0.5} 
			end
			end
		end)
	end)
