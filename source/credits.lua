local pd <const> = playdate
local gfx <const> = pd.graphics
class('Credits').extends(playdate.graphics.sprite)
function Credits:init()
    print("[Credits] Init...")
    self.screamplease = false
    self.bg = gfx.sprite.new()
    self.bg:setCenter(0, 0)
    self.bg:moveTo(0, 0)
    self.bg:setZIndex(Z_Index.BG)
    self.bg:setImage(AssetsLoader.LoadImage("images/UI/UndercreditsBG"))
    self.bg:add()

    self.battlefield = gfx.sprite.new()
    self.battlefield:setCenter(0, 0)
    self.battlefield:moveTo(42, 92)
    self.battlefield:setZIndex(Z_Index.BG)
    self.battlefield:setImage(AssetsLoader.LoadImage("images/UI/UndercreditsBattlefield"))
    self.battlefield:add()

    self.enemy = gfx.sprite.new()
    self.enemy:setCenter(0, 0)
    self.enemy:moveTo(146, 0)
    self.enemy:setZIndex(Z_Index.TotalBumer)
    self.enemy:setImage(AssetsLoader.LoadImage("images/UI/UndercreditsEnemy"))
    self.enemy:add()

    self.wait = pd.frameTimer.new(7)
	self.wait.timerEndedCallback = function(timer)
        self.crash = gfx.sprite.new()
        self.crash:setCenter(0, 0)
        self.crash:moveTo(0, 0)
        self.crash:setZIndex(Z_Index.AllAtop)
        self.crash:setImage(AssetsLoader.LoadImage("images/UI/crashmipa"))
        self.crash:add()
        self.screamplease = true
        playdate.sound.micinput.startListening()
	end
	self.wait:start()
    
    return self
end

function Credits:Update()
    if self.screamplease then
        if playdate.sound.micinput.getLevel() > 0.4 then
            playdate.sound.micinput.stopListening()
            NextLevel = "menu"
            StartGame()
        end
    end
end