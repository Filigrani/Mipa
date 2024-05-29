local pd <const> = playdate
CheatsManager = {}
CheatsManager.cheats = {}
CheatsManager.currentcombination = ""

CheatsManager.AddCheat = function (combination, fn)
    CheatsManager.cheats[combination] = fn
end

CheatsManager.HandleInput = function (str)
    if #CheatsManager.currentcombination == 10 then
        CheatsManager.currentcombination = CheatsManager.currentcombination:sub(2)
    end
    CheatsManager.currentcombination = CheatsManager.currentcombination..str
    if  CheatsManager.cheats[CheatsManager.currentcombination] ~= nil then
        CheatsManager.cheats[CheatsManager.currentcombination]()
        if UIIsnt ~= nil then
            UIIsnt:StartDialog(GetDialogDataFromString("Cheater"))
        end
    end
    --print(CheatsManager.currentcombination)
end

CheatsManager.HandleInputs = function ()
    if pd.buttonJustPressed(pd.kButtonA) then
		CheatsManager.HandleInput("A")
	end
	if pd.buttonJustPressed(pd.kButtonB) then
		CheatsManager.HandleInput("B")
	end
	if pd.buttonJustPressed(pd.kButtonUp) then
		CheatsManager.HandleInput("U")
	elseif pd.buttonJustPressed(pd.kButtonDown) then
		CheatsManager.HandleInput("D")
	end
	if pd.buttonJustPressed(pd.kButtonLeft) then
		CheatsManager.HandleInput("L")
	elseif pd.buttonJustPressed(pd.kButtonRight) then
		CheatsManager.HandleInput("R")
	end
end

CheatsManager.RegisterCheats = function ()
    -- Cheats should be 10 buttons long combination
    --                      1234567890
    CheatsManager.AddCheat("UUDDLRLRBA", function ()
        if MipaInst then
            MipaInst.hpmax = 5
            MipaInst.hp = 5
            MipaInst:Konami()
        end
    end)
    --                      1234567890
    CheatsManager.AddCheat("UUUDDDBBBB", function ()
        if DebugFlags.FPSCounter then
            DebugFlags.FPSCounter = false
        else
            DebugFlags.FPSCounter = true
        end
    end)
    --                      1234567890
    CheatsManager.AddCheat("BABAUBABAU", function ()
        DebugFlags.AllOpen = true
    end)
    --                      1234567890
    CheatsManager.AddCheat("DURALDURAL", function ()
        DebugFlags.NoDamage = true
    end)
end