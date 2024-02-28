local pd <const> = playdate
local gfx <const> = pd.graphics

class("Activator").extends(gfx.sprite)

function Activator:init(x, y, group, timer, indicatorUID)
    if timer == nil then
        timer = 0
    end
    if indicatorUID == nil then
        indicatorUID = 0
    end
    self:moveTo(x, y)
    self:setZIndex(Z_Index.Object)
    self:setCenter(0, 0)
    self:setTag(TAG.Interactive)
    self:add() -- Add to draw list
    self.activegroup = {}
    self.activated = false
    self.IsButton = true
    self.CustomUpdate = nil
    self.timertime = timer
    self.timertimems = timer*1000
    self.timertimeleft = 0
    self.indicatorUID = indicatorUID
    self.indicator = nil
    self.lastindicatorframe = 21
    if self.timertime ~= 0 then
        self.timer = pd.timer.new(1000, function ()
            if self.timertimeleft > 0 then
                self.timertimeleft = self.timertimeleft-1
                if self.timertimeleft == 0 then
                    self.activated = false
                    if self.indicator then
                        SoundManager:PlaySound("Stop")
                    end
                else
                    self:TimerTick()
                end
            end
        end)
        self.timer.repeats = true
        self.timer:start()
    end

    if group and group ~= "" then
        if string.find(group, ",") then
            for g in string.gmatch(group, '([^,]+)') do
                table.insert(self.activegroup, g)
            end
        else
            table.insert(self.activegroup, group)
        end
    end

    ActiveManager.AddActivator(self)
end

function Activator:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

function Activator:TimerTick()
    SoundManager:PlaySound("Tick")
end

function Activator:PressButton()
    if self.timertime == 0 then
        if not self.activated then
            self.activated = true
            SoundManager:PlaySound("Button")
            print("[Activator] Activator triggered groups:")
            for i = 1, #self.activegroup, 1 do
                print(self.activegroup[i])
            end
        else
            SoundManager:PlaySound("No")
        end
    else
        if self.indicator == nil and self.timertimeleft > 0 then
            SoundManager:PlaySound("No")
            return
        end
        SoundManager:PlaySound("Button")
        self.timertimeleft = self.timertime
        self.activated = true
        if self.timer ~= nil then
            self.timer:reset()
            if self.timerprogress ~= nil then
                self.timerprogress:remove()
            end
            self.timerprogress = pd.timer.new(self.timertimems)
            self.timerprogress:start()
        end
        print("[Activator] Activator triggered groups:")
        for i = 1, #self.activegroup, 1 do
            print(self.activegroup[i])
        end
    end
end

function Activator:UpdateIndicator(indicatorframe)
    if self.indicator == nil then
        if self.indicatorUID ~= 0 then
            self.indicator = TrackableManager.GetByUID(self.indicatorUID)
            if self.indicator == nil then
                self.indicatorUID = 0
                return
            end
        else
            return
        end
    end
    if indicatorframe == 0 then
        indicatorframe = 21
    end
    self.indicator:setImage(self.indicator.imagetable:getImage(indicatorframe))
end

function Activator:update()
    if self.CustomUpdate ~= nil then
        self.CustomUpdate()
    end
    if self.timerprogress ~= nil then
        local indicatorframe = math.floor((self.timerprogress.timeLeft / self.timerprogress.duration * 21 )+0.5)
        if self.lastindicatorframe ~= indicatorframe then
            self.lastindicatorframe = indicatorframe
            self:UpdateIndicator(indicatorframe)
        end
    end
end