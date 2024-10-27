TAG =
{
	Default = 0,
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
	BG = 0,
	Object = 1,
	ObjectAtop = 2,
	Enemy = 3,
	Player = 4,
	PlayerAtop = 5,
	AtopPlayerAtop = 6,
	UI = 7,
	AllAtop = 8,
}

DebugFlags = 
{
	NoDialogs = false,
	AllOpen = false,
	NoDamage = false,
	FPSCounter = false,
	FrameByFrame = false,
	ForceLikeReplay = false,
	DrawSpriteBounds = false,
	DrawVisibleSpriteBounds = false,
}

FONT_BUTTONS =
{
	A = "①",
	B = "②",
	UP = "③",
	DOWN = "④",
	LEFT = "⑤",
	RIGHT = "⑥",
	PaddleLock = "⑦",
}

null = nil

SUPRESSCURRENTFRAME = false

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