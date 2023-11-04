local pd <const> = playdate
local gfx <const> = pd.graphics

class("Mipa").extends(gfx.sprite)

function Mipa:init(x, y)
    self.mipaimages = gfx.imagetable.new("images/mipa")
    self.mipaimagedithered = nil
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setCollideRect(3,3,8,11)
    self:add() -- Add to draw list
    self:setTag(TAG.Player)
    -- Stats
    self.hp = 4
    self.hpmax = 4
    self.equipment = {1}
    self.passiveitems = {}
    self.selectedequipment = 1
    -- Moving vars
    self.speed = 1.66
    self.pushingspeed = 1.1
    self.pullingspeed = 1.33
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
    self.candoublejump = true
    self.midfalljump = false
    self.freefall = 0
    self.highestY = self.y
    self.coyoteframes = 5
    self.coyotetime = self.coyoteframes
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
    self.pulltimer.id = math.random()
    self.pulltimer.timerEndedCallback = function(timer)
        self:ProcessPulling()
    end
end

function Mipa:HasPassiveItem(item)
    for i = 1, #self.passiveitems, 1 do
        if self.passiveitems[i] == item then
            return true
        end
    end
    return false
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
    if self:IsOnFloor() and not self:IsDead() and not self:IsDown() and not self:IsPushing() and self.equipment[self.selectedequipment] == 1 then
        return pd.buttonIsPressed(pd.kButtonB) 
    end
    return false
end

function Mipa:IsCoyotTime()
    if self.midfalljump then
        return true
    end

    return self.coyotetime < self.coyoteframes
end

function Mipa:NextEquipment()
    if self.selectedequipment == #self.equipment then
        self.selectedequipment = 1
    else
        self.selectedequipment = self.selectedequipment +1;
    end
    UIIsnt:UpdateEquipment(self.equipment, self.selectedequipment, self.passiveitems)
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
    self:AddAnimation("walkpull", {30, 31, 32})
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
                        if not self:IsPulling() then
                            self:SetAnimation("walk")
                        else
                            self:SetAnimation("walkpull")
                        end
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

function Mipa:GetSpeed()
    if not self:IsDown() then
        if not self:IsPushing() and not self:IsPulling() then
            if self:IsOnFloor() then
                return self.speed
            else
                return self.airspeed
            end
        elseif self:IsPushing() then
            return self.pushingspeed
        elseif self:IsPulling() then
            return self.pullingspeed
        end
    end
    return 0
end

function Mipa:TryMoveRight()
    if not self:IsDead() and (not self:IsPulling() and not self:IsPulling())then -- So when push her body she not facing to motion direction
        self.mirrored = gfx.kImageUnflipped
    end
    if not self:IsDown() then
        self.velocityX = self:GetSpeed()
        return true
    end
    return false
end

function Mipa:TryMoveLeft() -- So when push her body she not facing to motion direction
    if not self:IsDead() and (not self:IsPulling() and not self:IsPulling()) then
        self.mirrored = gfx.kImageFlippedX
    end
    if not self:IsDown() then
        self.velocityX = -self:GetSpeed()
    end
    return false
end

function Mipa:TryJump()  
    local canDoubleJump = self:HasPassiveItem(1) and self.candoublejump
    if self:IsOnFloor() or (self:IsCoyotTime() and not self:IsOnFloor()) then
        if self.canjump then
            self.canjump = false
            self.velocityY = self.maxjumpvelocity
            return true
        end
    end
    if not self:IsOnFloor() and canDoubleJump then
        self.candoublejump = false
        self.velocityY = self.maxjumpvelocity
        return true
    end
end

function Mipa:collisionResponse(other)
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or (other:getTag() == TAG.HazardNoColide) then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Mipa:Damage(damage)
    if self:IsDead() or DebugFlags.NoDamage then
        return
    end

    if damage > self.hp then
        self.hp = 0
    else
        self.hp = self.hp-damage
    end

    if self:IsDead() then
        if UIIsnt ~= nil then
            UIIsnt:CancleDialog()
        end
        self.speed = 1.01 -- so will be able to push her body without animation glitched, like a box
        SoundManager:PlaySound("MipaGameOver")
    end

    InvertedColorsFrames = InvertedColorsFrames+4
    SoundManager:PlaySound("Scream")
end

function Mipa:TryClimb()
    print("Try climb")
    local _x, _y = self:getPosition()
    local feetsY = _y-12
    local disiredX = _x + self.velocityX
    local disiredY = _y - 19
    local actualX, actualY, collisions, length = self:checkCollisions(disiredX, disiredY)
    local futureFeetsY = actualY-12
    print("[Try climb] disiredX ", disiredX)
    print("[Try climb] disiredY ", disiredY)
    print("[Try climb] actualX ", actualX)
    print("[Try climb] actualY ", actualY)
    if feetsY > futureFeetsY and actualX == disiredX then
        
        self:moveTo(actualX, actualY)
    end
    return false
end
function Mipa:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    local actualX, actualY, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    local lastground = self.onground
    local lasthighestY = self.highestY
    self.onground = false
    self.pusing = false
    local maytryclimb = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if (collisionTag == TAG.Hazard or collisionTag == TAG.HazardNoColide) and not self:IsDead() then
            self:Damage(self.hpmax)
        end
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if actualX ~= disiredX and self:IsOnFloor() then
                maytryclimb = true
            end
            if collision.normal.y == -1 then
                self.onground = true
                self.canjump = true
                self.coyotetime = 0
                self.candoublejump = true
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
                        AnimEffect(self.x-7, collision.otherRect.y-14, "Effects/ground", 1, true)
                        SoundManager:PlaySound("Bloop", landvolume)
                        if collisionObject ~= nil and collisionObject.Breaks ~= nil then
                            gfx.sprite.removeSprite(collisionObject)
                        end
                    end                
                end
                if collisionObject.enemyname ~= nil and collisionObject.enemyname == "blob" then
                    if not collisionObject.squshed then
                        collisionObject.squshed = true
                        collisionObject.thinkticks = 0
                    end
                end
            elseif collision.normal.y == 1 then
                self.velocityY = 0
            end
            --print("collision.other ", collision.other.y)    
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
                if collisionObject.IsTrigger and not self:IsDead() then
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
    if self.y < 35 then
        self.velocityY = 0
        self.y = 35
    end
    if self:IsFalling()  then
        if self:IsCoyotTime() then
            self.coyotetime = self.coyotetime+1
        else
            self.canjump = false
        end
    end
    if maytryclimb then
        --self:TryClimb()
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
        --SoundManager:PlaySound("BeamLoop")
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
            local jumped = self:TryJump()
            if jumped then
                SoundManager:PlaySound("Oop")
            end
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
    if not self:IsDead() and self.hp == 1 and not self.IsClone then
        if UIIsnt ~= nil then
            if math.random(0,100) <= 0.002 then
                UIIsnt.glitchframes = math.floor(math.random(2,7)+0.5)
            end
        end
    end
end