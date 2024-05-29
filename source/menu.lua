local pd <const> = playdate
local gfx <const> = pd.graphics
class('Menu').extends(playdate.graphics.sprite)
local poornumbers = AssetsLoader.LoadImageTable("images/Ui/poornumbers")
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
    self.selector:setZIndex(Z_Index.AllAtop)
    self.selector:add()
    self:AddToggleRender(self.selector, "selector-big")

    self.selector_small = gfx.sprite.new()
    self.selector_small:setCenter(0, 0)
    self.selector_small:moveTo(13, 92)
    self.selector_small:setZIndex(Z_Index.AllAtop)
    self.selector_small:add()
    self:AddToggleRender(self.selector_small, "selector-small")

    -- Start menu
    self.startmenu = gfx.sprite.new()
    self.startmenu:setCenter(0, 0)
    self.startmenu:moveTo(76, 92)
    self.startmenu:setZIndex(Z_Index.UI)
    self.startmenu:add()
    self.startmenu:setVisible(false)
    self:AddToggleRender(self.startmenu, "menu-start", true)

    local startoptions = {}
    
    table.insert(startoptions, {posX = 13, posY = 80, fn = function()
        self:SetMenu("level")
    end})

    table.insert(startoptions, {posX = 13, posY = 125, fn = function()
        self:SetMenu("options")
    end})

    table.insert(startoptions, {posX = 13, posY = 165, fn = function()
        NextLevel = "credits"
        StartGame()
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
            SoundManager:PlaySound("Pap")
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
            if SettingsManager:Get("lang") == "english" then
                SettingsManager:Set("lang", "russian")
            else
                SettingsManager:Set("lang", "english")
            end
            LocalizationManager.currentlanguage = Settings.lang
            LocalizationManager.Load()
            self:ChangeLanguage()
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            self:SaveSettings()
            SoundManager:PlaySound("Pap")
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:SetMenu("options2")
            SoundManager:PlaySound("Pip")
        end
    end)

    -- Options2 menu


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
    self:AddToggleRender(self.dialogboxmode, "menu-dialogbox-"..SettingsManager:Get("dialogboxmode"), true)

    self:AddMenu("options2", optionsoptions, {self.dialogbox, self.options_controls, self.options_selection, self.dialogboxmode}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) then
		    local mode = SettingsManager:Get("dialogboxmode")
            if mode == "dyn" then
                SettingsManager:Set("dialogboxmode", "fixeddown")
            elseif mode == "fixeddown" then
                SettingsManager:Set("dialogboxmode", "fixedup")
            else
                SettingsManager:Set("dialogboxmode", "dyn")
            end
            self.dialogboxmode.originalname = "menu-dialogbox-"..Settings.dialogboxmode
            self:ApplyChangeOnElement(self.dialogboxmode)
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            local mode = SettingsManager:Get("dialogboxmode")
            if mode == "fixeddown" then
                SettingsManager:Set("dialogboxmode", "dyn")
            elseif mode == "fixedup" then
                SettingsManager:Set("dialogboxmode", "fixeddown")
            else
                SettingsManager:Set("dialogboxmode", "fixedup")
            end
            self.dialogboxmode.originalname = "menu-dialogbox-"..Settings.dialogboxmode
            self:ApplyChangeOnElement(self.dialogboxmode)
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self:SetMenu("options")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:SetMenu("music")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            self:SaveSettings()
        end
    end)

    self.musicvolume = gfx.sprite.new()
    self.musicvolume:setCenter(0, 0)
    self.musicvolume:moveTo(50, 106)
    self.musicvolume:setZIndex(Z_Index.UI)
    self.musicvolume:add()
    self.musicvolume:setVisible(false)
    self:AddToggleRender(self.musicvolume, "menu-music", true)

    self.musicvolumesymbol = gfx.sprite.new()
    self.musicvolumesymbol:setCenter(0, 0)
    self.musicvolumesymbol:moveTo(38, 143)
    self.musicvolumesymbol:setZIndex(Z_Index.UI)
    self.musicvolumesymbol:add()
    self.musicvolumesymbol:setVisible(false)
    self:AddToggleRender(self.musicvolumesymbol, "menu-volumeindicator"..SoundManager.MusicVolumeSetting, false)

    local optionsoptionsonleft = {}
    
    table.insert(optionsoptionsonleft, {posX = 7, posY = 90, fn = function()

    end})

    self:AddMenu("music", optionsoptionsonleft, {self.musicvolume, self.options_controls, self.options_selection, self.musicvolumesymbol}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) then
            if SoundManager.MusicVolumeSetting > 0 then
                SoundManager.MusicVolumeSetting = SoundManager.MusicVolumeSetting-1
            end
			SettingsManager:Set("musicvolume", SoundManager.MusicVolumeSetting)
            self.musicvolumesymbol.originalname = "menu-volumeindicator"..SoundManager.MusicVolumeSetting
            self:ApplyChangeOnElement(self.musicvolumesymbol)
            SoundManager:ApplyMusicVolume()
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            if SoundManager.MusicVolumeSetting < 5 then
                SoundManager.MusicVolumeSetting = SoundManager.MusicVolumeSetting+1
            end
            SettingsManager:Set("musicvolume", SoundManager.MusicVolumeSetting)
            self.musicvolumesymbol.originalname = "menu-volumeindicator"..SoundManager.MusicVolumeSetting
            self:ApplyChangeOnElement(self.musicvolumesymbol)
            SoundManager:ApplyMusicVolume()
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self:SetMenu("options2")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:SetMenu("damageglitches")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            self:SaveSettings()
        end
    end)

    self.damageglitches = gfx.sprite.new()
    self.damageglitches:setCenter(0, 0)
    self.damageglitches:moveTo(71, 102)
    self.damageglitches:setZIndex(Z_Index.UI)
    self.damageglitches:add()
    self.damageglitches:setVisible(false)
    self:AddToggleRender(self.damageglitches, "menu-damageglitches", true)

    self.damageglitchessymbol = gfx.sprite.new()
    self.damageglitchessymbol:setCenter(0, 0)
    self.damageglitchessymbol:moveTo(40, 142)
    self.damageglitchessymbol:setZIndex(Z_Index.UI)
    self.damageglitchessymbol:add()
    self.damageglitchessymbol:setVisible(false)
	if SettingsManager:Get("damageglitches") then
	    self:AddToggleRender(self.damageglitchessymbol, "menu-damageglitcheson", false)
	else
	    self:AddToggleRender(self.damageglitchessymbol, "menu-damageglitchesoff", false)
	end

    local optionsoptionsonleftup = {}
    
    table.insert(optionsoptionsonleftup, {posX = 20, posY = 90, fn = function()

    end})

    self:AddMenu("damageglitches", optionsoptionsonleftup, {self.damageglitches, self.options_controls, self.options_selection, self.damageglitchessymbol}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) or pd.buttonJustPressed(pd.kButtonUp) then
            if SettingsManager:Get("damageglitches") then
                Settings.damageglitches = false
				self.damageglitchessymbol.originalname = "menu-damageglitchesoff"
            else
				Settings.damageglitches = true
				self.damageglitchessymbol.originalname = "menu-damageglitcheson"
            end
            self:ApplyChangeOnElement(self.damageglitchessymbol)
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self:SetMenu("music")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            self:SetMenu("lowhpglitches")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            self:SaveSettings()
        end
    end)

    self.lowhpglitches = gfx.sprite.new()
    self.lowhpglitches:setCenter(0, 0)
    self.lowhpglitches:moveTo(71, 102)
    self.lowhpglitches:setZIndex(Z_Index.UI)
    self.lowhpglitches:add()
    self.lowhpglitches:setVisible(false)
    self:AddToggleRender(self.lowhpglitches, "menu-lowhpglitches", true)

    self.lowhpglitchessymbol = gfx.sprite.new()
    self.lowhpglitchessymbol:setCenter(0, 0)
    self.lowhpglitchessymbol:moveTo(40, 142)
    self.lowhpglitchessymbol:setZIndex(Z_Index.UI)
    self.lowhpglitchessymbol:add()
    self.lowhpglitchessymbol:setVisible(false)
	if SettingsManager:Get("lowhpglitches") then
	    self:AddToggleRender(self.lowhpglitchessymbol, "menu-lowhpglitcheson", false)
	else
	    self:AddToggleRender(self.lowhpglitchessymbol, "menu-lowhpglitchesoff", false)
	end

    self:AddMenu("lowhpglitches", optionsoptionsonleftup, {self.lowhpglitches, self.options_controls, self.options_selection, self.lowhpglitchessymbol}, function ()
        if pd.buttonJustPressed(pd.kButtonDown) or pd.buttonJustPressed(pd.kButtonUp) then
            if SettingsManager:Get("lowhpglitches") then
                Settings.lowhpglitches = false
				self.lowhpglitchessymbol.originalname = "menu-lowhpglitchesoff"
            else
                Settings.lowhpglitches = true
				self.lowhpglitchessymbol.originalname = "menu-lowhpglitcheson"
            end
            
            self:ApplyChangeOnElement(self.lowhpglitchessymbol)
            SoundManager:PlaySound("Button")
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self:SetMenu("damageglitches")
            SoundManager:PlaySound("Pip")
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            self:SaveSettings()
        end
    end)

    self.addonsbackground = gfx.sprite.new()
    self.addonsbackground:setCenter(0, 0)
    self.addonsbackground:moveTo(0, 0)
    self.addonsbackground:setImage(AssetsLoader.LoadImage("images/UI/addons_bg"))
    self.addonsbackground:setZIndex(Z_Index.UI)
    self.addonsbackground:add()
    self.addonsbackground:setVisible(false)

    self.addontextsprite = gfx.sprite.new()
    self.addontextsprite:setCenter(0, 0)
    self.addontextsprite:moveTo(85, 27)
    self.addontextsprite:setZIndex(Z_Index.UI)
    self.addontextsprite:setVisible(false)
    self.addontextsprite:add()

    local addonsOptions = {}
    
    table.insert(addonsOptions, 
    {posX = 20, posY = 90, fn = function()end})

    self:AddMenu("addons", addonsOptions, {self.addonsbackground, self.addontextsprite}, function ()

        if pd.buttonJustPressed(pd.kButtonB) then
            self:SetMenu("start")
            SoundManager:PlayMusic("Intro")
        end
    end, false)

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
    obj.imagetable = AssetsLoader.LoadImageTable("images/Ui/"..imagename)
    obj.animindex = 1
    obj:setImage(obj.imagetable:getImage(obj.animindex))
    obj.originalname = imagename
    obj.translatable = translatable
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
        if LocalizationManager.currentlanguage == "english" or not obj.translatable then
            obj.imagetable = AssetsLoader.LoadImageTable("images/Ui/"..obj.originalname)
        else
            obj.imagetable = AssetsLoader.LoadImageTable("images/Ui/"..obj.originalname.."-"..LocalizationManager.currentlanguage)
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

function Menu:AddMenu(name, options, objs, fn, selector_big)
    self.menus[name] = {}
    self.menus[name].options = options
    self.menus[name].objs = objs
    self.menus[name].fn = fn
    if selector_big == nil then
        self.menus[name].selector_big = true
    else
        self.menus[name].selector_big = false
    end
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
    if data.selector_big then
        self.selector:moveTo(optiondata.posX, optiondata.posY)
        if not self.selector:isVisible() then
            self.selector:setVisible(true)
        end
        if self.selector_small:isVisible() then
            self.selector_small:setVisible(false)
        end
    else
        self.selector_small:moveTo(optiondata.posX, optiondata.posY)
        if not self.selector_small:isVisible() then
            self.selector_small:setVisible(true)
        end
        if self.selector:isVisible() then
            self.selector:setVisible(false)
        end
    end
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
    SoundManager:PlaySound("Pap")
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
    SoundManager:PlaySound("Pap")
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
    SoundManager:PlaySound("Pip")
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

function Menu:SaveSettings()
    SaveManager.Save("settings", Settings)
end