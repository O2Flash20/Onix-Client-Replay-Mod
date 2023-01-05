name = "Replay Mod"
description = "Record a section of your world/server, then watch it back later!"

workingDir = "RoamingState/OnixClient/Scripts/Data/ReplayMod"

importLib("logger")

-- SETTINGS --------------------------------------------
status = "Waiting to record."
recording = false
function startRecording()
    recording = true
    startRecordingButton.visible = false
    endRecordingButton.visible = true
    status = "Recording..."

    centerX = math.floor(px)
    centerY = math.floor(py)
    centerZ = math.floor(pz)

    fs.delete(fileName.value .. ".replay")
    saveFile = fs.open(fileName.value .. ".replay", 'w')

    saveFile:seek(5)
end

updatesFile = nil
saveFile = nil

function endRecording()
    recording = false
    startRecordingButton.visible = true
    endRecordingButton.visible = false
    status = "Waiting to record."

    saveFile:seek(0)
    -- packet Id
    saveFile:writeByte(1)
    -- Number of  blocks to update
    saveFile:writeUInt(blocksSaved)

    saveFile:close()
end

client.settings.addTitle("status")
startRecordingButton = client.settings.addFunction("Start Recording:", "startRecording", "Start")
endRecordingButton = client.settings.addFunction("End Recording", "endRecording", "Save")
endRecordingButton.visible = false
fileName = client.settings.addNamelessTextbox("Save file name:", "Untitled")

function test()
    -- making a file of the initial scan that is readable
    local input = fs.open(fileName.value .. ".replay", 'r')
    local output = io.open("text.txt", "w+")
    if input and output then
        output:write(input:readByte())
        local numBlocks = input:readUInt()
        output:write("\n")
        output:write(numBlocks)
        output:write("\n")
        for i = 1, numBlocks, 1 do
            output:write(input:readInt())
            output:write(" ")
            output:write(input:readInt())
            output:write(" ")
            output:write(input:readInt())
            output:write(" ")
            output:write(input:readUShort())
            output:write(" ")
            output:write(input:readByte())
            output:write("\n")
        end
        output:close()
    end
end

client.settings.addFunction("Test Button", "test", "Enter")

------------------------------------------------------------

initialBlocksScannedPerUpdate = 10000
function update()
    px, py, pz = player.pposition()
    pYaw, pPitch = player.rotation()

    -- initial scan
    if recording then
        print(blocksSaved)
        coroutine.resume(initialScan)
    end

end

-- for degugging
function set(x, y, z)
    client.execute("execute /setblock " .. x .. " " .. y .. " " .. z .. " glass")
end

-- adds a block to the world scan table
function addToWorldScan(x, y, z)
    local block = dimension.getBlock(math.floor(x), math.floor(y), math.floor(z))
    initalBlocksScanned = initalBlocksScanned + 1

    if block.id ~= 0 then
        blocksSaved = blocksSaved + 1

        saveFile:writeInt(x)
        saveFile:writeInt(y)
        saveFile:writeInt(z)
        saveFile:writeUShort(block.id)
        saveFile:writeByte(block.data)
    end
end

-- y = max(centerY - math.floor((r - 1) / 2), -worldBorder), min(centerY + math.floor((r - 1) / 2), worldBorder)

-- get the world height border
_versionSplit = string.split(client.mcversion, ".")
_v = {}
for i = 1, #_versionSplit, 1 do
    table.insert(_v, tonumber(_versionSplit[i]))
end
worldMaxHeight = 320
worldMinHeight = -64
if _v[1] <= 1 and _v[2] < 18 then
    -- is an old world
    worldMaxHeight = 256
    worldMinHeight = 0
end
--

initalBlocksScanned = 0 -- counts the amount of blocks scanned to be used to guide the coroutine
blocksSaved = 0 -- this is different from the one above because it does not count air blocks, which do not get saved to the file
-- a coroutine loop that puts blocks from the world into a file
initialScan = coroutine.create(function(...)
    for r = 1, 10000 do
        -- Z-axis
        for x = centerX - (r - 1), centerX + (r - 1) do
            for y = centerY - math.floor((r - 1) / 2), centerY + math.floor((r - 1) / 2) do
                for i = -1, 1, 2 do
                    addToWorldScan(x, y, centerZ + (r - 1) * i)
                    if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                        coroutine.yield()
                    end
                end
            end
        end

        -- X-axis
        for z = centerZ - (r - 2), centerZ + (r - 2) do
            for y = centerY - math.floor((r - 1) / 2), centerY + math.floor((r - 1) / 2) do
                for i = -1, 1, 2 do
                    addToWorldScan(centerX + (r - 1) * i, y, z)
                    if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                        coroutine.yield()
                    end
                end
            end
        end

        -- Y-axis

        -- split into one for up, one for down
        if r % 2 == 0 then
            for x = centerX - (r - 3), centerX + (r - 3) do
                for z = centerZ - (r - 3), centerZ + (r - 3) do
                    for i = -1, 1, 2 do
                        addToWorldScan(x, centerY + math.floor((r - 1) / 2) * i, z)
                        if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                            coroutine.yield()
                        end
                    end
                end
            end
        end
    end
end)

--[[
    perfect cube version:

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
]]

--[[

    TODO: make the y scan capped to the world height limits
    TODO: make a seperate set of player xyz that are Ints, instead of rounding later?

    save the block update data for the initial load in one temp file
    save all the updates into another temp file
    then, when the save button is pressed, a new file is created (this will be the file that the user keeps to play back) it includes (in order)
        the amount of blocks in the inital update (included in the block update packet)
        the block updates to complete the packet
        all of the updates from the second temp file

    add a grahpic telling you if you're recording and for how long
    add a way to stop the world scan coroutine so that you can record two times in a row (something with errors?)
        now, stopping recording and restarting it will just continue the same loop

    scan start: starts the initial world scan starting at the player's inital position, then starts the smaller scan following the player
    scan end: writes everything that has been stored into a file, formatted
    player position can be interpolated
]]

--[[
(outdated now)

INITIAL SCAN, ALL ONE LINE
posX posY posZ blockId blockData
1000 100  0    12      2        , 1001 100 0 43 0, ...

THEN, EACH NEW LINE IS INFORMATION GATHERED IN ONE UPDATE CYCLE
block updates; player position; player inventory; other stuff (other players+their inventory, other entities)...
posX posY posZ blockId blockData                         playerX    playerY playerZ
1000 100  0    12      2        , 1001 100 0 43 0, ... ; 990.123123 98.3235 23.34432 ; inventory stuff idk
]]


--[[
    static data (id 0):
    ip, time

    block changes (id 1):
        amount of blocks (Int)

        
]]
