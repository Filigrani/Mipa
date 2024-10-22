local pd <const> = playdate
local gfx <const> = pd.graphics

class("Mipa").extends(gfx.sprite)

-- Optimize calls of requisting settings
local LowHpFXEnabled = SettingsManager:Get("lowhpglitches")
local DamageGlitchesEnabled = SettingsManager:Get("damageglitches")

PASSIVEITEMS = 
{
    None = 0,
    KoaKola = 1,
    Honey = 2,
    AdjustableJump = 3,
    MidFallJump = 4,
    Flippers = 5,
}

EQUIPMENT = 
{
    None = 0,
    MagnetHand = 1,
    PowerRing = 2,
    Bomber = 3,
    Thunder = 4,
}

function Mipa:init(x, y)
    self.mipaimages = AssetsLoader.LoadImageTable("images/mipa")
    self.mipaimagedithered = nil
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self.JobeeColisionApplied = false
    self:setCollideRect(3,3,8,11)
    self:setTag(TAG.Player)
    self.damagerectangle = gfx.sprite.new()
    self.damagerectangle:setCenter(0.5, 0.5)
    self.damagerectangle:setCollideRect(3,3,8,11)

    self.damagerectangle:setTag(TAG.Effect)  
    self.damagerectangle:add()
    --self:moveTo(x, y)
    -- Stats
    self.hp = 4
    self.hpmax = 4

    if LIQUID_TEST then
        self.equipment = {EQUIPMENT.Thunder}
        self.passiveitems = {PASSIVEITEMS.Flippers}
    else
        self.equipment = {EQUIPMENT.MagnetHand}
        self.passiveitems = {}
    end
    
    
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
    self.canbecontrolled = true
    -- Physic
    self.maxjumpvelocity = -10
    self.maxjumpvelocityinliquid = -6
    self.maxjumpvelocityjobee = -1.3
    self.gravity = 1
    self.gravityinliquid = 0.3
    self.gravityjobee = 1.6
    self.gravityjobeefall = 0.1
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
    self.lastmirrored = gfx.kImageUnflipped
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
    
    self.onbridge = false
    self.skipfalldamage = false

    self.IsMipa = true
    self.physichybirnateframes = 2

    self.Jobee = nil

    self:add() -- Add to draw list
    CrankManager:AddCrankables(self)
end

function Mipa:Konami()
    self.equipment = {EQUIPMENT.MagnetHand, EQUIPMENT.PowerRing, EQUIPMENT.Bomber, EQUIPMENT.Thunder}
    --self.passiveitems = {PASSIVEITEMS.KoaKola, PASSIVEITEMS.Honey, PASSIVEITEMS.AdjustableJump, PASSIVEITEMS.MidFallJump}
    self.passiveitems = {PASSIVEITEMS.KoaKola, PASSIVEITEMS.Flippers}
end

function Mipa:AddPassiveItem(item)
    if not self:HasPassiveItem(item) then
        table.insert(self.passiveitems, item)
    end
end

function Mipa:AddEquipment(item)
    if not self:HasEquipment(item) then
        table.insert(self.equipment, item)
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

function Mipa:HasEquipment(item)
    for i = 1, #self.equipment, 1 do
        if self.equipment[i] == item then
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
    if self:CanControl() and self:IsOnFloor() and pd.buttonIsPressed(pd.kButtonDown) then
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
    if self:CanControl() and self:IsOnFloor() and not self:IsDead() and not self:IsDown() and not self:IsPushing() and self:IsEquipped(EQUIPMENT.MagnetHand) then
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
    self:AddAnimation("shootbomb", {42})
    self:AddAnimation("jobeeflyidle", {44, 45, 46}, 7)
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
    if self.Jobee ~= nil then
        self:SetAnimation("jobeeflyidle")
        return
    end
    if not self:IsDead() then
        if self.shootbombtimer then
            self:SetAnimation("shootbomb")
            return
        end
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

function Mipa:SetMirrored(mirrored)
    
    if self.Jobee then
        self.mirrored = gfx.kImageUnflipped
        return
    end
    
    if mirrored then
        self.mirrored = gfx.kImageFlippedX
    else
        self.mirrored = gfx.kImageUnflipped
    end
end

function Mipa:IsMirrored()
    return self.mirrored == gfx.kImageFlippedX
end

function Mipa:SetMirrored(IsMirrored)
    if IsMirrored then
        self.mirrored = gfx.kImageFlippedX
    else
        self.mirrored = gfx.kImageUnflipped
    end
    self:ReRender()
end

function Mipa:ReRender()
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
    if not CheatsManager.MipaTrashMode then
        self:setImage(imagetable:getImage(self.animationframe), self.mirrored)
    else
        self:setImage(AssetsLoader.LoadImage("images/Props/Trash"), self.mirrored)
    end
end

function Mipa:UpdateAnimation()
    self:PickAnimation()
    local spritePath = self.currentanimation.."/"..self.animationframe
    local framechanged = self.lastimage ~= spritePath

    if framechanged or self.IsClone or (self.lastmirrored ~= self.mirrored) then
        self:ReRender()
        self.lastimage = spritePath
        self.lastmirrored = self.mirrored
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
    if not self:IsDead() and (not self:IsPulling() and not self:IsPulling()) and not (self.Jobee and self.JobeeCrank) then -- So when push her body she not facing to motion direction
        self:SetMirrored(false)
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
    if not self:IsDead() and (not self:IsPulling() and not self:IsPulling()) and not (self.Jobee and self.JobeeCrank) then
        self:SetMirrored(true)
    end
    if not self:IsDown() then
        self.velocityX = -self:GetSpeed()
    end
    return false
end

function Mipa:DoWingsFX()
    local wings = AnimEffect(0, 0, "Effects/wings", 1, true, false, self.mirrored)
    wings.Mipa = self
    wings.CustomUpdate = function ()
        if wings.Mipa then
            if wings.Mipa:IsMirrored() then
                wings:moveTo(self.x+5, self.y-7)
            else
                wings:moveTo(self.x-17, self.y-7)
            end
        end
    end
    wings.CustomUpdate()
end

function Mipa:DoCloudsFX()
    local _x, _y = self:getPosition()
    _x = _x-5
    local bigcloudSpread = 15
    local bigcloudYOffset = 5
    AnimEffect(_x, _y+bigcloudYOffset, "Effects/BigCloud", 2, true, false, self.mirrored)
    AnimEffect(_x-bigcloudSpread, _y+bigcloudYOffset, "Effects/BigCloud", 2, true, false)
    AnimEffect(_x+bigcloudSpread, _y+bigcloudYOffset, "Effects/BigCloud", 2, true, false, true)
    local cloudTimer = pd.frameTimer.new(1)
    cloudTimer.Mipa = self
    cloudTimer.timerEndedCallback = function(timer)
        _x, _y = cloudTimer.Mipa:getPosition()
        if not self:IsFlying() then
            cloudTimer:remove()
        end
        for i = 1, 2, 1 do
            local speadX = 12
            local spreadY = 2
            local effectX = math.floor(math.random(-speadX,speadX)+0.5)
            local effectY = math.floor(math.random(-spreadY,spreadY)+0.5)
            local animSpeed = math.floor(math.random(1,3)+0.5)
            local effect = AnimEffect(_x+effectX, _y+effectY, "Effects/SmallParticle", animSpeed, true, false)
        end
    end
    cloudTimer.repeats = true
    cloudTimer:start()
end

function Mipa:GetMaxJumpVelocity()
    if self:InLiquid() then
        return self.maxjumpvelocityinliquid
    end
    if self.Jobee then
        
        if self.JobeeCrank then
            return 0
        else
            return self.maxjumpvelocityjobee
        end
    end
    return self.maxjumpvelocity
end


function Mipa:TryJump()
    
    if self.Jobee then
        if self.JobeeCrank then
            self.velocityY = 0
            return false
        else
            self.velocityY = self:GetMaxJumpVelocity()
            return true
        end
    end
    
    if self.inliquid and self:HasPassiveItem(PASSIVEITEMS.Flippers) then
        if self.onliquidsurface then
            self.velocityY = self:GetMaxJumpVelocity()
        else
            self.velocityY = self:GetMaxJumpVelocity()/2
        end
        return true
    end
    if self.lastframonwall and self:HasPassiveItem(PASSIVEITEMS.Honey) then
        if self:IsMirrored() then
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
            self.velocityY = self:GetMaxJumpVelocity()
            return true
        end
    end

    if not self:IsOnFloor() and canDoubleJump then
        self.candoublejump = false
        self.highestY = self.y
        self.velocityY = self:GetMaxJumpVelocity()
        self:DoCloudsFX()
        SoundManager:PlaySound("Pfff")
        return true
    end
end

function Mipa:collisionResponse(other)
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or (other:getTag() == TAG.HazardNoColide) then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Mipa:Damage(damage, ignoreimmune)
    if self:IsDead() or DebugFlags.NoDamage then
        return
    end

    if ignoreimmune == nil then
        if self.damageimunetimer == nil then
            self.damageimunetimer = pd.frameTimer.new(30)
            self.damageimunetimer.repeats = false
            self.damageimunetimer.timerEndedCallback = function(timer)
                self.damageimunetimer = nil
            end
        else
            return
        end
    end

    if damage > self.hp then
        self.hp = 0
    else
        self.hp = self.hp-damage
        
        if DamageGlitchesEnabled and self.Jobee == nil then
            if UIIsnt ~= nil then
                UIIsnt.glitchframes = 3
                InvertedColorsFrames = InvertedColorsFrames+1
            end
        end
    end

    if self:IsDead() then
        if UIIsnt ~= nil then
            UIIsnt:CancleDialog()
        end
        self.speed = 1.01 -- so will be able to push her body without animation glitched, like a box
        SoundManager:PlaySound("MipaGameOver")
        SoundManager:PauseMusic()
        self:GetRidOffBox()
    end
    SoundManager:PlaySound("Scream")
end

function Mipa:FatalDamage()
    if self:IsDead() or DebugFlags.NoDamage then
        return
    end

    self:Damage(self.hp, true)
end

function Mipa:InLiquid()
    return self.inliquid
end

function Mipa:GetGravity()
    if self:InLiquid() then
        return self.gravityinliquid
    end
    if self.Jobee then
        if self.JobeeCrank then
            return 0
        else
            return self.gravityjobee
        end
    end
    return self.gravity
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

function Mipa:CrankChanged(change, absolute)
    if self.Jobee and self.JobeeCrank then
        self.velocityY = change
    end
end

function Mipa:ApplyVelocity()
    if self.crushed then
        return
    end

    if self.Jobee then
        
        if self.JobeeCrank then
            self.velocityX = 2.99
        else
            if self.velocityY >= 0 then
                self.velocityY = self:GetGravity()
            else
                self.velocityY = self.velocityY+self.gravityjobeefall
            end
            --print("Velocity ", self.velocityY)
        end
    else
        self.velocityY = self.velocityY+self:GetGravity()
    end
    

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
        self.momentumX = self.momentumX-self:GetGravity()
        if self.momentumX <= 0 then
            self.momentumX = 0
        end
    elseif self.momentumX < 0 then
        self.momentumX = self.momentumX+self:GetGravity()
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
    --print("-----------ApplyVelocity------------- ")
    --print("self.x ", self.x)
    --print("self.y ", self.y)
    --print("velocityX ", self.velocityX)
    --print("velocityY ", self.velocityY)
    --print("disiredX ", disiredX)
    --print("disiredY ", disiredY)
    local actualX, actualY, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    if self.damagerectangle then
        self.damagerectangle:moveTo(actualX-7, actualY-7)
    end
    if disiredX ~= actualX then
        if self.Jobee and self.JobeeCrank then
            self.Jobee:setCollideRect(3,6,8,11)
            --gfx.sprite.removeSprite(self.Jobee)
            self.Jobee.death = true
            self.Jobee.gravity = 0.53
            self.Jobee.momentumX = -8
            self.Jobee = nil
            self.momentumX = -9
            self:setCollideRect(3,3,8,11)
            --self.JobeeCrank = false
            self:FatalDamage()
        end
    end
    --print("actualX ", actualX)
    --print("actualY ", actualY)
    local lastground = self.onground
    local lasthighestY = self.highestY
    local lastonwall = self.lastframonwall
    local lastinliquid = self.inliquid
    self.onground = false
    self.pusing = false
    self.lastframonwall = false
    self.onbridge = false
    self.inliquid = false
    self.onliquidsurface = false
    self.elevator = nil
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        
        if collisionObject.IsFunnyBringe then
            self.onbridge = true
        end
        if collisionObject.IsElevator then
            self.elevator = collisionObject
        end
        if collisionObject.IsLiquid then
            self.inliquid = true
            self.highestY = self.y
        end
        if collisionObject.IsLiquidSurface then
            self.onliquidsurface = true
        end

        if (collisionTag == TAG.Hazard or collisionTag == TAG.HazardNoColide) or (collisionObject.IsLiquid and collisionObject.IsElectrified) and not self:IsDead() then
            local allowDamage = true
            if self.holdingbox ~= nil and self.damagerectangle then
                local colrect = collisionObject:getBoundsRect()
                local damrect = self.damagerectangle:getBoundsRect()
                damrect.width = 8
                damrect.height = 11
                local inter = colrect:intersection(damrect)
                if inter:isEmpty() then
                    allowDamage = false
                end
            end
            if allowDamage then
                if collisionObject.CustomHazardFn ~= nil then
                    --print("Mipa CustomHazardFn")
                    collisionObject.CustomHazardFn(self)
                    if collisionObject.destoryOnDamage then
                        gfx.sprite.removeSprite(collisionObject)
                    end
                else
                    if collisionObject.damage == 0 or collisionObject.damage == nil then
                        self:FatalDamage()
                    else
                        self:Damage(collisionObject.damage)
                    end
                    if collisionObject.destoryOnDamage then
                        gfx.sprite.removeSprite(collisionObject)
                    end
                end
            end
        end
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.onground = true
                self.canjump = true
                self.coyotetime = 0
                self.candoublejump = true
                self.velocityY = 0
                self.highestY = self.y

                if collisionObject.IsConveyorBelts then
                    if collisionObject.Inversed then
                        self.velocityXnextframe  = -1
                    else
                        self.velocityXnextframe = 1
                    end
                elseif collisionObject.velocityXnextframe then
                    self.velocityXnextframe = collisionObject.velocityXnextframe
                end

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
                            if not self.skipfalldamage or self.Jobee then
                                self:Damage(1)
                            else
                                self.skipfalldamage = false
                            end
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
            elseif collision.normal.y == 1 then
                self.velocityY = 0
            end

            if self.holdingbox == nil then
                if collisionTag == TAG.PropPushable and (lastground or self.inliquid) then
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
                    if self.onbridge and collisionTag ~= TAG.PropPushable  then
                        self.velocityY = -3
                    else
                        self.pusing = true
                        if not lastground then
                            self.lastframonwall = true
                            if lastonwall == false and self:HasPassiveItem(PASSIVEITEMS.Honey) then
                                SoundManager:PlaySound("Splash", 0.1)
                            end
                            if collision.normal.x > 0 then
                                self:SetMirrored(true)
                            else
                                self:SetMirrored(false)
                            end
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
            if UIIsnt ~= nil then
                UIIsnt:CancleDialog()
                UIIsnt:Death()
            end
            SoundManager:PlaySound("MipaGameOver")
            SoundManager:PauseMusic()
            self:GetRidOffBox()
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
    if lastinliquid ~= self.inliquid then
        AnimEffect(_x-7, _y-7, "Effects/ground", 1, true)
        if self.inliquid then
            self.velocityY = self.velocityY/3
        end
    end
    if self.JobeeCrank and self.Jobee then
        self.velocityY = 0
    end
end

function Mipa:ProcessPulling()
    if self:IsPulling() then
        local bullet = Bullet(self.x, self.y-2)
        bullet:setImage(AssetsLoader.LoadImage("images/Effects/pull"), self.mirrored)
        bullet:setCollideRect(0, 0, 10, 10)
        if not self:IsMirrored() then
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
    --UIIsnt:ShowSpecificGroup()
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
    local collisions = collider:overlappingSprites(_x+offsetX, _y+offsetY)
    gfx.sprite.removeSprite(collider)
    for i=1,#collisions do
        local collisionObject = collisions[i]
        local collisionTag = collisionObject:getTag()
        if collisionObject ~= self and collisionObject ~= box and collisionTag ~= TAG.Effect then
            return false
        end
    end
    return true
end
function Mipa:CheckSpaceForBox(futureX, futureY)
    local collider = gfx.sprite.addEmptyCollisionSprite(futureX,futureY,12,12)
    collider:setTag(TAG.Effect)
    local collisions = collider:overlappingSprites()
    for i=1,#collisions do
        local collisionObject = collisions[i]
        local collisionTag = collisionObject:getTag()
        if collisionObject ~= self and collisionTag ~= TAG.Effect then
            gfx.sprite.removeSprite(collider)
            return false
        end
    end
    gfx.sprite.removeSprite(collider)
    return true
end

function Mipa:TryThroweBoxUpward()
    local _x, _y = self:getPosition()
    local momentumvalue = 3
    local momentumImpulseX = 0
    local pushoff = 0
    if not self:IsMirrored() then
        momentumImpulseX = momentumvalue
        pushoff = 8
    else
        momentumImpulseX = -momentumvalue
        pushoff = -20
    end
    local box_x, box_y = self.holdingbox:getPosition()
    if self:CheckSpaceForBox(box_x+pushoff, box_y-16) then
        self:setCollideRect(3,3,8,11)
        self.holdingbox:moveTo(box_x+pushoff+6, box_y-10)
        self.holdingbox.momentumX = momentumImpulseX
        self.holdingbox.velocityY = momentumvalue
        self.holdingbox:setTag(TAG.PropPushable)
        self.holdingbox.notapplyimpulses = false
        self.holdingbox.gravity = 0.35
        self.holdingbox = nil
        SoundManager:PlaySound("Weep")
        return true
    end
    return false
end

function Mipa:TryThroweBoxForward()
    local _x, _y = self:getPosition()
    local momentumvalue = 3
    local momentumImpulseX = 0
    local pushoff = 0
    if not self:IsMirrored() then
        momentumImpulseX = momentumvalue
        pushoff = 8
    else
        momentumImpulseX = -momentumvalue
        pushoff = -20
    end
    local box_x, box_y = self.holdingbox:getPosition()
    if self:CheckSpaceForBox(box_x+pushoff, box_y) then
        self:setCollideRect(3,3,8,11)
        self.holdingbox:moveTo(box_x+pushoff+6, box_y+7)
        self.holdingbox.momentumX = momentumImpulseX
        self.holdingbox.velocityY = momentumvalue
        self.holdingbox:setTag(TAG.PropPushable)
        self.holdingbox.notapplyimpulses = false
        self.holdingbox.gravity = 0.35
        self.holdingbox = nil
        SoundManager:PlaySound("Weep")
        return true
    end
    return false
end

function Mipa:GetRidOffBox()
    if self.holdingbox then
        self:setCollideRect(3,3,8,11)
        self.holdingbox:setTag(TAG.PropPushable)
        self.holdingbox.notapplyimpulses = false
        self.holdingbox.gravity = 0.35
        self.holdingbox = nil
    end
end

function Mipa:TryPlaceBox()
    local _x, _y = self:getPosition()
    local momentumvalue = 3
    local momentumImpulseX = 0
    local pushoff = 0
    if not self:IsMirrored() then
        momentumImpulseX = momentumvalue
        pushoff = 8
    else
        momentumImpulseX = -momentumvalue
        pushoff = -20
    end
    local box_x, box_y = self.holdingbox:getPosition()
    if self:CheckSpaceForBox(box_x+pushoff, box_y+5) then
        self:setCollideRect(3,3,8,11)
        self.holdingbox:moveTo(box_x+pushoff+6, box_y+11)
        self.holdingbox:setTag(TAG.PropPushable)
        self.holdingbox.notapplyimpulses = false
        self.holdingbox.gravity = 0.35
        self.holdingbox = nil
        SoundManager:PlaySound("Woop")
        return true
    end
    return false
end

function Mipa:RingAction()
    if self.holdingbox == nil then
        local facingoffset = 0
        if not self:IsMirrored() then
            facingoffset = 3
        else
            facingoffset = -15
        end
        local _x, _y = self:getPosition()
        local collider = gfx.sprite.addEmptyCollisionSprite(_x+facingoffset, _y-5, 12, 12)
        collider:setTag(TAG.Effect);
        local collisions = collider:overlappingSprites()
        for i=1,#collisions do
            local collisionObject = collisions[i]
            local collisionTag = collisionObject:getTag()
            if collisionTag == TAG.PropPushable or (collisionTag == TAG.Enemy and collisionObject.IsGrabbable) then
                if self:CheckSpaceForMipaWithBox(collisionObject) then
                    self:setCollideRect(1,-9,12,23)
                    self.holdingbox = collisionObject
                    collisionObject:setTag(TAG.Effect)
                    collisionObject.velocityX = 0
                    collisionObject.velocityY = 0
                    collisionObject.momentumX = 0
                    collisionObject.notapplyimpulses = true
                    SoundManager:PlaySound("Woop")
                else
                    SoundManager:PlaySound("No")
                end
            end
        end
        gfx.sprite.removeSprite(collider)
    else
        if not self:TryThroweBoxUpward() then
           if not self:TryThroweBoxForward() then
                if not self:TryPlaceBox() then
                    SoundManager:PlaySound("No")
                end
            end
        end
    end
end

function Mipa:ThunderAction()
    if self.lastbomb ~= nil then
        SoundManager:PlaySound("No")
        return
    end

    if self:InLiquid() then
        local tile = CurrentLevel:GetLiquidTileByWorld(self.x, self.y)
        if tile then
            CurrentLevel:ElectrifyLiquid(tile, "SHOCK "..math.floor(math.random(1,300000)+0.5))
            return
        end
    end
    
    if self.shootbombtimer == nil then
        self.shootbombtimer = pd.frameTimer.new(7)
        self.shootbombtimer.repeats = false
        self.shootbombtimer.timerEndedCallback = function(timer)
            self.shootbombtimer = nil
        end
    end
    local bullet = Bullet(self.x, self.y-2)
    bullet:setImage(AssetsLoader.LoadImage("images/Effects/ElecShockBullet"), self.mirrored)
    bullet.mirrored = self.mirrored
    bullet:setCollideRect(0, 2, 7, 9)
    self.lastbomb = bullet
    local starttrailoffset = 0
    if not self:IsMirrored() then
        bullet.speed = 7
        starttrailoffset = -18
    else
        bullet.speed = -7
        starttrailoffset = 4
    end
    local StartTrail = AnimEffect(-20, 0, "Effects/ElecShock", 1, false, false, bullet.mirrored)
    StartTrail:SetFollowParent(bullet, starttrailoffset, -7)
    StartTrail.trailIndex = 5
    table.insert(bullet.trailchilds, StartTrail)
    
    StartTrail.OnDestory = function ()
        StartTrail.removetimer = pd.frameTimer.new(StartTrail.trailIndex)
        StartTrail.removetimer.timerEndedCallback = function(timer)
            gfx.sprite.removeSprite(StartTrail)
        end
        StartTrail.removetimer.repeats = false
        StartTrail.removetimer:start()
    end
    SoundManager:PlaySound("ShockShot")
    bullet.lifedistance = 300
    bullet.lastpushonhit = false
    bullet.colideWithLiquid = true
    bullet.CustomUpdate = function()
        local t = bullet:GetTraveled()
        if t >= 14 then
            bullet:SetTraveled(0)
            
            local Trails = #bullet.trailchilds
            if Trails < 5 then
                local Trail = AnimEffect(-20, 0, "Effects/ElecShock", 1, false, false, bullet.mirrored)
                Trail.trailIndex = 5-Trails
                local xoffset = -14
                if bullet.speed < 0 then
                    xoffset = 14
                end
                Trail:SetFollowParent(bullet.trailchilds[Trails], xoffset, 0)
                Trail.OnDestory = function ()
                    Trail.removetimer = pd.frameTimer.new(Trail.trailIndex)
                    Trail.removetimer.timerEndedCallback = function(timer)
                        gfx.sprite.removeSprite(Trail)
                    end
                    Trail.removetimer.repeats = false
                    Trail.removetimer:start()
                end
                table.insert(bullet.trailchilds, Trail)
            end
        end
    end
    ---bullet.colnResponse = function (other)
    ---    if other.IsLiquid then
    ---        return gfx.sprite.kCollisionTypeSlide
    ---    else
    ---        if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Player or other:getTag() == TAG.Interactive or other:getTag() == TAG.HazardNoColide or other:getTag() == TAG.ObstacleCastNoPlayer) then
    ---            return gfx.sprite.kCollisionTypeOverlap
    ---        end
    ---    end
    ---    return gfx.sprite.kCollisionTypeSlide
    ---end
    bullet.OnHit = function (collision)
        SoundManager:PlaySound("BeamLoop")
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionObject ~= nil then
            if collisionObject.IsLiquid and not collisionObject.IsMergedCollider then
                CurrentLevel:ElectrifyLiquid(collisionObject, "SHOCK "..math.floor(math.random(1,300000)+0.5))
            else
                local shock_x = bullet.x+bullet.speed
                local shock_y = bullet.y
                if collisionObject.IsPhysProp then
                    shock_x = collisionObject.x
                    shock_y = collisionObject.y+2
                end
                local tile = CurrentLevel:GetLiquidTileByWorld(shock_x, shock_y)
                if tile then
                    CurrentLevel:ElectrifyLiquid(tile, "SHOCK "..math.floor(math.random(1,300000)+0.5))
                else
                    print("Wasn't able to find tile by merged collider")
                end
            end
        end
    end
    bullet.OnDestory = function()
        if self.lastbomb == bullet then
            self.lastbomb = nil
        end
    end
end

function Mipa:BomberAction()
    if self.lastbomb ~= nil then
        SoundManager:PlaySound("No")
        return
    end 
    
    if self.shootbombtimer == nil then
        self.shootbombtimer = pd.frameTimer.new(7)
        self.shootbombtimer.repeats = false
        self.shootbombtimer.timerEndedCallback = function(timer)
            self.shootbombtimer = nil
        end
    end
    local bullet = Bullet(self.x, self.y-2)
    bullet:setImage(AssetsLoader.LoadImage("images/Effects/bomb"), self.mirrored)
    bullet.mirrored = self.mirrored
    bullet:setCollideRect(2, 1, 6, 6)
    self.lastbomb = bullet
    if not self:IsMirrored() then
        bullet.speed = 7
    else
        bullet.speed = -7
    end
    SoundManager:PlaySound("Woop")
    bullet.lifedistance = 300
    bullet.lastpushonhit = false
    bullet.OnHit = function (collision)
        SoundManager:PlaySound("Heavyland")
        Clashbomb(bullet.x-4, bullet.y-4, bullet.mirrored, self)
    end
    bullet.OnDestory = function()
        if self.lastbomb == bullet then
            self.lastbomb = nil
        end
    end
end

function Mipa:AnimStunLock()
    return self.shootbombtimer ~= nil
end

function Mipa:CanControl()
    if not self.canbecontrolled then
        return false
    end
    return not self:IsDead() and (UIIsnt == nil or (not UIIsnt:IsCutscene() and not UIIsnt:IsShowingPause() and not UIIsnt:IsConversation())) and not self:AnimStunLock()
end

function Mipa:update()
    self.velocityX = 0
    if self:CanControl() and self.physichybirnateframes == 0 then
        self:ProcessWalking()
        if pd.buttonJustPressed(pd.kButtonA) then
            local jumped = self:TryJump()
            if jumped then
                SoundManager:PlaySound("Oop")
            end
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            if self:IsDown() then
                if self.holdingbox ~= nil then
                    if not self:TryPlaceBox() then
                        SoundManager:PlaySound("No")
                    end
                else
                    self:NextEquipment()
                end
            else
                if self:IsEquipped(EQUIPMENT.PowerRing) then
                    self:RingAction()
                elseif self:IsEquipped(EQUIPMENT.Bomber) and self:IsOnFloor() then
                    self:BomberAction()
                elseif self:IsEquipped(EQUIPMENT.Thunder) then
                    self:ThunderAction()
                end
            end 
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            self:Interact()
        end
    else
        if self.scriptedMoveToX ~= nil then
            local _x, _y = self:getPosition()
            if self.scriptedMoveToX < _x then
                local dist = _x-self.scriptedMoveToX
                if dist <= 1.1 then
                    self.scriptedMoveToX = nil
                else
                    self:TryMoveLeft()
                end
            elseif self.scriptedMoveToX > _x then
                local dist = self.scriptedMoveToX-_x
                if dist <= 1.1 then
                    self.scriptedMoveToX = nil
                else
                    self:TryMoveRight()
                end
            else
                self.scriptedMoveToX = nil
            end
        end
    end
    if self.physichybirnateframes > 0 then
        self.physichybirnateframes = self.physichybirnateframes-1
    else
        self:ApplyVelocity()
    end
    
    self:UpdateAnimation()
    if LoadNextLevel then
        if not self:IsDead() then
            if self.x > RightEdge or self.x < LeftEdge or self.y > 290 or self.y < 35 then
                LoadNextLevel = false
                StartGame()
            end
        end
    end
    if LowHpFXEnabled and not self.Jobee then
        if not self:IsDead() and self.hp == 1 and not self.IsClone then
            if UIIsnt ~= nil then
                if math.random(0,100) <= 0.002 then
                    UIIsnt.glitchframes = math.floor(math.random(2,7)+0.5)
                end
            end
        end
    end
    self:ApplyHoldingBox()

    if self.Jobee then
        local _x, _y = self:getPosition()
        self.Jobee:moveTo(_x+5, _y-13)
        if not self.JobeeColisionApplied then
            self.JobeeColisionApplied = true
            self:setCollideRect(3,-14,8,27)
            self.hpmax = 1
            self.hp = 1
            if UIIsnt then
                UIIsnt:ForceUpdateHP(self.hp, self.hpmax)
                --print("[Mipa] force to update Hearts")
            end
        end
    end
end