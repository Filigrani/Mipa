local pd <const> = playdate
local snd = pd.sound
SoundManager = {}
local sounds = {}
local soundvariants = {}
local function AddSound(name, variants)
    if variants == nil then
        sounds[name] = snd.sampleplayer.new('sfx/'..name)
        soundvariants[name] = -1
    else
        for i=0, variants do
            sounds[name..i] = snd.sampleplayer.new('sfx/'..name..i)
        end
        soundvariants[name] = variants
    end
end

AddSound("Land")
AddSound("Hit")
AddSound("Scream")
AddSound("Push",2)
AddSound("MetalPush",1)
AddSound("Door")
AddSound("No")
AddSound("Button")
AddSound("Sqeak", 4)
AddSound("Peaw", 3)
AddSound("Woop")
AddSound("Pap")
AddSound("Oop")
AddSound("Bloop")
AddSound("Gaw",4)
AddSound("Wapa")
AddSound("Pip")
AddSound("Tuboa")
AddSound("BeamLoop")
AddSound("Glitch",6)
AddSound("GlitchNew")
AddSound("MipaGameOver")

function SoundManager:PlaySound(name, vol)
    local volume = 1
    if vol ~= nil then
        volume = vol
    end
    local variants = soundvariants[name]
    if variants == -1 then
        if sounds[name] ~= nil and not sounds[name]:isPlaying() then
            sounds[name]:setVolume(volume)
            sounds[name]:play(1)
        end
    else
        for i=0, variants do
            if sounds[name..i] ~= nil and sounds[name..i]:isPlaying() then
                return
            end
            local RandomIndex = math.random(0, variants)
            sounds[name..RandomIndex]:setVolume(volume)
            sounds[name..RandomIndex]:play(1)
        end
    end
end

