TAG =
{
	Default = 1,
	Player = 1,
	Enemy = 2,
	Prop = 3,
	PropPushable = 4,
	Effect = 5,
	Interactive = 6,
	Hazard = 7,
	HazardNoColide = 8,
	ObstacleCastNoPlayer = 9,
}
Z_Index = 
{
	TotalBumer = -1,
	Enemy = 2,
	Object = 3,
	BG = 4,
	Player = 5,
	UI = 6,
	AllAtop = 7,
}

DebugFlags = 
{
	NoDialogs = false,
	AllOpen = false,
	NoDamage = false,
	FPSCounter = false,
}

null = nil

GetDialogDataFromString = function (key)
	local rawText = LocalizationManager.GetLine(key)
	local rawLines = {}
	if string.find(rawText, "\n") then
		for l in string.gmatch(rawText, '([^\n]+)') do
			table.insert(rawLines, l)
		end
	else
		table.insert(rawLines, rawText)
	end
	local DialogData = {}
	DialogData.Key = key
	local Prefix = "#"
	local LastActor = "#None"
	for i = 1, #rawLines, 1 do
		local rawLine = rawLines[i]
		if string.sub(rawLine,1,string.len(Prefix)) == Prefix then
			LastActor = rawLine
		else
			local lineData = {}
			lineData.actor = LastActor:sub(2)
			lineData.text = rawLine
			table.insert(DialogData, lineData)
		end
	end
	return DialogData
end