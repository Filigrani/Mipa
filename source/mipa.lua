local pd <const> = playdate
local gfx <const> = pd.graphics

class("Mipa").extends(gfx.sprite)

function Mipa:init(x, y)
    local img = gfx.image.new("images/Mipa/idle/0")
    self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setCollideRect(3,1,8,13)
    self:add() -- Add to draw list
    self:setTag(TAG.Player)

    -- Moving vars
    self.speed = 1.66
    self.pushingspeed = 1.1
    self.velocityX = 0
    self.velocityY = 0
    -- Physic
    self.maxjumpvelocity = -10
    self.gravity = 1
    self.pusing = false
    self.onground = true
    self.fallspeed = 7.2
    self.canjump = true

    self.currentanimation = ""
    self.animationframe = 0
    self.maxframes = 0
    self.animtable = {}
    self.loop = true
    self.pingpong = false
    self.inverseanim = false
    self.skipnextframechange = false
    self.movingflag = false
    
    self.animationtimer = pd.frameTimer.new(4)
    self.animationtimer.repeats = true
    self.animationtimer.timerEndedCallback = function(timer)
        self:MayNextFrame()    
    end
    self.animationtimer:start()
    self.mirrored = gfx.kImageUnflipped
end

function Mipa:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function Mipa:IsFlying()
    if self.velocityY < 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function Mipa:IsOnFloor()
    return self.onground
end

function Mipa:IsDown()
    if self:IsOnFloor() and pd.buttonIsPressed(pd.kButtonDown) then
        return true
    end
    return false
end

function Mipa:IsMoving()
    return self.movingflag
end

function Mipa:IsPushing()
    return self.pusing
end

function Mipa:SetAnimation(anim)
    if self.currentanimation == anim then
        return
    else
        self.currentanimation = anim
        self.animationframe = 0
        if anim == "idle" then
            self.maxframes = 1
            self.loop = true
            self.pingpong = false
        elseif anim == "falling" then
            self.maxframes = 1
            self.loop = true
            self.pingpong = false            
        elseif anim == "fallingstart" then
            self.maxframes = 2
            self.loop = true
            self.pingpong = false      
        elseif anim == "flying" then
            self.maxframes = 1
            self.loop = true
            self.pingpong = false      
        elseif anim == "walk" then
            self.maxframes = 2
            self.loop = true
            self.pingpong = false      
        elseif anim == "down" then
            self.maxframes = 0
            self.loop = true
            self.pingpong = false                 
        elseif anim == "push" then
            self.maxframes = 1
            self.loop = true
            self.pingpong = false                 
        end
    end
end

function Mipa:MayNextFrame()
    if self.skipnextframechange then
        self.skipnextframechange = false
        return
    end

    if not self.inverseanim then
        if self.animationframe == self.maxframes then
            if self.pingpong ~= true then
                self.animationframe = 0
            else
                self.inverseanim = true
                self.animationframe = self.animationframe - 1
            end
        else
            self.animationframe = self.animationframe + 1
        end   
    else
        if self.animationframe == 0 then
            if self.pingpong ~= true then
                self.animationframe = self.maxframes
            else
                self.inverseanim = false
                self.animationframe = self.animationframe + 1
            end
        else
            self.animationframe = self.animationframe - 1
        end            
    end
end

function Mipa:UpdateAnimation()
    if self:IsOnFloor() then
        if self:IsDown() then
            self:SetAnimation("down")
        else
            if self:IsMoving() then             
                if self:IsPushing() then
                    self:SetAnimation("push")
                else
                    self:SetAnimation("walk")
                end       
            else 
                self:SetAnimation("idle")
            end
        end
    elseif self:IsFlying() then
        self:SetAnimation("flying")
    elseif self:IsFalling() then
        if self.currentanimation ~= "falling" and self.currentanimation ~= "fallingstart" then
            self:SetAnimation("fallingstart")
        end
    else
        self:SetAnimation("idle")
    end
    local spritePath = "images/Mipa/"..self.currentanimation.."/"..self.animationframe
    local img = gfx.image.new(spritePath)
    self:setImage(img, self.mirrored)
end

function Mipa:ProcessWalking()
    local Moved = false
    if pd.buttonIsPressed(pd.kButtonLeft) then
        Moved = self:TryMoveLeft()
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        Moved = self:TryMoveRight()
    end
    return Moved
end

function Mipa:TryMoveRight()
    self.mirrored = gfx.kImageUnflipped
    if not self:IsDown() then
        if not self:IsPushing() then
            self.velocityX = self.speed
        else
            self.velocityX = self.pushingspeed
        end
        return true
    end
    return false
end

function Mipa:TryMoveLeft()
    self.mirrored = gfx.kImageFlippedX
    if not self:IsDown() then
        if not self:IsPushing() then
            self.velocityX = -self.speed
        else
            self.velocityX = -self.pushingspeed
        end
    end
    return false
end

function Mipa:TryJump()  
    if self.canjump then
        self.canjump = false
        self.velocityY = self.maxjumpvelocity
    end
end

function Mipa:collisionResponse(other)
    return gfx.sprite.kCollisionTypeSlide
end

function Mipa:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
    local lastground = self.onground
    self.onground = false
    self.pusing = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.onground = true
                self.canjump = true
                self.velocityY = 0
            elseif collision.normal.y == 1 then
                self.velocityY = 0
            end
            if collisionTag == TAG.PropPushable and lastground then
                if collision.normal.x > 0 then
                    collisionObject:TryMoveLeft()
                    collisionObject:ApplyVelocity()
                elseif collision.normal.x < 0 then
                    collisionObject:TryMoveRight()
                    collisionObject:ApplyVelocity()                            
                end
            end

            if collision.normal.x ~= 0 then
                self.pusing = true
            end            
        end
    end
    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        self.movingflag = true
    else
        self.movingflag = false
    end
end

function Mipa:update()
    self.velocityX = 0
    self:ProcessWalking()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:TryJump()
    end
    self:ApplyVelocity()
    self:UpdateAnimation()
end