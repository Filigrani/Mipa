local pd <const> = playdate
local gfx <const> = pd.graphics
import "jsonloader"

class('Level').extends(playdate.graphics.sprite)

function Level:init(levelPath)
    print("[Level] Trying to load "..levelPath)
    self.jsonTable = GetJSONData(levelPath)
	if self.jsonTable == nil then
		print("[Level] Loading failed!")
        return
	end
    print("[Level] Creating tilemap...")
    self.imagetable = pd.graphics.imagetable.new("images/tileset")

    if self.imagetable == nil then
        print("[Level] Imagetable is null")
        return
    end
    self.tilemap = pd.graphics.tilemap.new()
    self.tilemap:setImageTable(self.imagetable)
    self.tilemap:setSize(self.jsonTable.width_in_tile, self.jsonTable.height_in_tiles)  
    self:ParceLogic()
    self:ParceTileMap() 
    self:RenderTilemap()
    self:ParceProps()
    self:ParceZones()
end

function Level:CreateTile(ID, X, Y, Solid)
    self.tilemap:setTileAtPosition(X, Y, ID)
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
        local img = gfx.image.new("images/Props/Button0")
        butt:setImage(img)
        butt.CustomUpdate = function()
            if butt.activated ~= butt.lastactive then
                if butt.activated then
                    img = gfx.image.new("images/Props/Button1")
                else
                    img = gfx.image.new("images/Props/Button0")
                end
                butt.lastactive = butt.activated
                butt:setImage(img)
            end
        end
        butt:setCollideRect(4,5,6,5)
        TrackableManager.Add(butt, propData.UID)
    elseif type == "indicator" then
        local indi = Activatable(propData.x, propData.y, propData.group, propData.active, propData.activeType)
        local img = gfx.image.new("images/Props/Indicator0")
        indi:setImage(img)
        indi.CustomUpdate = function()
            if indi.activated ~= indi.lastactive then
                if indi.activated then
                    img = gfx.image.new("images/Props/Indicator1")
                else
                    img = gfx.image.new("images/Props/Indicator0")
                end
                indi:setImage(img)
            end
        end
        TrackableManager.Add(indi, propData.UID)
    elseif type == "door" then
        local door = Activatable(propData.x, propData.y, propData.group, propData.active, propData.activeType)
        
        door.defaultH = propData.h
        door.currentH = door.defaultH
        door.firstchange = true
        door.CustomUpdate = function()
            local targetH = door.defaultH
            if door.activated then
                targetH = 3
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
            end
        end
        TrackableManager.Add(door, propData.UID)
    elseif type == "logic" then
        local indi = Activatable(nil, nil, propData.group, 0, propData.activeType, propData.command)
    end
end

function Level:CreateZone(zoneData)
    local type = zoneData.zoneType
    if type == "spawn" then
        MipaInst = Mipa(zoneData.x, zoneData.y)
    elseif type == "dialog" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        local rawText = zoneData.text
        local rawLines = {}
        if string.find(rawText, "\n") then
            for l in string.gmatch(rawText, '([^\n]+)') do
                table.insert(rawLines, l)
            end
        else
            table.insert(rawLines, rawText)
        end
        local DialogData = {}
        local Prefix = "#"
        local LastActor = "Mipa"
        for i = 1, #rawLines, 1 do
            local rawLine = rawLines[i]
            if string.sub(rawLine,1,string.len(Prefix)) == Prefix then
                LastActor = rawLine
            else
                local lineData = {}
                lineData.actor = LastActor:sub(2)
                lineData.text = rawLine
                table.insert(DialogData, lineData)
            end
        end
        t.dialogdata = DialogData
        t.ondialogstart = zoneData.dialogstart
        t.ondialogfinish = zoneData.dialogfinish
        t.OnTrigger = function ()
            UIIsnt:StartDialog(t.dialogdata, t.ondialogstart, t.ondialogfinish)
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

function Level:RegisterLogic(LogicData)
    TrackableManager.RegisterLogicBlock(LogicData.UID, LogicData.code)
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
    print("[Level] Parcing zones...")
    if self.jsonTable.zones == nil then
        return
    end
    for i=1, #self.jsonTable.zones do
        self:CreateZone(self.jsonTable.zones[i])
    end
end
function Level:ParceLogic()
    print("[Level] Parcing logic...")
    if self.jsonTable.logic == nil then
        return
    end
    for i=1, #self.jsonTable.logic do
        self:RegisterLogic(self.jsonTable.logic[i])
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
    gfx.sprite.addWallSprites(tilemap,  {2,302,501,602,603} , self.jsonTable.root_x, self.jsonTable.root_y)
end