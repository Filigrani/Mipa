local pd <const> = playdate
local gfx <const> = pd.graphics
CrankManager = {}
CrankManager.crankables = {}

CrankManager.AddObject = function(obj)
    table.insert(CrankManager.crankables, obj)
end

CrankManager.Changed = function(num)
    for i = 1, #CrankManager.crankables, 1 do
        CrankManager.crankables[i]:Changed(num)
    end
    CrankManager.Abosulte = pd.getCrankPosition()
    print("change "..num)
    DrawCrankSinus(num)
end

CrankManager.Abosulte = 0

CrankManager.NewPlatform = function (x, y, dis)
    local data = {}
    data.x = x
    data.y = y
    data.dis = dis
    return data
end
