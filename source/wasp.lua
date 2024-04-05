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
    self.hp = 3
    self.maxhp = 3
    self.damagable = true
    self.damageimuneframes = 0
    self.damagesound = "BzzFast"
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
end

function Wasp:Death()
    SoundManager:PauseMusic()
    if UIIsnt ~= nil then
        UIIsnt:StartDialog(GetDialogDataFromString("Okay\nOkay....\nYou finished that build.\nIn fact that boss was unfinished.\nAswell as cutscene that leads to that level missing.\nSo all I can say, is thanks for testing.\n#Mipa\nYes! Thank you!\nYou can press round button to quit to menu.\nOh wait, this breaking narrative.\n#None\nThat way better. So you just press round button and it opens pause menu and you press MAIN MENU\nThat simple, yes."))
    end
    self.defeated = true
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
    bullet:setCollideRect(2, 1, 6, 6)
    bullet.speed = speed
    bullet.destoryOnDamage = true
    bullet.damage = 1
    bullet:setTag(TAG.HazardNoColide)   
    SoundManager:PlaySound("Woop")
    bullet.lifedistance = 500
    bullet.lastpushonhit = false
    bullet.OnHit = function (collision)
        SoundManager:PlaySound("Heavyland")
        local bomb = Clashbomb(bullet.x-4, bullet.y-4, self.mirrored, self, collision.other)
        bomb.dangerous = true
    end
    bullet.OnDestory = function()
        if self.lastbomb == bullet then
            self.lastbomb = nil
        end
    end
end

function Wasp:AIUpdate()
    if self.momentumX > 0 or self.notapplyimpulses or self.defeated then
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
end

function Wasp:PickAnimation()
    if self.shootbombtimer then
        self:SetAnimation("shoot")
        return
    end
    if self.paintimer or self.defeated then
        self:SetAnimation("pain")
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