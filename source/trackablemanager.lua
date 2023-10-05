local pd <const> = playdate
local gfx <const> = pd.graphics
TrackableManager = {}
TrackableManager.trackables = {}

TrackableManager.Reset = function ()
    TrackableManager.trackables = {}
end

TrackableManager.Add = function (obj, uid)
    TrackableManager.trackables[tostring(uid)] = obj
end

TrackableManager.RemoveByUID = function (uid)
    local obj = TrackableManager.trackables[tostring(uid)]
    if obj ~= nil then
        gfx.sprite.removeSprite(obj)
    end
end