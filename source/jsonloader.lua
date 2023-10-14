local pd <const> = playdate
local gfx <const> = pd.graphics

function GetJSONData(path)
	
	local levelData = nil
	
	local f = pd.file.open(path)
	if f then
		local s = pd.file.getSize(path)
		levelData = f:read(s)
		f:close()
		
		if levelData == nil then
			print('ERROR LOADING DATA for ', path)
			return nil
		end
	end

	local jsonTable = json.decode(levelData)
	
	if jsonTable == nil then
		print('ERROR PARSING JSON DATA for ', levelPath)
		return nil
	end
	
	return jsonTable
end