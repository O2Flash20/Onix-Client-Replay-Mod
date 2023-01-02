name = "Replay Mod"
description = "Record a section of your world/server, then watch it back later!"

importLib("logger")

function update()
    px, py, pz = player.position()

    -- scan 100 blocks
    for i = 1, 1000, 1 do
        coroutine.resume(co)
    end
end

-- function set(x, y, z)
--     client.execute("execute /setblock " .. x .. " " .. y .. " " .. z .. " air")
-- end
n = 1
function set(x, y, z)
    dimension.getBlock(x, y, z)
    n = n + 1
    log(n)
end

co = coroutine.create(function(...)
    for r = 1, 50, 1 do
        -- Z-axis
        for x = px - (r - 1), px + (r - 1) do
            for y = py - (r - 1), py + (r - 1) do
                for i = -1, 1, 2 do
                    set(x, y, pz + (r - 1) * i)
                    coroutine.yield()
                end
            end
        end

        -- X-axis
        for z = pz - (r - 2), pz + (r - 2) do
            for y = py - (r - 1), py + (r - 1) do
                for i = -1, 1, 2 do
                    set(px + (r - 1) * i, y, z)
                    coroutine.yield()
                end
            end
        end

        -- Y-axis
        for x = px - (r - 2), px + (r - 2) do
            for z = pz - (r - 2), pz + (r - 2) do
                for i = -1, 1, 2 do
                    set(x, py + (r - 1) * i, z)
                    coroutine.yield()
                end
            end
        end
    end
end)

--[[
    make height independant from x and z because there is usually less on the y-axis
    scan start: starts the initial world scan starting at the player's inital position, then starts the smaller scan following the player
    scan end: writes everything that has been stored into a file, formatted
    player position can be interpolated

    when a scan ends (r reaches the limit), coroutine.resume will make it scan again
]]

--[[
INITIAL SCAN, ALL ONE LINE
posX posY posZ blockId blockData
1000 100  0    12      2        , 1001 100 0 43 0, ...

THEN, EACH NEW LINE IS INFORMATION GATHERED IN ONE UPDATE CYCLE
block updates; player position; player inventory; other stuff (other players+their inventory, other entities)...
posX posY posZ blockId blockData                         playerX    playerY playerZ
1000 100  0    12      2        , 1001 100 0 43 0, ... ; 990.123123 98.3235 23.34432 ; inventory stuff idk
]]
