local pd <const> = playdate
local gfx <const> = pd.graphics

class("RayCastTrigger").extends(gfx.sprite)

function RayCastTrigger:init(x, y, raydistance)
    self.maxdistance = raydistance
    self.lasthitdistance = raydistance
    self:moveTo(x, y)
    self:setZIndex(Z_Index.BG)
    self:setCenter(1, 0) 
    self:setTag(TAG.Effect)
    self:setCollideRect(0,0,self.maxdistance,2)
    self:add()
end

function RayCastTrigger:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function RayCastTrigger:update()
    local _x, _y = self:getPosition()
    local _, _, collisions, length = self:checkCollisions(_x, _y)
    local closetshitdistance = self.maxdistance -- so when we will search closest one, first one will be always less than this.
    local HadHit = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        local hitdistance = math.floor(collision.otherRect.x-_x+0.5) -- float to int
        -- parent in this contenxt is laser itself, that way we ignore damage hitbox.
        --  hitdistance < closetshitdistance make it only accept most close (in left orindated lasers) objects that blocks off laser.
        -- Ignore TAG.Effect because collision of them made for differnet purpose.
        -- Ignore TAG.Player so, we can cast ray past Mipa, and damage trigger will hurt her.
        if self.parent ~= collisionObject and hitdistance < closetshitdistance and (collisionTag ~= TAG.Effect or (collisionTag == TAG.Effect and collisionObject.notapplyimpulses)) and collisionTag ~= TAG.Player and collisionTag ~= TAG.Interactive then
            closetshitdistance = hitdistance
            self.lasthitdistance = hitdistance
            HadHit = true
        end
    end
    if not HadHit then -- Got nothing, reset lasthitdistance to maximum, because it may previously be less than it. 
        self.lasthitdistance = self.maxdistance
    end
end