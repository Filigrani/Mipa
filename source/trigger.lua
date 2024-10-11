local pd <const> = playdate
local gfx <const> = pd.graphics

class("Trigger").extends(gfx.sprite)

function Trigger:init(x, y, w, h, active)
    self:setBounds(x,y,w,h)
    self:setTag(TAG.Interactive)
    self:setCollideRect(0,0,w,h)
    self:add() -- Add to draw list
    self.triggeronce = true
    self.destoryontrigger = true
    self.triggered = false
    self.OnTrigger = nil
    self.IsTrigger = true
    if active == nil or active == true then
        self.active = true
    else
        self.active = false
    end
end

function Trigger:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function Trigger:Trigger()
    if self.active == false then
        return
    end
    
    if self.triggeronce then
        if not self.triggered then
            self.triggered = true
            if self.OnTrigger ~= nil then
                self.OnTrigger()
            end
            if self.destoryontrigger then
                gfx.sprite.removeSprite(self)
            end  
        end
    else
        if self.OnTrigger ~= nil then
            self.OnTrigger()
        end
    end
end

function Trigger:SoftTrigger()
    if self.active == false then
        return
    end
    
    if self.OnTrigger ~= nil then
        self.OnTrigger()
    end
end

function Trigger:PressButton()
    if self.active == false then
        return
    end
    
    if self.OnTrigger ~= nil then
        self.OnTrigger()
    end
end

function Trigger:update()

end