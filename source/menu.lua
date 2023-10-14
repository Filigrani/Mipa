local pd <const> = playdate
local gfx <const> = pd.graphics
class('Menu').extends(playdate.graphics.sprite)
local poornumbers = gfx.imagetable.new("images/Ui/poornumbers")
function Menu:init()
    self.selectedlevel = 0
    Menu.super.init(self)
    local BGimg = gfx.image.new("images/UI/menudebug")
    local BG = gfx.sprite.new()
    BG:setImage(BGimg)
    BG:setCenter(0, 0)
    BG:moveTo(0, 0)
    BG:setZIndex(Z_Index.UI)
    self.bg = BG
    self.bg:add()
    print("[Menu] Init...")
    self:add()
    local Number1 = gfx.sprite.new()
    Number1:setImage(poornumbers:getImage(2))
    Number1:setCenter(0, 0)
    Number1:moveTo(85, 188)
    Number1:setZIndex(Z_Index.UI)
    self.num1 = Number1
    self.num1:add()
    local Number2 = gfx.sprite.new()
    Number2:setImage(poornumbers:getImage(3))
    Number2:setCenter(0, 0)
    Number2:moveTo(120, 188)
    Number2:setZIndex(Z_Index.UI)
    self.num2 = Number2
    self.num2:add()
    self:UpdateNumbers()
    return self
end

function Menu:UpdateNumbers()
    if self.selectedlevel < 10 then
        self.num2:setImage(gfx.image.new(1,1))
        self.num1:setImage(poornumbers:getImage(self.selectedlevel+1))
    else
        local n1 = tonumber(string.sub(tostring(self.selectedlevel), 1, 1))
        local n2 = tonumber(string.sub(tostring(self.selectedlevel), 2, 2))
        self.num1:setImage(poornumbers:getImage(n1+1))
        self.num2:setImage(poornumbers:getImage(n2+1))
    end
end

function Menu:Update()
    if pd.buttonJustPressed(pd.kButtonA) then
        NextLevel = "lvl"..self.selectedlevel
        StartGame()
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        if self.selectedlevel < 5 then
            self.selectedlevel = self.selectedlevel+1
        end
        self:UpdateNumbers()        
    end
    if pd.buttonJustPressed(pd.kButtonDown) then
        if self.selectedlevel > 0 then
            self.selectedlevel = self.selectedlevel-1
            self:UpdateNumbers()
        end
    end
end