local pd <const> = playdate
local gfx <const> = pd.graphics
deathimagetable = gfx.imagetable.new("images/ui/death")
glitchtable = gfx.imagetable.new("images/ui/glitch")
class('UI').extends(playdate.graphics.sprite)

function UI:init()
    UI.super.init(self)
    self.heartsimagetable = gfx.imagetable.new("images/ui/hp")
    self:add() -- Add to draw list
    self.hearts = {}
    self.equipment = {}
    self.passiveitems = {}
    self.lasthearts = 0
    self.lastcontainers = 0
    self.lastequipment = 0
    self.deathtriggered = false
    self.dialogdata = {}
    self.currentdialogindex = 0
    self.currenttext = ""
    self.currdialoglineindex = 1
    self.textwrapingindex = 0
    self.textwrapinglimit = 99
    self.currentdialogactor = "Mipa"
    self.textwaittime = 0
    self.lastglitch = 0
    self.glitchframes = 0
    self:LoadDialogUI()
    print("[UI] Init...")
    return self
end

function UI:PopulateHearts(containers)
    local ExistenHearts = #self.hearts
    if containers > ExistenHearts then
        local needToAdd = containers-ExistenHearts
        print("[UI] Adding "..needToAdd.." heart(s)")
        for i=1, needToAdd do
            self:AddHeart(1)
        end
    elseif containers < ExistenHearts then
        local needToRemove = ExistenHearts-containers
        print("[UI] Removing "..needToRemove.." heart(s)")
        for i=1, needToRemove do
            self:RemoveHeart()
        end
    end
end

function UI:PopulateEquipment(equipment, passive)
    local ExistenEQ = #self.equipment
    local ExistenPI = #self.passiveitems
    if #equipment > ExistenEQ then
        local needToAdd = #equipment-ExistenEQ
        print("[UI] Adding "..needToAdd.." equipment(s)")
        for i=1, needToAdd do
            self:AddEquipment(1, false)
        end
    elseif #equipment < ExistenEQ then
        local needToRemove = ExistenEQ-#equipment
        print("[UI] Removing "..needToRemove.." equipment(s)")
        for i=1, needToRemove do
            self:RemoveEquipment(false)
        end
    end
    if #passive > ExistenPI then
        local needToAdd = #passive-ExistenPI
        print("[UI] Adding "..needToAdd.." passive item(s)")
        for i=1, needToAdd do
            self:AddEquipment(1, true)
        end
    elseif #passive < ExistenPI then
        local needToRemove = ExistenPI-#passive
        print("[UI] Removing "..needToRemove.." passive item(s)")
        for i=1, needToRemove do
            self:RemoveEquipment(true)
        end
    end
end

function UI:UpdateHP(hearts, containers)
    for i=1, #self.hearts do
        local heart = self.hearts[i]
        local style = -1
        if i <= containers then
            if i-0.5 == hearts then
                style = 3
            elseif i <= hearts then
                style = 2
            elseif i > hearts then
                style = 1                   
            end        
        end

        if style == -1 then
            if heart:isVisible() then
                heart:setVisible(false)
            end
        else        
            if not heart:isVisible() then
                heart:setVisible(true)
            end
            if heart.style ~= style then
                print("Heart "..i.." updated to style "..style)
                heart.style  = style
                if heart.myIndex == 1 and style == 3 then
                    style = 1
                end
                heart:setImage(self.heartsimagetable:getImage(style))
            end
        end
    end
end

function UI:UpdateEquipment(equipment, selectedIndex, passiveitems)
    for i=1, #self.equipment do
        local eq = self.equipment[i]
        local style = ""
        local item = equipment[i]
        if i == selectedIndex then
            style = "_active"
        end
        if style ~= eq.style then
            if style == "" then
                print("Equipment slot frame "..i.." updated to style none active")
            else
                print("Equipment slot frame "..i.." updated to style active")
            end
            eq.style = style
            eq:setImage(gfx.image.new("images/UI/equip_slot"..style))
        end       
        if eq.icon.style ~= item then
            print("Equipment slot icon "..i.." updated with item "..item)
            eq.icon.style = item
            eq.icon:setImage(gfx.image.new("images/UI/equip"..item))
        end
    end
    for i=1, #self.passiveitems do
        local eq = self.passiveitems[i]
        local item = passiveitems[i]
        if eq.icon.style ~= item then
            print("Passive item slot icon "..i.." updated with item "..item)
            eq.icon.style = item
            eq.icon:setImage(gfx.image.new("images/UI/passive"..item))
        end
    end
end

function UI:Update()
    local hearts = 0;
    local containers = 0
    local equipment = {}
    local selectedequipment = 1
    local passive = {}
    if MipaInst then
        containers = MipaInst.hpmax/2
        equipment = MipaInst.equipment
        selectedequipment = MipaInst.selectedequipment
        if MipaInst.hp > 0 then
            hearts = MipaInst.hp/2
        end
        passive = MipaInst.passiveitems
    end

    if self.lastcontainers ~= containers then
        self:PopulateHearts(containers)
    end

    if #self.equipment ~= #equipment or #self.passiveitems ~= #passive then
        self:PopulateEquipment(equipment, passive)
        self:UpdateEquipment(equipment, selectedequipment, passive)
    end

    if self.lasthearts ~= hearts then
        self:UpdateHP(hearts, containers)
        self.lasthearts = hearts
    end
    self:ProcessDialog()
    if self.glitchframes > 0 then
        self.glitchframes = self.glitchframes-1
        self:DoGlitch()
    else
        if self.glitchoverlay ~= nil then
            gfx.sprite.removeSprite(self.glitchoverlay)
            self.glitchoverlay = nil
        end
    end
end

function UI:RemoveHeart()
    local lastindex = #self.hearts
    if lastindex > 0 then
        local heart = self.hearts[lastindex]
        if heart then
            table.remove(self.hearts, lastindex)
            gfx.sprite.removeSprite(heart)
        end
    end
end

function UI:AddHeart(style)
    local heart = gfx.sprite.new()
    heart:setCenter(0, 0)
    heart:moveTo(2+30*#self.hearts, 2)
    heart:add()
    heart.style = style
    self.hearts[#self.hearts+1] = heart
    heart.myIndex = #self.hearts
    heart.fadded = false
    heart.fadealpha = 1
    heart.slice = nil
    if heart.myIndex == 1 then
        local slice = gfx.sprite.new()
        slice:setImage(self.heartsimagetable:getImage(6))
        slice:setCenter(0, 0)
        slice:moveTo(heart.x, heart.y)
        slice:setVisible(false)
        slice:add()
        heart.slice = slice  
        heart.heartbittimer = pd.frameTimer.new(2)
        heart.heartbittimer.timerEndedCallback = function(timer)     
            if MipaInst and MipaInst.hp == 1 then
                if not heart.slice:isVisible() then
                    heart.slice:setVisible(true)
                end                   
                local Ditherimg = self.heartsimagetable:getImage(6)
                if heart.fadded then
                    heart.fadealpha = heart.fadealpha+0.1
                    if heart.fadealpha >= 1 then
                        heart.fadded = false
                        heart.fadealpha = 1               
                    end
                else
                    heart.fadealpha = heart.fadealpha-0.1
                    if heart.fadealpha <= 0.5 then
                        heart.fadded = true
                        heart.fadealpha = 0.5                              
                    end
                end
                Ditherimg = Ditherimg:fadedImage(heart.fadealpha, gfx.image.kDitherTypeBayer8x8)
                heart.slice:setImage(Ditherimg) 
            else
                if heart.slice:isVisible() then
                    heart.slice:setVisible(false)
                end   
            end
        end  
        heart.heartbittimer.repeats = true     
    end
end

function UI:Death()
    if self.deathtriggered then
        return
    end
    self.deathtriggered = true
    
    local overlay = gfx.sprite.new()
    overlay:setCenter(0, 0)
    overlay:add()
    overlay:setZIndex(Z_Index.BG)
    overlay.frame = 1
    overlay.animationtimer = pd.frameTimer.new(1)
    overlay.animationtimer.timerEndedCallback = function(timer)             
        if overlay.frame < 16 then
            overlay.frame = overlay.frame +1
            overlay:setImage(deathimagetable:getImage(overlay.frame))          
        else
            overlay.animationtimer.repeats = false
            gfx.sprite.removeAll()
            DeathTrigger()
        end
    end
    overlay.animationtimer.repeats = true
    overlay.animationtimer:start()
end

function UI:AddEquipment(style, ispassive)
    local eq = gfx.sprite.new()
    eq:setCenter(0, 0)
    if not ispassive then
        eq:setImage(gfx.image.new("images/UI/equip_slot"))
        eq:moveTo(371-30*#self.equipment, 2)
    else
        eq:setImage(gfx.image.new("images/UI/passive_slot"))
        local lastEQPosition = 378-30*#self.equipment
        eq:moveTo(lastEQPosition-27*#self.passiveitems, 9)
    end
    eq:add()
    eq.style = ""
    if not ispassive then
        self.equipment[#self.equipment+1] = eq
    else
        self.passiveitems[#self.passiveitems+1] = eq
    end
    eq.icon = gfx.sprite.new()
    eq.icon.style = 0
    local imgSlice = gfx.image.new("images/UI/equip0")
    eq.icon:setImage(imgSlice)
    eq.icon:setCenter(0, 0)
    eq.icon:moveTo(eq.x, eq.y)
    eq.icon:add()
end

function UI:RemoveEquipment(ispassive)
    if not ispassive then
        local lastindex = #self.equipment
        if lastindex > 0 then
            local eq = self.equipment[lastindex]
            if eq then
                table.remove(self.equipment, lastindex)
                gfx.sprite.removeSprite(eq.icon)
                gfx.sprite.removeSprite(eq)
            end
        end
    else
        local lastindex = #self.passiveitems
        if lastindex > 0 then
            local p = self.passiveitems[lastindex]
            if p then
                table.remove(self.passiveitems, lastindex)
                gfx.sprite.removeSprite(p.icon)
                gfx.sprite.removeSprite(p)
            end
        end
    end
end

function UI:ProcessDialog()
    if self.currentdialogindex ~= 0 and #self.dialogdata > 0 and self.dialogbg ~= nil then
        local ShowActor = true
        local ActorChanged = false
        local currentLineData = self.dialogdata[self.currdialoglineindex]
        if self.currentdialogactor ~= currentLineData.actor then
            self.currentdialogactor = currentLineData.actor
            ActorChanged = true
        end
        if self.currentdialogactor == "None" then
            ShowActor = false
        end
        if not self.dialogbg:isVisible() then
            self.dialogbg:setVisible(true)
        end
        if not self.dialogactor:isVisible() and ShowActor then
            self.dialogactor:setVisible(true)
        elseif self.dialogactor:isVisible() and not ShowActor then
            self.dialogactor:setVisible(false)
        end
        if not self.dialogtextsprite:isVisible() then
            self.dialogtextsprite:setVisible(true)
        end
        if ActorChanged then
            if ShowActor then
                self.dialogactor:setImage(gfx.image.new("images/UI/Dialog"..self.currentdialogactor))
            end
            print("Actor changed "..self.currentdialogactor)
        end
        local LineText = currentLineData.text
        if self.currenttext ~= LineText then
            local character = string.sub(LineText, self.currentdialogindex, self.currentdialogindex)
            self.currenttext = self.currenttext..character
            self.currentdialogindex = self.currentdialogindex+1
            self.textwaittime = self.currentdialogindex*2
            --self.textwrapingindex = self.textwrapingindex+1
            --if self.textwrapingindex >= self.textwrapinglimit then
            --    self.textwrapingindex = 0
            --    self.currenttext = self.currenttext.."\n"
            --end
            if self.currentdialogactor == "None" then
                SoundManager:PlaySound("Pap")
            elseif self.currentdialogactor == "Mipa" then
                SoundManager:PlaySound("Peaw")
            elseif self.currentdialogactor == "Wipa" then
                SoundManager:PlaySound("Sqeak")
            else
                SoundManager:PlaySound("Pap")
            end
            local drawingW = 300
            local darwingH = 62
            if not ShowActor then
                drawingW = 388
            end
            self.dialogtextimage:clear(gfx.kColorClear)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            gfx.pushContext(self.dialogtextimage)
                gfx.drawTextInRect(self.currenttext, 0, 0, drawingW, darwingH, nil, "")
            gfx.popContext()
            gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
            self.dialogtextsprite:setImage(self.dialogtextimage)
            --print("character "..character)
            --print("Fulltext "..self.currenttext)
            if ActorChanged then
                if ShowActor then
                    if self.currentdialogactor == "Mipa" then
                        self.dialogtextsprite:moveTo(91, 175)
                        self.dialogactor:moveTo(7, 170)
                    else
                        self.dialogtextsprite:moveTo(7, 175)
                        self.dialogactor:moveTo(323, 170)
                    end
                else
                    self.dialogtextsprite:moveTo(7, 175)
                end
            end
        else
            if self.textwaittime > 0 then
                self.textwaittime = self.textwaittime-1
            else
                if self.currdialoglineindex+1 <= #self.dialogdata then
                    self.currdialoglineindex = self.currdialoglineindex+1
                    self.currentdialogindex = 1
                    self.currenttext = ""
                    self.dialogtextimage = gfx.image.new(388, 62)
                else             
                    self.currentdialogindex = 0
                    self.dialogdata = {}
                    self.dialogtextimage = gfx.image.new(388, 62)
                    if self.ondialogfinish ~= nil and self.ondialogfinish ~= "" then
                        TrackableManager.ProcessCommandLine(self.ondialogfinish)
                        self.ondialogfinish = nil
                    end
                    self.dialogbg:remove()
                    self.dialogactor:remove()
                    self.dialogtextsprite:remove()
                end
            end
        end
    end
end

function UI:LoadDialogUI()
    local BGimg = gfx.image.new("images/UI/dialog")
    local BG = gfx.sprite.new()
    BG:setImage(BGimg)
    BG:setCenter(0, 0)
    BG:moveTo(0, 170)
    BG:setZIndex(Z_Index.UI)
    local Actorimg = gfx.image.new("images/UI/DialogMipa")
    local Actor = gfx.sprite.new()
    Actor:setImage(Actorimg)
    Actor:setCenter(0, 0)
    Actor:moveTo(0, 170)
    Actor:setZIndex(Z_Index.UI)
    local DialogTextSprite = gfx.sprite.new()
    DialogTextSprite:setCenter(0, 0)
    DialogTextSprite:moveTo(91, 175)
    DialogTextSprite:setZIndex(Z_Index.UI)
    self.dialogtextimage = gfx.image.new(388, 62)
    self.dialogbg = BG
    self.dialogactor = Actor
    self.dialogtextsprite = DialogTextSprite
end

function UI:StartDialog(data, onstart, onfinish)
    if DebugFlags.NoDialogs then
        return
    end
    self.dialogtextimage = gfx.image.new(388, 62)
    self.currentdialogindex = 1
    self.currdialoglineindex = 1
    self.dialogdata = data
    self.currenttext = ""
    self.textwrapingindex = 0
    self.dialogbg:add()
    self.dialogactor:add()
    self.dialogtextsprite:add()
    if self.ondialogfinish ~= nil and self.ondialogfinish ~= "" then -- in case when we start new dialog when previous was still in process
        TrackableManager.ProcessCommandLine(self.ondialogfinish)
    end
    self.ondialogfinish = onfinish
    if onstart ~= nil and onstart ~= "" then
        TrackableManager.ProcessCommandLine(onstart)
    end
end

function UI:DoGlitch()
    if self.glitchoverlay == nil then
        local glitchSP = gfx.sprite.new()
        glitchSP:setCenter(0, 0)
        glitchSP:moveTo(0, 0)
        glitchSP:setZIndex(Z_Index.UI)
        glitchSP:add()
        self.glitchoverlay = glitchSP
    end
    local glitchIndex = math.floor(math.random(1,6)+0.5)
    if self.lastglitch == glitchIndex then
        if glitchIndex == 6 then
            glitchIndex = math.floor(math.random(1,5)+0.5)
        else
            glitchIndex = glitchIndex+1
        end
    end
    self.lastglitch = glitchIndex
    self.glitchoverlay:setImage(glitchtable:getImage(glitchIndex))
    SoundManager:PlaySound("GlitchNew")
end