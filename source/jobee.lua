local pd <const> = playdate
local gfx <const> = pd.graphics

import "Creature"
class("Jobee").extends(Creature)

function Jobee:init(x, y)
    Jobee.super.init(self, x, y)
    self.name = "Blob"
    self.imagetable = AssetsLoader.LoadImageTable("images/Jobee")
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:clearCollideRect()
    self:add() -- Add to draw list
    self:setTag(TAG.Enemy)
    self.IsGrabbable = true
    self.Mipa = nil
    self.IsJobee = true
end

function Jobee:collisionResponse(other)
    if self.notapplyimpulses then
        return nil
    end
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or other:getTag() == TAG.HazardNoColide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Jobee:ApplyVelocity()

end

function Jobee:update()
    self:CommonUpdates()

    if self.Mipa == nil then
        self.Mipa = MipaInst
    else
        self.Mipa.Jobee = self
        local _x, _y = self.Mipa:getPosition()
        self:moveTo(_x+5, _y-13)
    end
end

function Jobee:Respawn()

end

function Jobee:AIUpdate()

end

function Jobee:RegisterAnimations()
    self:AddAnimation("idle", {1,2})
end

function Jobee:PickAnimation()
    self:SetAnimation("idle")
end