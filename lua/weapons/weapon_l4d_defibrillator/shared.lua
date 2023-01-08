
SWEP.AdminOnly = false
SWEP.ViewModelFOV = 60
SWEP.ViewModel = "models/v_models/defib/v_defibrillator.mdl"
SWEP.UseHands = true
SWEP.WorldModel = "models/w_models/weapons/defib/w_eq_defibrillator.mdl"
SWEP.AutoSwitchTo = false
SWEP.Slot = 2
SWEP.HoldType = "duel"
SWEP.PrintName = "Defibrillator"
SWEP.Author = "Shadowysn"
SWEP.Spawnable = true
SWEP.AutoSwitchFrom = false
SWEP.FiresUnderwater = true
SWEP.Weight = 5
SWEP.DrawCrosshair = true
SWEP.Category = "Left 4 Dead 2"
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.Instructions = "Left Click or Right Click = Defibrillate dead body"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.base = "weapon_base"

SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Automatic = true
SWEP.Secondary.Damage = 10
SWEP.Secondary.Force = 2
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	if CLIENT then
	hook.Add("CalcView","L4D2_DeathModel_DefibCamera",function(ply, pos, angles, fov)
		if !IsValid(self) or !IsValid(self.Owner) then return end
		if !self.Owner:Alive() or self.Owner!=ply then return end
		local ent = GetViewEntity()
		if ent!=ply then return end
		local defib_animprop = self.Owner:GetNWEntity("DefibrillatorAnimatedProp")
		if IsValid(defib_animprop) and GetConVar("cl_l4d2_defib_body_camera"):GetInt() > 0 then
			local get_eyes = defib_animprop:LookupAttachment("eyes")
			if get_eyes > 0 then
			local getattachment = defib_animprop:GetAttachment(get_eyes)
			--print(getpos)
			--print(getang)
			return {origin=getattachment.Pos,angles=getattachment.Ang,fov=fov,znear=znear}
			end
		elseif IsValid(defib_animprop) then
			local hullbottom, hulltop = self.Owner:GetHull()
			local rd = util.TraceLine({start=self.Owner:GetPos(),endpos=self.Owner:GetPos()-angles:Forward()*105,filter={self.Owner,LocalPlayer()}})
			return {origin=Vector(self.Owner:GetPos().x,self.Owner:GetPos().y,self.Owner:GetPos().z+hulltop.z)-angles:Forward()*(50*rd.Fraction),angles=angles,fov=fov,znear=0.5} 
		end
	end)
	end
	--self.DefibrillatorProgress = 0
	self:SetWeaponHoldType( self.HoldType )
end

function SWEP:ResetProgress(defibtarget)
	if self.HasFinishedReviving then return end
	if IsValid(self.Owner) then
		self.Owner:DrawViewModel(true)
	end
	if SERVER then
		if IsValid(self.Owner) then
			self.Owner:DrawWorldModel(true)
			if timer.Exists("L4D2_Defibrillator_ShockTimer_"..self.Owner:EntIndex()) then
				timer.Remove("L4D2_Defibrillator_ShockTimer_"..self.Owner:EntIndex())
			end
			if timer.Exists("L4D2_Defibrillator_RevivalTimer_"..self.Owner:EntIndex()) then
				timer.Remove("L4D2_Defibrillator_RevivalTimer_"..self.Owner:EntIndex())
			end
		end
		if IsValid(self.Owner) and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then
			self:SetNoDraw(true)
		end
		if IsValid(self.Owner) and self.Owner:GetNoDraw() and self.Owner.DefibModelNoDraw then
			self.Owner:SetNoDraw(false)
			self.Owner.DefibModelNoDraw = nil
		end
		
		--self.DefibrillatorProgress = 0
		self.DefibrillatorFailTarget = self.DefibrillatorTarget
		self.DefibrillatorTarget = nil
		self.RevivingBody = nil
		if IsValid(self.Owner) and self.Owner:GetWalkSpeed() <= 1 and self.DefibModelStoredWalkSpeed then
			self.Owner:SetWalkSpeed(self.DefibModelStoredWalkSpeed)
		end
		if IsValid(self.Owner) and self.Owner:GetRunSpeed() <= 1 and self.DefibModelStoredRunSpeed then
			self.Owner:SetRunSpeed(self.DefibModelStoredRunSpeed)
		end
		if IsValid(self.Owner) and self.Owner:GetJumpPower() <= 1 and self.DefibModelStoredJumpPower then
			self.Owner:SetJumpPower(self.DefibModelStoredJumpPower)
		end
		self.ReachedHalfwayState = nil
		if IsValid(self.Owner) and IsValid(self.Owner.DeathModelDefibAnim) then self.Owner.DeathModelDefibAnim:Remove() end
		if IsValid(self.Owner) and IsValid(self.Owner.DeathModelDefibAnimProp) then self.Owner.DeathModelDefibAnimProp:Remove() end
		
		if self.DefibrillatorSound then self.Owner:StopSound("L4D2_Defibrillator_StartSound") self.DefibrillatorSound = nil end
	end
end

function SWEP:BeginProgress(defibtarget)
	self.Owner:DrawViewModel(false)
	if SERVER then 
	self.Owner:SetNoDraw(true)
	self.Owner:DrawWorldModel(false)
	self.Owner.DefibModelNoDraw = true
	if IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then
	self:SetNoDraw(true)
	end
	if self.Owner:GetWalkSpeed() > 1 then
		self.DefibModelStoredWalkSpeed = self.Owner:GetWalkSpeed()
		self.Owner:SetWalkSpeed(0.000000001)
	end
	if self.Owner:GetRunSpeed() > 1 then
		self.DefibModelStoredRunSpeed = self.Owner:GetRunSpeed()
		self.Owner:SetRunSpeed(0.000000001)
	end
	if self.Owner:GetJumpPower() > 1 then
		self.DefibModelStoredJumpPower = self.Owner:GetJumpPower()
		self.Owner:SetJumpPower(0.000000001)
	end
	if !IsValid(self.Owner.DeathModelDefibAnim) then -- Animation Prop
		self.Owner.DeathModelDefibAnim = ents.Create("prop_dynamic_override")
		self.Owner.DeathModelDefibAnim:SetModel("models/defib/survivor_gambler.mdl")
			local cvar_anim_num = self.Owner:GetInfoNum("cl_l4d2_body_animation", 0)
			local model = nil
			if IsValid(self.Owner) and IsValid(self.Owner.DeathModelDefibAnim) and cvar_anim_num != nil then
				if cvar_anim_num == 3 then -- Ellis
				model = Model("models/defib/survivor_mechanic.mdl")
				elseif cvar_anim_num == 2 then -- Coach
				model = Model("models/defib/survivor_coach.mdl")
				elseif cvar_anim_num == 1 then -- Rochelle
				model = Model("models/defib/survivor_producer.mdl")
				else
				model = Model("models/defib/survivor_gambler.mdl")
				end
			else
			model = Model("models/defib/survivor_gambler.mdl") -- Nick (default)
			end
			self.Owner.DeathModelDefibAnim:SetModel(model)
			if self.Owner:Crouching() then
			self.Owner.DeathModelDefibAnim:Fire("SetAnimation", "ACT_TERROR_CROUCH_USE_DEFIBRILLATOR")
			else
			self.Owner.DeathModelDefibAnim:Fire("SetAnimation", "ACT_TERROR_USE_DEFIBRILLATOR")
			end
		self.Owner.DeathModelDefibAnim:SetPos( self.Owner:GetPos() )
		local p_ang = self.Owner:GetAngles()
		self.Owner.DeathModelDefibAnim:SetAngles( Angle(0, p_ang.y, p_ang.r) )
		self.Owner.DeathModelDefibAnim:SetNoDraw(true)
		self.Owner.DeathModelDefibAnim:Spawn()
		self.Owner.DeathModelDefibAnim:Activate()
		self.Owner.DeathModelDefibAnim:SetKeyValue("solid", "0")
		--self.Owner.DeathModelDefibAnim:SetParent(self.Owner)
		if self.Owner:Crouching() then
			self.Owner.DeathModelDefibAnim:Fire("SetAnimation", "ACT_TERROR_CROUCH_USE_DEFIBRILLATOR")
		else
			self.Owner.DeathModelDefibAnim:Fire("SetAnimation", "ACT_TERROR_USE_DEFIBRILLATOR")
		end
	end
	if !IsValid(self.Owner.DeathModelDefibAnimProp) then -- Visible Prop
		local modelstr = self.Owner:GetModel()
		self.Owner.DeathModelDefibAnimProp = ents.Create("prop_dynamic_override")
		self.Owner.DeathModelDefibAnimProp:SetModel(modelstr or "models/player/kleiner.mdl")
		if modelstr and modelstr != nil and (!util.IsValidModel(modelstr) or IsUselessModel(modelstr)) then
		self.Owner.DeathModelDefibAnimProp:Remove()
		return
		end
		self.Owner.DeathModelDefibAnimProp:SetPos( self.Owner:GetPos() )
		local p_ang = self.Owner:GetAngles()
		self.Owner.DeathModelDefibAnimProp:SetAngles( Angle(0, p_ang.y, p_ang.r) )
		self.Owner.DeathModelDefibAnimProp:SetSkin(self.Owner:GetSkin())
		self.Owner.DeathModelDefibAnimProp:SetMaterial(self.Owner:GetMaterial())
		self.Owner.DeathModelDefibAnimProp:SetColor(self.Owner:GetColor())
		for k,v in pairs(self.Owner:GetBodyGroups()) do
			self.Owner.DeathModelDefibAnimProp:SetBodygroup(v.id,self.Owner:GetBodygroup(v.id))
		end
		self.Owner.DeathModelDefibAnimProp:Spawn()
		self.Owner.DeathModelDefibAnimProp:Activate()
		self.Owner.DeathModelDefibAnimProp:SetKeyValue("solid", "0")
		if IsValid(self.Owner.DeathModelDefibAnim) then
		local attachments = self.Owner.DeathModelDefibAnim:GetAttachments()
		if #attachments > 0 then
			self.Owner.DeathModelDefibAnimProp:AddEffects(bit.bor(EF_PARENT_ANIMATES, EF_BONEMERGE))
			self.Owner.DeathModelDefibAnimProp:SetParent(self.Owner.DeathModelDefibAnim)
			self.Owner.DeathModelDefibAnimProp:Fire("Setparentattachment", attachments[1].name)
		end
		end
		net.Start("L4D2_DeathModel_GetPlayerColor")
		net.WriteInt(self.Owner.DeathModelDefibAnimProp:EntIndex(),32)
		net.WriteInt(self.Owner:EntIndex(),32)
		net.WriteVector(self.Owner:GetPlayerColor())
		net.WriteInt(self.DefibrillatorTarget:EntIndex(),32)
		net.Send(player.GetAll())
	end
	if !self.DefibrillatorSound then
	self.Owner:EmitSound("L4D2_Defibrillator_StartSound")
	self.DefibrillatorSound = true
	end
	--self.DefibrillatorProgress = self.DefibrillatorProgress + 1
	if !self.ReachedHalfwayState and !timer.Exists("L4D2_Defibrillator_ShockTimer_"..self.Owner:EntIndex()) and GetConVar("sv_l4d2_defib_time"):GetFloat() > 1.5 then
		timer.Create("L4D2_Defibrillator_ShockTimer_"..self.Owner:EntIndex(), 1.5, 1, function()
		if IsValid(defibtarget) and IsValid(self) and IsValid(self.Owner) then --and self.DefibrillatorProgress == 100 then
			self.ReachedHalfwayState = true
			defibtarget:Input("Shock")
			defibtarget:EmitSound("weapons/defibrillator/defibrillator_use.wav")
			self.Owner:StopSound("L4D2_Defibrillator_StartSound")
		end
		end)
	end
	if !timer.Exists("L4D2_Defibrillator_RevivalTimer_"..self.Owner:EntIndex()) then
		timer.Create("L4D2_Defibrillator_RevivalTimer_"..self.Owner:EntIndex(), GetConVar("sv_l4d2_defib_time"):GetFloat() or 3, 1, function()
			if IsValid(defibtarget) and IsValid(self) and IsValid(self.Owner) then --and self.DefibrillatorProgress >= 212 then
				if IsValid(defibtarget.DeathModelOwner) or defibtarget.DeathModelNPCString
				--and !defibtarget.DeathModelOwner:Alive() 
				then
					defibtarget:RespawnOwner()
					self.HasFinishedReviving = true
					if self.Owner != defibtarget.DeathModelOwner then
						if IsValid(defibtarget.DeathModelOwner) and defibtarget.DeathModelOwner:IsPlayer() then
							defibtarget.DeathModelOwner:DrawWorldModel(false)
						end
						if self.Owner:GetNoDraw() and self.Owner.DefibModelNoDraw == true then
							self.Owner:SetNoDraw(false) self.Owner.DefibModelNoDraw = nil
						end
						if self.Owner:GetWalkSpeed() <= 1 and self.DefibModelStoredWalkSpeed then
							self.Owner:SetWalkSpeed(self.DefibModelStoredWalkSpeed)
						end
						if self.Owner:GetRunSpeed() <= 1 and self.DefibModelStoredRunSpeed then
							self.Owner:SetRunSpeed(self.DefibModelStoredRunSpeed)
						end
						if self.Owner:GetJumpPower() <= 1 and self.DefibModelStoredJumpPower then
							self.Owner:SetJumpPower(self.DefibModelStoredJumpPower)
						end
					end
					self.Owner.DeathModelDefibAnimProp:Remove()
					self.Owner.DeathModelDefibAnim:Remove()
					self:Remove()
				end
			end
		end)
	end
	--print(self.DefibrillatorProgress)
	--self.Owner:ChatPrint(self.DefibrillatorProgress)
	end
	self.Owner:SetNWEntity("DefibrillatorAnimatedProp", self.Owner.DeathModelDefibAnimProp)
end

function SWEP:Think()
	if self.HasFinishedReviving then return end
	if SERVER then
	if IsValid(self.Owner) and !IsValid(self.DefibVisModel) then 
	-- ^ This function is needed to snap defib worldmodel back to player, due to original being deleted upon the animated prop's removal
	self.DefibVisModel = ents.Create("defib_worldmodel")
	self.DefibVisModel:SetOwner( self.Owner )
	self.DefibVisModel:SetParent( self.Owner ) 
	self.DefibVisModel:SetPos( self:GetPos() )
	self.DefibVisModel:Spawn()
	self.DefibVisModel:Activate()
	end
	end
	if self.Owner:KeyDown(IN_ATTACK) or self.Owner:KeyDown(IN_ATTACK2) then
		--[[for T,ent in pairs( ents.FindInCone( self.Owner:EyePos(), self.Owner:GetAimVector(), 50, 0.79 ) ) do
			if IsValid(ent) and ent != self.Owner and ent:GetClass() == "survivor_death_model" and 
			ent.DeathModelOwner and IsValid(ent.DeathModelOwner) and ent.DeathModelOwner:IsPlayer()
			then
			self.DefibrillatorTarget = ent
			return
			end
		end--]]
		local trace = util.TraceLine( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + ( self.Owner:GetAimVector() * 100 ),
			filter = self.Owner,
			mask = MASK_ALL
		} )
		local tgt = trace.Entity --print(tgt)
		if IsValid(tgt) and tgt != self.Owner and tgt:GetClass() == "survivor_death_model" and 
		(IsValid(tgt.DeathModelOwner) and tgt.DeathModelOwner:IsPlayer() or tgt.DeathModelNPCString) and 
		tgt.DeathModelCannotRevive != true and
		(tgt:GetPos()-self.Owner:GetPos()):Length() <= 90 and 
		(self.DefibrillatorTarget == nil or self.DefibrillatorFailTarget == tgt) then
			self.DefibrillatorTarget = tgt
		elseif self.ReachedHalfwayState and IsValid(self.DefibrillatorTarget) and self.DefibrillatorTarget != self.Owner and 
		self.DefibrillatorTarget:GetClass() == "survivor_death_model" and 
		IsValid(self.DefibrillatorTarget.DeathModelOwner) and self.DefibrillatorTarget.DeathModelOwner:IsPlayer() and 
		self.DefibrillatorTarget.DeathModelCannotRevive != true and 
		(self.DefibrillatorTarget:GetPos()-self.Owner:GetPos()):Length() <= 90 then
			-- Leave self.DefibrillatorTarget alone
		elseif !IsValid(tgt) or tgt.DeathModelCannotRevive == true or 
		(self.DefibrillatorFailTarget != nil and self.DefibrillatorFailTarget != tgt) or 
		tgt != self.DefibrillatorTarget or (tgt:GetPos()-self.Owner:GetPos()):Length() > 90 then
			self.DefibrillatorTarget = nil
		end
		--[[tr = util.TraceHull( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 80,
		filter = self.Owner,
		mins = Vector( -16, -16, 0 ),
		maxs = Vector( 16, 16, 0 ),
		mask = MASK_ALL
		} )
		if IsValid(tr.Entity) and tr.Entity != self.Owner and tr.Entity:GetClass() == "survivor_death_model" and 
		tr.Entity.DeathModelOwner and IsValid(tr.Entity.DeathModelOwner) and tr.Entity.DeathModelOwner:IsPlayer() 
		then
			self.DefibrillatorTarget = tr.Entity
		end--]]
	end
	if ((!self.Owner:KeyDown(IN_ATTACK) and !self.Owner:KeyDown(IN_ATTACK2))) or 
	!IsValid(self.DefibrillatorTarget) or !self.Owner:IsFlagSet(FL_ONGROUND) or 
	(GetConVar("sv_l4d2_defib_alive_prevent"):GetInt() > 0 and IsValid(self.DefibrillatorTarget) and self.DefibrillatorTarget.DeathModelOwner:Alive()) or 
	self.Owner.WOS_InLastStand == true or IsValid(self.Owner.DeathModelGetUp) or IsValid(self.Owner.DeathModelGetUpProp)
	then
		self:ResetProgress(self.DefibrillatorTarget)
	end
	if self.DefibrillatorTarget and IsValid(self.DefibrillatorTarget) and 
	self.DefibrillatorTarget:GetClass() == "survivor_death_model" then
		if self.RevivingBody!=true then self.RevivingBody=true end
		self:BeginProgress(self.DefibrillatorTarget)
	end
	
	self:NextThink( CurTime() + 0.1 )
end

function SWEP:PrimaryAttack()
	if ( !self:CanPrimaryAttack() ) then return end
	if self.RevivingBody then return end
	--[[local tracerange = (trace.HitPos-trace.StartPos):Length()
	if tracerange < PickupRange then
		PickupRange = tracerange+30
	end--]]
	--self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SecondaryAttack()
	if ( !self:CanSecondaryAttack() ) then return end
	if self.RevivingBody or self.HasFinishedReviving then return end
	if self.Owner.WOS_InLastStand then return end
	local tr = util.TraceLine( {
	start = self.Owner:GetShootPos(),
	endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 80,
	filter = self.Owner,
	mask = MASK_SHOT_HULL
	} )
	if !IsValid( tr.Entity ) then
	tr = util.TraceHull( {
	start = self.Owner:GetShootPos(),
	endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 80,
	filter = self.Owner,
	mins = Vector( -16, -16, 0 ),
	maxs = Vector( 16, 16, 0 ),
	mask = MASK_SHOT_HULL
	} )
	end
	if SERVER then
		if IsValid( tr.Entity ) then
			local dmg = DamageInfo()
			local attacker = self.Owner
			if !IsValid( attacker ) then
				attacker = self
			end
			dmg:SetAttacker( attacker )
			dmg:SetInflictor( self )
			dmg:SetDamage( self.Secondary.Damage )
			dmg:SetDamageType( DMG_CLUB )
			dmg:SetDamageForce( self.Owner:GetForward() * self.Secondary.Force )
			tr.Entity:TakeDamageInfo( dmg )
			if tr.Entity:IsNPC() || tr.Entity:IsPlayer() then
				tr.Entity:SetVelocity( self.Owner:GetAimVector() * Vector( 1500, 1500, 0 ) )
			end
		end
		local rand_swing = nil
		if !tr.Hit then
			local swingnothing = { 5, 6 }
			rand_swing = table.Random( swingnothing )
			self.Owner:EmitSound(string.format("player/survivor/swing/swish_weaponswing_swipe%i.wav",rand_swing), 75, 100, 0.7)
		end
		if tr.Hit then
			if tr.Entity:IsNPC() || tr.Entity:IsPlayer() then
				local swinginfected = { 7, 8, 9, 10, 11, 12 }
				rand_swing = table.Random( swinginfected )
				--local swinginf_string = "player/survivor/hit/rifle_swing_hit_infected"
				self.Owner:EmitSound(string.format("player/survivor/hit/rifle_swing_hit_infected%i.wav",rand_swing), 75, 100, 0.7)
			end
			if !( tr.Entity:IsNPC() || tr.Entity:IsPlayer() ) then
				self.Owner:EmitSound("player/survivor/hit/rifle_swing_hit_world.wav")
			end
		end
	end
	self.Owner:GetViewModel():SendViewModelMatchingSequence(self:LookupSequence("ACT_VM_MELEE"))
	--[[local sound_random = { 1, 2 }
	if sound_random == 1 then
		self.Owner:EmitSound("player/survivor/swing/swish_weaponswing_swipe5.wav")
	else
		self.Owner:EmitSound("player/survivor/swing/swish_weaponswing_swipe6")
	end--]]
	self.Owner:DoAnimationEvent( ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND )
	--self.Owner:SetAnimation(ACT_MELEE_ATTACK1)
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.8 )
end

function SWEP:Holster()
	if SERVER then
	if IsValid(self.DefibVisModel) then
		self.DefibVisModel:Remove()
	end
	end
	self:ResetProgress()
	return true
end

function SWEP:Deploy()
	self.Weapon:SendWeaponAnim( ACT_VM_DEPLOY )
	self.Weapon:SetNoDraw(true)
	if SERVER then
	if !IsValid(self.DefibVisModel) then
	self.DefibVisModel = ents.Create("defib_worldmodel")
	self.DefibVisModel:SetOwner( self.Owner )
	self.DefibVisModel:SetParent( self.Owner ) 
	self.DefibVisModel:SetPos( self:GetPos() )
	self.DefibVisModel:Spawn()
	self.DefibVisModel:Activate()
	--[[local attachments = self:GetAttachments()
	if #attachments > 0 then
		self.DefibVisModel:SetKeyValue("solid", "0")
		--self.DefibVisModel:AddEffects(bit.bor(EF_PARENT_ANIMATES, EF_BONEMERGE))
		self.DefibVisModel:SetParent(self)
		self.DefibVisModel:Fire("Setparentattachment", attachments[1].name)
	end--]]
	end
	end
end

function SWEP:OnDrop()
	if IsValid(self.DefibVisModel) then
		self.DefibVisModel:Remove()
	end
	self:ResetProgress()
end