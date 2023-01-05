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

    fs.delete("initialTEMP.replay")
    initialScanFile = fs.open("initialTEMP.replay", "w")
end

initialScanFile = nil

function endRecording()
    recording = false
    startRecordingButton.visible = true
    endRecordingButton.visible = false
    status = "Waiting to record."

    initialScanFile:close()
end

client.settings.addTitle("status")
startRecordingButton = client.settings.addFunction("Start Recording:", "startRecording", "Start")
endRecordingButton = client.settings.addFunction("End Recording", "endRecording", "Save")
endRecordingButton.visible = false
fileName = client.settings.addNamelessTextbox("Save file name:", "Untitled")

function test()
    local file = fs.open("initialTEMP.replay", 'r')
    for i = 1, 5, 1 do
        print(file:readInt())
        print(file:readInt())
        print(file:readInt())
        print(file:readUInt())
        print(file:readByte())
    end
    file:close()
end

client.settings.addFunction("Test Button", "test", "Enter")

------------------------------------------------------------

initialBlocksScannedPerUpdate = 10
function update()
    px, py, pz = player.pposition()
    pYaw, pPitch = player.rotation()

    -- initial scan
    if recording then
        print(initalBlocksScanned)
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

    initialScanFile:writeInt(x)
    initialScanFile:writeInt(y)
    initialScanFile:writeInt(z)
    initialScanFile:writeUInt(block.id)
    initialScanFile:writeByte(block.data)
end

-- a coroutine loop that puts blocks from the world into a table
initalBlocksScanned = 0
initialScan = coroutine.create(function(...)
    for r = 1, 10000 do
        -- Z-axis
        for x = centerX - (r - 1), centerX + (r - 1) do
            for y = centerY - math.floor((r - 1) / 2), centerY + math.floor((r - 1) / 2) do
                for i = -1, 1, 2 do
                    addToWorldScan(x, y, centerZ + (r - 1) * i)

                    initalBlocksScanned = initalBlocksScanned + 1
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

                    initalBlocksScanned = initalBlocksScanned + 1
                    if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                        coroutine.yield()
                    end
                end
            end
        end

        -- Y-axis
        if r % 2 == 0 then
            for x = centerX - (r - 3), centerX + (r - 3) do
                for z = centerZ - (r - 3), centerZ + (r - 3) do
                    for i = -1, 1, 2 do
                        addToWorldScan(x, centerY + math.floor((r - 1) / 2) * i, z)

                        initalBlocksScanned = initalBlocksScanned + 1
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
    save the block update data for the initial load in one temp file
    save all the updates into another temp file
    then, when the save button is pressed, a new file is created (this will be the file that the user keeps to play back) it includes (in order)
        the amount of blocks in the inital update (included in the block update packet)
        the block updates to complete the packet
        all of the updates from the second temp file

    add a grahpic telling you if you're recording and for how long
    add a way to stop the world scan coroutine so that you can record two times in a row (something with errors?)
        now, stopping recording and restarting it will just continue the same loop

    x and z grow twice as fast as y because worlds are usually more flat than tall
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
