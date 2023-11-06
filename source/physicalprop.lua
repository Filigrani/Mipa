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
    self.speed = 1.01
    self.momentumX = 0
    self.velocityX = 0
    self.velocityY = 0
    -- Physic
    self.gravity = 0.35
    self.movingflag = false
    self.onground = true
    self.freefall = 0
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
    local actualX, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
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
                if not lastground and self.onground and lastfreefall > 5 then
                    AnimEffect(self.x-7, collision.otherRect.y-14, "Effects/ground", 1, true)
                    SoundManager:PlaySound("Bloop", 0.3)
                    if collisionTag == TAG.Player and not lastground then
                        print("Damage "..lastfreefall)
    
                        if lastfreefall > 10 then
                            collisionObject:Damage(2)
                        else
                            collisionObject:Damage(1)
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
    end

    if not self.onground then
        self.freefall = self.freefall + self.gravity
    end 

    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        self.movingflag = true
    else
        self.movingflag = false
    end
    if self.y > 240 then
        gfx.sprite.removeSprite(self)
    end
end

function PhysicalProp:update()
    self.velocityX = 0
    self:ApplyVelocity()
end