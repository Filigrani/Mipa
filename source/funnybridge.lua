local pd <const> = playdate
local gfx <const> = pd.graphics

class("FunnyBridge").extends(gfx.sprite)

function FunnyBridge:init(x, y, image)
    self.colider = gfx.sprite.new()
    self.colider:setCenter(0, 0)
    self.colider:setBounds(x, y, 14, 14)
    self.colider:setCollideRect(0, 3, 14, 7)
    self.colider:add()

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setTag(TAG.Effect)
    self:setZIndex(Z_Index.BG)
    self:setCollideRect(0,0,14,3)
    self:addSprite()

    local visual = gfx.sprite.new()
    visual:setCenter(0, 0)
    visual:setBounds(x, y, 14, 14)
    visual:setImage(image)
    visual:add()
    self.visual = visual

    self.originalY = y
    self.shiftedY = y+3
    self.shifted = false

    self.IsFunnyBringe = true
    self.falling = false
end

function FunnyBridge:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function FunnyBridge:update()
    local previousShifted = self.shifted
    if not self.falling then
        self.shifted = false
        local _, _, collisions, length = self:checkCollisions(self.x, self.y)
        for i=1,length do
            local collision = collisions[i]
            local collisionType = collision.type
            local collisionObject = collision.other
            local collisionTag = collisionObject:getTag()
            self.shifted = true
        end
        if self.shifted then
            self.visual:moveTo(self.visual.x, self.shiftedY)
        else
            self.visual:moveTo(self.visual.x, self.originalY)
        end
    else
        self.visual:moveTo(self.visual.x, self.visual.y+4)
    end
    if not previousShifted and self.shifted then
        SoundManager:PlaySound("Crip")
    end 
end

function FunnyBridge:Drop()
    self.falling = true
    gfx.sprite.removeSprite(self.colider)
    SoundManager:PlaySound("Crip")
    SoundManager:PlaySound("Wooop")
    self:clearCollideRect()
end