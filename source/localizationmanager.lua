local pd <const> = playdate
LocalizationManager = {}
LocalizationManager.currentlocalization = {}
LocalizationManager.backuplocalization = {}
LocalizationManager.defaultlanguage = "english"
LocalizationManager.currentlanguage = SaveManager.Load("lang") or LocalizationManager.defaultlanguage

import "jsonloader"

LocalizationManager.Load = function ()
    LocalizationManager.currentlocalization = {}
    local jsondata = GetJSONData("localizations/"..LocalizationManager.currentlanguage..".json")
    for i=1, #jsondata.lines do
        local curline = jsondata.lines[i]
        LocalizationManager.currentlocalization[curline.key] = curline.line
    end
    local backupjsondata = GetJSONData("localizations/"..LocalizationManager.defaultlanguage..".json")
    for i=1, #backupjsondata.lines do
        local curline = backupjsondata.lines[i]
        LocalizationManager.backuplocalization[curline.key] = curline.line
    end
end

LocalizationManager.GetLine = function (key)
    if LocalizationManager.currentlocalization ~= nil then
        local localizedline = LocalizationManager.currentlocalization[key]
        if localizedline ~= nil then
            return localizedline
        end
    end
    if LocalizationManager.backuplocalization ~= nil then
        local localizedline = LocalizationManager.backuplocalization[key]
        if localizedline ~= nil then
            return localizedline
        end
    end
    return key
end