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
import "clashbomb"
local pd <const> = playdate;
local gfx <const> = pd.graphics
DEFAULT_FONT = nil
gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
UIIsnt = nil
MenuInst = nil
MipaInst = nil
CreditsInst = nil
CurrentLevel = nil
CurrentLevelName = "menu"
NextLevel = "menu"
LoadNextLevel = false
CanStartAgain = false
NewDeathScreen = true
InvertedColorsFrames = 0
LevelsLimit = 13
DialogboxMode = SaveManager.Load("dialogboxmode") or "dyn"
local font = gfx.font.new('font/Asheville Ayu')
ShouldUpdatePauseMenu = false
SeenDialogs = {}
FoundNotes = {}

AddFoundNote = function (noteID)
	for i = 1, #FoundNotes, 1 do
		if FoundNotes[i] == noteID then
			return
		end
	end
	table.insert(FoundNotes, noteID)
	table.sort(FoundNotes)
end

local function OpenItemsMenu()
	if UIIsnt then
		UIIsnt:ShowPauseMenu()
	end
end

local function AddSystemMenuButtons()
	local menu = pd.getSystemMenu()
	menu:removeAllMenuItems()

	if CurrentLevelName ~= "menu" then
		local menuItem, error = menu:addMenuItem("main menu", function()
			NextLevel = "menu"
			StartGame()
		end)
		if CurrentLevelName ~= "credits" then
			local menuItem, error = menu:addMenuItem("Restart level", function()
				StartGame()
			end)
			local menuItem, error = menu:addMenuItem("items", function()
				OpenItemsMenu()
			end)
		end
	end
end

debugsin = false
crankSinusVal = 1
gameTicks = 0

UpdateSinusMiniGame = function ()
	if not debugsin then
		return
	end
	if referenceSinus == nil then
		referenceSinus = gfx.sprite.new()
		referenceSinus:setCenter(0, 0)
		referenceSinus:setZIndex(Z_Index.AllAtop)
		referenceSinus:moveTo(0, 60)
		referenceSinus:add()
	end
	if crankSinus == nil then
		crankSinus = gfx.sprite.new()
		crankSinus:setCenter(0, 0)
		crankSinus:setZIndex(Z_Index.AllAtop)
		crankSinus:moveTo(0, 60)
		crankSinus:add()
	end
	local refimg = gfx.image.new(400, 120)
	gfx.pushContext(refimg)
	    gfx.drawSineWave(0, 60, 400, 60, 30, 30, 56, gameTicks)
    gfx.popContext()
    refimg = refimg:fadedImage(0.5, gfx.image.kDitherTypeDiagonalLine)
	referenceSinus:setImage(refimg)

	local img = gfx.image.new(400, 120)
	gfx.pushContext(img)
	    gfx.drawSineWave(0, 60, 400, 60, 30, 30, CrankManager.Abosulte+1, gameTicks)
    gfx.popContext()
	crankSinus:setImage(img)
end


DrawCrankSinus = function (change)
	crankSinusVal = crankSinusVal+change
end

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
	if NextLevel == "sintest" or debugsin then
		return
	end
	if NextLevel == "menu" then
		pd.setMenuImage(nil, 0)
		MenuInst = Menu()
		CurrentLevelName = "menu"
		AddSystemMenuButtons()
		return
	end
	if NextLevel == "credits" then
		UIIsnt = UI()
		local creditsDialog = GetDialogDataFromString("#None\nWell, you wanted to see a credits?\nSadly, you have to fight me first!")
		UIIsnt:StartDialog(creditsDialog, nil,"Glitch 20")
		UIIsnt.oneglitchover = function ()
			CreditsInst = Credits()
		end
		CurrentLevelName = "credits"
		AddSystemMenuButtons()
		return
	end
	--local clone = Mipa(165, 134)
	if clone then
		clone.IsClone = true
		clone.hp = 1
	end
	if CurrentLevelName ~= NextLevel then
		SeenDialogs = {}
	end
	CurrentLevelName = NextLevel
	CurrentLevel = Level("levels/"..CurrentLevelName..".json")
	UIIsnt = UI()
	--CrankDisk(100, 200, {CrankManager.NewPlatform(0,0,0)})
	AddSystemMenuButtons()
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

GetPauseMenuImage = function (extended)
	local img = gfx.image.new(400, 240)
	gfx.pushContext(img)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		if extended then
			AssetsLoader.LoadImage("images/UI/pause/bg_extended"):draw(0,0)
		else
			AssetsLoader.LoadImage("images/UI/pause/bg"):draw(0,0)
		end
		if MipaInst then
			for i = 1, #MipaInst.equipment, 1 do
				local overlay = AssetsLoader.LoadImage("images/UI/pause/a"..MipaInst.equipment[i])
				if overlay then
					overlay:draw(0,0)
				end
			end
			for i = 1, #MipaInst.passiveitems, 1 do
				local overlay = AssetsLoader.LoadImage("images/UI/pause/p"..MipaInst.passiveitems[i])
				if overlay then
					overlay:draw(0,0)
				end
			end
		end

		if extended then
			for i = 1, #MipaInst.equipment, 1 do
				local slot = AssetsLoader.LoadImage("images/UI/pause/slota")
				local item = AssetsLoader.LoadImage("images/UI/equip"..MipaInst.equipment[i])
				local x = 178 + 30*i
				local y = 30
				if slot then
					slot:draw(x,y)
				end
				if item then
					item:draw(x,y)
				end
			end
			for i = 1, #MipaInst.passiveitems, 1 do
				local slot = AssetsLoader.LoadImage("images/UI/pause/slotp")
				local item = AssetsLoader.LoadImage("images/UI/passive"..MipaInst.passiveitems[i])
				local x = 180 + 31*i
				local y = 61
				if slot then
					slot:draw(x,y)
				end
				if item then
					item:draw(x,y)
				end
			end
			for i = 1, #FoundNotes, 1 do
				local noteID = FoundNotes[i]
				local item = AssetsLoader.LoadImage("images/UI/pause/Note"..noteID)
				if i == 1 then
					item:draw(221,178)
				elseif i == 2 then
					item:draw(251,188)
				elseif i == 3 then
					item:draw(281,176)
				end
			end
		end
	gfx.popContext()
	return img
end

local function UpdatePauseMenu()
	if MipaInst == nil then
		pd.setMenuImage(nil, 0)
		return
	end
	if ShouldUpdatePauseMenu then
		ShouldUpdatePauseMenu = false
		pd.setMenuImage(GetPauseMenuImage(false), 0)
		print("[Main] PauseMenu Updated")
	end
end

function pd.gameWillPause()
	print("[PlayDate] gameWillPause")
	if UIIsnt then
		UIIsnt:HidePauseMenu()
	end
end

function pd.gameWillResume()
	print("[PlayDate] gameWillResume")
	UpdatePauseMenu()
end

local function loadGame()
	CheatsManager.RegisterCheats()
	LocalizationManager.Load()
	gfx.setFont(font)
	pd.display.setInverted(true)
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

loadGame()

local lastTime = playdate.getCurrentTimeMilliseconds()

function pd.update()
	local currentTime = playdate.getCurrentTimeMilliseconds()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime
	gameTicks = gameTicks+1
	updateGame()
	if DebugFlags.FPSCounter then
		pd.drawFPS(385,0) -- FPS widget
	end
	UpdatePauseMenu()
	UpdateSinusMiniGame()
end