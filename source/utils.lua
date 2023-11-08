TAG =
{
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
	Player = 5,
	Enemy = 2,
	Object = 3,
	BG = 4,
	UI = 6,
	TotalBumer = -1,
}

DebugFlags = 
{
	NoDialogs = false,
	AllOpen = false,
	NoDamage = false,
	FPSCounter = false,
}

null = nil

GetDialogDataFromString = function (str)
	local rawText = LocalizationManager.GetLine(str)
	local rawLines = {}
	if string.find(rawText, "\n") then
		for l in string.gmatch(rawText, '([^\n]+)') do
			table.insert(rawLines, l)
		end
	else
		table.insert(rawLines, rawText)
	end
	local DialogData = {}
	local Prefix = "#"
	local LastActor = "Mipa"
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