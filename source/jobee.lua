local pd <const> = playdate
local gfx <const> = pd.graphics

import "Creature"
class("Jobee").extends(Creature)

function Jobee:init(x, y, IsFly)
    print("[Jobee] Spawned IsFly? ", IsFly)
    Jobee.super.init(self, x, y)
    self.name = "Jobee"
    if IsFly then
        self:TurnToFly()
    else
        self:TurnToNormal()
    end

    self:moveTo(x, y)
    self:setZIndex(Z_Index.BG)
    self:add() -- Add to draw list
    self:setTag(TAG.Enemy)
    self.IsGrabbable = true
    self.Mipa = nil
    self.IsJobee = true
    self.gograb = false
    self.death = false
end

function Jobee:TurnToFly()
    self:clearCollideRect()
    self.imagetable = AssetsLoader.LoadImageTable("images/JobeeFly")
    self.IsJobeeFly = true
    print("[Jobee] TurnToFly")
end

function Jobee:TurnToNormal()
    self:setCollideRect(6,4,9,22)
    self.imagetable = AssetsLoader.LoadImageTable("images/Jobee")
    self:SetMirrored(true)
    self.IsJobeeFly = false
    print("[Jobee] TurnToNormal")
end

function Jobee:SetActorAct(command)
    
    if command == nil or command == "" then
        command = "STOCK"
    end

    if command == "Flink" then
        MipaInst.gravity = 0
        MipaInst.velocityY = -10
        return
    end

    if command == "Grab" then
        self.imagetable = AssetsLoader.LoadImageTable("images/JobeeFly")
        self.speed = 5.05
    end

    if command == "Grab" then
        self:setTag(TAG.Effect)
    else
        self:setTag(TAG.Enemy)
    end
    --self.nocolide = command == "Grab"
    self.gograb = command == "Grab"

    print("[Jobee] SetActorAct ", command)
    print("[Wasp] setTag ", self:getTag())
    print("[Wasp] speed ", self.speed)
    print("[Wasp] maxjumpvelocity ", self.maxjumpvelocity)
    print("[Wasp] gravity ", self.gravity)
    print("[Wasp] nocolide ", self.nocolide)
end

function Jobee:collisionResponse(other)
    if self.nocolide then
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

function Jobee:ApplyVelocity()
    if not self.IsJobeeFly or self.death then
        local lastground = self:IsOnFloor()
        local lastfreefall = self.freefall
        local actualX, actualY, collisions, length = self:ApplyVelocityBase()
    end
end

function Jobee:update()
    self:CommonUpdates()

    if not self.death then
        if self.IsJobeeFly then
            if self.Mipa == nil then
                self.Mipa = MipaInst
                if self.DoCrankControl then
                    self.Mipa.JobeeCrank = true
                end
            else
                self.Mipa.Jobee = self
                --local _x, _y = self.Mipa:getPosition()
                --self:moveTo(_x+5, _y-13)
            end
        end
    end
end

function Jobee:Respawn()

end

function Jobee:AIUpdate()
    if self.gograb then
        if self.x > 200 then
            self:TryMoveLeft()
        else
            self.gograb = false
            self:SetMirrored(false)
            self:TurnToFly()
        end
    end
end

function Jobee:RegisterAnimations()
    self:AddAnimation("idle", {1,2})
    self:AddAnimation("death", {3})
end

function Jobee:PickAnimation()
    if self.death then
        self:SetAnimation("death")
    else
        self:SetAnimation("idle")
    end
end