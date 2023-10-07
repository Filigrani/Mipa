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
import "soundmanager"
import "crankmanager"
import "crankdisk"
import "bullet"
import "activemanager"
import "trackablemanager"
import "activator"
import "activatable"
import "trigger"
import "spike"

local pd <const> = playdate;
local gfx <const> = pd.graphics
DEFAULT_FONT = nil
gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
UIIsnt = nil
MipaInst = nil
CurrentLevel = nil
NextLevel = "lvl1"
LoadNextLevel = false
CanStartAgain = false
local font = gfx.font.new('font/FiliFont')

StartGame = function ()
	gfx.sprite.removeAll()
	ActiveManager.Reset()
	TrackableManager.Reset()
	--local clone = Mipa(165, 134)
	if clone then
		clone.IsClone = true
		clone.hp = 1
	end
	CurrentLevel = Level("levels/"..NextLevel..".json")
	UIIsnt = UI()
	--CrankDisk(100, 200, {CrankManager.NewPlatform(0,0,0)})
end

DeathTrigger = function ()
	CanStartAgain = true
	local again = gfx.sprite.new()
	again:setCenter(0, 0)
	again:setImage(deathimagetable:getImage(18))
	again:add()
	again:setZIndex(Z_Index.BG)
	again.fadealpha = 1
	again.anim = pd.frameTimer.new(7)
	again.frame = 18
	again.anim.timerEndedCallback = function(timer)  
		if again.frame == 19 then
			again.frame = 18
		else
			again.frame = 19
		end
		again:setImage(deathimagetable:getImage(again.frame))
	end
	again.anim.repeats = true
	again.anim:start()

	local overlay = gfx.sprite.new()
	overlay:setCenter(0, 0)
	overlay:setImage(deathimagetable:getImage(17))
	overlay:add()
	overlay:setZIndex(Z_Index.BG)
	overlay.fadealpha = 1
	overlay.fader = pd.frameTimer.new(3)
	overlay.fader.timerEndedCallback = function(timer)  
		local Ditherimg = deathimagetable:getImage(17)
		if overlay.fadealpha <= 0 then
			overlay.fadealpha = 0  
			gfx.sprite.removeSprite(overlay)
			return
		else
			overlay.fadealpha = overlay.fadealpha-0.1
		end
		Ditherimg = Ditherimg:fadedImage(overlay.fadealpha, gfx.image.kDitherTypeBayer8x8)
		overlay:setImage(Ditherimg)
	end
	overlay.fader.repeats = true
	overlay.fader:start()
end
local function loadGame()
	gfx.setFont(font)
	pd.display.setInverted(true)
	local menu = pd.getSystemMenu()
	local menuItem, error = menu:addMenuItem("Restart level", function()
		StartGame()
	end)
	StartGame()
end

local function updateGame()
    ActiveManager.Update()
	gfx.sprite.update()
	pd.frameTimer.updateTimers()
	pd.timer.updateTimers()
	if UIIsnt ~= nil then
		UIIsnt:Update()
	end
	if CanStartAgain then
		if pd.buttonJustPressed(pd.kButtonA) then
			CanStartAgain = false
			StartGame()
        end
	end
	local change = playdate.getCrankChange()
	if change ~= 0 then
		CrankManager.Changed(change)
	end
end

local function drawGame()

end

loadGame()

function pd.update()
	updateGame()
	drawGame()
	--pd.drawFPS(385,0) -- FPS widget
end