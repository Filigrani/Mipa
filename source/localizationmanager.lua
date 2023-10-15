local pd <const> = playdate
LocalizationManager = {}
LocalizationManager.currentlocalization = {}
LocalizationManager.defaultlanguage = "english"

import "jsonloader"

LocalizationManager.Load = function ()
    LocalizationManager.currentlocalization = {}
    local jsondata = GetJSONData("localizations/"..LocalizationManager.defaultlanguage..".json")
    for i=1, #jsondata.lines do
        local curline = jsondata.lines[i]
        LocalizationManager.currentlocalization[curline.key] = curline.line
    end
end

LocalizationManager.GetLine = function (key)
    if LocalizationManager.currentlocalization ~= nil then
        local localizedline = LocalizationManager.currentlocalization[key]
        if localizedline ~= nil then
            return localizedline
        end
    end
    return key
end