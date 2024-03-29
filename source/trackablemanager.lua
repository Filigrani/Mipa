local pd <const> = playdate
local gfx <const> = pd.graphics
TrackableManager = {}
TrackableManager.trackables = {}
TrackableManager.logicfunctions = {}

TrackableManager.RegisterLogicBlock = function (uid, code)
    TrackableManager.logicfunctions[tostring(uid)] = load(code, #code)
end

TrackableManager.TriggerLogicBlock = function (uid)
    if uid ~= nil and uid > 0 then
        if TrackableManager.logicfunctions[tostring(uid)] ~= nil  then
            TrackableManager.logicfunctions[tostring(uid)]()
        end       
    end
end

TrackableManager.Reset = function ()
    TrackableManager.trackables = {}
    TrackableManager.logicfunctions = {}
end

TrackableManager.Add = function (obj, uid)
    TrackableManager.trackables[tostring(uid)] = obj
end

TrackableManager.RemoveByUID = function (uid)
    local obj = TrackableManager.trackables[tostring(uid)]
    if obj ~= nil then
        gfx.sprite.removeSprite(obj)
        TrackableManager.trackables[tostring(uid)] = nil
    end
end
TrackableManager.GetByUID = function (uid)
    local obj = TrackableManager.trackables[tostring(uid)]
    if obj ~= nil then
        return obj
    end
    return nil
end

TrackableManager.ExecuteCommand = function (commandWithParameters)
    print("[TrackableManager] ExecuteCommand: "..commandWithParameters)
    local command = commandWithParameters
    local parameters = {}
    if string.find(commandWithParameters, " ") then
        for l in string.gmatch(commandWithParameters, '%S+') do
            table.insert(parameters, l)
        end
        command = parameters[1]
    end

    if command == "Remove" then
        if parameters[2] ~= nil then
            TrackableManager.RemoveByUID(parameters[2])
        end
    elseif command == "Trigger" then
        local obj = TrackableManager.GetByUID(parameters[2])
        if obj and obj.Trigger then
            obj:Trigger()
        end
    elseif command == "Spawn" then
        local type = parameters[2]
        if type and type == "box" then
            PhysicalProp(tonumber(parameters[3]), tonumber(parameters[4]))
        end
    elseif command == "Glitch" then
        UIIsnt.glitchframes = tonumber(parameters[2])
    elseif command == "Dialog" then
        if UIIsnt ~= nil then
            UIIsnt:StartDialog(GetDialogDataFromString(parameters[2]))
        end
    end
end

TrackableManager.ProcessCommandLine = function (rawText)
    print("[TrackableManager] ProcessCommandLine: "..rawText)
    local CommandsLines = {}
    if string.find(rawText, "\n") then
        for l in string.gmatch(rawText, '([^\n]+)') do
            table.insert(CommandsLines, l)
        end
    else
        table.insert(CommandsLines, rawText)
    end
    if #CommandsLines > 0 then
        for i = 1, #CommandsLines, 1 do
            TrackableManager.ExecuteCommand(CommandsLines[i])            
        end 
    end
end