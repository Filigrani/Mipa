DefaultSettings = 
{
	lang = "english",
	dialogboxmode = "dyn",
	damageglitches = true,
	lowhpglitches = true,
	musicvolume = 5,
}
Settings = 
{

}

SettingsManager = {}


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