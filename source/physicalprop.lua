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
    self.movingflag = false
    self.onground = true
    self.freefall = 0
    self.notapplyimpulses = false
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

function PhysicalProp:ApplyVelocity()
    if self.notapplyimpulses then
        return
    end
    self.velocityY = self.velocityY+self.gravity
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
    self.onground = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
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
                if lastfreefall > 2 then
                    if self.isTrash then
                        AnimEffect(_x-13, _y-5, "Effects/Trashbox", 4, true, false)
                        gfx.sprite.removeSprite(self)
                        return
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
    end
    if logIt then
        --print("[PhysicalProp:ApplyVelocity()] PostForLoop -> self.velocityX ", self.velocityX)
        print("[PhysicalProp:ApplyVelocity()] PostForLoop -> self.x ", self.x)
    end
    if not self.onground then
        self.freefall = self.freefall + self.gravity
    end 

    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        self.movingflag = true
    else
        self.movingflag = false
    end
    if self.y > 250 then
        if self.Dropper then
            self.Dropper:DropBox()
        else
            gfx.sprite.removeSprite(self)
        end
    end
end

function PhysicalProp:update()
    self.velocityX = 0
    self:ApplyVelocity()
end