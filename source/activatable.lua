local pd <const> = playdate
local gfx <const> = pd.graphics

class("Activatable").extends(gfx.sprite)

function Activatable:init(x, y, group, defaultactive, activetype, command)
    if x ~= nil and y ~= nil then
        local img = gfx.image.new("images/Props/Box")
        self:setImage(img)
        self:moveTo(x, y)
        self:setZIndex(Z_Index.BG)
        self:setCenter(0, 0)    
    end
    self:add() -- Add to draw list 
    self.activegroup = {}
    self.activetype = activetype
    self.triggercommand = command

    self.defaultactive = false
    if defaultactive == 1 then
        self.defaultactive = true
    end
    self.activated = self.defaultactive
    self.lastactive = self.defaultactive
    self.CustomUpdate = nil
    self.CustomColision = nil
    if group and group ~= "" then
        if string.find(group, ",") then
            for g in string.gmatch(group, '([^,]+)') do
                table.insert(self.activegroup, g)
            end
        else
            table.insert(self.activegroup, group)
        end
    end
    
    ActiveManager.AddActivatable(self)
end

function Activatable:collisionResponse(other)
    if self.CustomColision ~= nil then
        return self:CustomColision(other)
    end
    return nil
end

function Activatable:update()
    if self.CustomUpdate ~= nil then
        self.CustomUpdate()
    end    
    if self.lastactive ~= self.activated then
        self.lastactive = self.activated
        print("Activatable object now has status "..tostring(self.activated))
        if self.triggercommand ~= nil and self.triggercommand ~= "" then
            print("Activatable object triggers command "..self.triggercommand)
            TrackableManager.ProcessCommandLine(self.triggercommand)
            self.triggercommand = nil
        end
    end
end