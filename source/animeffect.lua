local pd <const> = playdate
local gfx <const> = pd.graphics

class("AnimEffect").extends(gfx.sprite)

function AnimEffect:init(x, y, tablename, speed, oneshot, randomstartoffset)
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
        self:setImage(self.imagetable:getImage(self.currentindex))
    end
    self.animtimer:start()
end

function AnimEffect:update()

end