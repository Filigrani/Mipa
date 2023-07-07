local pd <const> = playdate
local gfx <const> = pd.graphics

class('UI').extends(playdate.graphics.sprite)

function UI:init()
    self:add() -- Add to draw list
    self.hearts = {}
    self:AddHeart(1)
    self:AddHeart(1)
    self:AddHeart(2)
    self:AddHeart(0)
    self:AddHeart(3)
    return self
end

function UI:AddHeart(style)
    local heart = gfx.sprite.new()
    local img = gfx.image.new("images/UI/hp"..style)
    heart:setImage(img)
    heart:setCenter(0, 0)
    heart:moveTo(2+30*#self.hearts, 2)
    heart:add()
    self.hearts[#self.hearts+1] = heart
end

function UI:Death()
    local overlay = gfx.sprite.new()
    local img = gfx.image.new("images/UI/death_0")
    overlay:setCenter(0, 0)
    overlay:add()
    overlay:setZIndex(Z_Index.BG)
    self.frame = 0
    self.animationtimer = pd.frameTimer.new(1)
    self.animationtimer.timerEndedCallback = function(timer)     
        if self.frame < 16 then
            self.frame = self.frame +1
        end
        img = gfx.image.new("images/UI/death_"..self.frame)
        overlay:setImage(img)
    end
    self.animationtimer.repeats = true
    self.animationtimer:start()
end