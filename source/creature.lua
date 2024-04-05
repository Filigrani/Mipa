local pd <const> = playdate
local gfx <const> = pd.graphics

class("Creature").extends(gfx.sprite)

function Creature:init()
    self.name = name
    -- Moving vars
    self.speed = 1.01
    self.velocityX = 0
    self.velocityY = 0
    self.momentumX = 0
    -- Physic
    self.gravity = 1
    self.movingflag = false
    self.onground = true
    self.freefall = 0
    self.maxjumpvelocity = -10
    self.canjump = true
    -- Animation
    self.animationtable = {}
    self:RegisterAnimations()
    self.currentanimationdata = nil
    self.currentanimation = ""
    self.animationframe = 1
    self.animationindex = 1
    self.inverseanim = false
    self.animationfinished = false
    self.skipnextframechange = false
    self.lastimage = ""
    self.animationtimer = pd.frameTimer.new(4)
    self.animationtimer.repeats = true
    self.animationtimer.timerEndedCallback = function(timer)
        self:MayNextFrame()    
    end
    self.animationtimer:start()
    self.mirrored = gfx.kImageUnflipped
    -- AI
    self.movingdirection = 0
    self.thinkticks = 1
    self.bumpwall = false
    self.homeX = 0
    self.homeY = 0
    -- Stats
    self.hp = 1
    self.maxhp = 1
    self.damagable = false
    self.damageimuneframes = 0
    self.damagesound = nil
end

function Creature:IsMirrored()
    return self.mirrored == gfx.kImageFlippedX
end

function Creature:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function Creature:IsFlying()
    if self.velocityY < 0 and not self:IsOnFloor() then
        return true
    end
    return false
end
function Creature:IsOnFloor()
    return self.onground
end

function Creature:IsMoving()
    return self.movingflag
end

function Creature:TryMoveRight(s)
    local speed = self.speed
    if s then
        speed = s
    end
    self.velocityX = speed
    self.mirrored = gfx.kImageUnflipped
end

function Creature:TryMoveLeft(s)
    local speed = self.speed
    if s then
        speed = s
    end
    self.velocityX = -speed
    self.mirrored = gfx.kImageFlippedX
end

function Creature:TryJump()  
    if self.canjump and self:IsOnFloor() then
        self.canjump = false
        self.velocityY = self.maxjumpvelocity
    end
end

function Creature:IsDead()
    return self.hp <= 0
end

function Creature:CanBeDamaged()
    return self.damagable
end

function Creature:Damage(damage, ignoreimmune)
    if self:IsDead() and self:CanBeDamaged() then
        return
    end

    if self.damageimuneframes > 0 then
        if ignoreimmune == nil then
            if self.damageimunetimer == nil then
                self.damageimunetimer = pd.frameTimer.new(self.damageimuneframes)
                self.damageimunetimer.repeats = false
                self.damageimunetimer.timerEndedCallback = function(timer)
                    self.damageimunetimer = nil
                end
            else
                return
            end
        end
    end

    if damage > self.hp then
        self.hp = 0
    else
        self.hp = self.hp-damage
    end
    if self.damagesound ~= nil and self.damagesound ~= "" then
        SoundManager:PlaySound(self.damagesound)
    end
    if self.hp == 0 then
        self:Death()
    end
end

function Creature:Death()

end

function Creature:collisionResponse(other)
    if self.notapplyimpulses then
        return nil
    end
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or other:getTag() == TAG.HazardNoColide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Creature:ApplyVelocityBase()
    if self.notapplyimpulses then
        return nil
    end
    self.velocityY = self.velocityY+self.gravity
    if self.momentumX > 0 then
        self.momentumX = self.momentumX-self.gravity
        if self.momentumX <= 0 then
            self.momentumX = 0
        end
    elseif self.momentumX < 0 then
        self.momentumX = self.momentumX+self.gravity
        if self.momentumX >= 0 then
            self.momentumX = 0
        end
    end
    if self.momentumX ~= 0 then
        self.velocityX = self.velocityX+self.momentumX
    end
    if self.velocityXnextframe ~= nil then
        if self.velocityXnextframe ~= 0 then
            self.velocityX = self.velocityX+self.velocityXnextframe
            self.velocityXnextframe = 0
        end
    end
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    self.bumpwall = false
    local actualX, actualY, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    local lastground = self.onground
    local lastfreefall = self.freefall
    self.onground = false

    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.onground = true
                self.velocityY = 0
                self.freefall = 0
                self.canjump = true
                if collisionObject.IsConveyorBelts then
                    if collisionObject.Inversed then
                        self.velocityXnextframe  = -1
                    else
                        self.velocityXnextframe = 1
                    end
                elseif collisionObject.velocityXnextframe then
                    self.velocityXnextframe = collisionObject.velocityXnextframe
                end     
            elseif collision.normal.y == 1 then
                self.velocityY = 0
            end
            if collision.normal.x ~= 0 then
                if collisionTag == TAG.Player then
                    --collisionObject:Damage(1)
                end
                self.bumpwall = true
            end
        end
    end
    if not self.onground then
        self.freefall = self.freefall + self.gravity
    end
    if self:IsFalling()  then
        self.canjump = false
    end
    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        self.movingflag = true
    else
        self.movingflag = false
    end
    return actualX, actualY, collisions, length
end

function Creature:ApplyVelocity()
    self:ApplyVelocityBase()
end

function Creature:CommonUpdates()
    if self.homeX == 0 and self.homeY == 0 then
        if self:IsOnFloor() then
            self.homeX = self.x
            self.homeY = self.y
        end
    end
    
    self.velocityX = 0
    self:AIUpdate()
    self:ApplyVelocity()
    self:UpdateAnimation()
end

function Creature:update()
    self:CommonUpdates()
end

function Creature:AIUpdate()
    
end

function Creature:UpdateAnimation()
    if self.imagetable == nil then
        return
    end
    self:PickAnimation()
    local spritePath = self.currentanimation.."/"..self.animationframe
    if self.lastimage ~= spritePath then
        local imagetable = self.imagetable
        local img = imagetable:getImage(self.animationframe)
        self:setImage(img, self.mirrored) 
        self.lastimage = spritePath
    end
end

function Creature:AddAnimation(name, frames, speed, loop, pingpong)
    local data = {}
    data.name = name
    data.frames = frames
    if speed == nil then
        data.speed = 4
    else
        data.speed = speed
    end
    if loop == nil then
        data.loop = true
    else
        data.loop = loop
    end
    if pingpong == nil then
        data.pingpong = false
    else
        data.pingpong = pingpong
    end
    self.animationtable[name] = data
end

function Creature:RegisterAnimations()

end

function Creature:SetAnimation(anim)
    if self.currentanimation == anim then
        return
    else
        local data = self.animationtable[anim]
        if data ~= nil then
            self.currentanimationdata = data
        else
            return
        end
        self.animationfinished = false
        self.animationindex = 1
        self.currentanimation = anim
        self.animationframe = data.frames[self.animationindex]
        self.animationtimer.duration = data.speed
    end
end

function Creature:GetCurrentAnimationData()
    if self.currentanimationdata then
        return self.currentanimationdata
    end
    local data = {}
    data.name = ""
    data.frames = {1}
    data.speed = 4
    data.loop = true
    data.pingpong = false
    return data
end

function Creature:MayNextFrame()
    if self.skipnextframechange then
        self.skipnextframechange = false
        return
    end

    local data = self:GetCurrentAnimationData()
    local firstIndex = 1
    local lastIndex = #data.frames

    if first == lastIndex then
        self.animationindex = firstIndex
        self.animationframe = data.frames[self.animationindex]
        return
    end
    
    if not self.animationfinished then
        if not self.inverseanim then
            if self.animationindex == lastIndex then
                if data.loop then
                    if data.pingpong ~= true then
                        self.animationindex = firstIndex
                    else
                        self.inverseanim = true
                        self.animationindex = self.animationindex - 1
                    end
                else
                    self.animationfinished = true
                end
            else
                self.animationindex = self.animationindex + 1
            end   
        else
            if self.animationindex == firstIndex then
                if data.loop then
                    if data.pingpong ~= true then
                        self.animationindex = lastIndex
                    else
                        self.inverseanim = false
                        self.animationindex = self.animationindex + 1
                    end
                else
                    self.animationfinished = true
                end
            else
                self.animationindex = self.animationindex - 1
            end            
        end  
    end
    self.animationframe = data.frames[self.animationindex]
end

function Creature:PickAnimation()

end