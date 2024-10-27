local pd <const> = playdate
local gfx <const> = pd.graphics

class("Bullet").extends(gfx.sprite)

function Bullet:init(x, y)
    --local img = gfx.image.new("images/Props/Box")
    --self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    --self:setCenter(0, 0)
    self:setCollideRect(0,0,12,12)
    self:add() -- Add to draw list
    self:setTag(TAG.Effect)
    -- Moving vars
    self.speed = 1
    self.velocityX = 0
    self.velocityY = 0
    self.traveledX = 0
    -- Physic
    self.gravity = 0
    self.freefall = 0
    self.puller = true
    self.lifedistance = -1
    self.spawnX = x
    self.spawnY = y
    self.lastpushonhit = false
    self.Dangerous = false
    self.IsBullet = true
    self.trailchilds = {}
end

function Bullet:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function Bullet:collisionResponse(other)
    if self.colnResponse == nil then
        if other then
            if other.IsSinkSand then
                return gfx.sprite.kCollisionTypeOverlap
            end
            if (other:getTag() == TAG.Effect or other:getTag() == TAG.Player or other:getTag() == TAG.Interactive or other:getTag() == TAG.HazardNoColide or other:getTag() == TAG.ObstacleCastNoPlayer) then
                return gfx.sprite.kCollisionTypeOverlap
            end
        end
        return gfx.sprite.kCollisionTypeSlide
    else
        return self.colnResponse(other)
    end
end

function Bullet:LastHit(collision, lastfreefall)
    if self.OnHit == nil then
    else
        self.OnHit(collision, lastfreefall)
    end
end

function Bullet:LastPush()
    if not self.lastpushonhit then
        return
    end

    self:moveBy(self.speed, 0)
    local _, _, collisions, length = self:checkCollisions(self.x, self.y)
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            self:LastHit(collision, lastfreefall)
        end
    end
end

function Bullet:ProcessLastContact(collision, lastfreefall)
    if self.OnContact == nil then
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide or (self.colideWithLiquid and collisionObject.IsLiquid) then
            if collision.normal.y == -1 then
                self.velocityY = 0
                self.freefall = 0
                self:LastHit(collision, lastfreefall)
                self:LastPush()
                self:Destroy()
                return
            elseif collision.normal.y == 1 then       
                self.velocityY = 0
                self:LastHit(collision, lastfreefall)
                self:LastPush()
                self:Destroy()
                return
            end

            if self.velocityX > 0 then
                if collision.normal.x < 0 then
                    self.velocityX = 0
                    self:LastHit(collision, lastfreefall)
                    self:LastPush()
                    self:Destroy()
                    return
                end                  
            end
            if self.velocityX < 0 then
                if collision.normal.x > 0 then     
                    self.velocityX = 0
                    self:LastHit(collision, lastfreefall)
                    self:LastPush()
                    self:Destroy()
                    return
                end                  
            end                 
        end
    else
        self.OnContact(collision, lastfreefall)
    end
end

function Bullet:GetTraveled()
    if self.traveledX < 0 then
        return -self.traveledX
    end
    return self.traveledX
end

function Bullet:SetTraveled(val)
    self.traveledX = val
end

function Bullet:ApplyVelocity()
    local _x, _y = self:getPosition()
    self.velocityY = self.velocityY+self.gravity
    self.velocityX = self.speed
    local actualX, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
    self.traveledX = self.traveledX+self.velocityX
    
    local lastfreefall = self.freefall
    for i=1,length do
        local collision = collisions[i]
        self:ProcessLastContact(collision, lastfreefall)
    end

    self.freefall = self.freefall + self.gravity

    if self.velocityX == 0 and self.velocityY == 0 then
        self:Destroy()
    end
    if self.y > 400 then
        self:Destroy()
    end
end

local function distance( x1, y1, x2, y2 )
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

function Bullet:Destroy()
    if self.OnDestory then
        self.OnDestory()
    end
    for i = 1, #self.trailchilds, 1 do
        local trail = self.trailchilds[i]
        if trail.OnDestory then
            trail.OnDestory()
        else
            gfx.sprite.removeSprite(trail)
        end
    end
    gfx.sprite.removeSprite(self)
end

function Bullet:update()
    if self.CustomUpdate ~= nil then
        self.CustomUpdate()
    end
    
    if self.lifedistance > 0 then
        if distance(self.x, self.y, self.spawnX, self.spawnY) > self.lifedistance then
            self:Destroy()
        end
    end
    self:ApplyVelocity()
end