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

    if MipaInst and MipaInst.elevator then
        local _x, _y = MipaInst.elevator:getPosition()
        local _x2, _y2 = MipaInst:getPosition()

        if num > 0 then
            MipaInst.elevator:moveWithCollisions(_x, _y+num)
            MipaInst:moveWithCollisions(_x2, _y2+num)
        else
            MipaInst:moveWithCollisions(_x2, _y2+num)
            MipaInst.elevator:moveWithCollisions(_x, _y+num)
        end
    end

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
