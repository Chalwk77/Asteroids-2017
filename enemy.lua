local enemy = { }

local hb = { }
local width, height

function enemy.load(game)

    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    hb[1] = game.images[9]
    hb[2] = game.images[10]
    hb[3] = game.images[11]
    hb[4] = game.images[12]
    hb[5] = game.images[13]
    hb[6] = game.images[14]
    hb[7] = game.images[15]
    hb[8] = game.images[16]
    hb[9] = game.images[17]
    hb[10] = game.images[18]
    hb[11] = game.images[19]
    hb[12] = game.images[20]
    hb[13] = game.images[21]
    hb[14] = game.images[22]
    hb[15] = game.images[23]
    hb[16] = game.images[24]
    hb[17] = game.images[25]

    enemyDestroy = love.audio.newSource(game.sounds.enemyDestroy)
    enemyDestroy:setVolume(.3)

    enemy.width = 64
    enemy.height = 64
    enemy.speed = 0
    enemy.friction = 15

end

function enemy.spawn(posX, posY)

    enemy.weapon = { }
    enemy.weapon.ready = 0
    enemy.weapon.bullets = { }
    enemy.weapon.bullets.posX = 0
    enemy.weapon.bullets.posY = 0

    if (difficulty == "Easy") then
        enemy.startX, enemy.startY = 4500,4500
        enemy.minSpeed, enemy.maxSpeed = 1000, 1200
        enemy.weapon.damage = 0.5
        enemy.weapon.speed = 1000
        enemy.weapon.minReloadTime, enemy.weapon.maxReloadTime = .70,3.5
    elseif (difficulty == "Medium") then
        enemy.startX, enemy.startY = 3500,3500
        enemy.minSpeed, enemy.maxSpeed = 1100, 1400
        enemy.weapon.damage = 1
        enemy.weapon.speed = 1100
        enemy.weapon.minReloadTime, enemy.weapon.maxReloadTime = .50,3.0
    elseif (difficulty == "Hard") then
        enemy.startX, enemy.startY = 2500,2500
        enemy.minSpeed, enemy.maxSpeed = 1150, 1600
        enemy.weapon.damage = 1.5
        enemy.weapon.speed = 1150
        enemy.weapon.minReloadTime, enemy.weapon.maxReloadTime = .30,2.8
    elseif (difficulty == "Super Hard") then
        enemy.startX, enemy.startY = 1500,1500
        enemy.minSpeed, enemy.maxSpeed = 1200, 1800
        enemy.weapon.damage = 2
        enemy.weapon.speed = 1300
        enemy.weapon.minReloadTime, enemy.weapon.maxReloadTime = .25,2.5
    end

    local randomX = math.random() * (width + 1000) - enemy.startX
    local randomY = math.random() * (height + 1000) - enemy.startY
    -- local randomX, randomY = width/2, height/2
    table.insert(enemy, {posX = randomX, posY = randomY, xvel = 0, yvel = 0, health = #hb, width = enemy.width, height = enemy.height, img = enemyImg, direction = 0})
end

function enemy.draw()
    local e = enemy[#enemy]

    -- Display Enemy Health Bar:
    local cur_health = e.health
    love.graphics.draw(hb[cur_health], e.posX - 50, e.posY + 10)
    local alien = love.graphics.draw(e.img, e.posX, e.posY, 0, 1, 1, 21, 36)

    -- Draw Bullets:
    local bullets = enemy.weapon.bullets
    for i = 1, #bullets do
        love.graphics.draw(enemy_bullet, bullets[i].posX, bullets[i].posY, 0, 1, 1, 4, 4)
    end
end

function enemy.physics(dt, spaceship)

    local maxSpeed = math.random(50, 150)
    local multiplier = math.random() * 2 * maxSpeed - maxSpeed

    local e = enemy[#enemy]
    e.posX = e.posX + (e.xvel + multiplier) * dt
    e.posY = e.posY + (e.yvel + multiplier) * dt

    e.xvel = e.xvel * (1 - math.min(dt*enemy.friction, 1))
    e.yvel = e.yvel * (1 - math.min(dt*enemy.friction, 1))
end

function enemy.AI(dt, spaceship)
    local e = enemy[#enemy]

    enemy.speed = math.random(enemy.minSpeed, enemy.maxSpeed)

    -- X axis
    if (spaceship.posX + spaceship.width / 2 < e.posX + e.width / 2) then
        if (e.xvel > -enemy.speed) then
            e.xvel = e.xvel - enemy.speed * dt
        end
    end
    if (spaceship.posX + spaceship.width / 2 > e.posX + e.width / 2) then
        if (e.xvel < enemy.speed) then
            e.xvel = e.xvel + enemy.speed * dt
        end
    end
    -- Y axis
    if (spaceship.posY + spaceship.height / 2 < e.posY + e.height / 2) then
        if (e.yvel > -enemy.speed) then
            e.yvel = e.yvel -enemy.speed * dt
        end
    end
    if (spaceship.posY + spaceship.height / 2 > e.posY + e.height / 2) then
        if (e.yvel < enemy.speed) then
            e.yvel = e.yvel + enemy.speed * dt
        end
    end
end

function enemy.update(dt, spaceship, spaceship_weapon)

    enemy.physics(dt, spaceship)
    enemy.AI(dt, spaceship)

    local sBullets = spaceship_weapon

    local w = enemy.weapon
    if (w.ready > 0) then
        w.ready = w.ready - dt
    end

    if (w.ready <= 0) then
        w.ready = love.math.random(w.minReloadTime, w.maxReloadTime)
        table.insert(w.bullets, {})

        local e = enemy[#enemy]
        local dir = math.atan2(( spaceship.posY - e.posY ), ( spaceship.posX - e.posX ))
        local dx, dy = w.speed * math.cos(dir), w.speed * math.sin(dir)

        w.bullets[#w.bullets].posX = (e.posX + math.sin(dir))
        w.bullets[#w.bullets].posY = (e.posY - math.cos(dir))
        w.bullets[#w.bullets].velX = dx
        w.bullets[#w.bullets].velY = dy
    end

    local collision_with_enemy = checkCollision(spaceship, enemy[#enemy], 64)

    if (collision_with_enemy) then
        if not spaceship.shipCollision:isPlaying() then
            spaceship.health = spaceship.health - 1
            love.audio.play(spaceship.shipCollision)
        end
    end

    local bullets = w.bullets
    for i = #bullets, 1, -1 do
        local delete = moveObject(bullets[i], dt, 0, width, height)
        local bullet_collision = checkCollision(bullets[i], spaceship, 32)
        if (delete) then
            table.remove(bullets, i)
        elseif (bullet_collision) then
            spaceship.health = spaceship.health - 1
            table.remove(w.bullets, i)
            if not enemyDestroy:isPlaying() then
                enemyDestroy:play()
            elseif not enemyDestroy:isPlaying() then
                enemyDestroy:play()
            end
        end
    end

    -- Check for collision between bullet and enemies:
    for i = #sBullets, 1, -1 do
        local bullet_collision = checkCollision(sBullets[i], enemy[#enemy], 24)
        if (bullet_collision) then
            table.remove(sBullets, i)
            if not enemyDestroy:isPlaying() then
                enemyDestroy:play()
            elseif not enemyDestroy:isPlaying() then
                enemyDestroy:play()
            end
            local e = enemy[#enemy]
            e.health = e.health - 2
            if (e.health <= 0) then
                table.remove(enemy, _)
                enemy.spawn(500,300)
                displayScore = displayScore + math.floor(50)
            end
            break
        end
    end
end

return enemy
