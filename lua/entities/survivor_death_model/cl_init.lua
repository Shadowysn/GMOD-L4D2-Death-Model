if (SERVER) then return end
include("shared.lua")

function ENT:Initialize()
self:UseClientSideAnimation()
self:SetNoDraw(true)
	hook.Add("CalcView","L4D2_DeathModel_Camera",function(ply, pos, angles, fov)
	if GetConVar("cl_l4d2_body_camera"):GetInt() > 0 then
		local ent = GetViewEntity()
		if IsValid(self) and IsValid(ply) and ply:IsPlayer() and !ply:Alive() and LocalPlayer()==ply and ent==ply then
			if GetConVar("cl_l4d2_body_camera"):GetInt() != 1 then
				for _,child in pairs(self:GetChildren()) do
				if child:GetModel() == ply:GetModel() and !child:GetNoDraw() and 
				(child:GetClass() == "prop_dynamic" or child:GetClass() == "prop_dynamic_override") then
					local get_eyes = child:LookupAttachment("eyes")
					if get_eyes > 0 then
					local getattachment = child:GetAttachment(get_eyes)
					--print(getpos)
					--print(getang)
					local ply_angs = LocalPlayer():GetAngles()
					return {origin=getattachment.Pos,angles=getattachment.Ang,fov=fov,znear=znear}
					end
				end
				end
			end
		local rd = util.TraceLine({start=self:GetPos(),endpos=self:GetPos()-angles:Forward()*105,filter={self,LocalPlayer()}})
		return {origin=Vector(self:GetPos().x,self:GetPos().y,self:GetPos().z+15)-angles:Forward()*(100*rd.Fraction),angles=angles,fov=fov,znear=0.5} 
		end
	end
	end)
end

function ENT:Draw()
	--self:DrawModel()
end

--[[function ENT:Think()
	local shared_owner = self:GetNWEntity("L4D2_DeathModel_SharedOwner")
	if IsValid(shared_owner) then
		for _,child in pairs(self:GetChildren()) do
		if child:GetModel() == shared_owner:GetModel() and !child:GetNoDraw() and 
		(child:GetClass() == "prop_dynamic" or child:GetClass() == "prop_dynamic_override") then
			local get_eyes = child:LookupAttachment("eyes")
				if get_eyes > 0 then
				child:SetEyeTarget(child:GetAttachment(get_eyes).Pos)
				return
				end
			end
		end
	end
end--]]

--[[net.Receive("L4D2_DeathModel_SnapCameraToGetUp", function() -- Doesn't work
	local body = net.ReadEntity()
	local visbody = net.ReadEntity()
	hook.Add("CalcView","L4D2_DeathModel_DefibGetUpCamera",function(ply, pos, angles, fov)
		if GetConVar("cl_l4d2_defib_body_camera"):GetInt() <= 0 then return end
		if !IsValid(body) then return end
		if !IsValid(visbody) then return end
		if !IsValid(ply) then return end
		if !ply:IsPlayer() then return end
		if !ply:Alive() then return end
		if LocalPlayer()!=ply then return end
		local ent = GetViewEntity()
		if ent!=ply then return end
		if IsValid(visbody) then
			local get_eyes = visbody:LookupAttachment("eyes")
			if get_eyes > 0 then
			local getattachment = visbody:GetAttachment(get_eyes) --print("shouldbe")
			return {origin=getattachment.Pos,angles=getattachment.Ang,fov=fov,znear=znear}
			end
		end
	end)
end)--]]
