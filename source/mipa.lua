local pd <const> = playdate
local gfx <const> = pd.graphics

class("Mipa").extends(gfx.sprite)

PASSIVEITEMS = 
{
    None = 0,
    KoaKola = 1,
    Honey = 2,
    AdjustableJump = 3,
    MidFallJump = 4,
}

EQUIPMENT = 
{
    None = 0,
    MagnetHand = 1,
    PowerRing = 2,
}

function Mipa:init(x, y)
    self.mipaimages = AssetsLoader.LoadImageTable("images/mipa")
    self.mipaimagedithered = nil
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setCollideRect(3,3,8,11)
    self:add() -- Add to draw list
    self:setTag(TAG.Player)
    -- Stats
    self.hp = 4
    self.hpmax = 4
    self.equipment = {EQUIPMENT.MagnetHand}
    self.passiveitems = {}
    self.selectedequipment = 1
    -- Moving vars
    self.speed = 1.66
    self.pushingspeed = 1.12
    self.pullingspeed = 1.33
    self.airspeed = 1.99
    self.momentumX = 0
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
    self.slidesoundtimer = pd.frameTimer.new(5)
    self.slidesoundtimer.repeats = true
    self.slidesoundtimer.id = math.random()
    self.slidesoundtimer.timerEndedCallback = function(timer)
        if self.lastframonwall and self:HasPassiveItem(PASSIVEITEMS.Honey) and not self:IsOnFloor() then
            SoundManager:PlaySound("Slip", 0.08)
        end
    end
    self.holdingbox = nil
    self.lastframonwall = false
    self.jumpoffwallmomentum = 10
end

function Mipa:Konami()
    self.equipment = {EQUIPMENT.MagnetHand, EQUIPMENT.PowerRing}
    self.passiveitems = {PASSIVEITEMS.KoaKola, PASSIVEITEMS.Honey, PASSIVEITEMS.AdjustableJump, PASSIVEITEMS.MidFallJump}
end

function Mipa:AddPassiveItem(item)
    if not self:HasPassiveItem(item) then
        table.insert(self.passiveitems, item)
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

function Mipa:CurrentEquipment()
    return self.equipment[self.selectedequipment]
end

function Mipa:IsEquipped(device)
    return self:CurrentEquipment() == device
end

function Mipa:IsPulling()
    if self:IsOnFloor() and not self:IsDead() and not self:IsDown() and not self:IsPushing() and self:IsEquipped(EQUIPMENT.MagnetHand) then
        return pd.buttonIsPressed(pd.kButtonB) 
    end
    return false
end

function Mipa:IsCoyotTime()
    if self:HasPassiveItem(PASSIVEITEMS.MidFallJump) then
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
    self:AddAnimation("idlebox", {33, 34})
    self:AddAnimation("walkbox", {35, 36, 37})
    self:AddAnimation("downbox", {38})
    self:AddAnimation("sliping", {39, 40, 41}, 6)
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
    local affix = ""
    if self.holdingbox ~= nil then
        affix = "box"
    end
    if not self:IsDead() then
        if self:IsOnFloor() then
            if self:IsDown() then
                self:SetAnimation("down"..affix)
            else
                if self:IsMoving() then             
                    if self:IsPushing() then
                        self:SetAnimation("push")
                    else
                        if not self:IsPulling() then
                            self:SetAnimation("walk"..affix)
                        else
                            self:SetAnimation("walkpull")
                        end
                    end
                else
                    if self:IsPulling() then
                        self:SetAnimation("pull")
                    else
                        self:SetAnimation("idle"..affix)
                    end
                end
            end
        elseif self.lastframonwall then
            self:SetAnimation("sliping")
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
    local ditheredtable = AssetsLoader.GetAsset("images/mipadithred")
    if ditheredtable ~= nil then
        self.mipaimagedithered = ditheredtable
        return
    end
    ditheredtable = AssetsLoader.LoadImageTableAsNew("images/mipa", "images/mipadithred")
    for i = 1, #self.mipaimages, 1 do
        local img = self.mipaimages:getImage(i)
        ditheredtable:setImage(i, img:fadedImage(0.5, gfx.image.kDitherTypeBayer2x2))
    end
    self.mipaimagedithered = ditheredtable
end

function Mipa:UpdateAnimation()
    self:PickAnimation()
    local spritePath = self.currentanimation.."/"..self.animationframe
    local framechanged = self.lastimage ~= spritePath
    local imagetable = self.mipaimages
    if self.IsClone then
        if self.mipaimagedithered == nil then
            self:SetDitherImageTable()
        end
        if self:IsEvenFrame() then
            imagetable = self.mipaimagedithered
        else
            imagetable = self.mipaimages
        end
    end   
    if framechanged or self.IsClone then
        self:setImage(imagetable:getImage(self.animationframe), self.mirrored)
        self.lastimage = spritePath
    end
    self:ToggleEvenFrame()
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
    if self.momentumX ~= 0 then
        return false
    end
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
    if self.momentumX ~= 0 then
        return false
    end
    if not self:IsDead() and (not self:IsPulling() and not self:IsPulling()) then
        self.mirrored = gfx.kImageFlippedX
    end
    if not self:IsDown() then
        self.velocityX = -self:GetSpeed()
    end
    return false
end

function Mipa:TryJump()  
    if self.lastframonwall and self:HasPassiveItem(PASSIVEITEMS.Honey) then
        if self.mirrored == gfx.kImageFlippedX then
            self.momentumX = self.jumpoffwallmomentum
        else
            self.momentumX = -self.jumpoffwallmomentum
        end
        AnimEffect(self.x-12, self.y, "Effects/reflect", 1, true, false, self.mirrored)
        SoundManager:PlaySound("Splash", 0.2)
        return true
    end
    local canDoubleJump = self:HasPassiveItem(PASSIVEITEMS.KoaKola) and self.candoublejump
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

function Mipa:FatalDamage()
    if self:IsDead() or DebugFlags.NoDamage then
        return
    end

    self:Damage(self.hp)
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
    if self.lastframonwall and self:HasPassiveItem(PASSIVEITEMS.Honey) then
        if not pd.buttonIsPressed(pd.kButtonDown) then
            self.velocityY = 0.4
            self.slidesoundtimer.duration = 7
        else
            self.velocityY = 0.9
            self.slidesoundtimer.duration = 4
        end
    end
    if self:IsFlying() and self:HasPassiveItem(PASSIVEITEMS.AdjustableJump) then
        if not pd.buttonIsPressed(pd.kButtonA) then
            self.velocityY = 0
        end
    end
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
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    local actualX, actualY, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    local lastground = self.onground
    local lasthighestY = self.highestY
    local lastonwall = self.lastframonwall
    self.onground = false
    self.pusing = false
    self.lastframonwall = false
    local maytryclimb = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if (collisionTag == TAG.Hazard or collisionTag == TAG.HazardNoColide) and not self:IsDead() then
            self:FatalDamage()
        end
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if actualX ~= disiredX then
                if self:IsOnFloor() then
                    maytryclimb = true
                end
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
                            --if UIIsnt ~= nil then
                            --    UIIsnt:StartDialog(GetDialogDataFromString(""))
                            --end
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

            if self.holdingbox == nil then
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
                    if not lastground then
                        self.lastframonwall = true
                        if lastonwall == false and self:HasPassiveItem(PASSIVEITEMS.Honey) then
                            SoundManager:PlaySound("Splash", 0.1)
                        end
                        if collision.normal.x > 0 then
                            self.mirrored = gfx.kImageFlippedX
                        else
                            self.mirrored = gfx.kImageUnflipped
                        end
                    end
                end
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
        bullet:setImage(AssetsLoader.LoadImage("images/Effects/pull"), self.mirrored)
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
function Mipa:ApplyHoldingBox()
    if self.holdingbox ~= nil then
        local _x, _y = self:getPosition()
        local offset = 0
        if (self.currentanimation == "idlebox" or self.currentanimation == "walkbox") and self.animationindex == 2 then
            offset = 1
        elseif self.currentanimation == "downbox" then
            offset = 2
        end
        self.holdingbox:moveTo(_x, _y-12+offset)
    end
end
function Mipa:CheckSpaceForMipaWithBox(box)
    local _x, _y = self:getPosition()
    local offsetX = -7
    local offsetY = -7
    local collider = gfx.sprite.addEmptyCollisionSprite(_x+offsetX, _y+offsetY,1,1)
    collider:setTag(TAG.Effect)
    collider:setCollideRect(1,-9,12,23)
    local _, _, collisions, length = collider:checkCollisions(_x+offsetX, _y+offsetY)
    --gfx.sprite.removeSprite(collider)
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        print("colide ", i)
        if collisionObject ~= self and collisionObject ~= box and collisionTag ~= TAG.Effect then
            print("colide x ", collisionObject.x)
            print("colide y ", collisionObject.y)
            --gfx.sprite.removeSprite(collisionObject)
            return false
        end
    end
    return true
end
function Mipa:CheckSpaceForBox(futureX, futureY)
    local collider = gfx.sprite.addEmptyCollisionSprite(0,0,12,12)
    collider:moveTo(futureX, futureY)
    collider:setCollideRect(0,0,12,12)
    local _, _, collisions, length = collider:checkCollisions(futureX, futureY)
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType ~= gfx.sprite.kCollisionTypeOverlap and collisionObject ~= self then
            gfx.sprite.removeSprite(collider)
            return false
        end
    end
    gfx.sprite.removeSprite(collider)
    return true
end

function Mipa:RingAction()
    if self.holdingbox == nil then
        local facingoffset = 0
        if self.mirrored == gfx.kImageUnflipped then
            facingoffset = 5
        else
            facingoffset = -5
        end
        local _x, _y = self:getPosition()
        local _, _, collisions, length = self:checkCollisions(self.x+facingoffset, self.y)
        for i=1,length do
            local collision = collisions[i]
            local collisionType = collision.type
            local collisionObject = collision.other
            local collisionTag = collisionObject:getTag()
            if collisionTag == TAG.PropPushable then
                --if self:CheckSpaceForMipaWithBox(collisionObject) then
                if self:CheckSpaceForBox(_x, _y-12) then
                    self:setCollideRect(1,-9,12,23)
                    self.holdingbox = collisionObject
                    collisionObject:setTag(TAG.Effect)
                    collisionObject.velocityX = 0
                    collisionObject.velocityY = 0
                    collisionObject.momentumX = 0
                    SoundManager:PlaySound("Woop")
                else
                    SoundManager:PlaySound("No")
                end
            end
        end
    else
        local _x, _y = self:getPosition()
        local momentumvalue = 3
        local momentumImpulseX = 0
        local pushoff = 0
        if self.mirrored == gfx.kImageUnflipped then
            momentumImpulseX = momentumvalue
            pushoff = 12
        else
            momentumImpulseX = -momentumvalue
            pushoff = -12
        end
        local box_x, box_y = self.holdingbox:getPosition()
        if self:CheckSpaceForBox(box_x+pushoff, box_y) then
            self:setCollideRect(3,3,8,11)
            self.holdingbox:moveBy(pushoff, 0)
            self.holdingbox.momentumX = momentumImpulseX
            self.holdingbox.velocityY = momentumvalue
            self.holdingbox:setTag(TAG.PropPushable)
            self.holdingbox = nil
            SoundManager:PlaySound("Weep")
        else
            SoundManager:PlaySound("No")  
        end
    end
end

function Mipa:update()
    self.velocityX = 0
    if not self:IsDead() and (UIIsnt == nil or not UIIsnt:IsCutscene()) then
        self:ProcessWalking()
        if pd.buttonJustPressed(pd.kButtonA) then
            local jumped = self:TryJump()
            if jumped then
                SoundManager:PlaySound("Oop")
            end
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            if self:IsDown() then
                self:NextEquipment()
            else
                if self:IsEquipped(EQUIPMENT.PowerRing) then
                    self:RingAction()
                end
            end 
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
    self:ApplyHoldingBox()
end