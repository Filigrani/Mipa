import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frametimer"
import "CoreLibs/ui"
import "CoreLibs/qrcode"
import "CoreLibs/math"
import "settings"
import "savemanager"
Settings = SaveManager.Load("settings") or DefaultSettings
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
import "blob"
import "wasp"
import "jobee"
import "funnybridge"
import "drop"
import "dropper"

local pd <const> = playdate;
local gfx <const> = pd.graphics
DEFAULT_FONT = nil
--DebugLevelToLoad = "lvl3"
BACKGROUND_TEST = false

gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
UIIsnt = nil
MenuInst = nil
MipaInst = nil
CreditsInst = nil
CurrentLevel = nil
CurrentLevelName = "intro"
NextLevel = "intro"
LoadNextLevel = false
CanStartAgain = false
NewDeathScreen = true
InvertedColorsFrames = 0
IsReplay = false
LevelsLimit = 22
local font = gfx.font.new('font/Asheville Ayu')

displayWidth, displayHeight = playdate.display.getSize()
halfDisplayWidth = displayWidth / 2

ShouldUpdatePauseMenu = false
SeenDialogs = {}
FoundNotes = SaveManager.Load("notes") or {}
UnlockedLevels = SaveManager.Load("unlockedlevels") or {}
DrawCrankFrames = 0
CrankedThisFrame = false
CameraX = 0
CameraY = 0
CameraXMaxScroll = 0
CameraXMinScroll = 0
CameraYMaxScroll = 0
CameraYMinScroll = 0

LeftEdge = 0
RightEdge = 400

CanScroll = false

LastDeltaTime = 0

--CurrentLevelName = "menu"
--NextLevel = "lvl-1"

--CurrentLevelName = "lvl14c"
--NextLevel = "lvl14c"

if DebugLevelToLoad and DebugLevelToLoad ~= "" then
	CurrentLevelName = DebugLevelToLoad
    NextLevel = DebugLevelToLoad
end

ScrollingMode = 1

ScrollingSmoothRate = 4

StoryLineLevels = {}

AddStoryLineLevel = function (FileName, PrefixName, NeedUnlock)
	if NeedUnlock == nil then
		NeedUnlock = true
	end
	table.insert(StoryLineLevels, {name = FileName, prefix = PrefixName, requiresunlock = NeedUnlock})
end

AddStoryLineChapter = function (ChapterName)
	table.insert(StoryLineLevels, {name = ChapterName, chapter = true})
end

RegisterStoryLine = function ()
	AddStoryLineChapter("Outside")

	AddStoryLineLevel("lvl-1", "", false)

	AddStoryLineChapter("Cave")

	AddStoryLineLevel("lvl0", "0")
	AddStoryLineLevel("lvl1", "1")
	AddStoryLineLevel("lvl2", "2")
	AddStoryLineLevel("lvl3", "3")
	AddStoryLineLevel("lvl4", "4")
	AddStoryLineLevel("lvl5", "5")
	AddStoryLineLevel("lvl6", "6")
	AddStoryLineLevel("lvl7", "7")
	AddStoryLineLevel("lvl8", "8")
	AddStoryLineLevel("lvl9", "9")

	AddStoryLineChapter("Soil")

	AddStoryLineLevel("lvl10", "10")
	AddStoryLineLevel("lvl11", "11")
	AddStoryLineLevel("lvl12", "12")
	AddStoryLineLevel("lvl13", "13")
	AddStoryLineLevel("lvl14", "14")
	AddStoryLineLevel("lvl15", "15")
	AddStoryLineLevel("lvl16", "16")

	AddStoryLineChapter("Hive")

	AddStoryLineLevel("lvl17", "17")
	AddStoryLineLevel("lvl18", "18")
	AddStoryLineLevel("lvl19", "19")
	AddStoryLineLevel("lvl20", "20")
	AddStoryLineLevel("lvl21", "21")
	AddStoryLineLevel("lvl22", "22")

	AddStoryLineChapter("Dripstone Cave")

	--AddStoryLineLevel("JobeeFly", "23")

	--AddStoryLineChapter("Sand Drifts")

	--AddStoryLineLevel("Sinksand", "23b")
end

RegisterStoryLine()

Lerp = function (current, goal, frametoreachgoal, epsilon)
	if epsilon == nil then
		epsilon = 1
	end
	local delta = 0
	local result = goal
	if current < goal then
		delta = (goal-current)/frametoreachgoal
		result = current+delta+epsilon
		if result > goal then
			return goal
		else
			return result
		end
	elseif current > goal then
		delta = (current-goal)/frametoreachgoal
		result = current-delta-epsilon
		if result < goal then
			return goal
		else
			return result
		end
	end
end

InterpolateScrolling = function (current, goal)
	local result = goal
	if current < goal then
		result = current+ScrollingSmoothRate
		if result > goal then
			return goal
		else
			return result
		end
	elseif current > goal then
		result = current-ScrollingSmoothRate
		if result < goal then
			return goal
		else
			return result
		end
	end
end

UpdateCameraPosition = function (MipaX, MipaY, force)
	local newX = math.floor(math.max(math.min(MipaX - halfDisplayWidth + 60, CameraXMaxScroll), CameraXMinScroll))
	local newY = math.floor(math.max(math.min(MipaY - halfDisplayWidth + 60, CameraYMaxScroll), CameraYMinScroll))
	if (newX ~= -CameraX or newY ~= -CameraY) or force then
		if not force then
			if newX ~= -CameraX and ((newX ~= 0 and CameraX ~= 0) or (newX ~= 0 and CameraX == 0) or (newX == 0 and CameraX ~= 0)) then
				local interpolatedX = InterpolateScrolling(CameraX, -newX)
				newX = -interpolatedX
			end
			if newY ~= -CameraY and ((newY ~= 0 and CameraY ~= 0) or (newY ~= 0 and CameraY == 0)or (newY == 0 and CameraY ~= 0))  then
				local interpolatedY = InterpolateScrolling(CameraY, -newY)
				newY = -interpolatedY
			end
		end
		if ScrollingMode == 1 then
			CameraX = -newX
			CameraY = -newY
			gfx.setDrawOffset(CameraX, CameraY)
			gfx.sprite.addDirtyRect(newX, newY, displayWidth, displayHeight)
		elseif ScrollingMode == 2 then
			local d = newX + CameraX
			CameraX = -newX
			gfx.setDrawOffset(CameraX,0)
			gfx.getDisplayImage():draw(newX,0)
	
			if d > 0 then
				playdate.graphics.sprite.addDirtyRect(newX + displayWidth - d, 0, d, displayHeight)
			else
				playdate.graphics.sprite.addDirtyRect(newX, 0, -d, displayHeight)
			end
		end
		--print("[UpdateCameraPosition] Scroll X "..newX.." bounds: "..LeftEdge.." "..RightEdge)
		--print("[UpdateCameraPosition] Scroll Y "..newY)
	end
end

AddFoundNote = function (noteID)
	for i = 1, #FoundNotes, 1 do
		if FoundNotes[i] == noteID then
			return
		end
	end
	table.insert(FoundNotes, noteID)
	table.sort(FoundNotes)
	SaveManager.Save("notes", FoundNotes)
end

AddUnlockedLevel = function (levelName)
	if not LevelIsUnlocked(levelName) then
		table.insert(UnlockedLevels, levelName)
		SaveManager.Save("unlockedlevels", UnlockedLevels)
	end
end

LevelIsUnlocked = function (levelName)
	for i = 1, #UnlockedLevels, 1 do
		if UnlockedLevels[i] == levelName then
			return true
		end
	end
	return false
end

local function OpenItemsMenu()
	if UIIsnt then
		UIIsnt:ShowPauseMenu()
	end
end

function LevelList(dir)
	SoundManager:PlayMusic("Xband")
	if MenuInst then
		local addonsOptions = {}
		local LevelNames = ""
		local SelectorOffset = 20
		if playdate.file.isdir(dir) then
			print("Scanning Levels Folder")

			local IsStoryLine = dir == "levels"

			if not IsStoryLine then
				local files = playdate.file.listFiles(dir)
				for i = 1, #files, 1 do
					local levelName, IsListed = GetLevelDisplayData(dir.."/"..files[i], files[i])
	
					if IsListed then
						if LevelNames == "" then
							LevelNames = levelName
						else
							LevelNames = LevelNames.."\n"..levelName
						end
						table.insert(addonsOptions, 
						{
						posX = 40, posY = SelectorOffset, fn = function()
							NextLevel = dir.."/"..files[i]
							StartGame()
						end
						})
						SelectorOffset = SelectorOffset + 20
					end
				end
			else
				for i = 1, #StoryLineLevels, 1 do
					local Data = StoryLineLevels[i]

					if not Data.chapter then
						local Unlocked = not Data.requiresunlock or LevelIsUnlocked(Data.name)

						local levelName, IsListed
						if Unlocked then
							levelName, IsListed = GetLevelDisplayData(dir.."/"..Data.name..".json", Data.name)
						else
							IsListed = true
							levelName = ""
						end
		
						if IsListed then
							if Unlocked then
								if Data.prefix ~= "" then
									levelName = Data.prefix..". "..levelName
								end
							else
								levelName = "⑦. ????????"
							end

							table.insert(addonsOptions, 
							{
							posX = 40, posY = SelectorOffset, fn = function()
								
								if Unlocked then
									NextLevel = Data.name
									StartGame()
								else
									SoundManager:PlaySound("Error")
								end
							end
							})
							
							if LevelNames == "" then
								LevelNames = levelName
							else
								LevelNames = LevelNames.."\n"..levelName
							end

							SelectorOffset = SelectorOffset + 20
						end
					else
						local chapterName = "\n*"..Data.name.."*\n"
						if LevelNames == "" then
							LevelNames = chapterName
						else
							LevelNames = LevelNames.."\n"..chapterName
						end
						SelectorOffset = SelectorOffset + 60
					end
				end
			end
		end
		local Pages = 1
		local PageSize = 220
		if #addonsOptions == 0 then
			LevelNames = "No custom levels found"
			table.insert(addonsOptions, 
			{
			posX = 40, posY = 20, fn = function()
				MenuInst:SetMenu("start")
				SoundManager:PlayMusic("Menu")
				AddSystemMenuButtons()
			end
			})
			Pages = 1
			CameraYMaxScroll = 0
		else
			Selectables = #addonsOptions
			if SelectorOffset > PageSize then
				Pages = math.ceil(SelectorOffset/PageSize)
				print("Pages ", Pages)
				CameraYMaxScroll = SelectorOffset
			else
				Pages = 1
				CameraYMaxScroll = 0
			end
		end
		MenuInst.addonsbackgroundtilemap:setSize(1, Pages)
		for i = 1, Pages, 1 do
			local bgIndex = math.floor(math.random(1,MenuInst.addonsbackgroundtilemaptable:getLength())+0.5)
			MenuInst.addonsbackgroundtilemap:setTileAtPosition(1, i, bgIndex)
		end
		MenuInst.addonsbackground:setTilemap(MenuInst.addonsbackgroundtilemap)
		MenuInst.menus["addons"].options = addonsOptions
		MenuInst:SetMenu("addons")
		local addontextimage = gfx.image.new(194, SelectorOffset)
		addontextimage:clear(gfx.kColorClear)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.pushContext(addontextimage)
			gfx.drawTextInRect(LevelNames, 3, 0, 194, SelectorOffset, nil, "")
		gfx.popContext()
		gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)
		MenuInst.addontextsprite:setImage(addontextimage)
	end
	AddSystemMenuButtons()
end

local function OpenAddons()
	LevelList("/Shared/Mipa/Levels")
end

local function OpenNewLevelSelect()
	LevelList("levels")
end

AddSystemMenuButtons = function ()
	local menu = pd.getSystemMenu()
	menu:removeAllMenuItems()

	if MenuInst and MenuInst.currentmenu == "addons" then
		local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuMainMenu"), function()
			NextLevel = "menu"
			StartGame()
			AddSystemMenuButtons()
		end)
		return
	end

	if CurrentLevelName ~= "menu" and CurrentLevelName ~= "intro" then
		local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuMainMenu"), function()
			NextLevel = "menu"
			StartGame()
		end)
		if CurrentLevelName ~= "credits" then
			local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuRestart"), function()
				StartGame()
			end)
			local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuItems"), function()
				OpenItemsMenu()
			end)
		end
	else
		if CurrentLevelName == "intro" then
			local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuSkip"), function()
				if UIIsnt then
					UIIsnt:SkipIntro()
				end
			end)
		else
			local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("SystemMenuAddons"), function()
				NextLevel = "menu"
				OpenAddons()
			end)
			--local menuItem, error = menu:addMenuItem(LocalizationManager.GetLine("Alt. Level list"), function()
			--	NextLevel = "menu"
			--	OpenNewLevelSelect()
			--end)
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

	local a = math.sin(math.rad(gameTicks)) 
	a = a*30
	print("A ", a)
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
	    gfx.drawSineWave(0, 60, 400, 60, a, a, 56, gameTicks)
    gfx.popContext()
    refimg = refimg:fadedImage(0.5, gfx.image.kDitherTypeDiagonalLine)
	referenceSinus:setImage(refimg)

	local img = gfx.image.new(400, 120)
	gfx.pushContext(img)
	    gfx.drawSineWave(0, 60, 400, 60, a, a, CrankManager.Abosulte+1, gameTicks)
    gfx.popContext()
	crankSinus:setImage(img)
end


DrawCrankSinus = function (change)
	crankSinusVal = crankSinusVal+change
end

StartGame = function ()
	CameraX = 0
	CameraY = 0
	CameraXMaxScroll = 0
	CameraXMinScroll = 0
	CameraYMaxScroll = 0
	CameraYMinScroll = 0
	CanScroll = false
	LeftEdge = 0
    RightEdge = 400
	UpdateCameraPosition(0, 0, true)
	IsReplay = DebugFlags.ForceLikeReplay
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
	CrankManager.Reset()
	MenuInst = nil
	CreditsInst = nil
	if NextLevel == "sintest" or debugsin then
		return
	end
	if NextLevel == "menu" then
		NoSoundsInCutscenes = true
		SoundManager:PlayMusic("Intro")
		pd.setMenuImage(nil, 0)
		MenuInst = Menu()
		CurrentLevelName = "menu"
		AddSystemMenuButtons()
		return
	end
	if NextLevel == "intro" then
		NoSoundsInCutscenes = false
		SoundManager:PlayMusic("Intro")
		pd.setMenuImage(nil, 0)
		CurrentLevelName = "intro"
		UIIsnt = UI()
		UIIsnt:StartCutscene("Intro")
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
		SoundManager:PauseMusic()
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
	else
		IsReplay = true
	end
	--DebugFlags.FrameByFrame = true
	--SUPRESSCURRENTFRAME = true
	CurrentLevelName = NextLevel

	if string.find(CurrentLevelName, ".json") == nil then
		CurrentLevel = Level("levels/"..CurrentLevelName..".json")
		AddUnlockedLevel(CurrentLevelName)
	else
		CurrentLevel = Level(CurrentLevelName)
	end
	
	UIIsnt = UI()
	AddSystemMenuButtons()
end

DeathTrigger = function ()
	CanStartAgain = true
	local again = gfx.sprite.new()
	again:setIgnoresDrawOffset(true)
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
		overlay:setIgnoresDrawOffset(true)
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

DrawCrank = function ()
	DrawCrankFrames = 60
end

StopDrawCrank = function ()
	DrawCrankFrames = 0
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
				local affix = ""
				if i == 4 and MipaInst:HasEquipment(EQUIPMENT.Bomber) then
					affix = "b"
				end
				
				local overlay = AssetsLoader.LoadImage("images/UI/pause/a"..MipaInst.equipment[i]..affix)
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

		if CheatsManager.LegWrap then
			local overlay = AssetsLoader.LoadImage("images/UI/pause/leggy")
			if overlay then
				overlay:draw(0,0)
			end
		end

		if extended then
			for i = 1, #MipaInst.equipment, 1 do
				local slot = AssetsLoader.LoadImage("images/UI/pause/slota")
				local item = AssetsLoader.LoadImageTable("images/UI/equipment"):getImage(MipaInst.equipment[i])
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
				local item = AssetsLoader.LoadImageTable("images/UI/passive"):getImage(MipaInst.passiveitems[i])
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

function IsNightTime(clock)
	return clock.hour > 22 or (clock.hour >= 0 and clock.hour < 4)
end

function IsEarlyMorning(clock)
	return (clock.hour >= 5 and clock.hour <= 7)
end

function IsMipaMonday(clock)
	return (clock.weekday == 1)
end

local function loadGame()
	CheatsManager.RegisterCheats()
	LocalizationManager.Load()
	gfx.setFont(font)
	pd.display.setInverted(true)

	local CanHaveFun = false

	local clock = playdate.getTime()
	local previousvisit = SaveManager.Load("lastvisit")

	if previousvisit then
		if previousvisit.day ~= clock.day or previousvisit.month ~= clock.month then
			CanHaveFun = true
		end
	end

	SaveManager.Save("lastvisit", clock)

	if not SettingsManager:Get("seenflashingwarning") and ReduceFlashingSystemSetting then
		CurrentLevelName = "Warning"
		UIIsnt = UI()
		local Dialog = GetDialogDataFromString("#None\nWe noticed *Reduce Flashing* setting set on your system, and automatically disabled some in-game effects.                  \nYou always can re-enable this effects in game settings. This message shown only once. Be safe.   ")

		UIIsnt:StartDialog(Dialog, nil, "Level intro")
		SettingsManager:ApplyReduceFlashing()
	else
		if CanHaveFun then
			if IsMipaMonday(clock) then
				CurrentLevelName = "Funny"
				UIIsnt = UI()
				local Dialog = GetDialogDataFromString("#Mipa_4\nIt's Mipa Monday today!\nI hope start of your week is good!")
				UIIsnt:StartDialog(Dialog, nil, "Conversation BootMipa monday")
				return
			elseif IsEarlyMorning(clock) then
				CurrentLevelName = "Funny"
				UIIsnt = UI()
				local Dialog = GetDialogDataFromString("#Mipa_3\nWhat the deal of playing this early in the morning?\n#Mipa_4\nHowever, I hope you have good breakfast!")
				UIIsnt:StartDialog(Dialog, nil, "Level intro")
				return
			elseif IsNightTime(clock) then
				CurrentLevelName = "Funny"
				UIIsnt = UI()
				local Dialog = GetDialogDataFromString("#Mipa_3\nWhat the deal of playing this late?\n#Mipa_7\n... ... ...\nOkay, I will let game start anyway!")
				UIIsnt:StartDialog(Dialog, nil, "Level intro")
				return
			end
		end
		StartGame()
	end
end

local function updateGame()
	if InvertedColorsFrames > 0 and not ReduceFlashingSystemSetting then
		InvertedColorsFrames = InvertedColorsFrames-1
		if pd.display.getInverted() then
			pd.display.setInverted(false)
		end
	elseif not pd.display.getInverted() then
		pd.display.setInverted(true)
	end

	if MipaInst then
		if CanScroll then
			UpdateCameraPosition(MipaInst.x, MipaInst.y)
		end
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
		CrankedThisFrame = true
	else
		CrankedThisFrame = false
	end
	if CreditsInst ~= nil then
		CreditsInst:Update()
	end
	TrackableManager.Update()
end

loadGame()



function pd.keyPressed(key)
	if pd.isSimulator == 1 then
		if DebugFlags.FrameByFrame then
			if key == "u" then -- When 'U' held, game updates as normal
				SUPRESSCURRENTFRAME = false
			end
		end
	end
end

function pd.keyReleased(key)
	if pd.isSimulator == 1 then
		if DebugFlags.FrameByFrame then
			if key == "i" then -- When 'I' released, processing single frame.
				SUPRESSCURRENTFRAME = false
			end
		end
		if key == "f" then -- When 'F' released, toggle FrameByFrame
			if DebugFlags.FrameByFrame then
				DebugFlags.FrameByFrame = false
			else
				DebugFlags.FrameByFrame = true
				SUPRESSCURRENTFRAME = true
			end
		end
	end
end


local lastTime = playdate.getCurrentTimeMilliseconds()

function pd.debugDraw()
	if pd.isSimulator == 1 and (DebugFlags.DrawSpriteBounds or DebugFlags.DrawVisibleSpriteBounds) then
		local debugdrawfunction = function (sp)
			if DebugFlags.DrawVisibleSpriteBounds and not sp:isVisible() then
				return
			end
			local x, y, width, height = sp:getBounds()
			gfx.drawRect(x, y, width, height)
		end
		gfx.sprite.performOnAllSprites(debugdrawfunction)
	end
end

function pd.gameWillTerminate()
	print("[PlayDate] gameWillTerminate")
	--SoundManager:PlaySound("BuffetScream")
end

function pd.deviceDidUnlock()
	print("[PlayDate] deviceDidUnlock")
	SoundManager:PlaySound("BuffetScream")
end

function pd.update()
	--print("pd.update()")
	if pd.isSimulator == 1 then
		if DebugFlags.FrameByFrame then
			if SUPRESSCURRENTFRAME then
				return
			else
				SUPRESSCURRENTFRAME = true
			end
		end
	end
	local currentTime = playdate.getCurrentTimeMilliseconds()
	LastDeltaTime = currentTime - lastTime
	lastTime = currentTime
	gameTicks = gameTicks+1
	updateGame()
	if DebugFlags.FPSCounter then
		pd.drawFPS(385,0) -- FPS widget
	end
	UpdatePauseMenu()
	UpdateSinusMiniGame()
	if DrawCrankFrames > 0 then
		DrawCrankFrames = DrawCrankFrames-1
		pd.ui.crankIndicator:draw()
	end
end
