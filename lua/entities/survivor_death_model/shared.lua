AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.AutomaticFrameAdvance = true

ENT.PrintName = "Survivor Death Model"

ENT.Spawnable = false

--[[function ENT:Initialize()
	if self.DeathModelOwner and self.DeathModelOwner != nil and self.DeathModelOwner:IsPlayer() then
		self:SetNWEntity("L4D2_DeathModel_SharedOwner")
	end
end--]]

function ENT:Think()
	self:NextThink( CurTime() )
	return true
end
