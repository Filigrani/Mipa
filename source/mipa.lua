local pd <const> = playdate
local gfx <const> = pd.graphics

class("Mipa").extends(gfx.sprite)

function Mipa:init(x, y)
    self.mipaimages = gfx.imagetable.new("images/mipa")
    self.mipaimagedithered = nil
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setCollideRect(3,1,8,13)
    self:add() -- Add to draw list
    self:setTag(TAG.Player)
    -- Stats
    self.hp = 4
    self.hpmax = 4
    self.equipment = {0, 1}
    self.selectedequipment = 1
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
    self.IsClone = false
    self.skipdeathscreen = false
    self.pulltimer = pd.frameTimer.new(3)
    self.pulltimer.repeats = true
    self.pulltimer.timerEndedCallback = function(timer)
        self:ProcessPulling()    
    end
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

function Mipa:IsPulling()
    if self:IsOnFloor() and not self:IsDead() and not self:IsDown() and self.equipment[self.selectedequipment] == 1 then
        return pd.buttonIsPressed(pd.kButtonB) 
    end
    return false
end

function Mipa:NextEquipment()
    if self.selectedequipment == #self.equipment then
        self.selectedequipment = 1
    else
        self.selectedequipment = self.selectedequipment +1;
    end
    UIIsnt:UpdateEquipment(self.equipment, self.selectedequipment)
end

function Mipa:AddAnimation(name, frames, speed, loop, pingpong)
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

function Mipa:RegisterAnimations()
    self:AddAnimation("idle", {1, 2})
    self:AddAnimation("walk", {3, 4, 5})
    self:AddAnimation("falling", {28, 29})
    self:AddAnimation("fallingstart", {6, 7, 8}, 4, false)
    self:AddAnimation("flying", {9, 10})
    self:AddAnimation("down", {11})
    self:AddAnimation("push", {12, 13})
    self:AddAnimation("pull", {14, 15})
    self:AddAnimation("deathstart", {16, 17, 18, 19, 20, 21}, 3, false)
    self:AddAnimation("death", {22, 23, 24, 25, 26, 27}, 7, false)
end

function Mipa:SetAnimation(anim)
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

function Mipa:GetCurrentAnimationData()
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

function Mipa:MayNextFrame()
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
function Mipa:ToggleEvenFrame()
    if self.evenframe then
        self.evenframe = false
    else
        self.evenframe = true
    end
end

function Mipa:IsEvenFrame()
    return self.evenframe
end

function Mipa:PickAnimation()
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
                    if self:IsPulling() then
                        self:SetAnimation("pull")
                    else
                        self:SetAnimation("idle")
                    end
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
end

function Mipa:SetDitherImageTable()
    self.mipaimagedithered = gfx.imagetable.new("images/mipa")
    for i = 1, #self.mipaimages, 1 do
        local img = self.mipaimages:getImage(i)
        self.mipaimagedithered:setImage(i, img:fadedImage(0.5, gfx.image.kDitherTypeBayer2x2))
    end
end

function Mipa:UpdateAnimation()
    self:PickAnimation()
    local spritePath = self.currentanimation.."/"..self.animationframe
    if self.lastimage ~= spritePath then
        local imagetable = self.mipaimages
        if self.IsClone and self:IsEvenFrame() then
            if self.mipaimagedithered == nil then
                self:SetDitherImageTable()
            end
            imagetable = self.mipaimagedithered
        end
        local img = imagetable:getImage(self.animationframe)
        self:setImage(img, self.mirrored) 
        self.lastimage = spritePath 
    else
        if self.IsClone then
            local imagetable = self.mipaimages
            if self:IsEvenFrame()  then
                if self.mipaimagedithered == nil then
                    self:SetDitherImageTable()
                end
                imagetable = self.mipaimagedithered
            end
            local img = imagetable:getImage(self.animationframe)
            self:setImage(img, self.mirrored)
        end
    end
    if self.IsClone then
        self:ToggleEvenFrame()
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
    if self.canjump and self:IsOnFloor() then
        self.canjump = false
        self.velocityY = self.maxjumpvelocity
    end
end

function Mipa:collisionResponse(other)
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard) then
        return gfx.sprite.kCollisionTypeOverlap
    end
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
    end

    pd.display.setInverted(false)
    local t = pd.frameTimer.new(4)
    t.timerEndedCallback = function(timer)
        pd.display.setInverted(true)
    end
    t:start()
    --SoundManager:PlaySound("Hit")
    SoundManager:PlaySound("Scream")

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
        if collisionTag == TAG.Hazard and not self:IsDead() then
            self:Damage(self.hpmax)
        end
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
        elseif collisionType == gfx.sprite.kCollisionTypeOverlap then
            if collisionTag == TAG.Interactive then
                if collisionObject.IsTrigger then
                    collisionObject:Trigger()
                end
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
    if self.y > 400 and not self:IsDead() and not LoadNextLevel then
        self.skipdeathscreen = true
        self.hp = 0
        if not self.IsClone then
            UIIsnt:Death()
        end
    end
end

function Mipa:ProcessPulling()
    if self:IsPulling() then
        local bullet = Bullet(self.x, self.y-2)
        bullet:setImage(gfx.image.new("images/Effects/pull"), self.mirrored)
        bullet:setCollideRect(0, 0, 10, 10)
        if self.mirrored == gfx.kImageUnflipped then
            bullet.speed = 5
        else
            bullet.speed = -5
        end
        bullet.lifedistance = 49
        bullet.lastpushonhit = true
        bullet.OnHit = function (collision)
            local collisionObject = collision.other
            local collisionTag = collisionObject:getTag()
            if collisionTag == TAG.PropPushable then
                if collision.normal.x > 0 then
                    collisionObject:TryMoveRight()
                    collisionObject:ApplyVelocity()
                    SoundManager:PlaySound("Push")
                    bullet.lastpushonhit = false
                elseif collision.normal.x < 0 then
                    collisionObject:TryMoveLeft()
                    collisionObject:ApplyVelocity()
                    SoundManager:PlaySound("Push")
                    bullet.lastpushonhit = false
                end
            end
        end
    end
end

function Mipa:Interact()
    local _, _, collisions, length = self:checkCollisions(self.x, self.y)
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeOverlap then
            if collisionTag == TAG.Interactive then
                if collisionObject.IsButton then
                    collisionObject:PressButton()
                end
            end
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
        if pd.buttonJustPressed(pd.kButtonB) and self:IsDown() then
            self:NextEquipment()
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            self:Interact()
        end
    end
    self:ApplyVelocity()
    self:UpdateAnimation()
    if LoadNextLevel then
        if not self:IsDead() then
            if self.x > 450 or self.x < 50 or self.y > 290 then
                LoadNextLevel = false
                StartGame()
            end 
        end
    end
end