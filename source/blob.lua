local pd <const> = playdate
local gfx <const> = pd.graphics

import "Creature"
class("Blob").extends(Creature)

function Blob:init(x, y)
    Blob.super.init(self, x, y)
    self.name = "Blob"
    self.imagetable = AssetsLoader.LoadImageTable("images/Blob")
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCollideRect(2,7,10,7)
    self:add() -- Add to draw list
    self:setTag(TAG.Enemy)
    self.IsGrabbable = true
    self.Mipa = nil
end

function Blob:collisionResponse(other)
    if self.notapplyimpulses then
        return nil
    end
    if other and (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.Hazard or other:getTag() == TAG.ObstacleCastNoPlayer) or other:getTag() == TAG.HazardNoColide then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Blob:ApplyVelocity()
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
    self.Mipa = nil
    if self:IsOnFloor() then
        local _, _, collisions2, length = self:checkCollisions(self.x, self.y-1)
        for i=1,length do
            local collision = collisions2[i]
            local collisionType = collision.type
            local collisionObject = collision.other
            local collisionTag = collisionObject:getTag()
            if collisionObject.IsMipa then
                self.Mipa = collisionObject
                if not self.squshed then
                    self.movingdirection = 0
                    self.thinkticks = 0
                    self.squshed = true
                    SoundManager:PlaySound("Splash")
                end
            end
        end
    end

    if self.y > 400 then
        if self.homeX == 0 and self.homeY == 0 then
            gfx.sprite.removeSprite(self)
        else
            self.thinkticks = 50
            self.movingdirection = 0
            self:moveTo(self.homeX, self.homeY)
            self:SetAnimation("spawn")
        end
    end
end

function Blob:update()
    self:CommonUpdates()
end

function Blob:AIUpdate()
    if self.momentumX > 0 or self.notapplyimpulses then
        self.movingdirection = 0
        return
    end
    
    self.thinkticks = self.thinkticks+1

    if self.thinkticks >= 100 then
        if self.movingdirection == 0 and not self.squshed then
            if math.random(0,100) <= 50 then
                self.movingdirection = 1
            else
                self.movingdirection = -1
            end
        end
    end
    if self.thinkticks >= 200 then
        if self.movingdirection ~= 0 and not self.squshed then
            --self.movingdirection = -1
        end
    end
    if self.bumpwall then
        if self.movingdirection == 1 then
            self.movingdirection = -1
        else
            self.movingdirection = 1
        end
        self.bumpwall = false
    end
    if self.squshed then
        self:setCollideRect(2,10,10,4)
        if self.thinkticks >= 30 then
            if self.Mipa ~= nil then
                self.Mipa.velocityY = -15
                self.Mipa.canjump = false
                self.Mipa:ApplyVelocity()
            end
            self.thinkticks = 85
            self.squshed = false
            self:setCollideRect(2,7,10,7)
        end
    else        
        if self:IsOnFloor() then
            if self.movingdirection == 1 then
                self:TryMoveRight()
                --SoundManager:PlaySound("Slip", 0.07)
            elseif self.movingdirection == -1 then
                self:TryMoveLeft()
                --SoundManager:PlaySound("Slip", 0.07)
            end
        end
    end
end

function Blob:RegisterAnimations()
    self:AddAnimation("idle", {1})
    self:AddAnimation("walk", {1, 3, 2, 4})
    self:AddAnimation("squshed", {5})
    self:AddAnimation("rest", {6})
    self:AddAnimation("spawn", {10,9,8,7,6}, nil, false)
end

function Blob:PickAnimation()
    if self.currentanimation == "spawn" then
        if self.animationfinished then 
            self:SetAnimation("rest")
        end
        return
    end
    if self:IsMoving() then
        self:SetAnimation("walk")
    else
        if self.movingdirection == 0 then
            if self.squshed then
                self:SetAnimation("squshed")
            else
                self:SetAnimation("rest")
            end
        else
            self:SetAnimation("idle")
        end
    end
end