local pd <const> = playdate
local gfx <const> = pd.graphics

class("Activator").extends(gfx.sprite)

function Activator:init(x, y, group)
    local img = AssetsLoader.LoadImage("images/Props/Box")
    self:setImage(img)
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCenter(0, 0)
    self:setTag(TAG.Interactive)
    self:add() -- Add to draw list
    self.activegroup = {}
    self.activated = false
    self.IsButton = true
    self.CustomUpdate = nil

    if group and group ~= "" then
        if string.find(group, ",") then
            for g in string.gmatch(group, '([^,]+)') do
                table.insert(self.activegroup, g)
            end
        else
            table.insert(self.activegroup, group)
        end
    end

    ActiveManager.AddActivator(self)
end

function Activator:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function Activator:PressButton()
    if not self.activated then
        self.activated = true
        SoundManager:PlaySound("Button")
        print("[Activator] Activator triggered groups:")
        for i = 1, #self.activegroup, 1 do
            print(self.activegroup[i])
        end
    else
        SoundManager:PlaySound("No")
    end
end


function Activator:update()
    if self.CustomUpdate ~= nil then
        self.CustomUpdate()
    end
end