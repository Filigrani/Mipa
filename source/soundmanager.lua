local pd <const> = playdate
local snd = pd.sound
SoundManager = {}
local sounds = {}
local musicplayer = nil
local lastmusicloaded = ""
local musicresumetimer = nil
SoundManager.MusicVolume = 1
NoSoundsInCutscenes = true
do
    local vol = 5
    local savevol = Settings.musicvolume
    if savevol then
        vol = savevol
    end
    SoundManager.MusicVolumeSetting = vol
end

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

function SoundManager:ApplyMusicVolume()
    if SoundManager.MusicVolumeSetting == 5 then
        SoundManager.MusicVolume = 1
    elseif SoundManager.MusicVolumeSetting == 4 then
        SoundManager.MusicVolume = 0.8
    elseif SoundManager.MusicVolumeSetting == 3 then
        SoundManager.MusicVolume = 0.6
    elseif SoundManager.MusicVolumeSetting == 2 then
        SoundManager.MusicVolume = 0.4
    elseif SoundManager.MusicVolumeSetting == 1 then
        SoundManager.MusicVolume = 0.2
    elseif SoundManager.MusicVolumeSetting == 0 then
        SoundManager.MusicVolume = 0
    end
    if musicplayer then
        musicplayer:setVolume(SoundManager.MusicVolume)
    end
end

SoundManager:ApplyMusicVolume()

AddSound("Land")
AddSound("Hit")
AddSound("Scream")
AddSound("Push",2)
AddSound("PushShort",3)
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
AddSound("BzzFast")
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
AddSound("Wooop", nil, true)
AddSound("Crip", nil, true)
AddSound("Dzip", 1, true)
AddSound("ShockShot")
AddSound("BossFight")
AddSound("Commander",2)
AddSound("Bounce",2)
AddSound("Glass",3)
AddSound("BuffetScream")
AddSound("Error")

function SoundManager:PlayMusic(name, smooth)
    if smooth == nil then
        smooth = true
    end
    local justplayfromstart = false
    if lastmusicloaded == name then
        if musicplayer ~= nil then
            if not musicplayer:isPlaying() then
                justplayfromstart = true
            else
                return
            end
        end
    end
    if musicplayer == nil then
        musicplayer = pd.sound.fileplayer.new("music/"..name)
    else
        musicplayer:stop()
        if not justplayfromstart then
            musicplayer = pd.sound.fileplayer.new("music/"..name)
        end
    end
    if smooth then
        musicplayer:setVolume(0)
        musicplayer:setVolume(SoundManager.MusicVolume, SoundManager.MusicVolume, 3)
    else
        musicplayer:setVolume(SoundManager.MusicVolume)
    end
    
    musicplayer:play(0)
    lastmusicloaded = name
end

function SoundManager:PauseMusic()
    if musicplayer == nil then
        return
    end
    musicplayer:pause()
end

function SoundManager:ResumeMusic()
    if musicplayer == nil then
        return
    end
    musicplayer:play()
end

function SoundManager:PauseMusicForWhile(frames)
    if musicresumetimer ~= nil then
        musicresumetimer:remove()
    end
    SoundManager:PauseMusic()
    musicresumetimer = pd.frameTimer.new(frames)
    musicresumetimer.repeats = true
    musicresumetimer.timerEndedCallback = function(timer)
        SoundManager:ResumeMusic()
    end
end

function SoundManager:FadeMusicForWhile(frames)
    if musicresumetimer ~= nil then
        musicresumetimer:remove()
    end
    if musicplayer and musicplayer:isPlaying() then
        musicplayer:setVolume(0, 0, 0.5)
    else
        return
    end
    musicresumetimer = pd.frameTimer.new(frames)
    musicresumetimer.repeats = true
    musicresumetimer.timerEndedCallback = function(timer)
        if musicplayer and musicplayer:isPlaying() then
            musicplayer:setVolume(SoundManager.MusicVolume, SoundManager.MusicVolume, 5)
        else
            return
        end
    end
end

function SoundManager:StopSound(name)
    if sounds[name] ~= nil then
        local data = sounds[name]
        if data.variants == -1 then
            if data.sound:isPlaying() then
                sounds[name].sound:stop()
            end
        else
            for i=0, data.variants do
                if data.sound[i] ~= nil and data.sound[i]:isPlaying() then
                    data.sound[i]:stop()
                end
            end
        end
    end
end

function SoundManager:StopSoundSmooth(name)
    if sounds[name] ~= nil then
        local data = sounds[name]
        if data.variants == -1 then
            if data.sound:isPlaying() then
                sounds[name].sound:setVolume(0, 0, 1)
            end
        else
            for i=0, data.variants do
                if data.sound[i] ~= nil and data.sound[i]:isPlaying() then
                    data.sound[i]:setVolume(0, 0, 1)
                end
            end
        end
    end
end

function SoundManager:PlaySound(name, vol, ignorecutscene)
    if UIIsnt and UIIsnt:IsCutscene() then
        if ignorecutscene == nil then
            if NoSoundsInCutscenes then
                return
            end
        end
    end
    local volume = 1
    if vol ~= nil then
        volume = vol
    end

    if name == "Push" then
        volume = 0.3
        --name = "PushShort"
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

