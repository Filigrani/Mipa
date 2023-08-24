local pd <const> = playdate
local gfx <const> = pd.graphics
deathimagetable = gfx.imagetable.new("images/ui/death")
class('UI').extends(playdate.graphics.sprite)

function UI:init()
    UI.super.init(self)
    self.heartsimagetable = gfx.imagetable.new("images/ui/hp")
    self:add() -- Add to draw list
    self.hearts = {}
    self.equipment = {}
    self.lasthearts = 0
    self.lastcontainers = 0
    self.lastequipment = 0
    self.deathtriggered = false
    self.dialogdata = {}
    self.currentdialogindex = 0
    self.currenttext = ""
    self.currdialoglineindex = 1
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

function UI:PopulateEquipment(equipment)
    local ExistenEQ = #self.equipment
    if #equipment > ExistenEQ then
        local needToAdd = #equipment-ExistenEQ
        print("[UI] Adding "..needToAdd.." equipment(s)")
        for i=1, needToAdd do
            self:AddEquipment(1)
        end
    elseif #equipment < ExistenEQ then
        local needToRemove = ExistenEQ-#equipment
        print("[UI] Removing "..needToRemove.." equipment(s)")
        for i=1, needToRemove do
            self:RemoveEquipment()
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

function UI:UpdateEquipment(equipment, selectedIndex)
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
end

function UI:Update()
    local hearts = 0;
    local containers = 0
    local equipment = {}
    local selectedequipment = 1
    if MipaInst then
        containers = MipaInst.hpmax/2
        equipment = MipaInst.equipment
        selectedequipment = MipaInst.selectedequipment
        if MipaInst.hp > 0 then
            hearts = MipaInst.hp/2
        end
    end

    if self.lastcontainers ~= containers then
        self:PopulateHearts(containers)
    end

    if #self.equipment ~= #equipment then
        self:PopulateEquipment(equipment)
        self:UpdateEquipment(equipment, selectedequipment)
    end

    if self.lasthearts ~= hearts then
        self:UpdateHP(hearts, containers)
        self.lasthearts = hearts
    end
    self:ProcessDialog()
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

function UI:AddEquipment(style)
    local eq = gfx.sprite.new()
    local img = gfx.image.new("images/UI/equip_slot")
    eq:setImage(img)
    eq:setCenter(0, 0)
    eq:moveTo(371-30*#self.equipment, 2)
    eq:add()
    eq.style = ""
    self.equipment[#self.equipment+1] = eq
    eq.icon = gfx.sprite.new()
    eq.icon.style = 0
    local imgSlice = gfx.image.new("images/UI/equip0")
    eq.icon:setImage(imgSlice)
    eq.icon:setCenter(0, 0)
    eq.icon:moveTo(eq.x, eq.y)
    eq.icon:add()
end

function UI:RemoveEquipment()
    local lastindex = #self.equipment
    if lastindex > 0 then
        local eq = self.equipment[lastindex]
        if eq then
            table.remove(self.equipment, lastindex)
            gfx.sprite.removeSprite(eq.icon)
            gfx.sprite.removeSprite(eq)
        end
    end
end

function UI:ProcessDialog()
    if self.currentdialogindex ~= 0 and #self.dialogdata > 0 then
        if not self.dialogbg:isVisible() then
            self.dialogbg:setVisible(true)
        end
        if not self.dialogactor:isVisible() then
            self.dialogactor:setVisible(true)
        end
        if not self.dialogtextsprite:isVisible() then
            self.dialogtextsprite:setVisible(true)
        end
        local LineText = self.dialogdata[self.currdialoglineindex].text
        if self.currenttext ~= LineText then
            local character = string.sub(LineText, self.currentdialogindex, self.currentdialogindex)
            local charID = 4
            local charX = (self.currentdialogindex-1)*8
            local charY = 0
            gfx.pushContext(self.dialogtextimage)
            local CharImg = self.heartsimagetable:getImage(charID)
            CharImg:draw(charX, charY)
            gfx.popContext()
            self.currenttext = self.currenttext..character
            self.currentdialogindex = self.currentdialogindex+1
            print("character "..character)
        end
        self.dialogtextsprite:setImage(self.dialogtextimage)
    else
        if self.dialogbg:isVisible() then
            self.dialogbg:setVisible(false)
        end
        if self.dialogactor:isVisible() then
            self.dialogactor:setVisible(false)
        end
        if self.dialogtextsprite:isVisible() then
            self.dialogtextsprite:setVisible(false)
        end
    end
end

function UI:LoadDialogUI()
    local BGimg = gfx.image.new("images/UI/dialog")
    local BG = gfx.sprite.new()
    BG:setImage(BGimg)
    BG:setCenter(0, 0)
    BG:moveTo(39, 180)
    BG:setZIndex(Z_Index.BG)
    BG:add() -- Add to draw list
    BG:setVisible(false)
    local Actorimg = gfx.image.new("images/UI/DialogMipa")
    local Actor = gfx.sprite.new()
    Actor:setImage(Actorimg)
    Actor:setCenter(0, 0)
    Actor:moveTo(39, 180)
    Actor:setZIndex(Z_Index.BG)
    Actor:add() -- Add to draw list
    Actor:setVisible(false)
    local DialogTextSprite = gfx.sprite.new()
    DialogTextSprite:setCenter(0, 0)
    DialogTextSprite:moveTo(120, 185)
    DialogTextSprite:setZIndex(Z_Index.BG)
    DialogTextSprite:add() -- Add to draw list
    DialogTextSprite:setVisible(false)
    self.dialogtextimage = gfx.image.new(200, 48)
    self.dialogbg = BG
    self.dialogactor = Actor
    self.dialogtextsprite = DialogTextSprite
end

function UI:StartDialog(data)
    self.dialogtextimage = gfx.image.new(200, 48)
    self.currentdialogindex = 1
    self.currdialoglineindex = 1
    self.dialogdata = data
    self.currenttext = ""
end