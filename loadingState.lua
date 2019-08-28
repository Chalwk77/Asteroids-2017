local loader = require 'love-loader'
local loadingState = {}

-- Game Variables:
local ww, wh = love.graphics.getDimensions()

local function drawLoadingBar()
    local separation = 30
    local w = ww - 2*separation
    local h = 20
    local x,y = separation, wh - separation - h

    local posX, posY = 250, 180
    love.graphics.setColor(105,105,105, 1)
    love.graphics.rectangle("line", x + posX, y + posY, w, h)

    x, y = x + 3, y + 3
    w, h = w - 6, h - 7

    -- Increment Loadbar Percentage:
    if (loader.loadedCount > 0) then
        w = w * (loader.loadedCount / loader.resourceCount)

        local font = love.graphics.newFont("fonts/arial.ttf", 20)
        love.graphics.setFont(font)

        local percent_complete = math.floor(100 * loader.loadedCount / loader.resourceCount)
        local width = love.graphics.getWidth()

        local percent = 0
        if (loader.resourceCount ~= 0) then
            percent = loader.loadedCount / loader.resourceCount
        end
        love.graphics.printf(("Loading ... %d%%"):format(percent * 100), 0, y + 150, width, "center")
    end

    love.graphics.setColor(47,79,79, 1)
    love.graphics.rectangle("fill", x + posX, y + posY, w, h)
end

function loadingState.start(game, finishCallback)
    print("Assets are loading...")

    math.randomseed(os.time())

    -- Preload Static Images:
    loader.newImage(game.images, 1, 'media/images/moon.png')
    loader.newImage(game.images, 2, 'media/images/asteroid.png')
    loader.newImage(game.images, 3, 'media/images/bullet.png')
    loader.newImage(game.images, 4, 'media/images/Enemy/enemy_bullet.png')
    loader.newImage(game.images, 5, 'media/images/satellite.png')
    loader.newImage(game.images, 6, 'media/images/Enemy/alien_spaceship.png')
    loader.newImage(game.images, 7, 'media/images/spaceship.png')
    loader.newImage(game.images, 8, 'media/images/spaceship_flames.png')

    for i = 9,25 do
        local n = (i - 8)
        loader.newImage(game.images, i, 'media/images/Enemy/healthbar_' .. n .. '.png')
    end

    -- Preload Audio Files:
    loader.newSource(game.sounds, 'ambient', 'media/sounds/ambient.wav', 'stream')
    loader.newSoundData(game.sounds, 'button_click', 'media/sounds/button_click.mp3')
    loader.newSoundData(game.sounds, 'satellite_beep', 'media/sounds/beep.mp3')
    loader.newSoundData(game.sounds, 'asteroid_explosion', 'media/sounds/asteroidExplosion.mp3')
    loader.newSoundData(game.sounds, 'boost', 'media/sounds/boost.mp3')
    loader.newSoundData(game.sounds, 'shipCollision', 'media/sounds/shipCollision.mp3')
    loader.newSoundData(game.sounds, 'shoot', 'media/sounds/shoot.mp3')
    loader.newSoundData(game.sounds, 'enemyDestroy', 'media/sounds/enemyDestroy.mp3')

    -- Preload Fonts:
    loader.newFont(game.fonts, 1, 'fonts/CONFCRG_.ttf', 120)
    loader.newFont(game.fonts, 2, 'fonts/arial.ttf', 20)
    loader.newFont(game.fonts, 3, 'fonts/CONFCRG_.ttf', 32)
    loader.newFont(game.fonts, 4, 'fonts/font.ttf', 128)
    loader.newFont(game.fonts, 5, 'fonts/arial.ttf', 14)
    loader.newFont(game.fonts, 6, 'fonts/vector_battle.ttf', 64) -- Title Font

    loader.start(finishCallback, print)
end

function loadingState.draw()
    drawLoadingBar()
end

function loadingState.update(dt)
    loader.update()
end

return loadingState
