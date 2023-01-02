name = "Replay Mod"
description = "Record a section of your world/server, then watch it back later!"



-- This is how I'll get it to scan in a radius starting from the player
-- Thanks ChatGPT 🙂

-- Assuming that the 3D array is called arr and its dimensions are all odd

-- Calculate the center indices
local center_x = math.floor(#arr / 2) + 1
local center_y = math.floor(#arr[1] / 2) + 1
local center_z = math.floor(#arr[1][1] / 2) + 1

-- Loop through all elements in a spiral pattern, starting from the center
for r = 1, math.floor(#arr / 2) do
    -- Go right
    for x = center_x - r + 1, center_x + r - 1 do
        -- Do something with the element arr[x][center_y][center_z]
    end
    -- Go up
    for y = center_y - r + 1, center_y + r - 1 do
        -- Do something with the element arr[center_x + r - 1][y][center_z]
    end
    -- Go left
    for x = center_x + r - 1, center_x - r, -1 do
        -- Do something with the element arr[x][center_y][center_z]
    end
    -- Go down
    for y = center_y + r - 1, center_y - r, -1 do
        -- Do something with the element arr[center_x - r + 1][y][center_z]
    end
    -- Go back
    for z = center_z - r + 1, center_z + r - 1 do
        -- Do something with the element arr[center_x][center_y][z]
    end
end
