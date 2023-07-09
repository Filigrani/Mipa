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

    -- Stats
    self.hp = 1
    self.hpmax = 6
    -- Moving vars
    self.speed = 1.66
    self.pushingspeed = 1.1
    self.airspeed = 1.99
    self.velocityX = 0
    self.velocityY = 0
    self.movingflag = false
    -- Physic
    self.maxjumpvelocity = -10
    self.gravity = 1
    self.pusing = false
    self.onground = true
    self.fallspeed = 7.2
    self.canjump = true
    self.freefall = 0
    self.highestY = self.y
    -- Animation
    self.currentanimation = ""
    self.animationframe = 0
    self.maxframes = 0
    self.animtable = {}
    self.loop = true
    self.pingpong = false
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
    self.IsClone = false
    self.skipdeathscreen = false
end
function Mipa:IsDead()
    if self.hp == 0 then
        return true
    end
    return false
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
        self.animationfinished = false
        self.animationframe = 0
        self.currentanimation = anim
        self.animationtimer.duration = 4
        self.loop = true
        self.pingpong = false
        if anim == "idle" then
            self.maxframes = 1
        elseif anim == "falling" then
            self.maxframes = 1     
        elseif anim == "fallingstart" then
            self.maxframes = 2
            self.loop = false   
        elseif anim == "flying" then
            self.maxframes = 1
        elseif anim == "walk" then
            self.maxframes = 2    
        elseif anim == "down" then
            self.maxframes = 0
            self.loop = false           
        elseif anim == "push" then
            self.maxframes = 1
        elseif anim == "deathstart" then
            self.maxframes = 5
            self.loop = false
            self.animationtimer.duration = 3            
        elseif anim == "death" then
            self.maxframes = 5
            self.loop = false
            self.animationtimer.duration = 7                  
        end
    end
end

function Mipa:MayNextFrame()
    if self.skipnextframechange then
        self.skipnextframechange = false
        return
    end

    if not self.animationfinished then
        if not self.inverseanim then
            if self.animationframe == self.maxframes then
                if self.loop then
                    if self.pingpong ~= true then
                        self.animationframe = 0
                    else
                        self.inverseanim = true
                        self.animationframe = self.animationframe - 1
                    end
                else
                    self.animationfinished = true            
                end
            else
                self.animationframe = self.animationframe + 1
            end   
        else
            if self.animationframe == 0 then
                if self.loop then
                    if self.pingpong ~= true then
                        self.animationframe = self.maxframes
                    else
                        self.inverseanim = false
                        self.animationframe = self.animationframe + 1
                    end
                else
                    self.animationfinished = true
                end
            else
                self.animationframe = self.animationframe - 1
            end            
        end  
    end
end
function Mipa:CloneEffect(img)
    if self.evenframe then
        img = img:fadedImage(0.5, gfx.image.kDitherTypeBayer2x2)
        self.evenframe = false
    else
        self.evenframe = true
    end
    return img
end

function Mipa:UpdateAnimation()
    if not self:IsDead() then
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
            elseif self.currentanimation == "fallingstart" and self.animationfinished then
                self:SetAnimation("falling")
            end
        else
            self:SetAnimation("idle")
        end
    else
        if self.currentanimation ~= "deathstart" and self.currentanimation ~= "death" then
            self:SetAnimation("deathstart")
        elseif self.currentanimation == "deathstart" and self.animationfinished then
            self:setCollideRect(3,7,8,7)
            self:SetAnimation("death")
        elseif self.currentanimation == "death" and self.animationfinished and not self.IsClone and not self.skipdeathscreen then
            UIIsnt:Death()
        end
    end
    local spritePath = "images/Mipa/"..self.currentanimation.."/"..self.animationframe
    if self.lastimage ~= spritePath then
        local img = gfx.image.new(spritePath)
        if self.IsClone then
            img = self:CloneEffect(img)
        end

        self:setImage(img, self.mirrored)      
        self.lastimage = spritePath 
    else
        if self.IsClone then
            local img = gfx.image.new(spritePath)
            img = self:CloneEffect(img)
            self:setImage(img, self.mirrored) 
        end
    end
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
    if not self:IsDead() then -- So when push her body she not facing to motion direction
        self.mirrored = gfx.kImageUnflipped
    end
    if not self:IsDown() then
        if not self:IsPushing() then
            if self:IsOnFloor() then
                self.velocityX = self.speed
            else
                self.velocityX = self.airspeed
            end
        else
            self.velocityX = self.pushingspeed
        end
        return true
    end
    return false
end

function Mipa:TryMoveLeft() -- So when push her body she not facing to motion direction
    if not self:IsDead() then
        self.mirrored = gfx.kImageFlippedX
    end
    if not self:IsDown() then
        if not self:IsPushing() then
            if self:IsOnFloor() then
                self.velocityX = -self.speed
            else
                self.velocityX = -self.airspeed
            end
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

function Mipa:Damage(damage)
    if self:IsDead() then
        return
    end
    
    if damage > self.hp then
        self.hp = 0
    else
        self.hp = self.hp-damage
        pd.display.setInverted(false)
        local t = pd.frameTimer.new(4)
        t.timerEndedCallback = function(timer)
            pd.display.setInverted(true)   
        end       
        t:start()
        --SoundManager:PlaySound("Hit")
        SoundManager:PlaySound("Scream")      
    end

    if self.hp == 0 then
        self.speed = 1 -- so will be able to push her body without animation glitched, like a box
    end
end

function Mipa:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
    local lastground = self.onground
    local lasthighestY = self.highestY
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
                self.highestY = self.y

                if lasthighestY ~= 0 and not lastground then
                    local freefall = 0
                    if self.y > lasthighestY then
                        freefall = self.y-lasthighestY
                    else
                        freefall = lasthighestY-self.y
                    end
                    --print("freefall "..freefall)
                    if freefall > 0 then
                        local landvolume = freefall/154
                        if landvolume >= 0.77 then
                            landvolume = 1
                            self:Damage(1)
                        elseif landvolume < 0.3 then
                            landvolume = 0.3
                        end
                        SoundManager:PlaySound("Land", landvolume)
                    end                
                end
            elseif collision.normal.y == 1 then
                self.velocityY = 0
            end
            if collisionTag == TAG.PropPushable and lastground then
                if collision.normal.x > 0 then
                    collisionObject:TryMoveLeft()
                    collisionObject:ApplyVelocity()
                    SoundManager:PlaySound("Push")
                elseif collision.normal.x < 0 then
                    collisionObject:TryMoveRight()
                    collisionObject:ApplyVelocity()    
                    SoundManager:PlaySound("Push")                     
                end
            end
            if collisionTag == TAG.Player and collisionObject:IsDead() and lastground then
                if collision.normal.x > 0 then
                    collisionObject:TryMoveLeft()
                    collisionObject:ApplyVelocity()
                    SoundManager:PlaySound("MetalPush")
                elseif collision.normal.x < 0 then
                    collisionObject:TryMoveRight()
                    collisionObject:ApplyVelocity()    
                    SoundManager:PlaySound("MetalPush")                     
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
    if not self.onground then
        if self.highestY > self.y then
            self.highestY = self.y
            --print("highestY "..self.highestY)
        end
    end
    if self.y > 400 and not self:IsDead() then
        self.skipdeathscreen = true
        self.hp = 0
        if not self.IsClone then
            UIIsnt:Death()
        end
    end
end

function Mipa:update()
    self.velocityX = 0
    if not self:IsDead() then
        self:ProcessWalking()
        if pd.buttonJustPressed(pd.kButtonA) then
            self:TryJump()
        end
    end
    self:ApplyVelocity()
    self:UpdateAnimation()
end