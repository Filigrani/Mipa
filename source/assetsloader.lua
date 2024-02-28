local pd <const> = playdate
local gfx <const> = pd.graphics

AssetsLoader = {}
AssetsLoader.assets = {}

AssetsLoader.Clear = function ()
    AssetsLoader.assets = {}
    print("[AssetsLoader] Preloaded assets flushed!")
end

AssetsLoader.GetAsset = function (assetpath)
    local asset = AssetsLoader.assets[assetpath]
    if asset ~= nil then
        return asset
    end
    return nil
end

AssetsLoader.SetAsset = function (assetpath, asset)
    AssetsLoader.assets[assetpath] = asset
    print("[AssetsLoader] Image Table Loaded: ", assetpath)
end

AssetsLoader.LoadImage = function (path, localizable)
    if localizable and LocalizationManager.currentlanguage ~= "english" then
        path = path.."-"..LocalizationManager.currentlanguage
    end
    local asset = AssetsLoader.assets[path]
    if asset ~= nil then
        return asset
    else
        asset = gfx.image.new(path)
        if asset == nil then
            print("[AssetsLoader] Can't load Image ", path)
            if localizable then
                print("[AssetsLoader] Trying to find non localized version...")
                return AssetsLoader.LoadImage(path, false)
            end
            return nil
        end
        AssetsLoader.assets[path] = asset
        print("[AssetsLoader] Image Loaded: ", path)
        return asset
    end
end

AssetsLoader.LoadImageTable = function (path, localizable)
    if localizable and LocalizationManager.currentlanguage ~= "english" then
        path = path.."-"..LocalizationManager.currentlanguage
    end

    local asset = AssetsLoader.assets[path]
    if asset ~= nil then
        return asset
    else
        asset = gfx.imagetable.new(path)
        if asset == nil then
            print("[AssetsLoader] Can't load Image Table: ", path)
            if localizable then
                print("[AssetsLoader] Trying to find non localized version...")
                return AssetsLoader.LoadImageTable(path, false)
            end
            return nil
        end
        AssetsLoader.assets[path] = asset
        print("[AssetsLoader] Image Table Loaded: ", path)
        return asset
    end
end

AssetsLoader.LoadImageTableAsNew = function (path, newname)
    local asset = gfx.imagetable.new(path)
    if asset == nil then
        print("[AssetsLoader] Can't load Image Table: ", path)
        return nil
    else
        AssetsLoader.assets[newname] = asset
        print("[AssetsLoader] Image Table Loaded: ", newname)
        return asset
    end
end