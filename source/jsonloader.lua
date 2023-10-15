local pd <const> = playdate
local gfx <const> = pd.graphics

function GetJSONData(path)

	local Data = nil

	local f = pd.file.open(path)
	if f then
		local s = pd.file.getSize(path)
		Data = f:read(s)
		f:close()

		if Data == nil then
			print('ERROR LOADING DATA for ', path)
			return nil
		end
	end

	local jsonTable = json.decode(Data)

	if jsonTable == nil then
		print('ERROR PARSING JSON DATA for ', path)
		return nil
	end

	return jsonTable
end