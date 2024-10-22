local pd <const> = playdate
local gfx <const> = pd.graphics

import "Creature"
class("Wasp").extends(Creature)

function Wasp:init(x, y)
    Wasp.super.init(self, x, y)
    self.name = "Beepa"
    self.imagetable = AssetsLoader.LoadImageTable("images/Beepa")
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCollideRect(4,3,8,15)
    self:add() -- Add to draw list
    self:setTag(TAG.Enemy)
    self.damage = 1
    -- Movement
    self.speed = 1.66
    self.IsWasp = true
    self.hp = 1
    self.maxhp = 3
    self.damagable = true
    self.damageimuneframes = 0
    self.damagesound = "BzzFast"
    self.noAIUpdates = false
end

function Creature:collisionResponse(other)
    
    if self.escape or self.escape2 or self.nocolide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    
    
    if self.notapplyimpulses then
        return nil
    end
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or other:getTag() == TAG.HazardNoColide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Wasp:ApplyVelocity()
    local lastground = self:IsOnFloor()
    local lastfreefall = self.freefall
    local actualX, actualY, collisions, length = self:ApplyVelocityBase()
    if actualX then -- ApplyVelocityBase not null so, it been processed
        for i=1,length do
            local collision = collisions[i]
            local collisionType = collision.type
            local collisionObject = collision.other
            local collisionTag = collisionObject:getTag()
            if collisionType == gfx.sprite.kCollisionTypeSlide then
                if collision.normal.y == -1 then
                    if not lastground and self:IsOnFloor() and lastfreefall > 5 then
                        AnimEffect(self.x-7, collision.otherRect.y-14, "Effects/ground", 1, true)
                        SoundManager:PlaySound("Bloop", 0.3)
                    end
                end
            end
        end
    end
end

function Wasp:update()
    self:CommonUpdates()

    if self.LookAtMipa then
        if MipaInst then
            if self.x < MipaInst.x then
                self.mirrored = gfx.kImageUnflipped
            else
                self.mirrored = gfx.kImageFlippedX
            end
        end
    end
end

function Wasp:Death()
    SoundManager:PauseMusic()
    if UIIsnt ~= nil then
        --UIIsnt:StartDialog(GetDialogDataFromString("Okay\nOkay....\nYou finished that build.\nIn fact that boss was unfinished.\nAswell as cutscene that leads to that level missing.\nSo all I can say, is thanks for testing.\n#Mipa\nYes! Thank you!\nYou can press round button to quit to menu.\nOh wait, this breaking narrative.\n#None\nThat way better. So you just press round button and it opens pause menu and you press MAIN MENU\nThat simple, yes."))
        local dialog = GetDialogDataFromString("WaspDefeat")
        UIIsnt:StartDialog(dialog, nil, "ChangeActor 387 Escape\nMusic None\nBigTrashKoaKola 383\nBigTrashKoaKola 736")
        --NextLevel = "lvl14b"
    end
    self.defeated = true
end

function Wasp:DoCloudsFX()
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
    self.cloudtimer = cloudTimer
end

function Wasp:DoWingsFX()
    local wings = AnimEffect(0, 0, "Effects/WingsPair", 1, true, false, self.mirrored)
    wings:setCenter(0.5, 0.5)
    wings.Wasp = self
    wings.CustomUpdate = function()
        if wings.Wasp then
            if wings.Wasp:IsMirrored() then
                wings:moveTo(self.x, self.y)
            else
                wings:moveTo(self.x, self.y)
            end
        end
    end
    wings.CustomUpdate()
end

function Wasp:Shoot()    
    if self.shootbombtimer == nil then
        self.shootbombtimer = pd.frameTimer.new(7)
        self.shootbombtimer.repeats = false
        self.shootbombtimer.timerEndedCallback = function(timer)
            self.shootbombtimer = nil
        end
    end
    self.lastbomb = bullet
    local xoff = 0
    local speed = 0
    if not self:IsMirrored() then
        xoff = 12
        speed = 7
    else
        xoff = -12
        speed = -7
    end
    local bullet = Bullet(self.x+xoff, self.y-2)
    bullet:setImage(AssetsLoader.LoadImage("images/Effects/bomb"), self.mirrored)
    bullet.mirrored = self.mirrored
    bullet:setCollideRect(2, 1, 6, 6)
    bullet.speed = speed
    bullet.destoryOnDamage = true
    bullet.damage = 0
    bullet:setTag(TAG.HazardNoColide)
    SoundManager:PlaySound("Woop")
    bullet.lifedistance = 500
    bullet.lastpushonhit = false
    bullet.OnHit = function (collision)
        SoundManager:PlaySound("Heavyland")
        local bomb = Clashbomb(bullet.x-4, bullet.y-4, bullet.mirrored, self, collision.other)
        bomb.dangerous = true
    end
    bullet.CustomHazardFn = function (Mipa)
        print("bullet.CustomHazardFn")
        SoundManager:PlaySound("Heavyland")
        local bomb = Clashbomb(Mipa.x, bullet.y, bullet.mirrored, self, Mipa)
        if bullet.speed < 0 then -- Bullet from the right
            bullet.parentXOffset = -4
        else
            bullet.parentXOffset = 4
        end
        bullet.parentYOffset = 0
        DrawCrank()
        bomb.dangerous = true
        bullet.OnDestory()
    end
    bullet.OnDestory = function()
        if self.lastbomb == bullet then
            self.lastbomb = nil
        end
    end
end

function Wasp:SetActorAct(command)
    
    if command == "JustStand4" or command == "PointRight" then
        self:SetMirrored(false)
    elseif command == "JustStand2" or command == "PointLeft" then
        self:SetMirrored(true)
    end

    self.point = command == "PointLeft" or command == "PointRight"

    if self.point then
        command = "Point"
    end
    
    if command == nil or command == "" then
        command = "STOCK"
    end

    if command == "Escape" or command == "Escape2" or command == "JustStand3" or command == "Point" then
        self.gravity = 0
    else
        self.gravity = 1
    end

    if command == "Escape" then
        self.maxjumpvelocity = -40
    else
        self.maxjumpvelocity = -10
    end

    if command == "Escape2" then
        self.speed = 1.1
    else
        self.speed = 1.66
    end

    if command == "JustStand" or command == "Escape" or command == "Escape2" or command == "JustStand3" or command == "Point" then
        self:setTag(TAG.Effect)
    else
        self:setTag(TAG.Enemy)
    end
    
    self.escape = command == "Escape"
    self.escape2 = command == "Escape2"
    self.nocolide = command == "JustStand3" or command == "Point"
    self.noAIUpdates = command == "Stuned" or command == "JustStand" or command == "JustStand2" or command == "JustStand3" or command == "JustStand4" or command == "Point"
    self.LookAtMipa = command == "JustStand" or command == "JustStand2" or command == "Stuned" or command == "JustStand3"
    self.pain = command == "Stuned"

    print("[Wasp] SetActorAct ", command)
    print("[Wasp] escape ", self.escape)
    print("[Wasp] escape2 ", self.escape2)
    print("[Wasp] noAIUpdates ", self.noAIUpdates)
    print("[Wasp] LookAtMipa ", self.LookAtMipa)
    print("[Wasp] pain ", self.pain)
    print("[Wasp] setTag ", self:getTag())
    print("[Wasp] speed ", self.speed)
    print("[Wasp] maxjumpvelocity ", self.maxjumpvelocity)
    print("[Wasp] gravity ", self.gravity)
    print("[Wasp] nocolide ", self.nocolide)
end

function Wasp:AIUpdate()
    if self.escape then
        if self.x < 223 then
            self:TryMoveRight()
        else
            if self.velocityY == 0 then
                self.velocityY = -10
                self:DoWingsFX()
                self:DoCloudsFX()
                SoundManager:PlaySound("Wooah")
            end
        end

        if self.y < 35 then
            self.cloudtimer:remove()
            gfx.sprite.removeSprite(self)
        end
        
        return
    end
    if self.escape2 then
        if self.x > 3 then
            self:TryMoveLeft()
        else
            gfx.sprite.removeSprite(self)
        end
        return
    end
    
    
    if self.momentumX > 0 or self.notapplyimpulses or self.defeated or self.noAIUpdates then
        self.movingdirection = 0
        return
    end
    self.thinkticks = self.thinkticks+1

    if self.thinkticks >= 35 and self.paintimer == nil then
        if self.movingdirection == 0 then
            if math.random(0,100) <= 50 then
                self.movingdirection = 1
            else
                self.movingdirection = -1
            end
        elseif self:IsOnFloor() then
            self:Shoot()
        end
        self.thinkticks = 0
    end
    if self.bumpwall then
        local needJump = true
        local collisions = self:overlappingSprites()
        for i=1,#collisions do
            local collisionObject = collisions[i]
            local collisionTag = collisionObject:getTag()
            if collisionTag == TAG.Interactive then
                if collisionObject.navtype then
                    if collisionObject.navtype == "left" then
                        self.movingdirection = -1
                    elseif collisionObject.navtype == "right" then
                        self.movingdirection = 1
                    end
                    needJump = false
                    break
                end
            end
        end
        if needJump then
            
            if self:IsOnFloor() then
                if self.lastxbeforejump ~= self.x then
                    self:DoWingsFX()
                    self:TryJump()
                else
                    if self.movingdirection == 1 then
                        self.movingdirection = -1
                    else
                        self.movingdirection = 1
                    end
                end
                
                self.lastxbeforejump = self.x
            end
        end
        
        self.bumpwall = false
    end

    if self.shootbombtimer == nil and self.paintimer == nil then
        if self.movingdirection == 1 then
            self:TryMoveRight()
        elseif self.movingdirection == -1 then
            self:TryMoveLeft()
        end
    end
end

function Wasp:RegisterAnimations()
    self:AddAnimation("idle", {1, 2})
    self:AddAnimation("walk", {3, 4, 5, 4})
    self:AddAnimation("shoot", {6})
    self:AddAnimation("fly", {7})
    self:AddAnimation("pain", {8, 9}, 10)
    self:AddAnimation("point", {10, 11, 10, 11, 10, 11, 10, 11, 5, 3, 5, 3, 5}, 10)
end

function Wasp:PickAnimation()
    if self.shootbombtimer then
        self:SetAnimation("shoot")
        return
    end
    if self.paintimer or (self.defeated and not self.escape and not self.escape2) or self.pain then
        self:SetAnimation("pain")
        return
    end

    if self.point then
        self:SetAnimation("point")
        return
    end
    
    if self:IsMoving() and self:IsOnFloor() then
        self:SetAnimation("walk")
    else
        if self:IsFalling() or self:IsFlying() then
            self:SetAnimation("fly")
        else
            if self.movingdirection == 0 then
                self:SetAnimation("idle")
            end
        end
    end
end