import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frametimer"
import "savemanager"
import "localizationmanager"
import "assetsloader"
import "utils"
-- classes
import "dummy"
import "mipa"
import "jsonloader"
import "level"
import "physicalprop"
import "ui"
import "menu"
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
import "animeffect"
import "raycasttrigger"
import "creature"
import "cheatsmanager"
import "credits"
local pd <const> = playdate;
local gfx <const> = pd.graphics
DEFAULT_FONT = nil
gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
UIIsnt = nil
MenuInst = nil
MipaInst = nil
CreditsInst = nil
CurrentLevel = nil
NextLevel = "menu"
LoadNextLevel = false
CanStartAgain = false
NewDeathScreen = true
InvertedColorsFrames = 0
LevelsLimit = 9
DialogboxMode = SaveManager.Load("dialogboxmode") or "dyn"
local font = gfx.font.new('font/Asheville Ayu')

StartGame = function ()
	InvertedColorsFrames = 0
	gfx.sprite.removeAll()
	local timers = playdate.frameTimer.allTimers()
	for i = 1, #timers, 1 do
		timers[i]:remove()
	end
	timers = playdate.timer.allTimers()
	for i = 1, #timers, 1 do
		timers[i]:remove()
	end	

	ActiveManager.Reset()
	TrackableManager.Reset()
	MenuInst = nil
	CreditsInst = nil
	if NextLevel == "menu" then
		MenuInst = Menu()
		return
	end
	if NextLevel == "credits" then
		UIIsnt = UI()
		local creditsDialog = GetDialogDataFromString("#None\nWell, you wanted to see a credits?\nSadly, you have to fight me first!")
		UIIsnt:StartDialog(creditsDialog, nil,"Glitch 20")
		UIIsnt.oneglitchover = function ()
			CreditsInst = Credits()
		end
		return
	end
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
	again:setZIndex(Z_Index.AllAtop)
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
	if not NewDeathScreen then
		local overlay = gfx.sprite.new()
		overlay:setCenter(0, 0)
		overlay:setImage(deathimagetable:getImage(17))
		overlay:add()
		overlay:setZIndex(Z_Index.AllAtop)
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
	else
		UIIsnt.glitchframes = 2
		local fadetimer = pd.frameTimer.new(2)
		fadetimer.timerEndedCallback = function(timer)
			UIIsnt.glitchframes = 0
		end
		fadetimer:start()
    end
end
local function loadGame()
	CheatsManager.RegisterCheats()
	LocalizationManager.Load()
	gfx.setFont(font)
	pd.display.setInverted(true)
	local menu = pd.getSystemMenu()
	local menuItem, error = menu:addMenuItem("Restart level", function()
		StartGame()
	end)
	local menuItem, error = menu:addMenuItem("main menu", function()
		NextLevel = "menu"
		StartGame()
	end)
	StartGame()
end

local function updateGame()
	if InvertedColorsFrames > 0 then
		InvertedColorsFrames = InvertedColorsFrames-1
		if pd.display.getInverted() then
			pd.display.setInverted(false)
		end
	elseif not pd.display.getInverted() then
		pd.display.setInverted(true)
	end

	CheatsManager.HandleInputs()
	
	ActiveManager.Update()
	gfx.sprite.update()
	pd.frameTimer.updateTimers()
	pd.timer.updateTimers()
	if UIIsnt ~= nil then
		UIIsnt:Update()
	end
	if MenuInst ~= nil then
		MenuInst:Update()
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
	if CreditsInst ~= nil then
		CreditsInst:Update()
	end
end

local function drawGame()

end

loadGame()

function pd.update()
	updateGame()
	drawGame()
	if DebugFlags.FPSCounter then
		pd.drawFPS(385,0) -- FPS widget
	end
end