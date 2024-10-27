ReduceFlashingSystemSetting = playdate.getReduceFlashing()

DefaultSettings = 
{
	lang = "english",
	dialogboxmode = "dyn",
	damageglitches = not ReduceFlashingSystemSetting,
	lowhpglitches = not ReduceFlashingSystemSetting,
	musicvolume = 5,
    liquidvisualid = 800,
    seenflashingwarning = false,
}
Settings = 
{

}

SettingsManager = {}

function SettingsManager:ApplyReduceFlashing()
    SettingsManager:Set("damageglitches", false)
    SettingsManager:Set("lowhpglitches", false)
    SettingsManager:Set("seenflashingwarning", true)
    SaveManager.Save("settings", Settings)
end


function SettingsManager:Get(entrykey)
    print("[SettingsManager] Get ", entrykey)
    local val = Settings[entrykey]
    if val == nil then
        local defaultVal = DefaultSettings[entrykey]
        if defaultVal ~= nil then
            print("[SettingsManager] Assign default value for "..entrykey..", now it is ", defaultVal)
            return defaultVal
        else
            print("[SettingsManager] Can't get value"..entrykey)
            return nil
        end
    else
        return val
    end
end

function SettingsManager:Set(entrykey, val)
    Settings[entrykey] = val
    print("[SettingsManager] Set value "..entrykey.." to ", val)
end