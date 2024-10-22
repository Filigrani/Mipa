local pd <const> = playdate
local gfx <const> = pd.graphics
CrankManager = {}
CrankManager.crankables = {}
CrankManager.Abosulte = 0

function CrankManager:AddCrankables(obj)
    table.insert(CrankManager.crankables, obj)
end

CrankManager.Reset = function()
    CrankManager.crankables = {}
end

CrankManager.Changed = function(num)
    for i = 1, #CrankManager.crankables, 1 do
        CrankManager.crankables[i]:CrankChanged(num, CrankManager.Abosulte)
    end
    CrankManager.Abosulte = pd.getCrankPosition()
    print("[CrankManager] Change "..num)
    print("[CrankManager] Abosulte "..CrankManager.Abosulte)

    DrawCrankSinus(num)
end

