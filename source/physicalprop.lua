local pd <const> = playdate
local gfx <const> = pd.graphics

class("PhysicalProp").extends(gfx.sprite)

function PhysicalProp:init(x, y)
    local img = gfx.image.new("images/Props/Box")
    self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    --self:setCenter(0, 0)
    self:setCollideRect(0,0,12,12)
    self:add() -- Add to draw list
    self:setTag(TAG.PropPushable)
    -- Moving vars
    self.speed = 1.012
    self.momentumX = 0
    self.velocityX = 0
    self.velocityY = 0
    -- Physic
    self.gravity = 0.35
    self.gravityinliquid = -0.01
    self.gravityonliquidsurface = 0.02
    self.movingflag = false
    self.onground = true
    self.freefall = 0
    self.notapplyimpulses = false
    self.IsPhysProp = true
end

function PhysicalProp:IsFalling()
    if self.velocityY > 0 and not self:IsOnFloor() then
        return true
    end
    return false
end

function PhysicalProp:IsOnFloor()
    return self.onground
end

function PhysicalProp:IsMoving()
    return self.movingflag
end

function PhysicalProp:TryMoveRight(s)
    local speed = self.speed
    if s then
        speed = s
    end
    self.velocityX = speed
end

function PhysicalProp:TryMoveLeft(s)
    local speed = self.speed
    if s then
        speed = s
    end
    self.velocityX = -speed
end

function PhysicalProp:collisionResponse(other)
    if self.notapplyimpulses then
        return nil
    end
    if other then
        if (other:getTag() == TAG.Effect or other:getTag() == TAG.Interactive or other:getTag() == TAG.HazardNoColide) then
            return gfx.sprite.kCollisionTypeOverlap
        else
            return gfx.sprite.kCollisionTypeSlide
        end
    else
        return gfx.sprite.kCollisionTypeOverlap
    end
end

function PhysicalProp:InLiquid()
    return self.inliquid
end

function PhysicalProp:GetGravity()
    if self:InLiquid() then
        if self.onliquidsurface then
            return self.gravityonliquidsurface
        else
            return self.gravityinliquid
        end
    end
    return self.gravity
end

function PhysicalProp:ApplyVelocity()
    if self.notapplyimpulses then
        return
    end
    self.velocityY = self.velocityY+self:GetGravity()

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

    local logIt = false

    if logIt then
        --print("[PhysicalProp:ApplyVelocity()] PreMove -> self.velocityX ", self.velocityX)
        print("[PhysicalProp:ApplyVelocity()] PreMove -> self.x ", self.x)
    end
    local _x, _y = self:getPosition()
    local disiredX = _x + self.velocityX
    local disiredY = _y + self.velocityY
    local actualX, _, collisions, length = self:moveWithCollisions(disiredX, disiredY)
    if logIt then
        --print("[PhysicalProp:ApplyVelocity()] PostMove -> self.velocityX ", self.velocityX)
        print("[PhysicalProp:ApplyVelocity()] PostMove -> self.x ", self.x)
    end
    local lastground = self.onground
    local lastfreefall = self.freefall
    local lastinliquid = self.inliquid
    local lastonliquidsurface = self.onliquidsurface
    self.onground = false
    self.onbridge = false
    self.inliquid = false
    self.onliquidsurface = false
    local hadsurfaceboost = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()

        if collisionObject.IsFunnyBringe then
            self.onbridge = true
        end
        if collisionObject.IsLiquid then
            self.inliquid = true
        end
        if collisionObject.IsLiquidSurface then
            self.onliquidsurface = true
            if not hadsurfaceboost then
                if collisionObject.y < _y then
                    hadsurfaceboost = true
                    local surfacedifference = _y-collisionObject.y
                    if surfacedifference < 1 then
                        surfacedifference = 1
                    end

                    --print("Surface Y ", surfacedifference)
                    self.velocityY = -surfacedifference/14
                    --print("Velocity ", self.velocityY)
                end
            end
        end

        if self.inliquid and self.onliquidsurface then
            self.freefall = 0
            lastfreefall = 0
        end

        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.onground = true
                self.velocityY = 0
                self.freefall = 0
                if collisionObject.IsConveyorBelts then
                    if collisionObject.Inversed then
                        self.velocityXnextframe  = -1
                    else
                        self.velocityXnextframe = 1
                    end
                --elseif collisionObject.velocityXnextframe then
                --    self.velocityXnextframe = collisionObject.velocityXnextframe
                end
                if not lastground and self.onground and lastfreefall > 5 then
                    AnimEffect(self.x-7, collision.otherRect.y-14, "Effects/ground", 1, true)
                    SoundManager:PlaySound("Bloop", 0.3)
                    if (collisionTag == TAG.Player or (collisionObject.IsWasp and not self.isTrash)) and not lastground then
                        print("Damage "..lastfreefall) 
                        if lastfreefall > 10 then
                            collisionObject:Damage(2, true)
                        else
                            collisionObject:Damage(1, true)
                        end
                        if collisionObject.IsWasp then
                            if collisionObject:IsMirrored() then
                                self.momentumX = 5
                            else
                                self.momentumX = -5
                            end
                            
                            self.velocityY = -5
                            AnimEffect(_x+5, _y+5, "Effects/BigCloud", animSpeed, true, false)
                            if collisionObject.paintimer == nil then
                                collisionObject.paintimer = pd.frameTimer.new(30)
                                collisionObject.paintimer.repeats = false
                                collisionObject.paintimer.timerEndedCallback = function(timer)
                                    collisionObject.paintimer = nil
                                end
                            end
                        end
                    end                    
                end
                if lastfreefall > 5 then
                    if self.isKoaKola then
                        if CurrentLevel then
                            local zoneData = {}
                            zoneData.x = _x-7
                            zoneData.y = _y-7
                            zoneData.zoneType = "koasoda"
                            CurrentLevel:CreateZone(zoneData)
                        end
                    end
                    if self.isTrash then
                        AnimEffect(_x-13, _y-5, "Effects/Trashbox", 4, true, false)
                        gfx.sprite.removeSprite(self)
                        return
                    end
                else
                    if self.isTrash then
                        if collisionObject.IsWasp or collisionObject.IsMipa then
                            AnimEffect(_x-13, _y-5, "Effects/Trashbox", 4, true, false)
                            gfx.sprite.removeSprite(self)
                            if collisionObject.IsMipa and lastfreefall > 1 then
                                collisionObject:Damage(1, true)
                            end
                        end
                    end
                end    
            elseif collision.normal.y == 1 then       
                self.velocityY = 0
                self.momentumX = 0
            end
            if collision.normal.x ~= 0 and self.momentumX ~= 0 then
                self.momentumX = 0
                self.velocityY = 0
            end
            if collisionTag == TAG.PropPushable and lastground then
                if self.velocityX > 0 then
                    if collision.normal.x < 0 then
                        collisionObject:TryMoveRight()
                        collisionObject:ApplyVelocity()  
                        SoundManager:PlaySound("Push")                        
                    end                  
                end
                if self.velocityX < 0 then
                    if collision.normal.x > 0 then
                        collisionObject:TryMoveLeft()
                        collisionObject:ApplyVelocity()    
                        SoundManager:PlaySound("Push")          
                    end                  
                end
            end    
            if collisionTag == TAG.Player and collisionObject:IsDead() and lastground then
                if self.velocityX > 0 then
                    if collision.normal.x < 0 then
                        collisionObject:TryMoveRight()
                        collisionObject:ApplyVelocity()    
                        SoundManager:PlaySound("MetalPush")
                    end                  
                end
                if self.velocityX < 0 then
                    if collision.normal.x > 0 then
                        collisionObject:TryMoveLeft()
                        collisionObject:ApplyVelocity() 
                        SoundManager:PlaySound("MetalPush")            
                    end                  
                end
            end                     
        end
        if collision.normal.x ~= 0 then
            if (self.onbridge or self.onliquidsurface) and collisionTag == TAG.Default and not collisionObject.IsFunnyBringe  then
                self.velocityY = -2
            end
        end
    end
    if logIt then
        --print("[PhysicalProp:ApplyVelocity()] PostForLoop -> self.velocityX ", self.velocityX)
        print("[PhysicalProp:ApplyVelocity()] PostForLoop -> self.x ", self.x)
    end
    if not self.onground then
        self.freefall = self.freefall + self:GetGravity()
    end
    if lastinliquid ~= self.inliquid then
        AnimEffect(_x-7, _y-7, "Effects/ground", 1, true)
        if self.inliquid then
            self.velocityY = self.velocityY/3
        end
    end

    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        self.movingflag = true
    else
        self.movingflag = false
    end

    if not self.pendingBigTrashKoaKola then
        if self.y > 250 or self.x > RightEdge or self.x < LeftEdge then
            if self.Dropper then
                self.Dropper:DropBox()
            else
                gfx.sprite.removeSprite(self)
            end
        end
    end
end

function PhysicalProp:update()
    self.velocityX = 0
    self:ApplyVelocity()
end