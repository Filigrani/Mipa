local pd <const> = playdate
local gfx <const> = pd.graphics
class('Menu').extends(playdate.graphics.sprite)
local poornumbers = gfx.imagetable.new("images/Ui/poornumbers")
function Menu:init()
    print("[Menu] Init...")
    self.selectedlevel = 0
    self.toggles = {}
    self.menus = {}
    self.currentmenu = "start"
    self.currentselectedindex = 1
    Menu.super.init(self)
    self:add()

    self.bg = gfx.sprite.new()
    self.bg:setCenter(0, 0)
    self.bg:moveTo(220, 0)
    self.bg:setZIndex(Z_Index.UI)
    self.bg:add()
    self:AddToggleRender(self.bg, "MipaBG")

    self.title = gfx.sprite.new()
    self.title:setCenter(0, 0)
    self.title:moveTo(63, 5)
    self.title:setZIndex(Z_Index.UI)
    self.title:add()
    self:AddToggleRender(self.title, "menu-title")

    self.selector = gfx.sprite.new()
    self.selector:setCenter(0, 0)
    self.selector:moveTo(13, 92)
    self.selector:setZIndex(Z_Index.UI)
    self.selector:add()
    self:AddToggleRender(self.selector, "selector-big")

    -- Start menu
    self.startmenu = gfx.sprite.new()
    self.startmenu:setCenter(0, 0)
    self.startmenu:moveTo(76, 112)
    self.startmenu:setZIndex(Z_Index.UI)
    self.startmenu:add()
    self.startmenu:setVisible(false)
    self:AddToggleRender(self.startmenu, "menu-start", true)

    local startoptions = {}
    
    table.insert(startoptions, {posX = 13, posY = 100, fn = function()
        self:SetMenu("level")
    end})

    table.insert(startoptions, {posX = 13, posY = 145, fn = function()
        self:SetMenu("options")
    end})

    self:AddMenu("start", startoptions, {self.startmenu})

    -- Level Menu

    self.levelmenu = gfx.sprite.new()
    self.levelmenu:setCenter(0, 0)
    self.levelmenu:moveTo(81, 110)
    self.levelmenu:setZIndex(Z_Index.UI)
    self.levelmenu:add()
    self.levelmenu:setVisible(false)
    self:AddToggleRender(self.levelmenu, "level-title", true)

    self.num1 = gfx.sprite.new()
    self.num1:setImage(poornumbers:getImage(2))
    self.num1:setCenter(0, 0)
    self.num1:moveTo(213, 115)
    self.num1:setZIndex(Z_Index.UI)
    self.num1:add()
    self.num1:setVisible(false)

    self.num2 = gfx.sprite.new()
    self.num2:setImage(poornumbers:getImage(3))
    self.num2:setCenter(0, 0)
    self.num2:moveTo(248, 115)
    self.num2:setZIndex(Z_Index.UI)
    self.num2:add()
    self.num2:setVisible(false)

    self:UpdateNumbers()

    self.menu_controls = gfx.sprite.new()
    self.menu_controls:setCenter(0, 0)
    self.menu_controls:moveTo(0, 211)
    self.menu_controls:setZIndex(Z_Index.UI)
    self.menu_controls:add()
    self.menu_controls:setVisible(false)
    self:AddToggleRender(self.menu_controls, "menu-controls", true)

    local leveloptions = {}

    table.insert(leveloptions, {posX = 13, posY = 100, fn = function()
        NextLevel = "lvl"..self.selectedlevel
        StartGame()
    end})

    self:AddMenu("level", leveloptions, {self.levelmenu, self.num1, self.num2, self.menu_controls}, function ()
        if pd.buttonJustPressed(pd.kButtonUp) then
            if self.selectedlevel < LevelsLimit then
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
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
        end               
    end)

    -- Options menu
    self.optionsmenu = gfx.sprite.new()
    self.optionsmenu:setCenter(0, 0)
    self.optionsmenu:moveTo(70, 108)
    self.optionsmenu:setZIndex(Z_Index.UI)
    self.optionsmenu:add()
    self.optionsmenu:setVisible(false)
    self:AddToggleRender(self.optionsmenu, "menu-options", true)

    self.currentlang = gfx.sprite.new()
    self.currentlang:setCenter(0, 0)
    self.currentlang:moveTo(68, 153)
    self.currentlang:setZIndex(Z_Index.UI)
    self.currentlang:add()
    self.currentlang:setVisible(false)
    self:AddToggleRender(self.currentlang, "menu-lang", true)

    self.options_controls = gfx.sprite.new()
    self.options_controls:setCenter(0, 0)
    self.options_controls:moveTo(0, 211)
    self.options_controls:setZIndex(Z_Index.UI)
    self.options_controls:add()
    self.options_controls:setVisible(false)
    self:AddToggleRender(self.options_controls, "menu-options-controls", true)

    self.options_selection = gfx.sprite.new()
    self.options_selection:setCenter(0, 0)
    self.options_selection:moveTo(92, 75)
    self.options_selection:setZIndex(Z_Index.UI)
    self.options_selection:add()
    self.options_selection:setVisible(false)
    self:AddToggleRender(self.options_selection, "menu-options-selection", true)


    local optionsoptions = {}
    
    table.insert(optionsoptions, {posX = 13, posY = 100, fn = function()

    end})

    self:AddMenu("options", optionsoptions, {self.optionsmenu, self.currentlang, self.options_controls, self.options_selection}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) or pd.buttonJustPressed(pd.kButtonUp) then
            if LocalizationManager.defaultlanguage == "english" then
                LocalizationManager.defaultlanguage = "russian"
            else
                LocalizationManager.defaultlanguage = "english"
            end
            LocalizationManager.Load()
            self:ChangeLanguage()
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:SetMenu("options2")
        end
    end)

    -- Options2 menu

    
    -- TO-DO:
    -- Add russian variant for menu-dialogbox, and option select for static/dyanmic dialog


    self.dialogbox = gfx.sprite.new()
    self.dialogbox:setCenter(0, 0)
    self.dialogbox:moveTo(65, 98)
    self.dialogbox:setZIndex(Z_Index.UI)
    self.dialogbox:add()
    self.dialogbox:setVisible(false)
    self:AddToggleRender(self.dialogbox, "menu-dialogbox", true)

    self.dialogboxmode = gfx.sprite.new()
    self.dialogboxmode:setCenter(0, 0)
    self.dialogboxmode:moveTo(62, 145)
    self.dialogboxmode:setZIndex(Z_Index.UI)
    self.dialogboxmode:add()
    self.dialogboxmode:setVisible(false)
    self:AddToggleRender(self.dialogboxmode, "menu-dialogbox-"..DialogboxMode, true)

    self:AddMenu("options2", optionsoptions, {self.dialogbox, self.options_controls, self.options_selection, self.dialogboxmode}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) then
            if DialogboxMode == "dyn" then
                DialogboxMode = "fixeddown"
            elseif DialogboxMode == "fixeddown" then
                DialogboxMode = "fixedup"
            else
                DialogboxMode = "dyn"
            end
            self.dialogboxmode.originalname = "menu-dialogbox-"..DialogboxMode
            self:ApplyChangeOnElement(self.dialogboxmode)
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            if DialogboxMode == "fixeddown" then
                DialogboxMode = "dyn"
            elseif DialogboxMode == "fixedup" then
                DialogboxMode = "fixeddown"
            else
                DialogboxMode = "fixedup"
            end
            self.dialogboxmode.originalname = "menu-dialogbox-"..DialogboxMode
            self:ApplyChangeOnElement(self.dialogboxmode)
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self:SetMenu("options")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
        end
    end)

    self.animtimer = pd.frameTimer.new(7)
	self.animtimer.timerEndedCallback = function(timer)
        self:ToggleSprites()
	end
	self.animtimer.repeats = true
	self.animtimer:start()
    self:SetMenu(self.currentmenu)
    self:SelectorPos()
    self:ChangeLanguage()
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

function Menu:AddToggleRender(obj, imagename, translatable)
    obj.imagetable = gfx.imagetable.new("images/Ui/"..imagename)
    obj.animindex = 1
    obj:setImage(obj.imagetable:getImage(obj.animindex))
    if translatable then
        obj.originalname = imagename
    end
    table.insert(self.toggles, obj)
end

function Menu:ToggleSprites()
    for i = 1, #self.toggles, 1 do
        local obj = self.toggles[i]
        if obj ~= nil then
            if obj.animindex == 1 then
                obj.animindex = 2
            else
                obj.animindex = 1
            end
            obj:setImage(obj.imagetable:getImage(obj.animindex))
        end
    end
end

function Menu:ApplyChangeOnElement(obj)
    if obj.originalname then
        if LocalizationManager.defaultlanguage == "english" then
            obj.imagetable = gfx.imagetable.new("images/Ui/"..obj.originalname)
        else
            obj.imagetable = gfx.imagetable.new("images/Ui/"..obj.originalname.."-"..LocalizationManager.defaultlanguage)
        end
    end
    obj:setImage(obj.imagetable:getImage(obj.animindex))    
end

function Menu:ChangeLanguage()
    for i = 1, #self.toggles, 1 do
        local obj = self.toggles[i]
        if obj ~= nil then
            self:ApplyChangeOnElement(obj)
        end
    end
end

function Menu:AddMenu(name, options, objs, fn)
    self.menus[name] = {}
    self.menus[name].options = options
    self.menus[name].objs = objs
    self.menus[name].fn = fn
end

function Menu:SetMenu(name)
    local currentMenuData = self.menus[self.currentmenu]
    for i = 1, #currentMenuData.objs, 1 do
        currentMenuData.objs[i]:setVisible(false)
    end
    self.currentmenu = name
    currentMenuData = self.menus[self.currentmenu]
    if currentMenuData == nil then
        return
    end
    for i = 1, #currentMenuData.objs, 1 do
        currentMenuData.objs[i]:setVisible(true)
    end
    self.currentselectedindex = 1
    self:SelectorPos()
end

function Menu:SelectorPos()
    local data = self.menus[self.currentmenu]
    if data == nil then
        return
    end
    local optiondata = data.options[self.currentselectedindex]
    self.selector:moveTo(optiondata.posX, optiondata.posY)
end

function Menu:InputUp()
    local data = self.menus[self.currentmenu]
    if data == nil then
        return
    end
    local maxelemets =  #data.options
    if self.currentselectedindex == 1 then
        self.currentselectedindex = maxelemets
    else
        self.currentselectedindex = self.currentselectedindex-1
    end
    self:SelectorPos()
end

function Menu:InputDown()
    local data = self.menus[self.currentmenu]
    if data == nil then
        return
    end
    local maxelemets =  #data.options
    if self.currentselectedindex == maxelemets then
        self.currentselectedindex = 1
    else
        self.currentselectedindex = self.currentselectedindex+1
    end
    self:SelectorPos()
end

function Menu:InputSelect()
    local data = self.menus[self.currentmenu]
    if data == nil then
        return
    end
    local fn = data.options[self.currentselectedindex].fn
    if fn then
        fn()
    end
end

function Menu:Update()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:InputSelect()
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        self:InputUp()      
    end
    if pd.buttonJustPressed(pd.kButtonDown) then
        self:InputDown()
    end
    if self.menus[self.currentmenu] then
        local data = self.menus[self.currentmenu]
        if data.fn then
            data.fn()
        end
    end
end