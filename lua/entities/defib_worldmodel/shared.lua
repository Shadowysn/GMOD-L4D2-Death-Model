
ENT.Type = "anim"  
ENT.Base = "base_gmodentity"  

if SERVER then   
AddCSLuaFile("shared.lua")

function ENT:Initialize()   
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	self:DrawShadow(false)
	self:SetModel("models/w_models/weapons/defib/w_eq_defibrillator_paddles.mdl")
	if !IsValid(self:GetOwner()) or !self:GetOwner():IsPlayer() or !self:GetOwner():Alive() then
		self:Remove()
	end
	self:AddEffects(EF_BONEMERGE)
	self:AddEffects(EF_PARENT_ANIMATES)
end
function ENT:Think()
	local p = nil
	if IsValid(self:GetOwner():GetNWEntity("DefibrillatorAnimatedProp")) then
	p = self:GetOwner():GetNWEntity("DefibrillatorAnimatedProp")
	else
	p = self:GetOwner()
	end
	if !IsValid(self:GetParent()) or self:GetParent() != p then
	self:SetParent(p)
	end
end
end


if CLIENT then
function ENT:Draw() 
	local p = nil
	if IsValid(self:GetOwner():GetNWEntity("DefibrillatorAnimatedProp")) then
	p = self:GetOwner():GetNWEntity("DefibrillatorAnimatedProp")
	else
	p = self:GetOwner()
	end
	if !IsValid(p) then return end
	--[[local l_hand = p:LookupBone("ValveBiped.Bip01_L_Hand")
	if l_hand then
		local position, angles = p:GetBonePosition(l_hand)
		local l_pad = self:LookupBone("ValveBiped.Bip01_L_Hand") --print("pos:", position, "ang:", angles)
		if l_pad then
		--self:SetBonePosition(l_pad, position, angles)
		self:ManipulateBonePosition(l_pad, position)
		self:ManipulateBoneAngles(l_pad, angles)
		end
	end--]]
	--[[local r_hand = p:LookupBone("ValveBiped.Bip01_R_Hand")
	if r_hand then
		local position, angles = p:GetBonePosition(r_hand)
		self:SetPos(position)
		self:SetAngles(angles)
	end--]]
	local eyepos = EyePos()  
	local eyepos2 = LocalPlayer():EyePos()  
	if eyepos:Distance(eyepos2) > 5 or LocalPlayer() != self:GetOwner() or p != self:GetOwner() then
		--self:SetupBones()
		self:DrawModel()
		self:DrawShadow(true)
	end
end
end
