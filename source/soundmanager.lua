local pd <const> = playdate
local snd = pd.sound
SoundManager = {}
local sounds = {}
local function AddSound(name, variants, caninterupt)
    sounds[name] = {}
    sounds[name].caninterupt = caninterupt
    if variants == nil then
        sounds[name].sound = snd.sampleplayer.new('sfx/'..name)
        sounds[name].variants = -1
    else
        sounds[name] = {}
        sounds[name].sound = {}
        sounds[name].variants = variants
        for i=0, variants do
            table.insert(sounds[name].sound, snd.sampleplayer.new('sfx/'..name..i))
        end
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
AddSound("Weep")
AddSound("BeamLoop")
AddSound("Glitch",6)
AddSound("Bzz",1)
AddSound("Splash",2)
AddSound("Slip")
AddSound("GlitchNew")
AddSound("MipaGameOver")
AddSound("Note")
AddSound("Tick")
AddSound("Stop")
AddSound("Warning")
AddSound("Heavyland")
AddSound("Wooah")
AddSound("PfffBrr")
AddSound("Pfff", nil, true)


function SoundManager:PlaySound(name, vol, ignorecutscene)
    if UIIsnt and UIIsnt:IsCutscene() then
        if ignorecutscene == nil then
            return
        end
    end
    local volume = 1
    if vol ~= nil then
        volume = vol
    end

    if sounds[name] ~= nil then
        local data = sounds[name]
        if data.variants == -1 then
            if not data.sound:isPlaying() or data.caninterupt then
                sounds[name].sound:setVolume(volume)
                sounds[name].sound:play(1)
            end
        else
            if not data.caninterupt then
                for i=0, data.variants do
                    if data.sound[i] ~= nil and data.sound[i]:isPlaying() then
                        return
                    end
                end
            end
            local RandomIndex = math.random(1, data.variants+1)
            data.sound[RandomIndex]:setVolume(volume)
            data.sound[RandomIndex]:play(1)
        end
    end
end

