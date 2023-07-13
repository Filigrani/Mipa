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
import "activator"
import "activatable"
import "trigger"

local pd <const> = playdate;
local gfx <const> = pd.graphics
gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
UIIsnt = nil
MipaInst = nil
CurrentLevel = nil
CanStartAgain = false

StartGame = function ()
	gfx.sprite.removeAll()
	ActiveManager.Reset()
	--MipaInst = Mipa(151, 134)
	--local clone = Mipa(165, 134)
	if clone then
		clone.IsClone = true
		clone.hp = 1
	end
	CurrentLevel = Level("levels/lvl0.json")
	UIIsnt = UI()
	--CrankDisk(100, 200, {CrankManager.NewPlatform(0,0,0)})
end

DeathTrigger = function ()
	CanStartAgain = true
	local again = gfx.sprite.new()
	again:setCenter(0, 0)
	again:setImage(gfx.image.new("images/UI/again0"))
	again:add()
	again:setZIndex(Z_Index.BG)
	again.fadealpha = 1
	again.anim = pd.frameTimer.new(7)
	again.frame = 0
	again.anim.timerEndedCallback = function(timer)  
		if again.frame == 0 then
			again.frame = 1
		else
			again.frame = 0
		end
		again:setImage(gfx.image.new("images/UI/again"..again.frame))
	end
	again.anim.repeats = true
	again.anim:start()

	local overlay = gfx.sprite.new()
	overlay:setCenter(0, 0)
	overlay:setImage(gfx.image.new("images/UI/death_16"))
	overlay:add()
	overlay:setZIndex(Z_Index.BG)
	overlay.fadealpha = 1
	overlay.fader = pd.frameTimer.new(3)
	overlay.fader.timerEndedCallback = function(timer)  
		local Ditherimg = gfx.image.new("images/UI/death_16")
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
	pd.display.setInverted(true)
	gfx.setFont(gfx.font.new('font/Mini Sans 2X'))
	StartGame()
end

local function updateGame()
    ActiveManager.Update()
	gfx.sprite.update()
	pd.frameTimer.updateTimers()
	pd.timer.updateTimers()
	UIIsnt:Update()
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