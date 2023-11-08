local pd <const> = playdate
local gfx <const> = pd.graphics
import "jsonloader"
waterfallimagetable = nil
class('Level').extends(playdate.graphics.sprite)

function Level:init(levelPath)
    print("[Level] Trying to load "..levelPath)
    self.jsonTable = GetJSONData(levelPath)
	if self.jsonTable == nil then
		print("[Level] Loading failed!")
        return
	end
    print("[Level] Creating tilemap...")
    self.imagetable = AssetsLoader.LoadImageTable("images/tileset")

    if self.imagetable == nil then
        print("[Level] Imagetable is null")
        return
    end
    self.tilemap = pd.graphics.tilemap.new()
    self.tilemap:setImageTable(self.imagetable)
    self.tilemap:setSize(self.jsonTable.width_in_tile, self.jsonTable.height_in_tiles)  
    self:ParceTileMap() 
    self:RenderTilemap()
    self:ParceProps()
    self:ParceZones()
end

function Level:CreateTile(ID, X, Y, Solid)
    if ID ~= 4 then
        self.tilemap:setTileAtPosition(X, Y, ID)
    end
    
    local WorldX = self.jsonTable.root_x+14*(X-1)
    local WorldY = self.jsonTable.root_y+14*(Y-1)
    if ID == 2 then
        local SlapColider = gfx.sprite.new()
        local TileW = 14
        local TileH = 7
        SlapColider:setUpdatesEnabled(false) 
        SlapColider:setVisible(false)
        SlapColider:setCenter(0, 0)
        SlapColider:setBounds(WorldX, WorldY, TileW, TileH)
        SlapColider:setCollideRect(0, 0, TileW, TileH)
        SlapColider:addSprite()
    end
    if ID == 4 then
        local SlapColider = gfx.sprite.new()
        local TileW = 14
        local TileH = 7
        SlapColider:setCenter(0, 0)
        SlapColider:setImage(self.imagetable:getImage(4))
        SlapColider:setBounds(WorldX, WorldY, TileW, TileH)
        SlapColider:setCollideRect(0, 0, TileW, TileH)
        SlapColider:add()
        SlapColider.Breaks = true
    end
    --[[
    if ID == 302 then
        local Colider = gfx.sprite.new()
        local TileW = 14
        local TileH = 14
        Colider:setUpdatesEnabled(false) 
        Colider:setVisible(false)
        Colider:setCenter(0, 0)
        Colider:setBounds(WorldX, WorldY, TileW, TileH)
        Colider:setCollideRect(0, 0, TileW, TileH)
        Colider:addSprite()
    end    
    --]]
    if ID == 302 then
        Spike(WorldX, WorldY)
    end
end

function Level:ParceTileMap()
    print("[Level] Parcing tilemap...")
    for i=1, #self.jsonTable.tiles do
        local tile = self.jsonTable.tiles[i]
        self:CreateTile(tile.tileID, tile.x, tile.y, tile.solid)
    end
end

function Level:CreateProp(propData)
    local type = propData.propType
    if type == "box" then
        TrackableManager.Add(PhysicalProp(propData.x, propData.y), propData.UID)
    elseif type == "button" then
        local butt = Activator(propData.x, propData.y, propData.group)
        local img = AssetsLoader.LoadImage("images/Props/Button0")
        butt:setImage(img)
        butt.CustomUpdate = function()
            if butt.activated ~= butt.lastactive then
                if butt.activated then
                    img = AssetsLoader.LoadImage("images/Props/Button1")
                else
                    img = AssetsLoader.LoadImage("images/Props/Button0")
                end
                butt.lastactive = butt.activated
                butt:setImage(img)
            end
        end
        butt:setCollideRect(4,5,6,5)
        TrackableManager.Add(butt, propData.UID)
    elseif type == "indicator" then
        local indi = Activatable(propData.x, propData.y, propData.group, propData.active, propData.activeType)
        local img = AssetsLoader.LoadImage("images/Props/Indicator0")
        indi:setImage(img)
        indi.CustomUpdate = function()
            if indi.activated ~= indi.lastactive then
                if indi.activated then
                    img = AssetsLoader.LoadImage("images/Props/Indicator1")
                else
                    img = AssetsLoader.LoadImage("images/Props/Indicator0")
                end
                indi:setImage(img)
            end
        end
        TrackableManager.Add(indi, propData.UID)
    elseif type == "door" then
        local doorx = propData.x
        local doory = propData.y
        local vetical = true
        if propData.a ~= nil and ( propData.a == 90 or propData.a == 269 ) then
            vetical = false
            if propData.a == 90 then
                doorx = doorx-propData.h
            elseif propData.a == 269 then
                --doorx = doorx+propData.h
            end
        end
        local door = Activatable(doorx, doory, propData.group, propData.active, propData.activeType)
        door.defaultH = propData.h
        if not door.defaultactive then
            door.currentH = door.defaultH
        else
            door.currentH = 3
        end  
        door.firstchange = true
        door.CustomUpdate = function()
            local targetH = 0  
            if door.defaultactive then
                if not door.activated then
                    targetH = 3
                else
                    targetH = door.defaultH
                end
            else
                if not door.activated then
                    targetH = door.defaultH
                else
                    targetH = 3
                end                
            end
            local changed = false
            if targetH > door.currentH then
                door.currentH = door.currentH+1
                changed = true
            elseif targetH < door.currentH then
                door.currentH = door.currentH-1
                changed = true
            end
            if changed or door.firstchange then
                if not door.firstchange then
                    SoundManager:PlaySound("Door")
                end
                door.firstchange = false
                
                if vetical then
                    door:setCollideRect(0,0,4,door.currentH)
                    local img = gfx.image.new(4, door.currentH)
                    local Skip = false
                    gfx.pushContext(img)
                        gfx.setColor(gfx.kColorBlack)
                        for i = 0, door.currentH-1, 1 do
                            if not Skip then
                                gfx.drawLine(0, i, 4, i)
                                Skip =  true
                            else
                                Skip = false
                            end
                        end
                    gfx.popContext()
                    door:setImage(img)
                else -- Horizontal
                    local left = true
                    local img = gfx.image.new(door.currentH, 4)
                    local Skip = false                    
                    if propData.a == 269 then -- if angle 270, then it opens to right.
                        left = false
                    end
                    if not left then
                        door:setCollideRect(0,0,door.currentH,4)
                        gfx.pushContext(img)
                            gfx.setColor(gfx.kColorBlack)
                            for i = 0, door.currentH-1, 1 do
                                if not Skip then
                                    gfx.drawLine(i, 0, i, 4)
                                    Skip =  true
                                else
                                    Skip = false
                                end
                            end
                        gfx.popContext()
                        door:setImage(img)
                    else
                        door:setCollideRect(door.defaultH-door.currentH,0,door.currentH,4)
                        gfx.pushContext(img)
                            gfx.setColor(gfx.kColorBlack)
                            for i = door.defaultH, door.currentH-1, -1 do
                                if not Skip then
                                    gfx.drawLine(i, 0, i, 4)
                                    Skip =  true
                                else
                                    Skip = false
                                end
                            end
                        gfx.popContext()     
                        door:setImage(img)                                            
                    end 
                end
            end
        end
        TrackableManager.Add(door, propData.UID)
    elseif type == "laser" then
        local laser = Activatable(propData.x, propData.y, propData.group, propData.active, propData.activeType)
        laser.fx = AnimEffect(propData.x, propData.y, "Effects/reflect", 1, false, true)
        laser.raycaster = RayCastTrigger(propData.x, propData.y, propData.w)
        laser.raycaster.parent = laser
        laser.eventick = false
        laser.w = propData.w
        laser.lastcoliderw = laser.w
        laser.fx:moveTo(laser.lastcoliderw-14+propData.x, propData.y-8)
        laser:setCollideRect(0,0,laser.w,2)
        laser.CustomUpdate = function()
            local _x, _y = laser:getPosition()
            local RayCastChanged = false
            if laser.raycaster ~= nil then
                if laser.raycaster.lasthitdistance ~= laser.lastcoliderw then
                    laser.lastcoliderw = laser.raycaster.lasthitdistance
                    RayCastChanged = true
                end
            end
            
            if RayCastChanged then
                if laser.lastcoliderw < 0 then
                    laser:setCollideRect(0,0,1,2)
                else
                    laser:setCollideRect(0,0,laser.lastcoliderw,2)
                end
                if laser.fx ~= nil then
                    laser.fx:moveTo(laser.lastcoliderw-14+_x, _y-8)
                end
            end
            if laser.lastcoliderw <= 4 or laser.activated then
                if laser.fx:isVisible() then
                    laser.fx:setVisible(false)
                end
            elseif not laser.fx:isVisible() and not laser.activated then
                laser.fx:setVisible(true)
            end
            if laser.activated then
                if laser:isVisible() then
                    laser:setVisible(false)
                end
            else
                if not laser:isVisible() then
                    laser:setVisible(true)
                end
            end
            if not laser.activated and laser.lastcoliderw > 0 then
                laser:setTag(TAG.HazardNoColide)
                local img = gfx.image.new(laser.lastcoliderw, 2)
                if not laser.eventick then
                    gfx.pushContext(img)
                        gfx.setColor(gfx.kColorBlack)
                        gfx.drawLine(0, 0, laser.lastcoliderw, 0)
                        gfx.drawLine(0, 1, laser.lastcoliderw, 1)
                    gfx.popContext()
                    laser.eventick = true
                else
                    gfx.pushContext(img)
                        gfx.setColor(gfx.kColorBlack)
                        local skip = false
                        for i = 0, laser.lastcoliderw, 1 do
                            if not skip then
                                gfx.drawPixel(i, 0)
                                skip = true
                            else
                                skip = false
                            end
                        end
                        skip = true
                        for i = 0, laser.lastcoliderw, 1 do
                            if not skip then
                                gfx.drawPixel(i, 1)
                                skip = true
                            else
                                skip = false
                            end
                        end                  
                    gfx.popContext()
                    laser.eventick = false       
                end
                laser:setImage(img) 
            elseif laser.activated then
                laser:setTag(TAG.Effect)  
            end
        end
        TrackableManager.Add(door, propData.UID)
    elseif type == "logic" then
        Activatable(nil, nil, propData.group, 0, propData.activeType, propData.command)
    elseif type == "poky" then
        local pokey = gfx.sprite.new()
        pokey:setCenter(0, 0)
        pokey:moveTo(propData.x, propData.y)
        pokey:setZIndex(Z_Index.Object)
        pokey:setImage(AssetsLoader.LoadImage("images/Props/Poky"))
        pokey:add()
    elseif type == "jobee" then
        local jobee = gfx.sprite.new()
        jobee:setCenter(0, 0)
        jobee:moveTo(propData.x, propData.y)
        jobee:setZIndex(Z_Index.Object)
        jobee:setImage(AssetsLoader.LoadImage("images/Props/Jobee"))
        jobee:add()
    elseif type == "waterfall" then
        local waterfall = gfx.sprite.new()
        if waterfallimagetable == nil then
            waterfallimagetable = AssetsLoader.LoadImageTable("images/props/waterfall")
        end
        waterfall:setCenter(0, 0)
        waterfall:moveTo(propData.x, propData.y)
        waterfall:setZIndex(Z_Index.TotalBumer)
        waterfall:setImage(waterfallimagetable:getImage(1))
        waterfall:add()
        waterfall.curindex = 1
        waterfall.animationtimer = pd.frameTimer.new(4)
        waterfall.animationtimer.repeats = true       
        waterfall.animationtimer.timerEndedCallback = function(timer)
            if waterfall.curindex == 4 then
                waterfall.curindex = 1
            else
                waterfall.curindex = waterfall.curindex+1
            end
            waterfall:setImage(waterfallimagetable:getImage(waterfall.curindex))
        end
        waterfall.animationtimer:start()
    elseif type == "blob" then
        local c = Creature(propData.x, propData.y)
        c.enemyname = "blob"
    end
end

function Level:CreateZone(zoneData)
    local type = zoneData.zoneType
    if type == "spawn" then
        if self.foundmipas == 0 then
            MipaInst = Mipa(zoneData.x, zoneData.y)
            self.foundmipas = self.foundmipas+1
        else
            local clone = Mipa(zoneData.x, zoneData.y)
            clone.IsClone = true
            clone.hp = 1
            self.foundmipas = self.foundmipas+1
        end
    elseif type == "dialog" or type == "note" then
        local w = 14
        local h = 14
        if type == "dialog" then
            w = zoneData.w
            h = zoneData.h
        end
        local t = Trigger(zoneData.x, zoneData.y, w, h)
        if type == "note" then
            t:setImage(AssetsLoader.LoadImage("images/Props/Note"))
        end
        t.dialogdata = GetDialogDataFromString(zoneData.text)
        t.ondialogstart = zoneData.dialogstart
        t.ondialogfinish = zoneData.dialogfinish
        t.OnTrigger = function ()
            UIIsnt:StartDialog(t.dialogdata, t.ondialogstart, t.ondialogfinish)
        end
        TrackableManager.Add(t, zoneData.UID)
    elseif type == "trigger" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t.ontriggercommand = zoneData.ontrigger
        t.OnTrigger = function ()
            TrackableManager.ProcessCommandLine(t.ontriggercommand)
        end
        TrackableManager.Add(t, zoneData.UID)
    elseif type == "exit" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t.nextlevel = zoneData.nextLevel
        t.OnTrigger = function ()
            NextLevel = t.nextlevel
            LoadNextLevel = true
            print("Going outbounds will load "..NextLevel)
        end
        TrackableManager.Add(t, zoneData.UID)
    end
end

function Level:ParceProps()
    print("[Level] Parcing props...")
    if self.jsonTable.props == nil then
        return
    end
    for i=1, #self.jsonTable.props do
        self:CreateProp(self.jsonTable.props[i])
    end
end
function Level:ParceZones()
    self.foundmipas = 0
    print("[Level] Parcing zones...")
    if self.jsonTable.zones == nil then
        return
    end
    for i=1, #self.jsonTable.zones do
        self:CreateZone(self.jsonTable.zones[i])
    end
end

function Level:RenderTilemap()
    local tilemap = self.tilemap

    local layerSprite = gfx.sprite.new()
    layerSprite:setTilemap(tilemap)
    layerSprite:moveTo(self.jsonTable.root_x, self.jsonTable.root_y)
    layerSprite:setCenter(0, 0)
    layerSprite:setZIndex(Z_Index.BG)
    layerSprite:add()
    gfx.sprite.addWallSprites(tilemap,  {2,4,302,501,602,603} , self.jsonTable.root_x, self.jsonTable.root_y)
end