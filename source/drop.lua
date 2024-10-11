local pd <const> = playdate
local gfx <const> = pd.graphics

class("Drop").extends(gfx.sprite)

function Drop:init(x, y)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setTag(TAG.Effect)
    self:setCenter(0, 0)
    self:setCollideRect(0,0,1,1)
    self:setImage(AssetsLoader.LoadImage("images/Effects/Dot"))
    self:add()

    self.velocityX = 0
    self.velocityY = 0
    self.gravity = 0.35
end

function Drop:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function Drop:update()
    self.velocityY = self.velocityY+self.gravity
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    local actualX, _, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()

        if collisionObject.IsLiquid or (collisionTag ~= TAG.Effect and collisionTag ~= TAG.Interactive) then
            AnimEffect(self.x-7, self.y-15, "Effects/ground", 1, true)
            gfx.sprite.removeSprite(self)
        end
    end
end