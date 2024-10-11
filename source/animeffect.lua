local pd <const> = playdate
local gfx <const> = pd.graphics

class("AnimEffect").extends(gfx.sprite)

function AnimEffect:init(x, y, tablename, speed, oneshot, randomstartoffset, mirrored)
    if mirrored == nil then
        mirrored = gfx.kImageUnflipped
    else
        mirrored = gfx.kImageFlippedX
    end
    self.imagetable = AssetsLoader.LoadImageTable("images/"..tablename)
    self.currentindex = 1
    if randomstartoffset then
        self.currentindex = math.floor(math.random(1,self.imagetable:getLength())+0.5)
    end
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Player)
    self:setTag(TAG.Effect)
    self:setImage(self.imagetable:getImage(self.currentindex))
    self:add()
    if speed == nil then
        speed = 3
    end
    self.animtimer = pd.frameTimer.new(speed)
    self.animtimer.repeats = true
	self.animtimer.timerEndedCallback = function(timer)
        self.currentindex = self.currentindex+1
        if self.currentindex > self.imagetable:getLength() then
            if not oneshot then
                self.currentindex = 1
            else
                self.animtimer:remove()
                gfx.sprite.removeSprite(self)
                return
            end
        end
        self:setImage(self.imagetable:getImage(self.currentindex), mirrored)
    end
    self.animtimer:start()
    self.followparent = nil
    self.followparentxoffset = 0
    self.followparentyoffset = 0
end

function AnimEffect:SetFollowParent(parent, xoffset, yoffset)
    self.followparent = parent
    self.followparentxoffset = xoffset
    self.followparentyoffset = yoffset
end

function AnimEffect:ProcessFollow()
    local p_x, p_y = self.followparent:getPosition()
    self:moveTo(p_x+self.followparentxoffset, p_y+self.followparentyoffset)
end

function AnimEffect:update()
    if self.CustomUpdate then
        self.CustomUpdate()
    end
    if self.followparent then
        self:ProcessFollow()
    end
end