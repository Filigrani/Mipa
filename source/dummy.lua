local pd <const> = playdate
local gfx <const> = pd.graphics

class("Dummy").extends(gfx.sprite)

function Dummy:init(x, y)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.BG)
    self:setCenter(0, 0) 
    self:add()
end

function Dummy:collisionResponse(other)
    if self.CustomColision ~= nil then
        return self:CustomColision(other)
    end
    return nil
end

function Dummy:update()
    if self.CustomUpdate ~= nil then
        self.CustomUpdate()
    end
end