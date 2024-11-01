local pd <const> = playdate
local gfx <const> = pd.graphics

class("Clashbomb").extends(gfx.sprite)

function Clashbomb:init(x, y, mirrored, mipa, parant)
    self.IsClashBomb = true
    self:moveTo(x, y)
    self:setZIndex(Z_Index.BG)
    self:setCenter(0, 0) 
    self:add()
    self.mirrored = mirrored
    self.imagetable = AssetsLoader.LoadImageTable("images/Props/Bomb")
    self.frame = 1
    self:setImage(self.imagetable:getImage(self.frame), self.mirrored)
    self.MyMipa = mipa
    self.MyMipa.lastbomb = self
    self.explodetimer = pd.frameTimer.new(45)
	self.explodetimer.timerEndedCallback = function(timer)
        if self.MyMipa ~= nil then
            self.MyMipa.lastbomb = nil
        end
        self:BeginExplosion()
        self:DestoryBlocks()
        gfx.sprite.removeSprite(self)
	end
	self.explodetimer.repeats = false
	self.explodetimer:start()

    if parant then
        self.parent = parant
        self.parentXOffset = x-parant.x
        self.parentYOffset = y-parant.y
        if parant.childs == nil then
            parant.childs = {self}
        else
            table.insert(parant.childs, self)
        end
    end
    self.fallingdown = false
    self.gravity = 2
    self.momentumX = 0
    self.velocityX = 0
    self.crankedFrames = 0
end

function Clashbomb:collisionResponse(other)
    if self.CustomColision ~= nil then
        return self:CustomColision(other)
    end
    return nil
end

function Clashbomb:DestoryBlocks()
    local offsetx = 0
    local offsety = self.y-7
    if self.mirrored == gfx.kImageUnflipped then
        offsetx = self.x+7
    else
        offsetx =self.x-7
    end
    local collider = gfx.sprite.addEmptyCollisionSprite(offsetx, offsety, 7, 22)
    collider:setTag(TAG.Effect)
    --[[
    local _, _, collisions, length = collider:checkCollisions(offsetx, offsety)
    for i=1,length do
        local collision = collisions[i]
        local collisionObject = collision.other
        if collisionObject.IsBreakableTile then
            gfx.sprite.removeSprite(collisionObject)
        end
    end
    --]]
    local collisions = collider:overlappingSprites()
    for i=1,#collisions do
        local collision = collisions[i]
        if collision.IsBreakableTile then
            gfx.sprite.removeSprite(collision)
        end
        if self.dangerous and collision.IsMipa then
            collision:Damage(1)
        end
    end
    gfx.sprite.removeSprite(collider)
    if self.dangerous then
        local explosioncolider = gfx.sprite.addEmptyCollisionSprite(self.x-25, self.y-25, 50, 50)
        explosioncolider:setTag(TAG.Effect)
        local explosioncolissions = explosioncolider:overlappingSprites()
        for i=1,#explosioncolissions do
            local collision = explosioncolissions[i]
            if collision.IsMipa then
                collision:Damage(1)
            end
        end
        gfx.sprite.removeSprite(explosioncolider)
    end
end

function Clashbomb:BeginExplosion()
    if self.parent and self.parent.IsMipa ~= nil then
        StopDrawCrank()
    end
    SoundManager:PlaySound("GlitchNew")
    for i = 1, 10, 1 do
        self:DoExposionEffect()
    end
    local postTimer = pd.frameTimer.new(9)
    postTimer.timerEndedCallback = function(timer)
        for i = 1, 7, 1 do
            SoundManager:PlaySound("GlitchNew")
            self:DoExposionEffect()
        end
        local postpostTimer = pd.frameTimer.new(10)
        postpostTimer.timerEndedCallback = function(timer)
            for i = 1, 3, 1 do
                SoundManager:PlaySound("GlitchNew")
                self:DoExposionEffect()
            end
        end
        postpostTimer.repeats = false
        postpostTimer:start()
    end
    postTimer.repeats = false
    postTimer:start()
end

function Clashbomb:DoExposionEffect()
    local spead = 12
    local effectX = math.floor(math.random(-spead,spead)+0.5)
    local effectY = math.floor(math.random(-spead,spead)+0.5)
    local animSpeed = math.floor(math.random(1,3)+0.5)
    local effect = AnimEffect(self.x+effectX, self.y+effectY, "Effects/SimpleExplosion", animSpeed, true, false)
end

function Clashbomb:Remove()
    self.explodetimer:remove()
end

function Clashbomb:DisarmAndFall()
    self.explodetimer:remove()
    self.fallingdown = true
    self.parent = nil
end

function Clashbomb:ApplyFalling()
    if self.fallingdown then
        self.velocityX = 0
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
        self:moveTo(self.x+self.velocityX, self.y+self.gravity)
    end
end

function Clashbomb:update()
    if self.parent ~= nil and self.parent.IsMipa ~= nil then
        if CrankedThisFrame then
            self.crankedFrames = self.crankedFrames+1
        end
        if self.crankedFrames > 5 then
            self:DisarmAndFall()
            local direction = math.random(0,100)
            if direction < 50 then
                self.momentumX = math.random(7,12)
            else
                self.momentumX = -math.random(7,12)
            end
            StopDrawCrank()
        end
    end
    
    if self.frame == 2 then
        self.frame = 1
    else
        self.frame = 2
    end
    self:setImage(self.imagetable:getImage(self.frame), self.mirrored)

    if self.parent then
        self:moveTo(self.parent.x+self.parentXOffset, self.parent.y+self.parentYOffset)
    end

    if self.fallingdown then
        self:ApplyFalling()
    end
end