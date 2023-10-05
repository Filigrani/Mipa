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
    -- Physic
    self.gravity = 0
    self.freefall = 0
    self.puller = true
    self.lifedistance = -1
    self.spawnX = x
    self.spawnY = y
    self.lastpushonhit = false
end

function Bullet:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function Bullet:collisionResponse(other)
    if self.colnResponse == nil then
        if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Player or other:getTag() == TAG.Interactive) then
            return gfx.sprite.kCollisionTypeOverlap
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
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.velocityY = 0
                self.freefall = 0
                self:LastHit(collision, lastfreefall)
                self:LastPush()
                gfx.sprite.removeSprite(self)
            elseif collision.normal.y == 1 then       
                self.velocityY = 0
                self:LastHit(collision, lastfreefall)
                self:LastPush()
                gfx.sprite.removeSprite(self)
            end

            if self.velocityX > 0 then
                if collision.normal.x < 0 then
                    self.velocityX = 0
                    self:LastHit(collision, lastfreefall)
                    self:LastPush()
                    gfx.sprite.removeSprite(self)
                end                  
            end
            if self.velocityX < 0 then
                if collision.normal.x > 0 then     
                    self.velocityX = 0
                    self:LastHit(collision, lastfreefall)
                    self:LastPush()
                    gfx.sprite.removeSprite(self)
                end                  
            end                  
        end
    else
        self.OnContact(collision, lastfreefall)
    end
end

function Bullet:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    self.velocityX = self.speed
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
    local lastfreefall = self.freefall
    for i=1,length do
        local collision = collisions[i]
        self:ProcessLastContact(collision, lastfreefall)
    end

    self.freefall = self.freefall + self.gravity

    if self.velocityX == 0 and self.velocityY == 0 then
        gfx.sprite.removeSprite(self)
    end
    if self.y > 400 then
        gfx.sprite.removeSprite(self)
    end
end

local function distance( x1, y1, x2, y2 )
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

function Bullet:update()
    if self.lifedistance > 0 then
        if distance(self.x, self.y, self.spawnX, self.spawnY) > self.lifedistance then
            gfx.sprite.removeSprite(self)
        end
    end
    self:ApplyVelocity()
end