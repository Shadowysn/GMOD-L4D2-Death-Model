AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:AcceptInput( input, activator, caller, param )
	local input_compare = string.lower(input)
	
	if input_compare == "defib" then
		self:RespawnOwner()
		return true
	elseif input_compare == "shock" then
		self:ResetSequence("defib_jolt")
		local function ShockEffect()
			if !IsValid(self) or !IsValid(self.VisModel) then return end
			local effect = EffectData()
			effect:SetOrigin(self:GetPos())
			effect:SetStart(self:GetPos())
			effect:SetMagnitude(2)
			effect:SetEntity(self.VisModel)
			util.Effect("teslaHitBoxes",effect)
		end
		timer.Simple(0.07, function()
			timer.Create("L4D2_DeathModel_ShockEffect", 0.01, 3, function()
				ShockEffect()
			end)
		end)
		return true
	end
end

function ENT:Initialize() 
	local function GetOwnerSetVelocity(owner, velocity)
		if GetConVar("sv_l4d2_body_keepvelocity"):GetInt() > 0 then 
			local getvel = velocity
			local limit = 250
			if getvel.x > limit then getvel.x = limit end
			if getvel.x < -limit then getvel.x = -limit end
			if getvel.y > limit then getvel.y = limit end
			if getvel.y < -limit then getvel.y = -limit end
			self:SetVelocity(Vector(getvel.x, getvel.y, getvel.z))
		end
	end
	
	if IsValid(self.DeathModelOwner) and self.DeathModelOwner:IsPlayer() then
	local cvar_anim_num = self.DeathModelOwner:GetInfoNum("cl_l4d2_body_animation", 0)
	if cvar_anim_num != nil then
		self.DeathModelUseSurvivor = cvar_anim_num
	end
	self.DeathModelCannotRevive = true
	timer.Simple(0.5, function()
	if self.DeathModelBurningDeath != true then
		self.DeathModelCannotRevive = nil
	end
	end)
	end
	self:SetClientModelAnim()
	self:InitPhysics()
	self:DoRagdoll()
	--timer.Simple(0, function()
	if IsValid(self.DeathModelOwner) then
		self:SetNWEntity("L4D2_DeathModel_SharedOwner", self.DeathModelOwner)
		if self.DeathModelOwner:IsPlayer() then
			GetOwnerSetVelocity(self.DeathModelOwner, self.DeathModelOwner:GetVelocity())
			--timer.Simple(0, function()
			if self.DeathModelAnimType == 1 then
				if self:GetModel() == "models/defib/survivor_teenangst.mdl" and table.Random({1,2}) == 2 then
					self:ResetSequence( "Die_Incap" )
					self:SetPlaybackRate(0)
					timer.Simple(0.1,function()
						if !IsValid(self) then return end
						self:ResetSequence( "Death" )
						self:SetPlaybackRate(99999999999999999999)
					end)
				else
					self:ResetSequence( "Die_Incap" )
					net.Start("L4D2_DeathModel_SetClientSideAnimation")
					net.WriteEntity(self)
					net.Broadcast()
				end
			else
				if GetConVar("sv_l4d2_bonus_features"):GetBool() and table.Random({1,2}) == 2 then
					self:ResetSequence( "Death" )
				else
					self:ResetSequence( "Die_Standing" )
				end
				net.Start("L4D2_DeathModel_SetClientSideAnimation")
				net.WriteEntity(self)
				net.Broadcast()
			end
			if IsValid(self.DeathModelOwner:GetGroundEntity()) then
				self:SetGroundEntity(self.DeathModelOwner:GetGroundEntity())
			end
			--end)
			--if !self.DeathModelUseSurvivor then
			--self:SetPlaybackRate(0)
			--else
			--self:SetPlaybackRate(1)
			--end
		end
	end
	
	--[[if IsValid(self.DeathModelOwner) and self.DeathModelNPCString and self.DeathModelNPCString != nil then
		if self.DeathModelNPC_Velocity and self.DeathModelNPC_Velocity != nil then
		GetOwnerSetVelocity(self.DeathModelOwner, self.DeathModelNPC_Velocity)
		end
	end--]] -- This function does not work.
	if !IsValid(self.DeathModelOwner) or !self.DeathModelOwner:IsPlayer() then
		if GetConVar("sv_l4d2_bonus_features"):GetBool() and table.Random({1,2}) == 2 then
			self:ResetSequence( "Death" )
		else
			self:ResetSequence( "Die_Standing" )
		end
		--[[if self.DeathModelNPCString and self.DeathModelNPCString != nil then
			
		end--]]
	end
	--end)
	self:SpawnVisModel()
	if IsValid(self.VisModel) and self.DeathModelBurningDeath == true then
		self:BeginBurning()
	end
end

function ENT:InitPhysics()
	self:PhysicsDestroy()
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:SetMoveType(MOVETYPE_STEP)
	self:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
	--self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 16))
	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 14))
	self:SetFriction( 2 )
end

function ENT:SetClientModelAnim()
	local model = nil
	if self.DeathModelUseSurvivor == 8 then
		self.DeathModelUseSurvivor = table.Random({0,1,2,3,4,5,6,7})
	end
	if self.DeathModelUseSurvivor == 6 or self.DeathModelUseSurvivor == 7 then -- Francis + Louis
	model = Model("models/defib/survivor_biker.mdl")
	elseif self.DeathModelUseSurvivor == 5 then -- Zoey
	model = Model("models/defib/survivor_teenangst.mdl")
	elseif self.DeathModelUseSurvivor == 4 then -- Bill
	model = Model("models/defib/survivor_namvet.mdl")
	elseif self.DeathModelUseSurvivor == 3 then -- Ellis
	model = Model("models/defib/survivor_mechanic.mdl")
	elseif self.DeathModelUseSurvivor == 2 then -- Coach
	model = Model("models/defib/survivor_coach.mdl")
	elseif self.DeathModelUseSurvivor == 1 then -- Rochelle
	model = Model("models/defib/survivor_producer.mdl")
	else
	model = Model("models/defib/survivor_gambler.mdl") -- Nick (default)
	end
	self:SetModel(model)
	-- NICK=0 ROCHELLE=1 COACH=2 ELLIS=3 BILL=4 ZOEY=5 FRANCIS=6 LOUIS=7
end

function ENT:RespawnOwner()
	if !IsValid(self) or (!IsValid(self.DeathModelOwner) and !self.DeathModelNPCString) then return end
	
	local plyindex = self.DeathModelOwner:EntIndex()
	local ply = ents.GetByIndex(plyindex)
	timer.Simple(0.01, function()
		if IsValid(ply) and ply:IsPlayer() then
		ply:DrawViewModel(false)
		ply.DeathModelPreventDrawViewModel = true
		end
	end)
	timer.Simple(3, function()
		if IsValid(ply) and ply:IsPlayer() then
		ply:DrawViewModel(true)
		ply.DeathModelPreventDrawViewModel = nil
		end
	end)
	if SERVER then
	if IsValid(self.DeathModelOwner) then
		if self.DeathModelOwner:IsPlayer() then
		self.DeathModelOwner:DrawWorldModel(false)
		if self.DeathModelOwner:Alive() then
		self.DeathModelOwner:KillSilent()
		end
		self.DeathModelOwner:Spawn()
		end
		self.DeathModelOwner:SetPos(self:GetPos())
		local self_ang = self:GetAngles()
		if self.DeathModelOwner:IsPlayer() then
		self.DeathModelOwner:SetEyeAngles( Angle(0, self_ang.y, 0) )
		else
		self.DeathModelOwner:SetAngles(self_ang)
		end
		for k,v in pairs(self.VisModel:GetBodyGroups()) do
			self.DeathModelOwner:SetBodygroup(v.id,self.VisModel:GetBodygroup(v.id))
		end
		--if self.DeathModelOwner:GetViewEntity() == self.DeathModelOwner then
		--self.DeathModelOwner:ConCommand("thirdperson")
		--end
		if self.DeathModelOwner:IsPlayer() and self.DeathModelOwner:GetWalkSpeed() > 1 then
		self.DeathModelOwner.DefibModelStoredWalkSpeed = self.DeathModelOwner:GetWalkSpeed()
		self.DeathModelOwner:SetWalkSpeed(0.000000001)
		end
		if self.DeathModelOwner:IsPlayer() and self.DeathModelOwner:GetRunSpeed() > 1 then
		self.DeathModelOwner.DefibModelStoredRunSpeed = self.DeathModelOwner:GetRunSpeed()
		self.DeathModelOwner:SetRunSpeed(0.000000001)
		end
		if self.DeathModelOwner:IsPlayer() and self.DeathModelOwner:GetJumpPower() > 1 then
		self.DeathModelOwner.DefibModelStoredJumpPower = self.DeathModelOwner:GetJumpPower()
		self.DeathModelOwner:SetJumpPower(0.000000001)
		end
		self.DeathModelOwner:SetModel(self.VisModel:GetModel())
		--print(self.DeathModelOwner.DeathModelOwnerNoDraw)
		if !self.DeathModelOwner:GetNoDraw() then 
		self.DeathModelOwner:SetNoDraw(true)
		end
		self.DeathModelOwner.DeathModelOwnerNoDraw = true
		self.DeathModelOwner:Fire("AddOutput", string.format("health %i", self.DeathModelOwner:Health()/2) )
		
		if !IsValid(self.DeathModelOwner.DeathModelGetUp) then
		self.DeathModelOwner.DeathModelGetUp = ents.Create("prop_dynamic_override")
		local model = nil
		if self.DeathModelUseSurvivor == 3 then -- Ellis
		model = Model("models/defib/survivor_mechanic.mdl")
		elseif self.DeathModelUseSurvivor == 2 then -- Coach
		model = Model("models/defib/survivor_coach.mdl")
		elseif self.DeathModelUseSurvivor == 1 then -- Rochelle
		model = Model("models/defib/survivor_producer.mdl")
		else
		model = Model("models/defib/survivor_gambler.mdl") -- Nick (default)
		end
		self.DeathModelOwner.DeathModelGetUp:SetModel(model)
		self.DeathModelOwner.DeathModelGetUp:SetPos( self.DeathModelOwner:GetPos() )
		local p_ang = self.DeathModelOwner:GetAngles()
		self.DeathModelOwner.DeathModelGetUp:SetAngles( Angle(0, p_ang.y, p_ang.r) )
		self.DeathModelOwner.DeathModelGetUp:SetNoDraw(true)
		self.DeathModelOwner.DeathModelGetUp:Spawn()
		self.DeathModelOwner.DeathModelGetUp:Activate()
		self.DeathModelOwner.DeathModelGetUp:SetKeyValue("solid", "0")
		--self.DeathModelOwner.DeathModelGetUp:SetParent(self.DeathModelOwner)
		self.DeathModelOwner.DeathModelGetUp:Fire("SetAnimation", "defib_revive")
		end
		
		if !IsValid(self.DeathModelOwner.DeathModelGetUpProp) then
		local modelstr = self.VisModel:GetModel()
		self.DeathModelOwner.DeathModelGetUpProp = ents.Create("prop_dynamic_override")
		self.DeathModelOwner.DeathModelGetUpProp:SetModel(modelstr or "models/player/kleiner.mdl")
		if modelstr and modelstr != nil and (!util.IsValidModel(modelstr) or IsUselessModel(modelstr)) then
			self.DeathModelOwner.DeathModelGetUpProp:Remove()
			return
		end
		self.DeathModelOwner.DeathModelGetUpProp:SetPos( self.DeathModelOwner:GetPos() )
		local p_ang = self.DeathModelOwner:GetAngles()
		self.DeathModelOwner.DeathModelGetUpProp:SetAngles( Angle(0, p_ang.y, p_ang.r) )
		self.DeathModelOwner.DeathModelGetUpProp:SetSkin(self.DeathModelOwner:GetSkin())
		self.DeathModelOwner.DeathModelGetUpProp:SetMaterial(self.DeathModelOwner:GetMaterial())
		self.DeathModelOwner.DeathModelGetUpProp:SetColor(self.DeathModelOwner:GetColor())
		for k,v in pairs(self.DeathModelOwner:GetBodyGroups()) do
			self.DeathModelOwner.DeathModelGetUpProp:SetBodygroup(v.id,self.DeathModelOwner:GetBodygroup(v.id))
		end
		self.DeathModelOwner.DeathModelGetUpProp:Spawn()
		self.DeathModelOwner.DeathModelGetUpProp:Activate()
		self.DeathModelOwner.DeathModelGetUpProp:SetKeyValue("solid", "0")
		if IsValid(self.DeathModelOwner) and self.DeathModelOwner:IsPlayer() and IsValid(self.DeathModelOwner.DeathModelGetUp) then
		local attachments = self.DeathModelOwner.DeathModelGetUp:GetAttachments()
			if #attachments > 0 then
				self.DeathModelOwner.DeathModelGetUpProp:AddEffects(bit.bor(EF_PARENT_ANIMATES, EF_BONEMERGE))
				self.DeathModelOwner.DeathModelGetUpProp:SetParent(self.DeathModelOwner.DeathModelGetUp)
				self.DeathModelOwner.DeathModelGetUpProp:Fire("Setparentattachment", attachments[1].name)
			end
		end
		if self.DeathModelOwner:IsPlayer() then
		net.Start("L4D2_DeathModel_GetPlayerColor")
		net.WriteInt(self.DeathModelOwner.DeathModelGetUpProp:EntIndex(),32)
		net.WriteInt(self.DeathModelOwner:EntIndex(),32)
		net.WriteVector(self.DeathModelOwner:GetPlayerColor())
		net.WriteInt(self:EntIndex(),32)
		if IsValid(self.DeathModelOwner.DeathModelGetUpProp) and 
		IsValid(self.VisModel) and 
		self.DeathModelOwner.DeathModelGetUpProp:GetModel() == self.VisModel:GetModel() then
		net.WriteEntity(self.DeathModelOwner.DeathModelGetUpProp)
		net.WriteEntity(self.VisModel)
		--net.WriteBool(true)
		else
		net.WriteEntity(nil)
		net.WriteEntity(nil)
		--net.WriteBool(false)
		end
		net.Broadcast()
		
		net.Start("L4D2_DeathModel_SnapCameraToGetUp")
		net.WriteEntity(self.DeathModelOwner.DeathModelGetUpProp)
		net.Send(self.DeathModelOwner)
		end
		end
	--end
	--end
	--if IsValid(self.DeathModelOwner) and self.DeathModelOwner:Alive() and IsValid(self.DeathModelOwner.DeathModelGetUpProp) then
		local plyindex = self.DeathModelOwner:EntIndex()
		--self:SetNWBool("L4D2_DeathModel_GettingUp", true)
		timer.Simple(2.9, function()
			local ply = ents.GetByIndex(plyindex)
			net.Start("L4D2_DeathModel_GetPlayerColor")
			net.WriteInt(0,32)
			net.WriteInt(0,32)
			net.WriteVector(Vector(0,0,0))
			net.WriteInt(0,32)
			if IsValid(ply.DeathModelGetUpProp) and IsValid(ply) and ply.DeathModelGetUpProp:GetModel() == ply:GetModel() then
			net.WriteEntity(ply)
			net.WriteEntity(ply.DeathModelGetUpProp)
			else
			net.WriteEntity(nil)
			net.WriteEntity(nil)
			end
			net.Broadcast()
		end)
		timer.Simple(3, function()
			local ply = ents.GetByIndex(plyindex)
			if IsValid(ply) then
				if ply:IsPlayer() then
				ply:DrawWorldModel(true)
				if ply.DefibModelStoredWalkSpeed then
				ply:SetWalkSpeed(ply.DefibModelStoredWalkSpeed)
				end
				if ply.DefibModelStoredRunSpeed then
				ply:SetRunSpeed(ply.DefibModelStoredRunSpeed)
				end
				if ply.DefibModelStoredJumpPower then
				ply:SetJumpPower(ply.DefibModelStoredJumpPower)
				end
				if IsValid(ply.DeathModelGetUp) then
				ply.DeathModelGetUp:Remove()
				end
				if IsValid(ply.DeathModelGetUpProp) then
				ply.DeathModelGetUpProp:Remove()
				end
				end
				if (ply:IsPlayer() and ply:Alive() or ply:IsNPC() and ply:Health() > 0) and ply:GetNoDraw() and ply.DeathModelOwnerNoDraw then 
				ply:SetNoDraw(false)
				end
				if ply.DeathModelOwnerNoDraw then
				ply.DeathModelOwnerNoDraw = nil
				end
				--self:SetNWBool("L4D2_DeathModel_GettingUp", false)
				--ply:ConCommand("firstperson")
			end
		end)
		self:Remove()
	--end
	elseif self.DeathModelNPCString then
		local new_npc = ents.Create(self.DeathModelNPCString)
		new_npc:SetPos( self:GetPos() )
		new_npc:SetAngles( self:GetAngles() )
		new_npc:SetModel( self.VisModel:GetModel() )
		new_npc:Spawn()
		new_npc:Activate()
		new_npc:SetHealth( new_npc:GetMaxHealth()/2 )
		self:Remove()
	end
	end
	if IsValid(self.DeathModelOwner.DeathModelGetUpProp) then
		self.DeathModelOwner:SetNWEntity("L4D2_DeathModel_GettingUpEntity", self.DeathModelOwner.DeathModelGetUpProp)
	end
end

function ENT:SpawnVisModel()
	local modelstr = self.DeathModelString
		if IsValid(self.VisModel) then return end
		self.VisModel = ents.Create("prop_dynamic_override")
		self.VisModel:SetModel(modelstr or "models/player/kleiner.mdl")
		if modelstr and modelstr != nil and (!util.IsValidModel(modelstr) or IsUselessModel(modelstr)) then
			--timer.Simple(0.01, function()
			self:Remove()
			return
		--end)
		end
		self.VisModel:SetPos( self:GetPos() )
		self.VisModel:Spawn()
		self.VisModel:Activate()
		self.VisModel:SetKeyValue("solid", "0")
		self.VisModel:SetParent(self)
		local attachments = self:GetAttachments()
		if #attachments > 0 then
			self.VisModel:AddEffects(bit.bor(EF_PARENT_ANIMATES, EF_BONEMERGE))
			self.VisModel:Fire("Setparentattachment", attachments[1].name)
		end
	if IsValid(self.DeathModelOwner) then
	self.VisModel:SetSkin(self.DeathModelOwner:GetSkin())
	self.VisModel:SetMaterial(self.DeathModelOwner:GetMaterial())
	self.VisModel:SetColor(self.DeathModelOwner:GetColor())
	for k,v in pairs(self.DeathModelOwner:GetBodyGroups()) do
		self.VisModel:SetBodygroup(v.id,self.DeathModelOwner:GetBodygroup(v.id))
	end
		--[[local get_eyes = self.VisModel:LookupAttachment("eyes")
		if get_eyes > 0 then
		self.VisModel:SetEyeTarget(self.VisModel:GetAttachment(get_eyes).Pos)
		end--]]
	end
	--timer.Simple(0, function()
	if IsValid(self.VisModel) and 
	IsValid(self.DeathModelOwner) and self.DeathModelOwner:IsPlayer() and 
	self.DeathModelOwner:GetPlayerColor() and self.DeathModelOwner:GetPlayerColor() != nil then
		net.Start("L4D2_DeathModel_GetPlayerColor")
		net.WriteInt(self.VisModel:EntIndex(),32)
		net.WriteInt(self.DeathModelOwner:EntIndex(),32)
		net.WriteVector(self.DeathModelOwner:GetPlayerColor())
		net.WriteInt(self:EntIndex(),32)
		if IsValid(self.VisModel) and IsValid(self.DeathModelOwner) and self.VisModel:GetModel() == self.DeathModelOwner:GetModel() then
		net.WriteEntity(self.VisModel)
		net.WriteEntity(self.DeathModelOwner)
		--net.WriteBool(false)
		else
		net.WriteEntity(nil)
		net.WriteEntity(nil)
		--net.WriteBool(false)
		end
		net.Broadcast()
	end
	--end)
end

function ENT:BeginBurning()
	local function ColorSet(num)
		if IsValid(self.VisModel) and IsValid(self) then
		if !self.VisModel:IsOnFire() then--or self.VisModel.DeathModelLeftOvers then
			self.DeathModelBurningDeath = nil
			self.DeathModelCannotRevive = nil
			return
		end
		local prev_col = self.VisModel:GetColor()
		self.VisModel:SetColor(Color(prev_col.r-num,prev_col.g-num,prev_col.b-num,prev_col.a))
		self.DeathModelBurningDeath = true
		self.DeathModelCannotRevive = true
		end
	end
	self.VisModel:Ignite(30)
		timer.Simple(1.2, function() 
		ColorSet(37)
			timer.Simple(0.4, function() 
			ColorSet(36)
				timer.Simple(0.4, function() 
				ColorSet(37)

					timer.Simple(0.2, function() 
					ColorSet(37)
						timer.Simple(0.4, function() 
						ColorSet(36)
							timer.Simple(0.4, function() 
							ColorSet(37)
								timer.Simple(4, function() 
								if !IsValid(self) or !IsValid(self.VisModel) then return end
								self:Fire("BecomeRagdoll","",0)
								end)
							end)
						end)
					end)
					
				end)
			end)
		end)
end

function ENT:DoRagdoll()
	local cvar = GetConVar("sv_l4d2_body_ragdoll_timer"):GetFloat()
	--local cvar_float = GetConVar("sv_l4d2_body_ragdoll_timer"):GetInt()
	if !cvar or cvar == nil or cvar == 0 or cvar < 0 then return end
	timer.Simple(cvar, function()
		if IsValid(self) then
			self:Fire("BecomeRagdoll","",0)
			self.DeathModelCannotRevive = true
		end
	end)
end

function ENT:Think()
	if self:IsOnFire() then
	self:Extinguish()
		if IsValid(self.VisModel) then
		self.VisModel:Ignite(30)
		end
	end
	if !self.DeathModelBurningDeath and IsValid(self.VisModel) and self.VisModel:IsOnFire() then
	self.DeathModelBurningDeath = true
	self.DeathModelCannotRevive = true
	self:BeginBurning()
	end
	--[[if IsValid(self.VisModel) then
		local get_eyes = self.VisModel:LookupAttachment("eyes")
		if get_eyes > 0 then
		self.VisModel:SetEyeTarget(self.VisModel:GetAttachment(get_eyes).Pos)
		end
	end--]]
	self:NextThink( CurTime() )
	return true
	--self:NextThink( CurTime() )
	--return true
end