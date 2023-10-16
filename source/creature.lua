local pd <const> = playdate
local gfx <const> = pd.graphics

class("Creature").extends(gfx.sprite)

function Creature:init(x, y)
    self.imagetable = gfx.imagetable.new("images/blob")
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCollideRect(0,7,14,7)
    self:add() -- Add to draw list
    self:setTag(TAG.Enemy)
    -- Moving vars
    self.speed = 1
    self.velocityX = 0
    self.velocityY = 0
    -- Physic
    self.gravity = 1
    self.movingflag = false
    self.onground = true
    self.freefall = 0
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
    print("Creature Created")
end

function Creature:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
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
    self.mirrored = gfx.kImageFlippedX
end

function Creature:TryMoveLeft(s)
    local speed = self.speed
    if s then
        speed = s
    end
    self.velocityX = -speed
    self.mirrored = gfx.kImageUnflipped
end

function Creature:TryJump()  
    if self.canjump and self:IsOnFloor() then
        self.canjump = false
        self.velocityY = self.maxjumpvelocity
    end
end

function Creature:collisionResponse(other)
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or other:getTag() == TAG.HazardNoColide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Creature:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    local actualX, actualY, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    local lastground = self.onground
    local lastfreefall = self.freefall
    if actualX ~= disiredX then
        print("Blob can't move")
    end
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
                if not lastground and self.onground and lastfreefall > 5 then
                    AnimEffect(self.x-7, collision.otherRect.y-14, "Effects/ground", 1, true)
                    SoundManager:PlaySound("Bloop", 0.3)
                    if collisionTag == TAG.Player and not lastground then
                        print("Damage "..lastfreefall)
    
                        if lastfreefall > 10 then
                            collisionObject:Damage(2)
                        else
                            collisionObject:Damage(1)
                        end
                    end
                end         
            elseif collision.normal.y == 1 then    
                self.velocityY = 0
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
    if self.y > 400 then
        gfx.sprite.removeSprite(self)
    end
end

function Creature:update()
    self.velocityX = 0
    self:AIUpdate()
    self:ApplyVelocity()
    self:UpdateAnimation()
end

function Creature:AIUpdate()
    self.thinkticks = self.thinkticks+1

    if self.thinkticks >= 100 then
        if self.movingdirection == 0 then
            if math.random(0,100) <= 50 then
                self.movingdirection = 1
            else
                self.movingdirection = 1
            end
        end
    end
    if self.movingdirection == 1 then
        self:TryMoveRight()
    elseif self.movingdirection == -1 then
        self:TryMoveLeft()
    end
end

function Creature:UpdateAnimation()
    self:PickAnimation()
    local spritePath = self.currentanimation.."/"..self.animationframe
    if self.lastimage ~= spritePath then
        local imagetable = self.imagetable
        if self.IsClone and self:IsEvenFrame() then
            if self.mipaimagedithered == nil then
                self:SetDitherImageTable()
            end
            imagetable = self.mipaimagedithered
        end
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
    self:AddAnimation("idle", {1})
    self:AddAnimation("walk", {1, 3, 2, 4})
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
    if self:IsMoving() then
        self:SetAnimation("walk")
    else
        self:SetAnimation("idle")
    end
end