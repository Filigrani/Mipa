local pd <const> = playdate
local gfx <const> = pd.graphics
deathimagetable = AssetsLoader.LoadImageTable("images/ui/death")
glitchtable = AssetsLoader.LoadImageTable("images/ui/glitch")
class('UI').extends(playdate.graphics.sprite)
import "jsonloader"
-- Optimize calls of requisting settings
local dialogMode = SettingsManager:Get("dialogboxmode")
function UI:init()
    UI.super.init(self)
    self.heartstilemap = pd.graphics.tilemap.new()
    self.heartstilemap:setImageTable(AssetsLoader.LoadImageTable("images/ui/hp"))

    self.heartsui = gfx.sprite.new()
    self.heartsui:setIgnoresDrawOffset(true)
    self.heartsui:setTilemap(self.heartstilemap)
    self.heartsui:setCenter(0, 0)
    self.heartsui:add()

    self.equipmenttable = AssetsLoader.LoadImageTable("images/ui/equipment")
    self.equipmentsui = gfx.sprite.new()
    self.equipmentsui:setIgnoresDrawOffset(true)
    self.equipmentsui:setCenter(1, 0)
    self.equipmentsui:moveTo(398, 2)
    self.equipmentsui:add()
    self.equipmentpositionlookups = {}

    self.passivetable = AssetsLoader.LoadImageTable("images/ui/passive")
    self.passivesui = gfx.sprite.new()
    self.passivesui:setIgnoresDrawOffset(true)
    self.passivesui:setCenter(1, 0)
    self.passivesui:moveTo(0, 2)
    self.passivesui:add()

    self.selectorreachx = 0

    self.equipment_selectorsui = gfx.sprite.new()
    self.equipment_selectorsui:setIgnoresDrawOffset(true)
    self.equipment_selectorsui:setCenter(0, 0)
    self.equipment_selectorsui:moveTo(0, 0)
    self.equipment_selectorsui:setImage(AssetsLoader.LoadImage("images/ui/equip_slot_active"))
    self.equipment_selectorsui:add()
    self.equipment_selectorsui:setVisible(false)

    self:add() -- Add to draw list

    self.lasthearts = 0
    self.lastcontainers = 0

    self.deathtriggered = false
    self.dialogdata = {}
    self.currentdialogindex = 0
    self.currenttext = ""
    self.currdialoglineindex = 1
    self.textwrapingindex = 0
    self.textwrapinglimit = 99
    self.currentdialogactor = {}
    self.currentdialogactor.name = "None"
    self.currentdialogactor.arguments = {"1"}
    self.currentdialogactor.rawtext = "None"
    self.textwaittime = 0
    self.lastglitch = 0
    self.glitchframes = 0
    self.dialogYroot = 175
    self.skipflash = 0
    self.pixelfadeX = 0
    self.pixelfadeY = 0
    self.dialogskipframe = 0
    self:LoadDialogUI()
    print("[UI] Init...")

    if MipaInst then
        self:UpdateEquipment(MipaInst.equipment)
        self:UpdateEquipmentSelector(MipaInst.selectedequipment, true)
        self:UpdatePassiveEquipment(MipaInst.passiveitems)
    end

    return self
end

function UI:UpdateHeartFlash(hearts)
    if self.slice == nil and not self.disableflashingheart then
        local slice = gfx.sprite.new()
        slice:moveTo(0, 0)
        slice:setCenter(0, 0)
        slice:add()
        slice:setIgnoresDrawOffset(true)
        slice:setImage(AssetsLoader.LoadImageTable("images/ui/heartslice"):getImage(1))

        slice.imgindex = 1
        slice.direction = 1
        slice.nextupdate = 2

        self.slice = slice
    end

    if hearts == 0.5 and not self.disableflashingheart then
        if not self.slice:isVisible() then
            self.slice:setVisible(true)
        end
        if self.slice.nextupdate <= 0 then
			self.slice.nextupdate = 3
			if self.slice.imgindex >= 6 then
				self.slice.direction = -1
			elseif self.slice.imgindex == 1 then
				self.slice.direction = 1
			end
			self.slice.imgindex = self.slice.imgindex+self.slice.direction
			self.slice:setImage(AssetsLoader.LoadImageTable("images/ui/heartslice"):getImage(self.slice.imgindex))
		else
			self.slice.nextupdate = self.slice.nextupdate-1
		end
    else
        if self.slice and self.slice:isVisible() then
            self.slice:setVisible(false)
        end
    end
end

function UI:UpdateHP(hearts, containers)
    print("[UI] UpdateHP: Hearts "..hearts.." containers "..containers)
    local data, _ = self.heartstilemap:getTiles()

    if #data ~= containers then
        if containers < 1 then
            self.heartstilemap:setSize(1, 1)
        else
            self.heartstilemap:setSize(containers, 1)
        end
        print("[UI] Updated hearts containers, now there is "..containers.." hearts")
    end

    for i=1, math.ceil(containers) do
        local style = 0

        if MipaInst then
            if MipaInst.Jobee or MipaInst.JobeeCrank then
                self.disableflashingheart = true
                if hearts > 0 then
                    style = 7
                else
                    style = 8
                end
            else
                self.disableflashingheart = false
            end
        end

        if i <= containers then
            if i-0.5 == hearts then
                style = 3
            elseif i <= hearts then
                style = 2
            elseif i > hearts then
                style = 1
            end
        end

        if data[i] ~= style then
            self.heartstilemap:setTileAtPosition(i, 1, style)
            self.heartsui:setTilemap(self.heartstilemap)
            print("[UI] Heart "..i.." updated to style "..style)
        else
            --print("[UI] Heart "..i.." still remains to have style "..style)
        end
    end
end

function UI:UpdateEquipment(equipment)
    
    local spacing = 3
    local icon_size = 27
    local equipment_count = #equipment

    if equipment_count == 0 then
        if self.equipmentsui:isVisible() then
            self.equipmentsui:setVisible(false)
        end
        return
    else
        if not self.equipmentsui:isVisible() then
            self.equipmentsui:setVisible(true)
        end
    end

    local imageW = (icon_size*equipment_count)+(spacing*equipment_count)
    local image = gfx.image.new(imageW, icon_size)

    local drawoffset = imageW-icon_size

    local frame = AssetsLoader.LoadImage("images/UI/equip_slot")
    self.equipmentpositionlookups = {}

    local panelorigin = self.equipmentsui.x

    for i=1, equipment_count do
        gfx.pushContext(image)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        local item_index = equipment[i]
        local icon = self.equipmenttable:getImage(item_index)
        frame:draw(drawoffset,0)
        icon:draw(drawoffset,0)
        local lookup  = panelorigin-(icon_size*i)-(spacing*(i-1))
        table.insert(self.equipmentpositionlookups, lookup)
        print("[UI][UpdateEquipment] Draw Icon "..item_index.." on "..drawoffset)


        drawoffset = drawoffset-icon_size-spacing

        gfx.popContext()
    end
    self.equipmentsui:setImage(image)
    self.passivesui:moveTo(panelorigin-imageW-spacing, 9)
    ShouldUpdatePauseMenu = true
end

function UI:UpdatePassiveEquipment(passiveitems)
    local spacing = 3
    local icon_size = 20
    local equipment_count = #passiveitems

    if equipment_count == 0 then
        if self.passivesui:isVisible() then
            self.passivesui:setVisible(false)
        end
        return
    else
        if not self.passivesui:isVisible() then
            self.passivesui:setVisible(true)
        end
    end

    local imageW = (icon_size*equipment_count)+(spacing*equipment_count)
    local image = gfx.image.new(imageW, icon_size)

    local drawoffset = imageW-icon_size

    local frame = AssetsLoader.LoadImage("images/UI/passive_slot")

    for i=1, equipment_count do
        gfx.pushContext(image)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        local item_index = passiveitems[i]
        local icon = self.passivetable:getImage(item_index)
        frame:draw(drawoffset,0)
        icon:draw(drawoffset,0)

        print("[UI][UpdatePassiveEquipment] Draw Icon "..item_index.." on "..drawoffset)


        drawoffset = drawoffset-icon_size-spacing

        gfx.popContext()
    end
    self.passivesui:setImage(image)
    ShouldUpdatePauseMenu = true
end

function UI:UpdateEquipmentSelector(equipmentselected, force)
    local equipment_count = #self.equipmentpositionlookups
    if equipment_count == 0 then
        if self.equipment_selectorsui:isVisible() then
            self.equipment_selectorsui:setVisible(false)
        end
    else
        if not self.equipment_selectorsui:isVisible() then
            self.equipment_selectorsui:setVisible(true)
        end
        if equipmentselected ~= 0 then
            local x_position = self.equipmentpositionlookups[equipmentselected]
            self.selectorreachx = x_position
            if force then
                self.equipment_selectorsui:moveTo(x_position, 2)
            end
        end
    end
end

function UI:PauseMenuDown(type, ori)
    if MipaInst then
        if type == 1 then
            if #MipaInst.passiveitems > 0 then
                self.pauseoverlay.type = 2
                self.pauseoverlay.selected = 1
            elseif #FoundNotes > 0 then
                self.pauseoverlay.type = 3
                self.pauseoverlay.selected = 1
            else
                return
            end
        elseif type == 2 then
            if #FoundNotes > 0 then
                self.pauseoverlay.type = 3
                self.pauseoverlay.selected = 1
            else
                self.pauseoverlay.type = 1
                self.pauseoverlay.selected = 1
            end
        elseif type == 3 then
            self.pauseoverlay.type = 1
            self.pauseoverlay.selected = 1
        end
    end
    self:PauseSelector()
end

function UI:PauseMenuUp(type, ori)
    if MipaInst then
        if type == 1 then
            if #FoundNotes > 0 then
                self.pauseoverlay.type = 3
                self.pauseoverlay.selected = 1
            elseif #MipaInst.passiveitems > 0 then
                self.pauseoverlay.type = 2
                self.pauseoverlay.selected = 1
            else
                return
            end
        elseif type == 2 then
            self.pauseoverlay.type = 1
            self.pauseoverlay.selected = 1
        elseif type == 3 then
            if #MipaInst.passiveitems > 0 then
                self.pauseoverlay.type = 2
                self.pauseoverlay.selected = 1
            else
                self.pauseoverlay.type = 1
                self.pauseoverlay.selected = 1
            end
        end
    end
    self:PauseSelector()
end

function UI:ForceUpdateHP(hp, maxhp)
    self:UpdateHP(hp/2, maxhp/2)
    self.lasthearts = hp/2
end

function UI:Update()
    if pd.buttonIsPressed(pd.kButtonUp) then
        if self.dialogskipframe < 25 then
            self.dialogskipframe = self.dialogskipframe+1
        else
            self.dialogskipframe = 0 
            if CurrentLevelName == "intro" then
                NextLevel = "menu"
                self:SkipIntro()
            else
                if self:IsCutscene() and (self.scenejsonTable.linkeddialog == nil or self.scenejsonTable.linkeddialog == "") then
                    self:CutsceneFinished()
                else
                    self:CancleDialog()
                end
            end
        end
    else
        self.dialogskipframe = 0
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        self:SkipDialogLine()
    end

    if self.conversationTable ~= nil then
        if pd.buttonJustPressed(pd.kButtonUp) then
            if self.conversationTable.index == 1 then
                self.conversationTable.index = #self.conversationTable.options
            else
                self.conversationTable.index = self.conversationTable.index-1
            end
            self:SetConversationSelector(self.conversationTable.index)
        end
        if pd.buttonJustPressed(pd.kButtonDown) then
            if self.conversationTable.index < #self.conversationTable.options then
                self.conversationTable.index = self.conversationTable.index+1
            else
                self.conversationTable.index = 1
            end
            self:SetConversationSelector(self.conversationTable.index)
        end
        if pd.buttonJustPressed(pd.kButtonA) then
            self:SelectConversationOption(self.conversationTable.index)
        end
    end
    
    local hearts = 0;
    local containers = 0
    local passive = {}
    if MipaInst then
        containers = MipaInst.hpmax/2
        if MipaInst.hp > 0 then
            hearts = MipaInst.hp/2
        end
    end

    if self.lasthearts ~= hearts then
        self:UpdateHP(hearts, containers)
        self.lasthearts = hearts
    end
    self:UpdateHeartFlash(self.lasthearts)
    self:UpdateStaminaBar()

    if self.equipment_selectorsui then
        if self.equipment_selectorsui.x ~= self.selectorreachx then
            self.equipment_selectorsui:moveTo(Lerp(self.equipment_selectorsui.x, self.selectorreachx, 3), 2)
        end
    end

    self:ProcessDialog()
    if self.glitchframes > 0 then
        self.glitchframes = self.glitchframes-1
        self:DoGlitch()
        if self.glitchframes == 0 then
            if self.oneglitchover ~= nil then
                self.oneglitchover()
            end
        end
    else
        if self.glitchoverlay ~= nil then
            gfx.sprite.removeSprite(self.glitchoverlay)
            self.glitchoverlay = nil
        end
    end
    if self.pauseoverlay then
        if pd.buttonJustPressed(pd.kButtonA) then
            if MipaInst then
                if self.pauseoverlay.type == 1 then
                    self:StartDialog(GetDialogDataFromString("ExamineEquipment"..MipaInst.equipment[self.pauseoverlay.selected]))
                elseif self.pauseoverlay.type == 2 then
                    self:StartDialog(GetDialogDataFromString("ExaminePassive"..MipaInst.passiveitems[self.pauseoverlay.selected]))
                elseif self.pauseoverlay.type == 3 then
                    self:StartDialog(GetDialogDataFromString("Note"..FoundNotes[self.pauseoverlay.selected]))
                end
            end
        end
        if pd.buttonJustPressed(pd.kButtonDown) then
            self:PauseMenuDown(self.pauseoverlay.type)
        end
        if pd.buttonJustPressed(pd.kButtonUp) then
            self:PauseMenuUp(self.pauseoverlay.type)
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            self:HidePauseMenu()
        end
        if pd.buttonJustPressed(pd.kButtonLeft) then
            local max = 0
            if self.pauseoverlay.type == 1 then
                if MipaInst then
                    max = #MipaInst.equipment
                end
            elseif self.pauseoverlay.type == 2 then
                if MipaInst then
                    max = #MipaInst.passiveitems
                end
            elseif self.pauseoverlay.type == 3 then
                max = #FoundNotes
            end
            if max > 0 then
                if self.pauseoverlay.selected then
                    if self.pauseoverlay.selected-1 < 1 then
                        self.pauseoverlay.selected = max
                    else
                        self.pauseoverlay.selected = self.pauseoverlay.selected-1
                    end
                end
            end
            self:PauseSelector()
        end
        if pd.buttonJustPressed(pd.kButtonRight) then
            local max = 0
            if self.pauseoverlay.type == 1 then
                if MipaInst then
                    max = #MipaInst.equipment
                end
            elseif self.pauseoverlay.type == 2 then
                if MipaInst then
                    max = #MipaInst.passiveitems
                end
            elseif self.pauseoverlay.type == 3 then
                max = #FoundNotes
            end
            if max > 0 then
                if self.pauseoverlay.selected then
                    if self.pauseoverlay.selected+1 > max then
                        self.pauseoverlay.selected = 1
                    else
                        self.pauseoverlay.selected = self.pauseoverlay.selected+1
                    end
                end
            end
            self:PauseSelector()
        end
        
        if self.pauseoverlay and self.pauseoverlay.selector then
            local _x, _y = self.pauseoverlay.selector:getPosition()
            local new_x = _x
            local new_y = _y
            if _x ~= self.pauseoverlay.reachX then
                new_x = Lerp(_x, self.pauseoverlay.reachX, 2)
            end
            if _y ~= self.pauseoverlay.reachY then
                new_y = Lerp(_y, self.pauseoverlay.reachY, 2)
            end
            if _x ~= new_x or _y ~= new_y then
                self.pauseoverlay.selector:moveTo(new_x, new_y)
            end
            if self.pauseoverlay.frameIndex ~= self.pauseoverlay.reachIndex then
                if self.pauseoverlay.frameIndex < self.pauseoverlay.reachIndex then
                    self.pauseoverlay.frameIndex = self.pauseoverlay.frameIndex+1
                else
                    self.pauseoverlay.frameIndex = self.pauseoverlay.frameIndex-1
                end
                self.pauseoverlay.selector:setImage(AssetsLoader.LoadImageTable("images/UI/pause/slotselectormoph"):getImage(self.pauseoverlay.frameIndex))
            end
        end
    end
    if self.startpixelfade then
        self.pixelfadeX = self.pixelfadeX+0.1
        self.pixelfadeY = self.pixelfadeY+0.1

        if self.pixelfadeX >= 3 or self.pixelfadeY >= 3 then
            self.pixelfadeX = 3
            self.pixelfadeY = 3
            self.startpixelfade = false
            self.startpixelfadeout = true
        end
        pd.display.setMosaic(self.pixelfadeX, self.pixelfadeY)
    elseif self.startpixelfadeout then
        self.pixelfadeX = self.pixelfadeX-0.1
        self.pixelfadeY = self.pixelfadeY-0.1

        if self.pixelfadeX <= 0 or self.pixelfadeY <= 0 then
            self.pixelfadeX = 0
            self.pixelfadeY = 0
            self.startpixelfadeout = false
        end
        pd.display.setMosaic(self.pixelfadeX, self.pixelfadeY)
    end
    if self.CanSkipThisDialog then
        if self.skipflash > 30 then
            self.skipflash = 0
            if self.dialogSkip:isVisible() then
                self.dialogSkip:setVisible(false)
            else
                self.dialogSkip:setVisible(true)
            end
        else
            self.skipflash = self.skipflash + 1
        end
    end
end

function UI:Death()
    if self.deathtriggered then
        return
    end
    self.deathtriggered = true
    
    local overlay = gfx.sprite.new()
    overlay:setIgnoresDrawOffset(true)
    overlay:setCenter(0, 0)
    overlay:add()
    overlay:setZIndex(Z_Index.AllAtop)
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

function UI:DialogPosUpdate()
    if self.currentdialogactor.arguments[1] ~= "0" then
        if self.currentdialogactor.name ~= "None" then
            if self.currentdialogactor.name == "Mipa" then
                self.dialogtextsprite:moveTo(91, self.dialogYroot)
                self.dialogactor:moveTo(7, self.dialogYroot-5)
            else
                self.dialogtextsprite:moveTo(7, self.dialogYroot)
                self.dialogactor:moveTo(323, self.dialogYroot-5)
            end
        else
            self.dialogtextsprite:moveTo(7, self.dialogYroot)
        end
    else
        self.dialogtextsprite:moveTo(7, self.dialogYroot)
    end
    self.dialogbg:moveTo(0, self.dialogYroot-5)
    self.dialogSkip:moveTo(343, self.dialogYroot+43)
    
end


function UI:SkipDialogLine()
    if self.currentdialogindex ~= 0 and #self.dialogdata > 0 and self.dialogbg ~= nil then
        local currentLineData = self.dialogdata[self.currdialoglineindex]
        local LineText = currentLineData.text
        if self.currentdialogindex == #LineText+1 then
            self.textwaittime = 2
        else
            self.currentdialogindex = #LineText+1
            self.currenttext = LineText
            self.textwaittime = #LineText*2
            self:ProcessDialog(true)
        end
    end
end

function UI:ProcessDialog(ignoreappend)
    if self.currentdialogindex ~= 0 and #self.dialogdata > 0 and self.dialogbg ~= nil and self.dialogdata.Key ~= "" then
        local ShowActor = true
        local ActorChanged = false
        local currentLineData = self.dialogdata[self.currdialoglineindex]
        if self.currentdialogactor.rawtext ~= currentLineData.actor then
            self.currentdialogactor.rawtext = currentLineData.actor
            self.currentdialogactor.arguments = {"1"}
            self.currentdialogactor.name = currentLineData.actor

            if string.find(self.currentdialogactor.rawtext, "_") then
                local ActorArguments = {}
                for l in string.gmatch(self.currentdialogactor.rawtext, '([^_]+)') do
                    table.insert(ActorArguments, l)
                end
                self.currentdialogactor.name = ActorArguments[1]
                table.remove(ActorArguments, 1)
                self.currentdialogactor.arguments = ActorArguments
            end
            ActorChanged = true
        end
        if self.currentdialogactor.name == "None" or self.currentdialogactor.arguments[1] == "0" then
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
            local ActorName = self.currentdialogactor.name
            local ActorExpression = tonumber(self.currentdialogactor.arguments[1])
            if ShowActor then
                if CheatsManager.MipaTrashMode then
                    if ActorName == "Mipa" or ActorName == "Wipa" then
                        ActorName = ActorName.."Trash"
                    end
                end

                local ActorTable = AssetsLoader.LoadImageTable("images/UI/DialogActors/"..ActorName)
                if ActorTable ~= nil then
                    self.dialogactor:setImage(ActorTable:getImage(ActorExpression))
                else
                    self.dialogactor:setImage(nil)
                end
            end
            print("[UI] Actor changed "..ActorName.." expression "..ActorExpression)
        end
        local LineText = currentLineData.text
        if (self.currentdialogindex ~= #LineText+1) or ignoreappend then
            if not ignoreappend then
                local character = string.sub(LineText, self.currentdialogindex, self.currentdialogindex)
                self.currenttext = self.currenttext..character
                self.currentdialogindex = self.currentdialogindex+1
                self.textwaittime = self.currentdialogindex*2
                --self.textwrapingindex = self.textwrapingindex+1
                --if self.textwrapingindex >= self.textwrapinglimit then
                --    self.textwrapingindex = 0
                --    self.currenttext = self.currenttext.."\n"
                --end
                if character ~= " " and character ~= "." then
                    if self.currentdialogactor.name == "None" then
                        SoundManager:PlaySound("Pap", 1, false)
                    elseif self.currentdialogactor.name == "Mipa" then
                        SoundManager:PlaySound("Peaw", 1, false)
                    elseif self.currentdialogactor.name == "Wipa" then
                        SoundManager:PlaySound("Sqeak", 1, false)
                    elseif self.currentdialogactor.name == "Jobee" then
                        SoundManager:PlaySound("Bzz", 1, false)
                    elseif self.currentdialogactor.name == "Wasp" then
                        SoundManager:PlaySound("BzzFast", 1, false)
                    elseif self.currentdialogactor.name == "Commander" then
                        SoundManager:PlaySound("Commander", 1, false)                        
                    else
                        SoundManager:PlaySound("Pap", 1, false)
                    end
                end
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
            if ActorChanged then
                self:DialogPosUpdate()
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
                    print("[UI] Dialog "..self.dialogdata.Key.." finished")
                    table.insert(SeenDialogs, self.dialogdata.Key)
                    self:CancleDialog()
                end
            end
        end
        local disiredYRoot = self.dialogYroot
        if (self:IsShowingPause() and self.pauseoverlay.type ~= 3) or dialogMode == "fixeddown" or self:IsCutscene() then
            disiredYRoot = 175
        else
            if (self:IsShowingPause() and self.pauseoverlay.type == 3) or dialogMode == "fixedup" then
                disiredYRoot = 2
            else
                if dialogMode == "dyn" then      
                    if MipaInst ~= nil then         
                        if MipaInst.x > 0 and MipaInst.x < 400 then -- if out of bounds, dont make any changes
                            if MipaInst.y > 170 then
                                disiredYRoot = 2
                            else
                                if MipaInst.y < 150 then
                                    disiredYRoot = 175
                                end
                            end                
                        end
                    else
                        disiredYRoot = 175
                    end
                end
            end
        end
        if disiredYRoot ~= self.dialogYroot then
            self.dialogYroot = disiredYRoot
            self:DialogPosUpdate()
        end
    end
end

function UI:LoadDialogUI()
    local BGimg = AssetsLoader.LoadImage("images/UI/dialog")
    local BG = gfx.sprite.new()
    BG:setIgnoresDrawOffset(true)
    BG:setImage(BGimg)
    BG:setCenter(0, 0)
    BG:moveTo(0, 170)
    BG:setZIndex(Z_Index.UI)
    local Actor = gfx.sprite.new()
    Actor:setIgnoresDrawOffset(true)
    Actor:setCenter(0, 0)
    Actor:moveTo(0, 170)
    Actor:setZIndex(Z_Index.UI)
    local DialogTextSprite = gfx.sprite.new()
    DialogTextSprite:setIgnoresDrawOffset(true)
    DialogTextSprite:setCenter(0, 0)
    DialogTextSprite:moveTo(91, 175)
    DialogTextSprite:setZIndex(Z_Index.UI)

    local DialogSkip = gfx.sprite.new()
    DialogSkip:setIgnoresDrawOffset(true)
    DialogSkip:setCenter(0, 0)
    DialogSkip:moveTo(343, 218)
    DialogSkip:setZIndex(Z_Index.UI)
    DialogSkip:setImage(AssetsLoader.LoadImage("images/UI/HoldToSkip", true))
    self.dialogSkip = DialogSkip
    self.dialogtextimage = gfx.image.new(388, 62)
    self.dialogbg = BG
    self.dialogactor = Actor
    self.dialogtextsprite = DialogTextSprite
    
    self:DialogPosUpdate()
end

function UI:CancleDialog(skipCommand)
    --print("[UI] CancleDialog")
    local lastkey = self.dialogdata.Key
    self.currentdialogindex = 0
    self.dialogdata = {}
    self.dialogtextimage = gfx.image.new(388, 62)
    self.dialogtextimage:clear(gfx.kColorClear)
    self.dialogbg:remove()
    self.dialogactor:remove()
    self.dialogtextsprite:remove()
    self.dialogSkip:remove()
    if not skipCommand then
        if self.ondialogfinish ~= nil and self.ondialogfinish ~= "" then
            TrackableManager.ProcessCommandLine(self.ondialogfinish)
            self.ondialogfinish = nil
        end
        if self.scenejsonTable ~= nil and self.scenejsonTable.linkeddialog ~= nil and self.scenejsonTable.linkeddialog ~= "" then
            if lastkey == self.scenejsonTable.linkeddialog then
                self:CutsceneFinished()
            end
        end
    end
end

function UI:StartDialog(data, onstart, onfinish)
    if DebugFlags.NoDialogs then
        return
    end
    self.dialogtextimage = gfx.image.new(388, 62)
    self.currentdialogindex = 1
    self.currdialoglineindex = 1
    local lastkey = ""
    if self.dialogdata then
        lastkey = self.dialogdata.Key
    end
    self.dialogdata = data
    self.currenttext = ""
    self.textwrapingindex = 0
    self.dialogbg:add()
    self.dialogactor:add()
    self.dialogtextsprite:add()
    self.dialogSkip:add()
    self.CanSkipThisDialog = self:CanSkipDialog(data.Key)
    self.dialogSkip:setVisible(self.CanSkipThisDialog)
    self.skipflash = 0
    if self.ondialogfinish ~= nil and self.ondialogfinish ~= "" then -- in case when we start new dialog when previous was still in process
        --if self.scenejsonTable ~= nil and self.scenejsonTable.linkeddialog ~= nil then
        --    if lastkey == self.scenejsonTable.linkeddialog  then
        --        self:CutsceneFinished()
        --    end
        --end
        TrackableManager.ProcessCommandLine(self.ondialogfinish)
    end
    self.ondialogfinish = onfinish
    if onstart ~= nil and onstart ~= "" then
        TrackableManager.ProcessCommandLine(onstart)
    end
    self:DialogPosUpdate()
    self:ProcessDialog()
end

function UI:DoGlitch()
    if self.glitchoverlay == nil then
        local glitchSP = gfx.sprite.new()
        glitchSP:setIgnoresDrawOffset(true)
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

function UI:CutsceneFinished(skipCommand)
    local dialogmode = false
    if self.scenejsonTable.linkeddialog ~= nil and self.scenejsonTable.linkeddialog ~= "" then
        dialogmode = true
    end
    local onFinish = self.scenejsonTable.onfinished
    self.currentsceneimage = 0
    if not skipCommand then
        if self.scenejsonTableMain.currentIndex == #self.scenejsonTableMain.sequences then
            self.scenejsonTable = nil
            self.scenejsonTableMain = nil
            gfx.sprite.removeSprite(self.sceneoverlay)
            print("[UI] Cutscene finished")
        else
            print("[UI] Cutscene Next Sequence")
            self:StartCutsceneSequence(self.scenejsonTableMain.currentIndex+1)
        end
    else
        self.scenejsonTable = nil
        self.scenejsonTableMain = nil
        gfx.sprite.removeSprite(self.sceneoverlay)
        print("[UI] Cutscene finished")
    end
    if not dialogmode then
        --print("[UI] None dialog mode OnFinish")
        if onFinish then
            TrackableManager.ProcessCommandLine(onFinish)
        end
    end
end

function UI:NextCutsceneFrame()
    if self.scenejsonTable == nil then
        return
    end
    self.currentsceneimage = self.currentsceneimage+1
    if self.currentsceneimage > self.sceneimages then
        if self.scenejsonTable.linkeddialog == nil or self.scenejsonTable.linkeddialog == "" then
            self:CutsceneFinished()
            return
        else
            self.currentsceneimage = 1
        end
    end
    local frame = self.scenejsonTable.frames[self.currentsceneimage]
    --print("[UI] Cutscene frame "..self.currentsceneimage.." image index "..frame.image.." duration "..frame.duration)
    self.sceneoverlay:setImage(self.sceneimagetable:getImage(frame.image))
    self.scenetimer = pd.frameTimer.new(frame.duration)
    self.scenetimer.repeats = false
    self.scenetimer.timerEndedCallback = function(timer)
        self:NextCutsceneFrame()
    end
    self.scenetimer:start()
end

function UI:IsCutscene()
    if self.currentsceneimage == nil or self.currentsceneimage == 0 then
        return false
    end
    return true
end

function UI:IsShowingPause()
    if self.pauseoverlay == nil then
        return false
    end
    return true
end

function UI:StartCutsceneSequence(index)
    self.scenejsonTableMain.currentIndex = index
    self.scenejsonTable = self.scenejsonTableMain.sequences[self.scenejsonTableMain.currentIndex]
    print("[UI] Creating cutscene sequences ", index)
    if self.sceneoverlay == nil then
        self.sceneoverlay = gfx.sprite.new()
        self.sceneoverlay:setIgnoresDrawOffset(true)
        self.sceneoverlay:setCenter(0, 0)
        self.sceneoverlay:moveTo(0, 0)
        self.sceneoverlay:setZIndex(Z_Index.UI)
        self.sceneoverlay:add()
    end
    self.currentsceneimage = 0
    self.sceneimages = #self.scenejsonTable.frames
    self.sceneimagetable = AssetsLoader.LoadImageTable("images/UI/cutscenes/"..self.scenejsonTable.sheet)

    if self.scenejsonTable.linkeddialog ~= nil and self.scenejsonTable.linkeddialog ~= "" then
        self:StartDialog(GetDialogDataFromString(self.scenejsonTable.linkeddialog), "", self.scenejsonTable.onfinished)
    end
    --self.CanSkipThisDialog = self:CanSkipDialog("")
    --self.dialogSkip:setVisible(self.CanSkipThisDialog)
    self:NextCutsceneFrame()
end

function UI:StartCutscene(name)
    print("[UI] Trying to load cutscene "..name)
    self.scenejsonTableMain = GetJSONData("images/UI/cutscenes/"..name..".json")
	if self.scenejsonTableMain == nil then
		print("[UI] Cutscene loading failed!")
        return
	end
    self:StartCutsceneSequence(1)
end

function UI:CanSkipDialog(dialogKey)
    if CurrentLevelName == "intro" then
        return true
    elseif self:IsCutscene() then
        return true
    end
    for i = 1, #SeenDialogs, 1 do
        if dialogKey == SeenDialogs[i] then
            return true
        end
    end
    return false
end


function UI:PauseSelector(force)
    if self.pauseoverlay then
        if self.pauseoverlay.selector then
            if self.pauseoverlay.type == 1 then
                self.pauseoverlay.reachX = 178 + 30*self.pauseoverlay.selected
                self.pauseoverlay.reachY = 30
                self.pauseoverlay.reachIndex = 1
            elseif self.pauseoverlay.type == 2 then
                self.pauseoverlay.reachX = 180 + 31*self.pauseoverlay.selected
                self.pauseoverlay.reachY = 61
                self.pauseoverlay.reachIndex = 3
            elseif self.pauseoverlay.type == 3 then
                self.pauseoverlay.reachIndex = 1
                if self.pauseoverlay.selected == 1 then
                    self.pauseoverlay.reachX = 221
                    self.pauseoverlay.reachY = 178
                end
                if self.pauseoverlay.selected == 2 then
                    self.pauseoverlay.reachX = 251
                    self.pauseoverlay.reachY = 188
                end
                if self.pauseoverlay.selected == 3 then
                    self.pauseoverlay.reachX = 281
                    self.pauseoverlay.reachY = 176
                end
            end
            if force then
                self.pauseoverlay.frameIndex = self.pauseoverlay.reachIndex
                self.pauseoverlay.selector:moveTo(self.pauseoverlay.reachX, self.pauseoverlay.reachY)
                self.pauseoverlay.selector:setImage(AssetsLoader.LoadImageTable("images/UI/pause/slotselectormoph"):getImage(self.pauseoverlay.frameIndex))
            end
        end
    end
end

function UI:HidePauseMenu()
    if self.pauseoverlay then
        gfx.sprite.removeSprite(self.pauseoverlay.selector)
        gfx.sprite.removeSprite(self.pauseoverlay)
        self.pauseoverlay.selector = nil
        self.pauseoverlay = nil
    end
end

function UI:ShowPauseMenu()
    self:CancleDialog()
    local img = GetPauseMenuImage(true)
    img:setInverted(true)
    self.pauseoverlay = gfx.sprite.new()
    self.pauseoverlay:setIgnoresDrawOffset(true)
    self.pauseoverlay:setCenter(0, 0)
    self.pauseoverlay:moveTo(0, 0)
    self.pauseoverlay:setZIndex(Z_Index.UI)
    self.pauseoverlay:add()
    self.pauseoverlay:setImage(img)
    self.pauseoverlay.selected = 1
    self.pauseoverlay.type = 1

    self.pauseoverlay.selector = gfx.sprite.new()
    self.pauseoverlay.selector:setImage(AssetsLoader.LoadImageTable("images/UI/pause/slotselectormoph"):getImage(1))
    self.pauseoverlay.selector:setIgnoresDrawOffset(true)
    self.pauseoverlay.selector:setCenter(0, 0)
    self.pauseoverlay.selector:moveTo(0, 0)
    self.pauseoverlay.selector:setZIndex(Z_Index.UI)
    self.pauseoverlay.selector:add()
    self.pauseoverlay.reachX = 0
    self.pauseoverlay.reachY = 0
    self.pauseoverlay.reachIndex = 1
    self.pauseoverlay.frameIndex = 1
    self:PauseSelector(true)
end

function UI:PixelFade()
    self.pixelfadeX = 0
    self.pixelfadeY = 0
    self.startpixelfade = true
    pd.display.setMosaic(self.pixelfadeX, self.pixelfadeY)
end

function UI:SkipIntro()
    self:CancleDialog(true)
    self:CutsceneFinished(true)
    UIIsnt = nil
    NextLevel = "menu"
    StartGame()
end

function UI:Currupt()
    local img = playdate.graphics.getDisplayImage()
    img = img:scaledImage(0.3, 0.3):scaledImage(1.2, 1.2)
    local test = gfx.sprite.new()
    test:setCenter(0, 0)
    test:moveTo(0, 0)
    test:setZIndex(Z_Index.AllAtop)
    test:add()
    test:setImage(img)
end

function UI:ShowSpecificGroup(group)
    local img = playdate.graphics.getDisplayImage()
    img = img:blurredImage(2, 1, gfx.image.kDitherTypeBayer8x8)
    local test = gfx.sprite.new()
    test:setCenter(0, 0)
    test:moveTo(0, 0)
    test:setZIndex(Z_Index.AllAtop)
    test:add()
    gfx.pushContext(img)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
        local imgs = ActiveManager:GetGroupImages("A")
        for i = 1, #imgs, 1 do
            local imgdata = imgs[i]
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(imgdata.rect.x, imgdata.rect.y, imgdata.rect.w, imgdata.rect.h)
            imgdata.image:draw(imgdata.x, imgdata.y)
        end
    gfx.popContext()
    test:setImage(img)
    print("Found activators ",#imgs)
end

function UI:Blurout()

end

function UI:IsConversation()
    if self.conversationTable == nil then
        return false
    end
    return true
end

function UI:SetConversationSelector(index)
    if self.selector_conv then
        self.selector_conv:moveTo(6, 152+index*19)
    end
end

function UI:SelectConversationOption(index)
    if self.converstationbg then
        self.converstationbg:setVisible(false)
    end
    if self.selector_conv then
        self.selector_conv:setVisible(false)
    end

    local dialog = self.conversationTable.options[index].dialog
    local action = self.conversationTable.options[index].action

    self:StartDialog(GetDialogDataFromString(dialog), "NoControl", "ReturnControl\n"..action)

    self.conversationTable = nil

end

function UI:LoadConversationUI()
    local drawingW = 368
    local darwingH = 62

    local WholeText = ""

    local BGimg = gfx.image.new("images/UI/dialog")

    if self.conversationTable ~= nil then
        for i = 1, #self.conversationTable.options, 1 do
            local opTxt = LocalizationManager.GetLine(self.conversationTable.options[i].text)
            if WholeText == "" then
                WholeText = opTxt
            else
                WholeText = WholeText.."\n"..opTxt
            end
        end
	end

    self.conversationTable.index = 1

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.pushContext(BGimg)
        gfx.drawTextInRect(WholeText, 27, 5, drawingW, darwingH, nil, "")
    gfx.popContext()

    if self.converstationbg == nil then
        local BG = gfx.sprite.new()
        BG:setIgnoresDrawOffset(true)
        BG:setImage(BGimg)
        BG:setCenter(0, 0)
        BG:moveTo(0, 170)
        BG:setZIndex(Z_Index.UI)
    
        self.converstationbg = BG
        self.converstationbg:add()
    else
        self.converstationbg:setImage(BGimg)

        self.converstationbg:setVisible(true)
    end

    if self.selector_conv == nil then
        self.selector_conv = gfx.sprite.new()
        self.selector_conv:setIgnoresDrawOffset(true)
        self.selector_conv.table = AssetsLoader.LoadImageTable("images/Ui/selector-tiny")
        self.selector_conv:setCenter(0, 0)
        self.selector_conv:moveTo(6, 171)
        self.selector_conv:setZIndex(Z_Index.AllAtop)
        self.selector_conv:setImage(self.selector_conv.table:getImage(1))
        self.selector_conv:add()

        self.selector_conv.animtimer = pd.frameTimer.new(7)
        self.selector_conv.animtimer.timerEndedCallback = function(timer)
            if self.selector_conv.index == 1 then
                self.selector_conv.index = 2
            else
                self.selector_conv.index = 1
            end
            self.selector_conv:setImage(self.selector_conv.table:getImage(self.selector_conv.index))
        end
        self.selector_conv.animtimer.repeats = true
        self.selector_conv.animtimer:start()
    else
        self.selector_conv:setVisible(true)
    end

    self.selector_conv.index = 1

    self:SetConversationSelector(1)
end

function UI:UpdateStaminaBar()

    local shouldDisplay = (MipaInst and MipaInst.JobeeCrank) or false

    if shouldDisplay then
        if self.staminabar == nil then
            local bar = gfx.sprite.new()
            bar:setIgnoresDrawOffset(true)
            bar:setImage(AssetsLoader.LoadImage("images/Ui/staminabar"))
            bar:setCenter(0, 0)
            bar:moveTo(34, 13)
            bar:setZIndex(Z_Index.UI)
            bar:add()
            self.staminabar = bar
        end
        if self.staminabarfill == nil then
            local fillbar = gfx.sprite.new()
            fillbar:setIgnoresDrawOffset(true)
            fillbar:setCenter(0, 0)
            fillbar:moveTo(36, 15)
            fillbar:setZIndex(Z_Index.UI)
            fillbar:add()
            self.staminabarfill = fillbar
        end
        if self.staminaword == nil then
            local word = gfx.sprite.new()
            word:setIgnoresDrawOffset(true)
            word:setImage(AssetsLoader.LoadImage("images/Ui/staminaword"))
            word:setCenter(0, 0)
            word:moveTo(34, 3)
            word:setZIndex(Z_Index.UI)
            word:add()
            self.staminaword = word
        end
    else
        if self.staminabar and self.staminabar:isVisible() then
            self.staminabar:setVisible(false)
        end
        if self.staminabarfill and self.staminabarfill:isVisible() then
            self.staminabarfill:setVisible(false)
        end
        if self.staminaword and self.staminaword:isVisible() then
            self.staminaword:setVisible(false)
        end
    end
    -- barfill Width 57 Height 5
    if shouldDisplay and MipaInst then
        
        local max = MipaInst.staminamax
        local current = MipaInst.stamina
        local fillamount = 57-math.ceil((current / max) * 57)
        local difference = 57-fillamount

        if self.laststamina ~= fillamount then
            self.laststamina = fillamount
            --print("[UI][UpdateStaminaBar] current "..current.." max "..max.." fillamount "..fillamount.." difference "..difference)
            local fillImage = gfx.image.new(57, 5)
            gfx.pushContext(fillImage)
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(difference, 0, fillamount, 5)
            gfx.popContext()
            self.staminabarfill:setImage(fillImage)
        end
    end
end


function UI:StartConversation(name, sequence)
    if sequence == nil then
        sequence = "start"
    end
    
    print("[UI] Trying to load conversation "..name)
    local JSONDATA = GetJSONData("conversations/"..name..".json")
	if JSONDATA == nil then
		print("[UI] Conversation loading failed!")
        return
	end

    for i = 1, #JSONDATA.sequences, 1 do
        local Data = JSONDATA.sequences[i]
        if Data.sequence == sequence then
            self.conversationTable = Data
            break
        end
    end

    if self.conversationTable == nil then
        print("[UI] Sequence "..sequence.." not found in conversation "..name)
        return
    end

    --for i = 1, #self.conversationTable.options, 1 do
    --    print("[UI] Sequence Option #"..i)
    --    print("text "..self.conversationTable.options[i].text)
    --    print("dialog "..self.conversationTable.options[i].dialog)
    --    print("action "..self.conversationTable.options[i].action)
    --end

    self:LoadConversationUI()
end