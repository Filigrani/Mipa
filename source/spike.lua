local pd <const> = playdate
local gfx <const> = pd.graphics

class("Spike").extends(gfx.sprite)

function Spike:init(x, y)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCollideRect(0,3,14,11)
    self:setTag(TAG.Hazard)
    self.IsSpike = true
    print("Spike spawned")
    self:setUpdatesEnabled(false) 
    self:setVisible(false)
    self:addSprite()
end

function Spike:collisionResponse(other)
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Player) then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Spike:update()

end