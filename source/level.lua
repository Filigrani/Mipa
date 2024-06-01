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
    SoundManager:StopSound("MipaGameOver")

    if self.jsonTable.music == nil then
        SoundManager:PlayMusic("BG1")
    else
        if self.jsonTable.music == "" then
            SoundManager:PauseMusic()
        else
            SoundManager:PlayMusic(self.jsonTable.music)
        end
    end
    
    self:ParceTileMap() 
    self:RenderTilemap()
    self:ParceProps()
    self:ParceZones()
    print("[Level] IsReplay? ", IsReplay)
    if IsReplay then
        if self.jsonTable.replaylevelcommand ~= nil then
            print("[Level] Executing level replay command...")
            TrackableManager.ProcessCommandLine(self.jsonTable.replaylevelcommand)
        end
    else
        if self.jsonTable.newlevelcommand ~= nil then
            print("[Level] Executing level new level command...")
            TrackableManager.ProcessCommandLine(self.jsonTable.newlevelcommand)
        end
    end
end

TILESNAMES = 
{
	STONE = 1,
    STONE_SLAB_TOP = 2,
	STONE_SLAB_BOTTOM = 3,
	SHATRED_STONE_SLAB_TOP = 4,
	SHATRED_STONE_SLAB_BOTTOM = 5,
	SHATRED_STONE = 6,
    FUNNY_BRINGE = 7,

    SPIKE = 302,

    ConveyorBeltsEdgeLeft_BOTTOM = 501,
    ConveyorBelts_BOTTOM = 502,
    ConveyorBeltsEdgeRight_BOTTOM = 503,

    ConveyorBeltsEdgeLeft_TOP = 504,
    ConveyorBelts_TOP = 505,
    ConveyorBeltsEdgeRight_TOP = 506,

    ConveyorBeltsEdgeLeftInversed_BOTTOM = 507,
    ConveyorBeltsInversed_BOTTOM = 508,
    ConveyorBeltsEdgeRightInversed_BOTTOM = 509,

    ConveyorBeltsEdgeLeftInversed_TOP = 510,
    ConveyorBeltsInversed_TOP = 511,
    ConveyorBeltsEdgeRightInversed_TOP = 512,
}

function Level:CreateTileCollider(x, y, w, h, image, colOffsetX, colOffsetY)
    local colider = gfx.sprite.new()
    if noupdate then
        colider:setUpdatesEnabled(false)
    end
    if image then
        colider:setImage(image)
    else
        colider:setVisible(false)
    end
    colider:setCenter(0, 0)
    colider:setBounds(x, y, 14, 14)
    colider:setCollideRect(colOffsetX, colOffsetY, w, h)
    colider:add()
    --colider:markDirty()
    return colider
end

function Level:CreateTile(ID, X, Y)
    local WorldX = self.jsonTable.root_x+14*(X-1)
    local WorldY = self.jsonTable.root_y+14*(Y-1)
    local DefaultRender = true
    -- Special tiles
    if ID == TILESNAMES.SPIKE then
        Spike(WorldX, WorldY)
    elseif ID == TILESNAMES.FUNNY_BRINGE then
        DefaultRender = false
        local br = FunnyBridge(WorldX, WorldY, self.imagetable:getImage(ID))
        local UID = X.."x"..Y
        TrackableManager.Add(br, UID)
        print("Funny bridge "..UID)
    elseif ID == TILESNAMES.STONE_SLAB_TOP 
    or ID == TILESNAMES.STONE_SLAB_BOTTOM
    or ID == TILESNAMES.SHATRED_STONE_SLAB_TOP 
    or ID == TILESNAMES.SHATRED_STONE_SLAB_BOTTOM 
    or ID == TILESNAMES.SHATRED_STONE_SLAB_BOTTOM 
    or ID == TILESNAMES.SHATRED_STONE
    or ID == TILESNAMES.ConveyorBeltsEdgeLeft_BOTTOM
    or ID == TILESNAMES.ConveyorBeltsEdgeLeftInversed_BOTTOM
    or ID == TILESNAMES.ConveyorBelts_BOTTOM
    or ID == TILESNAMES.ConveyorBeltsInversed_BOTTOM
    or ID == TILESNAMES.ConveyorBeltsEdgeRight_BOTTOM
    or ID == TILESNAMES.ConveyorBeltsEdgeRightInversed_BOTTOM
    or ID == TILESNAMES.ConveyorBeltsEdgeLeft_TOP
    or ID == TILESNAMES.ConveyorBeltsEdgeLeftInversed_TOP
    or ID == TILESNAMES.ConveyorBelts_TOP
    or ID == TILESNAMES.ConveyorBeltsInversed_TOP
    or ID == TILESNAMES.ConveyorBeltsEdgeRight_TOP
    or ID == TILESNAMES.ConveyorBeltsEdgeRightInversed_TOP
    or ID == TILESNAMES.FUNNY_BRINGE
    then
        DefaultRender = false
        local TileW = 14
        local TileH = 14
        local ColisionOffsetX = 0
        local ColisionOffsetY = 0
        if ID == TILESNAMES.STONE_SLAB_TOP 
        or ID == TILESNAMES.SHATRED_STONE_SLAB_TOP
        or ID == TILESNAMES.ConveyorBelts_TOP
        or ID == TILESNAMES.ConveyorBeltsInversed_TOP
        or ID == TILESNAMES.ConveyorBeltsEdgeLeft_TOP
        or ID == TILESNAMES.ConveyorBeltsEdgeLeftInversed_TOP
        or ID == TILESNAMES.ConveyorBeltsEdgeRight_TOP
        or ID == TILESNAMES.ConveyorBeltsEdgeRightInversed_TOP
        then
            TileH = 7
        end
    
        if ID == TILESNAMES.STONE_SLAB_BOTTOM 
        or ID == TILESNAMES.SHATRED_STONE_SLAB_BOTTOM
        or ID == TILESNAMES.ConveyorBelts_BOTTOM
        or ID == TILESNAMES.ConveyorBeltsInversed_BOTTOM
        or ID == TILESNAMES.ConveyorBeltsEdgeLeft_BOTTOM
        or ID == TILESNAMES.ConveyorBeltsEdgeLeftInversed_BOTTOM
        or ID == TILESNAMES.ConveyorBeltsEdgeRight_BOTTOM
        or ID == TILESNAMES.ConveyorBeltsEdgeRightInversed_BOTTOM
        then
            TileH = 7
            ColisionOffsetY = 7
        end
    
        local col = self:CreateTileCollider(WorldX, WorldY, TileW, TileH, self.imagetable:getImage(ID), ColisionOffsetX, ColisionOffsetY)

        if ID == TILESNAMES.SHATRED_STONE then
            col.IsBreakableTile = true
        end

        if ID == TILESNAMES.SHATRED_STONE_SLAB_TOP or ID == TILESNAMES.SHATRED_STONE_SLAB_BOTTOM then
            col.Breaks = true
        end

        if ID >= 501 and ID <= 512 then
            if ID >= 501 and ID <= 506 then
                col.DefaultSpriteID = ID
                col.ReversedSpriteID = ID+6
                col.Inversed = false
            else
                col.DefaultSpriteID = ID-6
                col.ReversedSpriteID = ID
                col.Inversed = true
            end
            col.IsConveyorBelts = true
            col.animationtimer = pd.frameTimer.new(2)
            col.animationtimer.repeats = true
            col.even = false
            col:setImage(self.imagetable:getImage(col.DefaultSpriteID))
            col.animationtimer.timerEndedCallback = function(timer)
                if col.even then
                    col.even = false
                    col:setImage(self.imagetable:getImage(col.DefaultSpriteID))
                else
                    col.even = true
                    col:setImage(self.imagetable:getImage(col.ReversedSpriteID))
                end
            end
            col.animationtimer:start()
        end
    end

    if DefaultRender then
        self.tilemap:setTileAtPosition(X, Y, ID)
    end
end

function Level:ParceTileMapOld()
    print("[Level] Parcing tilemap...")
    for i=1, #self.jsonTable.tiles do
        local tile = self.jsonTable.tiles[i]
        self:CreateTile(tile.tileID, tile.x, tile.y, tile.solid)
    end
end

function Level:ParceTileMap()
    print("[Level] Parcing tilemap...")
    local rawtiles = self.jsonTable.tiles
    local w = self.jsonTable.width_in_tile+1
    local h = self.jsonTable.height_in_tiles+1
    local tiles = {}
    for tile in string.gmatch(rawtiles, "%S+") do
        table.insert(tiles, tile)
    end
    local TileIndex = 1
    for x=1, w do
        for y=1, h do
            self:CreateTile(tonumber(tiles[TileIndex]), x, y)
            TileIndex = TileIndex+1
        end
    end
end

function Level:CreateProp(propData)
    local type = propData.propType
    if type == "box" then
        TrackableManager.Add(PhysicalProp(propData.x, propData.y), propData.UID)
    elseif type == "trash" then
        local trashbox = PhysicalProp(propData.x, propData.y)
        trashbox:setImage(AssetsLoader.LoadImage("images/Props/Trash"))
        trashbox.isTrash = true
    elseif type == "button" then
        local butt = Activator(propData.x, propData.y, propData.group, propData.timer, propData.indicatorUID)
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
    elseif type == "boxbutton" then
        local butt = Activator(propData.x, propData.y, propData.group)
        butt.IsButton = false
        local img = AssetsLoader.LoadImage("images/Props/boxbutton")
        butt:setImage(img)
        butt:setCollideRect(0,3,14,2)
        butt.CustomUpdate = function()
            local _, _, collisions, length = butt:checkCollisions(butt.x, butt.y)
            local supposedBeActive = false
            for i=1,length do
                local collision = collisions[i]
                local collisionType = collision.type
                local collisionObject = collision.other
                local collisionTag = collisionObject:getTag()
                if collisionType == gfx.sprite.kCollisionTypeOverlap then
                    if collisionTag == TAG.PropPushable or collisionTag == TAG.Player then
                        supposedBeActive = true
                        break
                    end
                end
            end
            butt.activated = supposedBeActive
            if butt.activated ~= butt.lastactive then
                if butt.activated then
                    img = AssetsLoader.LoadImage("images/Props/boxbuttonheld")
                else
                    img = AssetsLoader.LoadImage("images/Props/boxbutton")
                end
                butt.lastactive = butt.activated
                butt:setImage(img)
            end
        end
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
    elseif type == "clockindicator" then
        local indi = Dummy(propData.x, propData.y)
        indi.imagetable = AssetsLoader.LoadImageTable("images/Props/clock")
        indi:setImage(indi.imagetable:getImage(21))
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
        if propData.openPixels ~= nil then
            door.openpixels = propData.openPixels
        else
            door.openpixels = 3
        end
        if propData.closeSpeed ~= nil then
            door.closespeed = propData.closeSpeed
        else
            door.closespeed = 1
        end
        if not door.defaultactive then
            door.currentH = door.defaultH
        else
            door.currentH = door.openpixels
        end
        door.firstchange = true
        door.CustomUpdate = function()
            local targetH = 0  
            if door.defaultactive then
                if not door.activated then
                    targetH = door.openpixels
                else
                    targetH = door.defaultH
                end
            else
                if not door.activated then
                    targetH = door.defaultH
                else
                    targetH = door.openpixels
                end                
            end
            local changed = false
            if targetH > door.currentH then
                door.currentH = door.currentH+door.closespeed
                if door.currentH > targetH then
                    door.currentH = targetH
                end
                changed = true
            elseif targetH < door.currentH then
                door.currentH = door.currentH-door.closespeed
                if door.currentH < targetH then
                    door.currentH = targetH
                end
                changed = true
            end
            if changed or door.firstchange then
                if not door.firstchange then
                    SoundManager:PlaySound("Door")
                end
                door.firstchange = false

                if door.currentH > 0 then
                    door:setTag(0)
                    door:collisionsEnabled(true)
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
                        local _, _, collisions, length = door:checkCollisions(door.x, door.y+1)
                        --print("Check Door collision", length)
                        for i=1,length do
                            local collision = collisions[i]
                            local collisionType = collision.type
                            local collisionObject = collision.other
                            local collisionTag = collisionObject:getTag()
                            if collisionTag == TAG.Player then
                                collisionObject:FatalDamage()
                            end
                        end
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
                else
                    door:setImage(nil)
                    door:setCollideRect(0,0,0,0)
                    door:setTag(TAG.Effect)
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
        TrackableManager.Add(laser, propData.UID)
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
        local c = Blob(propData.x, propData.y)
        c.enemyname = "blob"
    elseif type == "wasp" then
        local c = Wasp(propData.x, propData.y)
        c.enemyname = "wasp"
        TrackableManager.Add(c, propData.UID)
        c:SetActorAct(propData.actoraction)
    elseif type == "boxdropper" then
        local dropper = Activatable(propData.x, propData.y, propData.group, false, propData.activeType)
        local img = AssetsLoader.LoadImage("images/Props/boxdropper")
        dropper:setImage(img)
        dropper.DropBox = function ()
            AnimEffect(dropper.x+5, dropper.y+12, "Effects/BigCloud", 1, true, false)
            AnimEffect(dropper.x+3, dropper.y+13, "Effects/BigCloud", 1, true, false)
            AnimEffect(dropper.x+1, dropper.y+11, "Effects/BigCloud", 1, true, false)
            
            local BoxUID = propData.UID.."box"
            --[[
            local oldbox = TrackableManager.GetByUID(propData.UID.."box")
            if oldbox then
                for i = 1, 10, 1 do
                    local speadX = 8
                    local spreadY = -1*i
                    local effectX = math.floor(math.random(-speadX,speadX)+0.5)
                    local animSpeed = math.floor(math.random(1,3)+0.5)
                    AnimEffect(oldbox.x+effectX, oldbox.y+spreadY, "Effects/BigCloud", animSpeed, true, false)
                end
            end
            TrackableManager.RemoveByUID(BoxUID)
            local box =  PhysicalProp(propData.x+7, propData.y+7)
            TrackableManager.Add(box, propData.UID.."box")
            --]]
            local box = TrackableManager.GetByUID(propData.UID.."box")
            if box == nil then
                box =  PhysicalProp(propData.x+7, propData.y+7)
                TrackableManager.Add(box, propData.UID.."box")
                box.Dropper = dropper
            end
            if box then
                box.velocityX = 0
                box.velocityY = 0
                for i = 1, 10, 1 do
                    local speadX = 8
                    local spreadY = -1*i
                    local effectX = math.floor(math.random(-speadX,speadX)+0.5)
                    local animSpeed = math.floor(math.random(1,3)+0.5)
                    AnimEffect(box.x+effectX, box.y+spreadY, "Effects/BigCloud", animSpeed, true, false)
                end
                box:moveTo(propData.x+7, propData.y+7)
                if box.childs then
                    for i = 1, #box.childs, 1 do
                        local child = box.childs[i]
                        if child then
                            if child.Remove then
                                child:Remove()
                            end
                            gfx.sprite.removeSprite(child)
                        end
                    end
                end
            end
        end
        if propData.active == 1 then
            dropper.DropBox()
            print("DropBox propData.active")
        end
        dropper.CustomUpdate = function()
            if dropper.lastactive ~= dropper.activated then
                if dropper.activated then
                    dropper.DropBox()
                    print("DropBox CustomUpdate")
                end
            end
        end
        TrackableManager.Add(dropper, propData.UID)
    end
end

function Level:CreateZone(zoneData)
    local type = zoneData.zoneType
    if type == "spawn" then
        --print("---SPAWNER--")
        --print("Going to place Mipa to follwoing coordinates:")
        --print("spawn x ", zoneData.x)
        --print("spawn y ", zoneData.y)
        --print("----------")
        --local spawnVisual = Dummy(zoneData.x, zoneData.y, 14, 14)
        --spawnVisual:setCenter(0.5, 0.5) -- My Dummy class by default has center on 0, 0 (upper left corner)
        --spawnVisual:moveTo(zoneData.x, zoneData.y) -- Moving once again, just to make sure, after overriing of the center.
        --spawnVisual:setImage(AssetsLoader.LoadImageTable("images/mipa"):getImage(1))
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
        local StrKey = ""
        if type == "note" then
            t:setImage(AssetsLoader.LoadImage("images/Props/Note"))
            StrKey = "Note"..zoneData.noteID
        else 
            StrKey = zoneData.text
        end
        t.dialogdata = GetDialogDataFromString(StrKey)
        t.ondialogstart = zoneData.dialogstart
        t.ondialogfinish = zoneData.dialogfinish
        t.OnTrigger = function ()
            if type == "note" then
                InvertedColorsFrames = 2
                SoundManager:FadeMusicForWhile(240)
                SoundManager:PlaySound("Note")
                AddFoundNote(zoneData.noteID)
            end
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
    elseif type == "navright" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t.navtype = "right"
        t.triggeronce = false
    elseif type == "navleft" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t.navtype = "left"
        t.triggeronce = false
    elseif type == "invizcolider" then
        local t = Dummy(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t:setCollideRect(0,0,zoneData.w, zoneData.h)
    elseif type == "exit" then
        local t = Trigger(zoneData.x, zoneData.y, zoneData.w, zoneData.h)
        t.nextlevel = zoneData.nextLevel
        t.OnTrigger = function ()
            NextLevel = t.nextlevel
            LoadNextLevel = true
            print("Going outbounds will load "..NextLevel)
        end
        TrackableManager.Add(t, zoneData.UID)
    elseif type == "koasoda" then
        local w = 14
        local h = 14
        local t = Trigger(zoneData.x, zoneData.y, w, h)
        if type == "koasoda" then
            t:setImage(AssetsLoader.LoadImage("images/Props/KoaSoda"))
        end
        t.OnTrigger = function ()
            if type == "koasoda" then
                if zoneData.cutscene == nil then
                    InvertedColorsFrames = 2
                    SoundManager:PlaySound("Warning")
                else
                    UIIsnt:StartCutscene(zoneData.cutscene)
                end
                MipaInst:AddPassiveItem(PASSIVEITEMS.KoaKola)
            end
        end
    elseif type == "trashspawner" then
        local Spawner = Dummy(zoneData.x, zoneData.y)
        if self.shootbombtimer == nil then
            Spawner.spawntimer = pd.frameTimer.new(zoneData.spawnperioud)
            Spawner.spawntimer.repeats = true
            Spawner.spawntimer.timerEndedCallback = function(timer)
                local CanSpawn = true
                local collider = gfx.sprite.addEmptyCollisionSprite(zoneData.x, zoneData.y,15,12)
                collider:setTag(TAG.Effect)
                local collisions = collider:overlappingSprites(zoneData.x, zoneData.y)
                gfx.sprite.removeSprite(collider)
                for i=1,#collisions do
                    local collisionObject = collisions[i]
                    local collisionTag = collisionObject:getTag()
                    if collisionObject.IsMipa then
                        CanSpawn = false
                        break
                    end
                end

                if CanSpawn then
                    if not Spawner.pendingBigTrash and not Spawner.pendingBigTrashKoaKola then
                        local trashbox = PhysicalProp(zoneData.x, zoneData.y)
                        trashbox:setImage(AssetsLoader.LoadImage("images/Props/Trash"))
                        trashbox.isTrash = true
                    elseif Spawner.pendingBigTrash then
                        local BigTrash = PhysicalProp(zoneData.x, zoneData.y)
                        BigTrash:setImage(AssetsLoader.LoadImage("images/Props/TrashBig"))
                        BigTrash:setCollideRect(0,0,15,14)
                        Spawner.pendingBigTrash = false
                    elseif Spawner.pendingBigTrashKoaKola then
                        local BigTrashKoaKola = PhysicalProp(zoneData.x, zoneData.y)
                        BigTrashKoaKola:setImage(AssetsLoader.LoadImage("images/Props/TrashBigKoaKola"))
                        BigTrashKoaKola:setCollideRect(0,0,15,14)
                        BigTrashKoaKola.isTrash = true
                        BigTrashKoaKola.isKoaKola = true
                        Spawner.pendingBigTrashKoaKola = false
                    end
                end
            end
            Spawner.spawntimer:start()
            TrackableManager.Add(Spawner, zoneData.UID)
        end
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
    
    gfx.sprite.addWallSprites(tilemap,  {
        TILESNAMES.STONE_SLAB_TOP,
        TILESNAMES.STONE_SLAB_BOTTOM,
        TILESNAMES.SHATRED_STONE_SLAB_TOP,
        TILESNAMES.SHATRED_STONE_SLAB_BOTTOM,
        TILESNAMES.SHATRED_STONE,
        TILESNAMES.SPIKE,
        TILESNAMES.ConveyorBelts_TOP,
        TILESNAMES.ConveyorBeltsInversed_TOP,
        TILESNAMES.ConveyorBeltsEdgeLeft_TOP,
        TILESNAMES.ConveyorBeltsEdgeLeftInversed_TOP,
        TILESNAMES.ConveyorBeltsEdgeRight_TOP,
        TILESNAMES.ConveyorBeltsEdgeRightInversed_TOP,
        TILESNAMES.ConveyorBelts_BOTTOM,
        TILESNAMES.ConveyorBeltsInversed_BOTTOM,
        TILESNAMES.ConveyorBeltsEdgeLeft_BOTTOM,
        TILESNAMES.ConveyorBeltsEdgeLeftInversed_BOTTOM,
        TILESNAMES.ConveyorBeltsEdgeRight_BOTTOM,
        TILESNAMES.ConveyorBeltsEdgeRightInversed_BOTTOM
    } , self.jsonTable.root_x, self.jsonTable.root_y)
end