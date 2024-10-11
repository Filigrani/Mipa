local pd <const> = playdate
local gfx <const> = pd.graphics
TrackableManager = {}
TrackableManager.trackables = {}
TrackableManager.logicfunctions = {}
TrackableManager.executeQueue = {}

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
    TrackableManager.executeQueue = {}
end

TrackableManager.Add = function (obj, uid)
    TrackableManager.trackables[tostring(uid)] = obj
    print("[TrackableManager] Added object "..uid)
    print("[TrackableManager] Added object "..uid.." IsTrigger? ", obj.IsTrigger)
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
            print("[TrackableManager] Param: "..l)
        end
        command = parameters[1]
    end

    if command == "Remove" then
        if parameters[2] ~= nil then
            TrackableManager.RemoveByUID(parameters[2])
        end
    elseif command == "Trigger" then
        local obj = TrackableManager.GetByUID(parameters[2])
        if obj then
            if obj.IsTrigger then
                obj:Trigger()
            else
                print("[TrackableManager][Trigger] Object "..parameters[2].." is not trigger!")
            end
        else
            print("[TrackableManager][Trigger] Wasn't able to find object under ID ", parameters[2])
        end
    elseif command == "SoftTrigger" then
        local obj = TrackableManager.GetByUID(parameters[2])
        if obj and obj.IsTrigger then
            obj:SoftTrigger()
        end
    elseif command == "SetActive" then
        local obj = TrackableManager.GetByUID(parameters[2])
        local state = parameters[3]

        if obj and obj.Trigger then
            if state == nil then
                if obj.active then
                    obj.active = false
                else
                    obj.active = true
                end
            else
                if state == 1 or state == "1" or state == true or state == "true" or state == "TRUE" then
                    obj.active = true
                elseif state == 0 or state == "0" or state == false or state == "false" or state == "FALSE" then
                    obj.active = false
                end
            end
        end
    elseif command == "Spawn" then
        local type = parameters[2]
        if type == "box" then
            PhysicalProp(tonumber(parameters[3]), tonumber(parameters[4]))
        end
        if type == "wasp" then
            local data = {}
            data.propType = "wasp"
            data.x = tonumber(parameters[3])
            data.y = tonumber(parameters[4])
            if parameters[5] ~= nil then
                data.actoraction = parameters[5]
            else
                data.actoraction = ""
            end
            if parameters[6] ~= nil then
                data.UID  = parameters[6]
            else
                data.UID  = "wasp"
            end
            CurrentLevel:CreateProp(data)
        end
    elseif command == "Glitch" then
        UIIsnt.glitchframes = tonumber(parameters[2])
    elseif command == "Dialog" then
        if UIIsnt ~= nil then
            UIIsnt:StartDialog(GetDialogDataFromString(parameters[2]), parameters[3], parameters[4])
        end
    elseif command == "NoControl" then
        if MipaInst ~= nil then
            MipaInst.canbecontrolled = false
        end
    elseif command == "ReturnControl" then
        if MipaInst ~= nil then
            MipaInst.canbecontrolled = true
        end
    elseif command == "DropFunnyBridge" then
        local UID = parameters[2]
        local funnybridge = TrackableManager.GetByUID(UID)
        if funnybridge then
            funnybridge:Drop()
        end
    elseif command == "SkipFallDamage" then
        if MipaInst then
            MipaInst.skipfalldamage = true
        end
    elseif command == "ChangeActor" then
        local UID = parameters[2]
        local Action = parameters[3]
        local Actor = TrackableManager.GetByUID(UID)
        if Actor then
            Actor:SetActorAct(Action)
        else
            print("[TrackableManager][ChangeActor] Actor with UID "..UID.." not found!")
        end
    elseif command == "Music" then
        if parameters[2] == "None" then
            parameters[2] = ""
        end
        SoundManager:PlayMusic(parameters[2])
    elseif command == "MusicStop" then
        SoundManager:FadeMusicForWhile(70)
    elseif command == "MipaPosition" then
        if MipaInst then
            MipaInst:moveTo(parameters[2], parameters[3])
        end
    elseif command == "Cutscene" then
        UIIsnt:StartCutscene(parameters[2])
    elseif command == "Level" then
        NextLevel = parameters[2]
        StartGame()
    elseif command == "BigTrash" then
        local TrashSpawner = TrackableManager.GetByUID(parameters[2])
        TrashSpawner.pendingBigTrash = true
    elseif command == "BigTrashKoaKola" then
        local TrashSpawner = TrackableManager.GetByUID(parameters[2])
        TrashSpawner.pendingBigTrashKoaKola = true
    elseif command == "Activate" then
        local group = parameters[2]
        print("Exect param 2 ", group)
        ActiveManager.AddScripedActive("H")
    elseif command == "Deactivate" then
        local group = parameters[2]
        print("Exect param 2 ", group)
        ActiveManager.RemoveScripedActive(group)
    elseif command == "Conversation" then
        UIIsnt:StartConversation(parameters[2], parameters[3])
    end
end

TrackableManager.AddCommandLineToQueue = function (rawText)
    local CommandsLines = {}
    if string.find(rawText, "\n") then
        for l in string.gmatch(rawText, '([^\n]+)') do
            table.insert(CommandsLines, l)
        end
    else
        table.insert(CommandsLines, rawText)
    end

    local element = {}
    element.Commands = CommandsLines
    element.CurrentIndex = 1
    element.OnHold = 0
    table.insert(TrackableManager.executeQueue, element)
end

TrackableManager.ProcessCommandLine = function (rawText)
    print("[TrackableManager] ProcessCommandLine: "..rawText)
    TrackableManager.AddCommandLineToQueue(rawText)
end

TrackableManager.Update = function ()
    if #TrackableManager.executeQueue > 0 then
        local element = TrackableManager.executeQueue[1]
        if element.OnHold == 0 then
            local currentCommand = element.Commands[element.CurrentIndex]
            local command = currentCommand
            local parameters = {}
            if string.find(currentCommand, " ") then
                for l in string.gmatch(currentCommand, '%S+') do
                    table.insert(parameters, l)
                end
                command = parameters[1]
            end
            element.CurrentIndex = element.CurrentIndex+1
            if element.CurrentIndex > #element.Commands then
                table.remove(TrackableManager.executeQueue, 1)
            end
            if command == "Delay" then
                element.OnHold =  tonumber(parameters[2])
            else
                TrackableManager.ExecuteCommand(currentCommand)
                TrackableManager.Update()
            end
        else
            element.OnHold = element.OnHold-1
        end
    end
end