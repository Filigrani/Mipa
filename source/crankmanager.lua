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
    print("change "..num)
end

CrankManager.NewPlatform = function (x, y, dis)
    local data = {}
    data.x = x
    data.y = y
    data.dis = dis
    return data
end
