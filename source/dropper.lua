local pd <const> = playdate
local gfx <const> = pd.graphics

import "Creature"
class("Dropper").extends(PhysicalProp)

function Dropper:init(x, y)
    local img = gfx.image.new("images/Props/dropper")
    self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    --self:setCenter(0, 0)
    self:setCollideRect(0,0,12,12)
    self:add() -- Add to draw list
    self:setTag(TAG.HazardNoColide)
    -- Moving vars
    self.speed = 1.012
    self.momentumX = 0
    self.velocityX = 0
    self.velocityY = 0
    -- Physic
    self.gravity = 1.5
    self.gravityinliquid = 0.2
    self.gravityonliquidsurface = 0.2
    self.movingflag = false
    self.onground = false
    self.freefall = 0
    self.liquidsurfacesoftland = true
    self.liquidsurfacefloat = false
    self.notapplyimpulses = true
    self.IsPhysProp = true

    --Dropper
    self.fallable = true

    if self.triggerX == 0 then
        self.triggerX = 7
    end

    self.rotatebyval = 1
    self.swaydelay = 20
    self.swaingframes = math.floor(math.random(0,self.swaydelay)+0.5)
    self.swayperioud = 3
    self.swaydirection = 0
end

function Dropper:collisionResponse(other)
    if self.notapplyimpulses then
        return nil
    end
    if other then
        if (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.HazardNoColide) or other:getTag() == TAG.Player then
            return gfx.sprite.kCollisionTypeOverlap
        else
            return gfx.sprite.kCollisionTypeSlide
        end
    else
        return gfx.sprite.kCollisionTypeOverlap
    end
end

function Dropper:RotateBy(off)
    self:setRotation(self:getRotation()+off)
    --print("[Dropper] Rotated to "..self:getRotation())
end

function Dropper:update()
    self.velocityX = 0
    self:ApplyVelocity()

    if self.fallable then
        if MipaInst then
            local triggerRangeMin = self.x-self.triggerX
            local triggerRangeMax = self.x+self.triggerX
            local MipaX = MipaInst.x
            if MipaX >= triggerRangeMin and MipaX <= triggerRangeMax then
                
                if self.notapplyimpulses then
                    SoundManager:PlaySound("Wooop")
                    self.notapplyimpulses = false
                end
            end
        end
        if self.notapplyimpulses then
            --print("[Dropper] swaydirection "..self.swaydirection.." frame "..self.swaingframes)
            if self.swaydirection == 0 then
                if self.swaingframes > self.swaydelay then
                    self.swaingframes = 0
                    self.swaydirection = 1
                end
            elseif self.swaydirection == 1 or self.swaydirection == 3 then
                if self.swaingframes < self.swayperioud then
                    self:RotateBy(self.rotatebyval)
                else
                    self.swaingframes = 0
                    if self.swaydirection == 1 then
                        self.swaydirection = 2
                    else
                        self.swaydirection = 0
                        self:setRotation(0)
                    end
                end
            elseif self.swaydirection == 2 then
                if self.swaingframes < self.swayperioud*2 then
                    self:RotateBy(-self.rotatebyval)
                else
                    self.swaingframes = 0
                    self.swaydirection = 3
                end
            end
            self.swaingframes = self.swaingframes+1
        else
            if self:getRotation() ~= 0 then
                self:setRotation(0)
            end
        end
    end
end