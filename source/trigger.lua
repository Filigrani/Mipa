local pd <const> = playdate
local gfx <const> = pd.graphics

class("Trigger").extends(gfx.sprite)

function Trigger:init(x, y, w, h)
    self:setBounds(x,y,w,h)
    self:setTag(TAG.Interactive)
    self:setCollideRect(0,0,w,h)
    self:add() -- Add to draw list
    self.triggeronce = true
    self.triggered = false
    self.OnTrigger = nil
    self.IsTrigger = true
end

function Trigger:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function Trigger:Trigger()
    if self.triggeronce then
        if not self.triggered then
            self.triggered = true
            if self.OnTrigger ~= nil then
                self.OnTrigger()
            end
            gfx.sprite.removeSprite(self)         
        end
    else
        if self.OnTrigger ~= nil then
            self.OnTrigger()
        end
    end
end

function Trigger:update()

end