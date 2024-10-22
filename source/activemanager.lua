local pd <const> = playdate
local gfx <const> = pd.graphics
ActiveManager = {}
ActiveManager.activatables = {}
ActiveManager.activators = {}
ActiveManager.activegroups = {}
ActiveManager.scripedactivegroups = {}

ActiveManager.Reset = function ()
    ActiveManager.activatables = {}
    ActiveManager.activators = {}
    ActiveManager.activegroups = {}
end

ActiveManager.AddActivatable = function (obj)
    table.insert(ActiveManager.activatables, obj)
    print("[ActiveManager] Added activatable that requires "..obj.activetype.." of this groups to be active:")
    for i = 1, #obj.activegroup, 1 do
        print(obj.activegroup[i])
    end
end

ActiveManager.AddActivator = function (obj)
    table.insert(ActiveManager.activators, obj)
    print("[ActiveManager] Added activator that triggers groups:")
    for i = 1, #obj.activegroup, 1 do
        print(obj.activegroup[i])
    end
end

ActiveManager.AddScripedActive = function (group)
    for i = 1, #ActiveManager.scripedactivegroups, 1 do
        if ActiveManager.scripedactivegroups[i] == group then
            return
        end
    end
    print("[ActiveManager] Added scripted activation for group ", group)
    table.insert(ActiveManager.scripedactivegroups, group)
end

ActiveManager.RemoveScripedActive = function (group)
    for i = 1, #ActiveManager.scripedactivegroups, 1 do
        if ActiveManager.scripedactivegroups[i] == group then
            print("[ActiveManager] Removed scripted activation for group ", group)
            table.remove(ActiveManager.scripedactivegroups, i)
            return
        end
    end
end

ActiveManager.UpdateActiveGroups = function ()
    ActiveManager.activegroups = {}
    for i = 1, #ActiveManager.activators, 1 do
        local act = ActiveManager.activators[i]
        if act and act.activated then
            local groups = act.activegroup
            for i = 1, #groups, 1 do
                table.insert(ActiveManager.activegroups, groups[i])
            end
        end
    end
    return activeGroups
end

ActiveManager.GroupIsActive = function (group)
    for i = 1, #ActiveManager.activegroups, 1 do
        if ActiveManager.activegroups[i] == group then
            return true
        end
    end
    for i = 1, #ActiveManager.scripedactivegroups, 1 do
        if ActiveManager.scripedactivegroups[i] == group then
            return true
        end
    end
    return false
end

ActiveManager.GetGroupImages = function (group)
    local imgs = {}
    for i = 1, #ActiveManager.activators, 1 do
        local act = ActiveManager.activators[i]
        if act then
            local img = act:getImage()
            local r_x, r_y, r_w, r_h = act:getBounds()
            local rectangle = {x = r_x, y = r_y, w = r_w, h = r_h}
            if img ~= nil then
                table.insert(imgs, {image = img, x = act.x, y = act.y, rect = rectangle})
            end
        end
    end
    for i = 1, #ActiveManager.activatables, 1 do
        local act = ActiveManager.activatables[i]
        if act then
            local img = act:getImage()
            local r_x, r_y, r_w, r_h = act:getBounds()
            local rectangle = {x = r_x, y = r_y, w = r_w, h = r_h}
            if img ~= nil then
                table.insert(imgs, {image = img, x = act.x, y = act.y, rect = rectangle})
            end
        end
    end
    return imgs
end

ActiveManager.UpdateActivatables = function ()
    for i = 1, #ActiveManager.activatables, 1 do
        local act = ActiveManager.activatables[i]
        if act then
            local groups = act.activegroup
            local activeType = act.activetype
            if activeType == "Any" then
                local activeFlag = false
                for i2 = 1, #groups, 1 do
                    if ActiveManager.GroupIsActive(groups[i2]) then
                        activeFlag = true
                        break
                    end
                end
                act.activated = activeFlag
            elseif activeType == "Every" then
                local activeFlag = true
                for i2 = 1, #groups, 1 do
                    if not ActiveManager.GroupIsActive(groups[i2]) then
                        activeFlag = false
                        break
                    end
                end
                act.activated = activeFlag             
            end
            if DebugFlags.AllOpen then
                act.activated = true
            end
        end
    end   
end

ActiveManager.Update = function ()
    ActiveManager.UpdateActiveGroups()
    ActiveManager.UpdateActivatables()
end
