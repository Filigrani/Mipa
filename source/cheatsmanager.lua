local pd <const> = playdate
CheatsManager = {}
CheatsManager.cheats = {}
CheatsManager.currentcombination = ""

CheatsManager.AddCheat = function (combination, fn)
    CheatsManager.cheats[combination] = fn
end

CheatsManager.HandleInput = function (str)
    if #CheatsManager.currentcombination == 10 then
        CheatsManager.currentcombination = ""
    end
    CheatsManager.currentcombination = CheatsManager.currentcombination..str
    print("Cheat: ", CheatsManager.currentcombination)
    if  CheatsManager.cheats[CheatsManager.currentcombination] ~= nil then
        CheatsManager.cheats[CheatsManager.currentcombination]()
    end
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
    CheatsManager.AddCheat("UUDDLRLRBA", function ()
        if MipaInst then
            MipaInst.hpmax = 10
            MipaInst.hp = 10
        end
    end)
end