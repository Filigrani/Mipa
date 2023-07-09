local pd <const> = playdate
local gfx <const> = pd.graphics

class("CrankDisk").extends(gfx.sprite)

function CrankDisk:init(x, y, platforms)
    local img = gfx.image.new("images/Props/Box")
    self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    --self:setCollideRect(0,0,12,12)
    self:add() -- Add to draw list
    --self:setTag(TAG.Prop)
    self.plaforms = {}
    if platforms ~= nil then
        for i = 1, #platforms, 1 do
            self:AddPlatform(platforms[i])
        end
    end
    CrankManager.AddObject(self)
end

function CrankDisk:Changed(num)
    for i = 1, #self.plaforms, 1 do
        local platform = self.plaforms[i]
        platform.x = platform.x+num
    end
end

function CrankDisk:AddPlatform(platform)
    local img = gfx.image.new("images/Props/Box")
    self:setImage(img)
    self:moveTo(platform.x, platform.y)
    self:setZIndex(Z_Index.Object)
    self:setCollideRect(0,0,12,12)
    self:add() -- Add to draw list
    table.insert(self.plaforms, platform)
end

function CrankDisk:update()

end