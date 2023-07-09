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
    self.speed = 1
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

function PhysicalProp:TryMoveRight()
    self.velocityX = self.speed
end

function PhysicalProp:TryMoveLeft()
    self.velocityX = -self.speed
end

function PhysicalProp:TryJump()  
    if self.canjump then
        self.canjump = false
        self.velocityY = self.maxjumpvelocity
    end
end

function PhysicalProp:collisionResponse(other)
    return gfx.sprite.kCollisionTypeSlide
end

function PhysicalProp:ApplyVelocity()
    self.velocityY = self.velocityY+self.gravity
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.velocityX, self.y + self.velocityY)
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
                if collisionTag == TAG.Player and not lastground then
                    print("Damage "..lastfreefall)

                    if lastfreefall > 10 then
                        collisionObject:Damage(2)
                    else
                        collisionObject:Damage(1)
                    end                   
                end                   
            elseif collision.normal.y == 1 then       
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
    if self.y > 400 then
        gfx.sprite.removeSprite(self)
    end
end

function PhysicalProp:update()
    self.velocityX = 0
    self:ApplyVelocity()
end