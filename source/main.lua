import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frametimer"

import "utils"
-- classes
import "mipa"
import "jsonloader"
import "level"
import "physicalprop"
import "ui"

local pd <const> = playdate;
local gfx <const> = pd.graphics
local Inverted = false
local UIIsnt = nil

local function loadGame()
	pd.display.setInverted(true)
	Mipa(151, 134)
	Level("levels/level_template.json")
	UIIsnt = UI()
	--UIIsnt:Death()
end

local function updateGame()
    gfx.sprite.update()
	pd.frameTimer.updateTimers()
	pd.timer.updateTimers()
end

local function drawGame()

end

loadGame()

function pd.update()
	updateGame()
	drawGame()
	--pd.drawFPS(385,0) -- FPS widget
end