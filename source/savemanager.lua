local pd <const> = playdate
SaveManager = {}

SaveManager.Save = function (entrykey, content)
    pd.datastore.write(content, entrykey, true)
end

SaveManager.Load = function (entrykey)
    local dat = pd.datastore.read(entrykey)
    if dat == nil then
        print("[SaveManager] Wasn't able to load entry ", entrykey)
        return nil
    end
    print("[SaveManager] Successfully loaded entry ", entrykey)
    return dat
end