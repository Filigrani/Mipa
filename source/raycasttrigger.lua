local pd <const> = playdate
local gfx <const> = pd.graphics

class("RayCastTrigger").extends(gfx.sprite)

function RayCastTrigger:init(x, y, raydistance)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.BG)
    self:setCenter(0, 0) 
    self:add()
    self:setTag(TAG.ObstacleCastNoPlayer)
    self:setCollideRect(0,0,self.maxdistance,2)
    self.maxdistance = raydistance
    self.lasthitdistance = raydistance
end

function RayCastTrigger:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function RayCastTrigger:update()
    local _x, _y = self:getPosition()
    local _, _, collisions, length = self:checkCollisions(_x, _y)
    local closetshitdistance = self.maxdistance
    local HadHit = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        local hitdistance = math.floor(collision.otherRect.x-_x+0.5)
        if hitdistance < closetshitdistance then
            closetshitdistance = hitdistance
            self.lasthitdistance = hitdistance
            HadHit = true
        end
    end
    if not HadHit then
        self.lasthitdistance = self.maxdistance
    end
end