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
    self.imagetable = pd.graphics.imagetable.new("levels/tileset-table-14-14")

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
    self:addSprite()
    self:add() -- Add to draw list
end

function Level:draw(x, y, width, height)
	self.tilemap:draw(0, 0)
    print("[Level] Draw")
end

function Level:CreateTile(ID, X, Y, Solid)
    print("[Level] Creating Tile "..ID.." on X "..X.." Y "..Y)
    self.tilemap:setTileAtPosition(X, Y, ID)
end

function Level:ParceTileMap()
    print("[Level] Parcing tilemap...")
    for i=1, #self.jsonTable.tiles do
        local tile = self.jsonTable.tiles[i]
        self:CreateTile(tile.tileID, tile.x, tile.y, tile.solid)
    end
end

function Level:CreateProp(type, X, Y)
    if type == "box" then
        PhysicalProp(X, Y)
    end
end

function Level:ParceProps()
    print("[Level] Parcing props...")
    for i=1, #self.jsonTable.props do
        local prop = self.jsonTable.props[i]
        self:CreateProp(prop.propType, prop.x, prop.y)
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
    gfx.sprite.addWallSprites(tilemap,  _ , self.jsonTable.root_x, self.jsonTable.root_y) 
end