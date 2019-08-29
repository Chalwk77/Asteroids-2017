local playingState = { }
local enemy = require 'enemy'

-- Game Tables:
local buttons = { }
local spaceship, satellite, asteroids, stars = { }, { }, { }, { }
local weapon, gameover, life, lives = { }, { }, { }, { }

local control_inputs = { }
control_inputs[1] = {"a", "left"} -- Turn Left
control_inputs[2] = {"d", "right"} -- Turn Right
control_inputs[3] = {"w", "up"} -- Boost
control_inputs[4] = {"space", "return"} -- Fire

-- Game Variables:
local ww, wh
local fullscreen_width, fullscreen_height
local width, height

local moon
local timeLimit
local aboutMsg
local displayHighScore
displayScore = 0
local dismenuColor, normalColor
local useFontScore, useMessages, aboutMsgFont
local numAsteroids
local start_health = 10

local button_click
local button_height, button_font = 64, nil

local trans, shakeDuration, shakeMagnitude = 0, -1, 0

-- Local Functions:
local function centerText(str, strW, font)
    return {
        w = ww/2,
        h = wh/2,
        strW = math.floor(strW/2),
        fontH = math.floor(font:getHeight()/2),
    }
end

------------------------------------------------------------------------------------------------------------
function playingState.start(game)
    ww, wh = love.graphics.getDimensions()
    fullscreen_width, fullscreen_height = love.window.getDesktopDimensions()

    -- Get window Dimentions:
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    local function positionGraphic(image, X, Y)
        local x = math.floor(ww/2) - math.floor(image:getWidth()/2)
        local y = math.floor(wh/2) - math.floor(image:getHeight()/2)
        return {
            image = image,
            posX = (ww - X),
            posY = Y,
            changeRotation = false,
            rotation = 0,
            rotationAmount = 0.001
        }
    end

    -- Create Star Field:
    -- X,Y coordinates are limited to the screen size, minus 5 pixels of padding.
    local max_stars = 1500
    for i = 1, max_stars do
        local x = love.math.random(5, ww - 5)
        local y = love.math.random(5, wh - 5)
        stars[i] = { x, y }
    end

    game_started, timeLimit, displayScore = 0, 0, 0
    displayHighScore = "High Score: " .. highScore(0)
    aboutMsg = "An adaptation of the Classic 1979 Arcade game Asteroids by Atari, Inc.\nCopyright (c) 2019, Jericho Crosby <jericho.crosby227@gmail.com>"

    -- Time and Score color:
    dismenuColor = { 120, 0, 0, 255 }
    normalColor = { 255, 255, 255, 255 } -- white

    -- load fonts:
    useFontScore = game.fonts[1]
    useMessages = game.fonts[2]
    button_font = game.fonts[3]
    title_font = game.fonts[6]
    aboutMsgFont = game.fonts[5]

    -- Play background music:
    love.audio.play(game.sounds.ambient)
    game.sounds.ambient:setLooping(true)
    game.sounds.ambient:setVolume(.25)

    -- Make sounds quieter as they move away from centre of screen.
    love.audio.setPosition(ww / 2, wh / 2, 0)
    love.audio.setDistanceModel("exponent")
    ---------------------------------------------------------------

    -- Set moon position:
    moon = positionGraphic(game.images[1], 250, 50)

    -- Create initial asteroid:
    numAsteroids = 0
    asteroid = game.images[2]
    addAsteroids(16, nil, nil, 1.5, 1)

    -- load a picture of a bullet:
    bullet = game.images[3]
    enemy_bullet = game.images[4]

    enemy.load(game)

    -- Load Asteroid explosion sound:
    asteroidExplosion = love.audio.newSource(game.sounds.asteroid_explosion)
    asteroidExplosion:setVolume(.5)

    -- Create Satellite that drifts by:
    satellite.image = game.images[5]
    satellite.posX = love.math.random() * (width + 1000) - 4500
    satellite.posY = love.math.random() * (height + 1000) - 4500

    satellite.velX = love.math.random(20,25)
    satellite.velY = love.math.random(10,20)
    satellite.changeRotation = false
    satellite.rotation = 0
    satellite.rotationAmount = 0.001

    -- Satellite beeping sound:
    satellite.sound = love.audio.newSource(game.sounds.satellite_beep)
    satellite.sound:setVolume(1)
    satellite.sound:setLooping(true)
    satellite.sound:setAttenuationDistances(100, 500)
    satellite.sound:play()

    -- Preload Enemy Image:
    enemyImg = game.images[6]

    -- Create Spaceship (player):
    spaceship.coasting = game.images[7]
    spaceship.boosting = game.images[8]
    spaceship.useImage = "coasting"
    spaceship.posX = ww / 2
    spaceship.posY = wh / 2
    spaceship.direction = 0
    spaceship.health = start_health
    spaceship.acceleration = 250
    spaceship.turnSpeed = 3.5
    spaceship.velX = 0
    spaceship.velY = 0

    -- Load Spaceship sounds:
    spaceship.sound = love.audio.newSource(game.sounds.boost)
    spaceship.shipCollision = love.audio.newSource(game.sounds.shipCollision)
    spaceship.sound:setVolume(.5)

    -- Define Weapon:
    weapon.sound = love.audio.newSource(game.sounds.shoot)
    weapon.sound:setVolume(.3)
    weapon.sound:setLooping(false)
    weapon.reloadTime = .25
    weapon.speed = 1000
    weapon.ready = 0
    weapon.bullets = {}

    ------------------ CREATE MENU BUTTONS ------------------
    local function newButton(text, fn)
        return {
            text = text,
            fn = fn,
            now = false,
            last = false,
        }
    end

    button_click = love.audio.newSource(game.sounds.button_click)
    table.insert(buttons, newButton(
        "Easy",
        function()
            life.max = 3
            timeLimit = 180
            numAsteroids = 16
            difficulty = "Easy"
            StartGame()
        end)
    )
    table.insert(buttons, newButton(
        "Medium",
        function()
            life.max = 2
            timeLimit = 120
            numAsteroids = 24
            difficulty = "Medium"
            StartGame()
        end)
    )
    table.insert(buttons, newButton(
        "Hard",
        function()
            life.max = 1
            timeLimit = 60
            numAsteroids = 32
            difficulty = "Hard"
            StartGame()
        end)
    )
    table.insert(buttons, newButton(
        "Super Hard",
        function()
            life.max = 1
            timeLimit = 60
            numAsteroids = 64
            difficulty = "Super Hard"
            StartGame()
        end)
    )
    table.insert(buttons, newButton(
        "Exit",
        function()
            love.event.quit(0)
        end)
    )
end

local timer = 0
local SX, SY = 0,0

function playingState.draw(dt)

    -- Render star field and Moon:
    love.graphics.setColor(1, 1, 1, 1)
    for _, star in ipairs(stars) do
        love.graphics.points(star[1], star[2])
    end

    love.graphics.draw(moon.image, moon.posX, moon.posY, moon.rotation)

    -- Game hasn't started yet (viewing main menu)
    if (game_started == 0) then
        RenderMenuButtons()

        -- About Message:
        love.graphics.setFont(aboutMsgFont)
        love.graphics.setColor(normalColor)

        local strwidth = aboutMsgFont:getWidth(aboutMsg)
        local t = centerText(aboutMsg, strwidth, aboutMsgFont)
        love.graphics.print(aboutMsg, t.w, t.h + 350, 0, 1, 1, t.strW, t.fontH)
        --

        -- Display Previous High Score
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(useMessages)
        love.graphics.print(displayHighScore, ww / 2 - useMessages:getWidth(displayHighScore) / 2 + 300, 5)
        --

        -- Display Game Title
        love.graphics.setColor(normalColor)
        love.graphics.setFont(title_font)
        love.graphics.printf("Asteroids 2019\n   The Game", 0, 5, 800, "center")
        --

    elseif (game_started == 1) then -- Playing the Game!
        enemy.draw()

        if (trans < shakeDuration) then
            local dx = love.math.random(-shakeMagnitude, shakeMagnitude)
            local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
            love.graphics.translate(dx, dy)
        end

        -- Display time left and score:
        love.graphics.setFont(useFontScore)
        love.graphics.setColor(dismenuColor)
        love.graphics.print(math.floor(timeLimit), 10, 0)
        love.graphics.print(math.floor(displayScore), 10, 80)

        -- Display Health Bar:
        love.graphics.rectangle("fill", 15, 10, math.floor(spaceship.health * 205 / 5), 20)
        love.graphics.rectangle("line", 15, 10, math.floor(start_health * 205 / 5), 20)
        love.graphics.setColor(normalColor)

        -- Draw Spaceship!
        love.graphics.draw(spaceship[spaceship.useImage], spaceship.posX, spaceship.posY, spaceship.direction, 1, 1, 21, 36)

        -- Display Lives:
        for _,l in pairs(lives) do
            love.graphics.draw(l.img, l.x, l.y, l.r, l.sx, l.sy, l.ox, l.oy)
        end

        -- Display Lives message:
        love.graphics.setFont(button_font)

        local Lx = lives[#lives].x
        local Ly = lives[#lives].y

        love.graphics.printf(life.text, 495, Ly, Lx, "center")
    end

    -- Draw Asteroids (regardless of game mode)
    for i = 1, #asteroids do
        love.graphics.draw(asteroid, asteroids[i].posX, asteroids[i].posY, 0, asteroids[i].size, asteroids[i].size, 72, 72)
    end

    for i = 1, #weapon.bullets do
        --draw bullets regardless of game mode
        love.graphics.draw(bullet, weapon.bullets[i].posX, weapon.bullets[i].posY, 0, 1, 1, 4, 4)
    end

    --always draw satellite
    love.graphics.draw(satellite.image, satellite.posX, satellite.posY, satellite.rotation)

end

function playingState.update(dt)

    -- Update Spaceship and Satellite positions:
    moveObject(spaceship, dt, 45, ww, wh)
    moveObject(satellite, dt, 500, ww, wh)

    if (moon.changeRotation) then
        moon.rotation = moon.rotation + moon.rotationAmount
    end

    --moveObject(spaceship, dt, 45, width, height)
    --moveObject(satellite, dt, 500, width, height)

    --Tell sound engine where satellite is so beep can change volume:
    satellite.sound:setPosition(satellite.posX, satellite.posY, 0)
    love.graphics.draw(satellite.image, satellite.posX, satellite.posY, satellite.rotation)

    -- Move bullets - When they reach the edge of the screen, delete them:
    for i = #weapon.bullets, 1, -1 do
        flagDelete = moveObject(weapon.bullets[i], dt, 0, ww, wh)
        --flagDelete = moveObject(weapon.bullets[i], dt, 0, width, height)
        if flagDelete then
            -- Moved off edge of screen so delete the bullet:
            table.remove(weapon.bullets, i)
        end
    end

    -- Move Asteroids - Wrap their position when they go more than 500 pixels past the screen:
    for i = #asteroids, 1, -1 do
        moveObject(asteroids[i], dt, 500, ww, wh)
        --moveObject(asteroids[i], dt, 500, width, height)
    end

    -- Game in progress:
    if (game_started == 1) then
        controlSpaceship(dt)
        controlWeapons(dt)
        enemy.update(dt, spaceship, weapon.bullets)

        if (trans < shakeDuration) then
            trans = trans + dt
        end

        local function endGame()
            game_started = 0
            -- Compare the current "displayScore" to the saved highscore and update the display message:
            displayHighScore = "High Score: " .. highScore(displayScore)
            destroyExistingAsteroids()

            --love.audio.play(gameover.sound)
            for _,v in ipairs(enemy) do
                if (v.posX) then
                    table.remove(enemy, _)
                end
            end
        end

        -- End the game when the timer expires:
        if (math.floor(timeLimit) == 0) then
            endGame()
        elseif (spaceship.health == 0)  then
            if (#lives > 0) then
                -- Remove life
                table.remove(lives, #lives)
                spaceship.health = start_health

                if (#lives <= 0) then
                    endGame()
                end
            end
        end

        -- Check for collisions between an asteroid and the spaceship.
        -- Iterate through the list of asteroids backwards.
        -- If go forwards we stand to miss an asteroid if we delete the current.
        for i = #asteroids, 1, -1 do
            local flagCollide = checkCollision(spaceship, asteroids[i], 21 + 72 * asteroids[i].size)
            if (flagCollide) then
                if not spaceship.shipCollision:isPlaying() then
                    spaceship.health = spaceship.health - 1
                    love.audio.play(spaceship.shipCollision)
                    cameraShake(0.6, 2.5)
                end
            end
        end

        local satelliteCollision = checkCollision(spaceship, satellite, 32)
        if (satelliteCollision) then
            if not spaceship.shipCollision:isPlaying() then
                spaceship.health = spaceship.health - 1
                love.audio.play(spaceship.shipCollision)
            end
        end

        -- Check for collision between bullet and asteroids
        -- Check each bullet against each asteroid
        for i = #weapon.bullets, 1, -1 do
            for j = #asteroids, 1, -1 do
                -- The collision threshold distance is half a bullet width + half an asteroid width:
                local flagCollide = checkCollision(weapon.bullets[i], asteroids[j], 4 + 72 * asteroids[j].size)
                if (flagCollide) then

                    -- a bullet hit an asteroid
                    -- destroy the bullet
                    -- destroy the asteroid if size is < .5
                    -- split the asteroid into 2 if size is between .5 and .75
                    -- split the asteroid into 3 if size is between .75 and 1.0

                    -- update the score. Small asteroids give more points
                    displayScore = displayScore + math.floor(5 / asteroids[j].size)

                    if asteroids[j].size < 0.5 then
                        --nothing to do
                    elseif asteroids[j].size < 0.75 then
                        --add two new smaller asteroids where current asteroid is
                        --speed range is twice as fast as normal
                        addAsteroids(2, asteroids[j].posX, asteroids[j].posY, 0.5, 2)

                    elseif asteroids[j].size <= 1 then
                        --add two new smaller asteroids where current asteroid is
                        --speed range is twice as fast as normal
                        addAsteroids(3, asteroids[j].posX, asteroids[j].posY, 0.5, 2)
                    else
                        --add four new smaller asteroids where current asteroid is
                        --speed range is twice as fast as normal
                        addAsteroids(4, asteroids[j].posX, asteroids[j].posY, 0.5, 2)
                    end

                    --remove original asteroid
                    table.remove(asteroids, j)

                    --because asteroid explosions can overlap we'll use two samples
                    -- if either is free play an explosion
                    if not asteroidExplosion:isPlaying() then
                        asteroidExplosion:play()
                    elseif not asteroidExplosion:isPlaying() then
                        asteroidExplosion:play()
                    end
                    --stop checking for asteroid collisions with this bullet
                    --since we're going to destroy it in a moment
                    break
                end
            end

            if (flagCollide) then
                table.remove(weapon.bullets, i)
                break
            end

        end
    end

    if (game_started == 1) then
        -- If the number of asteroids is below the number specified
        -- by the difficulty level, make some more.
        if (#asteroids < numAsteroids) then
            -- If "posX" and "posY" are set as nil, the function will randomly generate a position.
            addAsteroids(numAsteroids - #asteroids, nil, nil, 1, 1)
        end
        timeLimit = timeLimit - dt
    end
end

function playingState.keypressed(key)
    if (key == 'escape') then
        love.event.quit(0)
    end
end

function StartGame()

    -- Create initial asteroids:
    destroyExistingAsteroids()
    addAsteroids(numAsteroids, nil, nil, 1.5, 1)

    spaceship.posX = ww / 2
    spaceship.posY = wh / 2

    spaceship.velX = 0
    spaceship.velY = 0
    spaceship.health = start_health
    spaceship.width = 12
    spaceship.height = 12
    displayScore = 0

    life.img = spaceship.coasting
    life.posX = ww - 50
    life.posY = wh - 50
    life.scaleX = 0.5
    life.scaleY = 0.5
    life.offsetY = 21
    life.offsetX = 36
    life.spacing = 5
    life.text = "Lives: "

    for i = 1,life.max do
        local imgSize = life.img:getWidth()
        life.spacing = life.spacing - imgSize
        lives[#lives + 1] = {
            img = life.img,
            -- The position to draw the object (x-axis).
            x = life.posX + life.spacing,
            -- The position to draw the object (y-axis).
            y = life.posY,
            -- Orientation (radians)
            r = 0,
            -- Scale Factor (x-axis)
            sx = life.scaleX,
            -- Scale Factor (y-axis)
            sy = life.scaleY,

            -- Origin offset (x-axis)
            ox = life.offsetX,
            -- Origin offset (y-axis)
            oy = life.offsetY,
        }
    end

    game_started = 1
end

function moveObject(spaceObject, dt, borderWidth, width, height)
    -- Move an Object according to its velX and velY
    -- If the object reaches 'borderWidth' past the edge of the screen, wrap it around to the opposite side.

    -- Function returns true if object was wrapped - False if not.
    returnValue = false

    -- Translate Object:
    spaceObject.posX = spaceObject.posX + spaceObject.velX * dt
    spaceObject.posY = spaceObject.posY + spaceObject.velY * dt

    if (spaceObject.changeRotation) then
        spaceObject.rotation = spaceObject.rotation + spaceObject.rotationAmount
    end

    -- Wrap the object from one side of the screen to the other:
    if (spaceObject.posX > width + borderWidth) then
        returnValue = true
        spaceObject.posX = -borderWidth
    elseif (spaceObject.posX < -borderWidth) then
        spaceObject.posX = width + borderWidth
        returnValue = true
    end

    if (spaceObject.posY > height + borderWidth) then
        spaceObject.posY = -borderWidth
        returnValue = true
    elseif (spaceObject.posY < -borderWidth) then
        spaceObject.posY = height + borderWidth
        returnValue = true
    end

    return returnValue
end

function controlWeapons(dt)
    --fire the weapon if 'space' is hit and it's reloaded
    if weapon.ready > 0 then
        --when weapon.ready reaches zero, it's ready to fire
        weapon.ready = weapon.ready - dt
    end

    if love.keyboard.isDown(control_inputs[4]) then
        if weapon.ready <= 0 then
            --play the firing sound
            if not weapon.sound:isPlaying() then
                weapon.sound:play()
            end

            --set the relod time for the next shot
            weapon.ready = weapon.reloadTime

            --create a bullet
            table.insert(weapon.bullets, {})
            --position if near the nose of the ship
            --move in the same direction the ship is pointing

            --some trigonometry magic
            weapon.bullets[#weapon.bullets].posX = spaceship.posX + math.sin(spaceship.direction) * 35
            weapon.bullets[#weapon.bullets].posY = spaceship.posY - math.cos(spaceship.direction) * 35
            weapon.bullets[#weapon.bullets].velX = math.sin(spaceship.direction) * weapon.speed
            weapon.bullets[#weapon.bullets].velY = -math.cos(spaceship.direction) * weapon.speed
        end
    end
end

function controlSpaceship(dt)
    --turn the ship CCW
    if love.keyboard.isDown(control_inputs[1]) then
        spaceship.direction = spaceship.direction - spaceship.turnSpeed * dt
    end

    -- Turn the ship CW
    if love.keyboard.isDown(control_inputs[2]) then
        spaceship.direction = spaceship.direction + spaceship.turnSpeed * dt
    end

    -- Boost spaceship:
    if love.keyboard.isDown(control_inputs[3]) then
        if not spaceship.sound:isPlaying() then
            spaceship.sound:play()
        end

        spaceship.velX = spaceship.velX + math.sin(spaceship.direction) * spaceship.acceleration * dt
        spaceship.velY = spaceship.velY + math.cos(spaceship.direction) * -spaceship.acceleration * dt

        spaceship.useImage = "boosting"
    else
        if spaceship.sound:isPlaying() then
            spaceship.sound:stop()
        end
        spaceship.useImage = "coasting"
    end
end

function RenderMenuButtons()

    local button_width = ww * (1 / 3)

    local margin = 16
    local total_height = (button_height + margin) * #buttons
    local cursor_y = 0

    for _, button in ipairs(buttons) do
        button.last = button.now

        local bx = (ww * 0.5) - (button_width * 0.5)
        local by = (wh * 0.5) - (total_height * 0.5) + cursor_y

        local button_alpha = 0.5

        local color = { 0.4, 0.4, 0.5, button_alpha }
        local mx, my = love.mouse.getPosition()

        local hovering = mx > bx and mx < bx + button_width and
                my > by and my < by + button_height

        if (hovering) then
            if (button.text == "Easy") then
                color = { 0 / 255, 255 / 255, 0 / 255, button_alpha }
            elseif (button.text == "Medium") then
                color = { 180 / 255, 255 / 255, 0 / 255, button_alpha }
            elseif (button.text == "Hard") then
                color = { 290 / 255, 255 / 255, 0 / 255, button_alpha }
            elseif (button.text == "Super Hard") then
                color = { 255 / 255, 0 / 255, 0 / 255, button_alpha }
            elseif (button.text == "Exit") then
                color = { 255, 0 / 255, 0 / 255, button_alpha }
            end
        end

        button.now = love.mouse.isDown(1)
        if (button.now and not button.last and hovering) then

            -- Play click sound:
            if (button.text ~= "Exit") and not button_click:isPlaying() then
                button_click:play()
            end

            button.fn()
            enemy.spawn(0,0)
        end

        love.graphics.setColor(unpack(color))
        love.graphics.rectangle(
            "fill",
            bx,
            by,
            button_width,
            button_height
        )

        local textW = button_font:getWidth(button.text)
        local textH = button_font:getHeight(button.text)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(
                button.text,
                button_font,
                (ww * 0.5) - textW * 0.5,
                by + textH * 0.5
        )
        cursor_y = cursor_y + (button_height + margin)
    end
end

function checkCollision(obj1, obj2, minDist)
    -- Using pythagean thereom to calculate the distance between the two objects
    -- distance = SquareRoot(Square(X2 - X1) + Square(Y2 - Y1))
    local dist = math.sqrt((obj1.posX - obj2.posX) ^ 2 + (obj1.posY - obj2.posY) ^ 2)
    if (dist ~= nil) and (dist <= minDist) then
        return true
    else
        return false
    end
end

function destroyExistingAsteroids()
    for i = #asteroids, 1, -1 do
        table.remove(asteroids, i)
    end
end

function addAsteroids(num, posX, posY, maxSize, speedMult)
    -- Add a number of asteroids.

    -- If "posX" or "posY" are nil then randomly generate off screen positions
    -- otherwise use the supplied position.

    -- The size of the new asteroid(s) will be between 0.2 and maxSize.
    -- The speed of the asteroids will be between +/- maxSpeed.
    -- "speedMult" can be used to boost the speed of new asteroids.

    for i = 1, num do
        local maxSpeed = math.random(50, 150)
        table.insert(asteroids, {})
        asteroids[#asteroids].size = math.random() * (maxSize - 0.2) + 0.2
        if (posX == nil or posY == nil) then
            asteroids[#asteroids].posX = math.random() * (ww + 1000) - 500
            asteroids[#asteroids].posY = math.random() * (wh + 1000) - 500
            -- Random positioned asteroids should appear in the middle of the screen so
            -- shift them off screen...
            if asteroids[#asteroids].posX > 0 and asteroids[#asteroids].posX < ww then
                asteroids[#asteroids].posX = asteroids[#asteroids].posX + ww
            end
        else
            asteroids[#asteroids].posX = posX
            asteroids[#asteroids].posY = posY
        end

        asteroids[#asteroids].velX = (math.random() * 2 * maxSpeed - maxSpeed) * speedMult
        asteroids[#asteroids].velY = (math.random() * 2 * maxSpeed - maxSpeed) * speedMult
    end
end

function highScore(newScore)

    local saveFile = "highscore.txt"
    local saveDir = love.filesystem.getInfo(saveFile)
    if saveDir then
        localHighScore = love.filesystem.read(saveFile)
        localHighScore = tonumber(localHighScore)
    else
        localHighScore = 0
    end

    if (newScore > localHighScore) then
        localHighScore = newScore
    end

    love.filesystem.write(saveFile, localHighScore)
    return localHighScore
end

function cameraShake(duration, magnitude)
    trans, shakeDuration, shakeMagnitude = 0, duration or 1, magnitude or 5
end

return playingState
