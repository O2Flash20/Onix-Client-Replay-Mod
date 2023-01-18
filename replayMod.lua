name = "Replay Mod"
description = "Record a section of your world/server, then watch it back later!"

workingDir = "RoamingState/OnixClient/Scripts/Data/ReplayMod"

importLib("logger")

importLib("keyconverter")

---@type BinaryFile|nil
updatesFile = nil
---@type BinaryFile|nil
saveFile = nil

-- starts starts the coroutine to load the world into the file
status = "Waiting to record."
recording = false
blockList = {}
timeRecordingStarted = nil
function startRecording()
    blockList = {}
    recording = true
    startRecordingButton.visible = false
    endRecordingButton.visible = true
    status = "Recording..."
    timeRecordingStarted = os.clock()

    centerX = pxInt
    centerY = pyInt
    centerZ = pzInt

    fs.delete(fileName.value .. ".replay")
    saveFile = fs.open(fileName.value .. ".replay", 'w')
    print("Writing to " .. fileName.value .. ".replay...")

    -- move the "cursor" so that there's space for the packet id and amount of blocks at the front
    saveFile:seek(5)

    updatesFile = fs.open("updates.TEMP", "w")
end

startRecordingButton = client.settings.addFunction("Start Recording:", "startRecording", "Start")

-- ends the recording, writes the block hash->name and data information, writes the amount of blocks in the initial scan
function endRecording()
    recording = false
    startRecordingButton.visible = true
    endRecordingButton.visible = false
    status = "Waiting to record."

    -- merge updates temp file into the save file
    updatesFile:close()
    updatesFile = fs.open("updates.TEMP", "r")
    print("Size: " .. updatesFile:size())
    saveFile:writeRaw(updatesFile:readRaw(updatesFile:size()))
    updatesFile:close()
    fs.delete("updates.TEMP")

    -- Save hash->name and data
    saveFile:writeUByte(0)
    local arraySize = saveFile:tell()
    local arrayLength = 0
    for hash, block in pairs(blockList) do
        saveFile:writeLong(hash)
        saveFile:writeString(block.name)
        saveFile:writeByte(block.data)
        arrayLength = arrayLength + 1
    end
    arraySize = saveFile:tell() - arraySize
    saveFile:writeUInt(arraySize)
    saveFile:writeUShort(arrayLength)
    print("Size of block list: " .. arraySize .. " length: " .. arrayLength)

    -- start off the packet of the initial block update
    saveFile:seek(0)
    -- packet Id
    saveFile:writeUByte(1)
    -- Number of  blocks to update
    saveFile:writeUInt(blocksSaved)

    saveFile:close()
end

endRecordingButton = client.settings.addFunction("End Recording", "endRecording", "Save")
endRecordingButton.visible = false


client.settings.addTitle("status")
fileName = client.settings.addNamelessTextbox("Save file name:", "Untitled")


-- making a file that is readable for degugging
function test()
    --reading the updates file
    --[[
        local input = fs.open("updates.TEMP", "r")
        local output = io.open("text.txt", "w+")
    
        if input == nil or output == nil then return end
    
        -- loop through all updates
        while input:eof() == false do
            output:write("\n") --new line
            local id = input:readUByte() --get the packet id
    
            if id == 255 then
                output:write("____update____")
            elseif id == 1 then -- a block update exists
                output:write("BLOCK: ")
                local numberOfBlocks = input:readUInt()
                output:write("(" .. numberOfBlocks .. ") ")
    
                if numberOfBlocks < 10 then
                    for i = 1, numberOfBlocks do
                        output:write(input:readInt() .. " ")
                        output:write(input:readInt() .. " ")
                        output:write(input:readInt() .. " ")
                        output:write(input:readLong() .. " ")
                    end
                else
                    for i = 1, numberOfBlocks do
                        output:write("Loop")
                        input:readInt()
                        input:readInt()
                        input:readInt()
                        input:readLong()
                    end
                end
            elseif id == 2 then -- this is a player update
                output:write("PLAYER: ")
                output:write(input:readFloat() .. " ")
                output:write(input:readFloat() .. " ")
                output:write(input:readFloat() .. " ")
                output:write(input:readByte() .. " ")
                output:write(input:readByte() .. " ")
            else
                output:write("Unknown id " .. id)
            end
        end
    
        input:close()
        output:close()
    ]]

    --reading the initial scan file
    --[[
        local input = fs.open(fileName.value .. ".replay", 'r')
        local output = io.open("text.txt", "w+")
        if input and output then
            output:write(input:readUByte())
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
    ]]

    --reading the combined file
    local input = fs.open(fileName.value .. ".replay", 'r')
    local output = io.open("text.txt", "w+")
    if input == nil or output == nil then return end

    -- hash information
    print(input:tell())
    local blockRegistry = readBlockRegistry(input)
    print("Length of Block Registry: " .. #blockRegistry)
    input:seek(0)
    print(input:size() .. " " .. input:tell())
    for hash, block in pairs(blockRegistry) do
        output:write(hash .. " " .. block.name .. " " .. block.data .. "\n")
    end

    -- initial scan
    local scanPacketNumber = input:readUByte()
    local numBlocks = input:readUInt()
    output:write("\n" .. numBlocks .. " initial scan blocks found: \n")
    for i = 1, numBlocks do
        output:write(input:readInt())
        output:write(" ")
        output:write(input:readInt())
        output:write(" ")
        output:write(input:readInt())
        output:write(" ")
        output:write(input:readLong())
        output:write("\n")
    end

    -- updates
    while input:eof() == false do
        output:write("\n") --new line
        local id = input:readUByte() --get the packet id

        if id == 255 then
            output:write("____update____")
        elseif id == 1 then -- a block update exists
            output:write("BLOCK: ")
            local numberOfBlocks = input:readUInt()
            output:write("(" .. numberOfBlocks .. ") ")

            if numberOfBlocks < 10 then
                for i = 1, numberOfBlocks do
                    output:write(input:readInt() .. " ")
                    output:write(input:readInt() .. " ")
                    output:write(input:readInt() .. " ")
                    output:write(input:readLong() .. " ")
                end
            else
                for i = 1, numberOfBlocks do
                    output:write("Loop")
                    input:readInt()
                    input:readInt()
                    input:readInt()
                    input:readLong()
                end
            end
        elseif id == 2 then -- this is a player update
            output:write("PLAYER: ")
            output:write(input:readFloat() .. " ")
            output:write(input:readFloat() .. " ")
            output:write(input:readFloat() .. " ")
            output:write(input:readByte() .. " ")
            output:write(input:readByte() .. " ")
        elseif id == 0 then -- block hash information
            output:write("\n HIT HASH INFORMATION - STOPPING")
            break
        else
            output:write("Unknown id " .. id)
        end
    end

    input:close()
    output:close()
end

client.settings.addFunction("Convert .replay to .txt", "test", "Enter")


-- reads the file for a single block returns position and hash
---@param file BinaryFile
function readSingleBlockData(file)
    local output = {}

    output.x = file:readInt()
    output.y = file:readInt()
    output.z = file:readInt()
    output.hash = file:readLong() --block hash to get name and data from registry

    return output
end

-- returns [hash->block name+data] information stored in the file to be used when reading
---@param file BinaryFile
function readBlockRegistry(file)
    local blockRegistry = {}

    file:seek(file:size() - 6)
    local registrySize = file:readUInt()
    local registryLen = file:readUShort()

    file:seek(file:size() - 6 - registrySize)
    for i = 1, registryLen do
        local hash = file:readLong()
        blockRegistry[hash] = {
            name = file:readString(),
            data = file:readByte()
        }
    end

    file:seek(0)
    return blockRegistry
end

-- reads the file and sets blocks in the world
loadingFile = nil
function startWorldLoad()
    -- allow updates to start at the origin
    centerX = pxInt
    centerY = pyInt
    centerZ = pzInt

    loadingFile = fs.open(fileName.value .. ".replay", "r")
    if loadingFile == nil then return nil end

    -- Get block list
    blockRegistry = readBlockRegistry(loadingFile)

    print("Packet ID (should be 1): " .. loadingFile:readByte())
    local amountOfBlocks = loadingFile:readUInt()
    print("Amount of blocks: " .. amountOfBlocks)

    for i = 1, amountOfBlocks do
        data = readSingleBlockData(loadingFile)
        placeBlock(data.x, data.y, data.z, blockRegistry[data.hash].name, blockRegistry[data.hash].data, true)
    end

    -- starts off the coroutine every update
    -- loading = true
    -- *DONE USING THE NUMBER 8 INSTEAD
end

replayLoad = coroutine.create(function()
    -- could be while true tbh
    while loadingFile:eof() == false do
        local packetId = loadingFile:readUByte()

        if packetId == 255 then
            -- new update
            coroutine.yield()

        elseif packetId == 1 then
            print("hit a block packet")
            -- block change
            local amountOfBlocks = loadingFile:readUInt()
            for i = 1, amountOfBlocks do
                print(">")
                local data = readSingleBlockData(loadingFile)
                placeBlock(data.x + centerX, data.y + centerY, data.z + centerZ, blockRegistry[data.hash].name,
                    blockRegistry[data.hash].data)
            end

        elseif packetId == 2 then
            -- player pos and rot
            local x = loadingFile:readFloat()
            local y = loadingFile:readFloat()
            local z = loadingFile:readFloat()
            local yaw = loadingFile:readByte()
            local pitch = loadingFile:readByte()
            client.execute(
                "execute /tp @s "
                .. x + centerX .. " "
                .. y + centerY - 1.6 .. " "
                .. z + centerZ .. " "
                .. yaw * 1.44 .. " "
                .. pitch
            )

        elseif packetId == 0 then
            break
        end
        print("loop")
    end
    print('REPLAY ENDED')
    loadingFile:close()
    loading = false
end)

function xyzFromYawPitch(playerX, playerY, playerZ, playerPitch, playerYaw, dist)
    playerPitch = math.rad(playerPitch)
    playerYaw = math.rad(-playerYaw)

    y = -dist * math.sin(playerPitch)
    z = dist * math.cos(playerPitch)
    x = z * math.sin(playerYaw)
    z = z * math.cos(playerYaw)

    return { x + playerX, y + playerY, z + playerZ }
end

client.settings.addFunction("Load World", "startWorldLoad", "Enter")
-- registerCommand("loading", function() loading = true end)

loading = false
scanShouldStop = false
lastWasRecoding = false --Keeps track of if the last update frame was recording or not. If it used to be recording but now isn't, the initial scan coroutine will be called one last time, so that it will be reset to the start for next time.
initialBlocksScannedPerUpdate = 5000
function update()
    log(loading)

    pxInt, pyInt, pzInt = player.position()
    px, py, pz = player.pposition()
    pYaw, pPitch = player.rotation()

    if lastWasRecoding == true and recording == false then
        scanShouldStop = true
        coroutine.resume(initialScan)
        scanShouldStop = false
    end

    if recording then
        -- initial scan
        print(blocksSaved)
        coroutine.resume(initialScan)


        -- Signifies a new update cycle
        updatesFile:writeUByte(255)

        -- write block changes
        if #blockChangesThisUpdate > 0 then
            -- signify block changes are starting
            updatesFile:writeUByte(1)
            -- the number of blocks to update
            updatesFile:writeUInt(#blockChangesThisUpdate)
            for _, block in pairs(blockChangesThisUpdate) do
                updatesFile:writeInt(block.x - centerX)
                updatesFile:writeInt(block.y - centerY)
                updatesFile:writeInt(block.z - centerZ)
                updatesFile:writeLong(block.hash)
            end
        end

        -- write player position and rotation
        updatesFile:writeUByte(2)
        updatesFile:writeFloat(px - centerX)
        updatesFile:writeFloat(py - centerY)
        updatesFile:writeFloat(pz - centerZ)
        updatesFile:writeByte(math.floor(pYaw / 1.44))
        updatesFile:writeByte(math.floor(pPitch))
    end

    if loading then
        coroutine.resume(replayLoad)
    end

    blockChangesThisUpdate = {}

    lastWasRecoding = recording
end

blockChangesThisUpdate = {}
-- detecting block changes
event.listen("BlockChanged", function(x, y, z, newBlock, oldBlock)
    if recording and blockList[newBlock.hash] == nil then
        --  get block id and name, add to blocklist
        local block = dimension.getBlock(x, y, z)
        print("Inserting new hash (from new block in update)")
        blockList[newBlock.hash] = { name = block.name, data = block.data }
    end
    table.insert(blockChangesThisUpdate, { x = x, y = y, z = z, hash = newBlock.hash })
end)

-- for degugging
function set(x, y, z)
    initalBlocksScanned = initalBlocksScanned + 1
    client.execute("execute /setblock " .. x .. " " .. y .. " " .. z .. " glass")
end

-- adds a block to the world scan table
function addToWorldScan(x, y, z)
    x = math.floor(x)
    y = math.floor(y)
    z = math.floor(z)
    local block = dimension.getBlock(x, y, z)
    initalBlocksScanned = initalBlocksScanned + 1

    if block.name == "air" or block.name == "client_request_placeholder_block" then return nil end

    if blockList[block.hash] == nil then blockList[block.hash] = { name = block.name, data = block.data } end

    blocksSaved = blocksSaved + 1

    saveFile:writeInt(x - centerX)
    saveFile:writeInt(y - centerY)
    saveFile:writeInt(z - centerZ)
    saveFile:writeLong(block.hash)
end

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

-- a coroutine loop that puts blocks from the world into a file
initalBlocksScanned = 0 -- counts the amount of blocks scanned to be used to guide the coroutine
blocksSaved = 0 -- this is different from the one above because it does not count air blocks, which do not get saved to the file
SCANLIMIT = 100
limitReached = false
initialScan = coroutine.create(function()
    ::start::
    print("SCAN RESTARTED")
    initalBlocksScanned = 0
    blocksSaved = 0
    coroutine.yield()

    for r = 1, SCANLIMIT do
        -- Z-axis
        for x = centerX - (r - 1), centerX + (r - 1) do
            for y = math.max(centerY - math.floor((r - 1) / 2), worldMinHeight), math.min(centerY +
                math.floor((r - 1) / 2), worldMaxHeight) do
                for i = -1, 1, 2 do

                    if scanShouldStop then goto start end

                    addToWorldScan(x, y, centerZ + (r - 1) * i)
                    -- set(x, y, centerZ + (r - 1) * i)
                    if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                        coroutine.yield()
                    end
                end
            end
        end

        -- X-axis
        for z = centerZ - (r - 2), centerZ + (r - 2) do
            for y = math.max(centerY - math.floor((r - 1) / 2), worldMinHeight), math.min(centerY +
                math.floor((r - 1) / 2), worldMaxHeight) do
                for i = -1, 1, 2 do

                    if scanShouldStop then goto start end

                    addToWorldScan(centerX + (r - 1) * i, y, z)
                    -- set(centerX + (r - 1) * i, y, z)
                    if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                        coroutine.yield()
                    end
                end
            end
        end

        -- Y-axis
        if centerY + math.floor((r - 1) / 2) <= worldMaxHeight then
            if r % 2 == 0 then
                for x = centerX - (r - 3), centerX + (r - 3) do
                    for z = centerZ - (r - 3), centerZ + (r - 3) do

                        if scanShouldStop then goto start end

                        addToWorldScan(x, centerY + math.floor((r - 1) / 2), z)
                        -- set(x, centerY + math.floor((r - 1) / 2), z)
                        if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                            coroutine.yield()
                        end
                    end
                end
            end
        end
        if centerY + math.floor((r - 1) / 2) * -1 >= worldMinHeight then
            if r % 2 == 0 then
                for x = centerX - (r - 3), centerX + (r - 3) do
                    for z = centerZ - (r - 3), centerZ + (r - 3) do

                        if scanShouldStop then goto start end

                        addToWorldScan(x, centerY + math.floor((r - 1) / 2) * -1, z)
                        -- set(x, centerY + math.floor((r - 1) / 2) * -1, z)
                        if initalBlocksScanned % initialBlocksScannedPerUpdate == 0 then
                            coroutine.yield()
                        end
                    end
                end
            end
        end
    end

    while true do
        if scanShouldStop then goto start
        else coroutine.yield() end
    end
end)

-- UI ELEMENTS
positionX = 50
positionY = 50
sizeX = 100
sizeY = 50
function render2()
    gfx2.color(38, 38, 38, 230)
    gfx2.fillRoundRect(0, 0, 100, 50, 2)
    gfx2.color(255, 255, 255, 115)
    gfx2.drawRoundRect(0, 0, 100, 50, 1, 1)

    -- title
    gfx2.color(255, 255, 255)
    gfx2.text(33, 2, "Replay Mod", 1)

    -- status
    if recording then
        gfx2.text(2, 13, "Status:       [" .. stylizedClock(timeRecordingStarted, os.clock()) .. "]", 0.8)
        gfx2.color(230, 20, 0)
        gfx2.fillElipse(23, 17, 2.5)
        gfx2.color(255, 255, 255)
    else
        gfx2.text(2, 13, "Status:", 0.8)
        gfx2.color(20, 20, 20)
        gfx2.fillElipse(23, 17, 2.5)
        gfx2.color(255, 255, 255)
    end

    -- file
    gfx2.text(2, 21, "Selected File: " .. fileName.value .. ".replay", 0.8)

    -- toggle button
    if recording then
        gfx2.text(2, 29, "Press [" .. keytostr(toggleKey) .. "] to Stop Recording", 0.8)
    else
        gfx2.text(2, 29, "Press [" .. keytostr(toggleKey) .. "] to Start Recording", 0.8)
    end
end

toggleKey = 0x48 -- (H)
client.settings.addKeybind("Start/Stop Key", "toggleKey")

event.listen("KeyboardInput", function(key, down)
    if key == toggleKey and down then
        -- toggle key was pressed
        if recording == false then startRecording()
        else endRecording() end

        return true
    end
    if key == 0x38 then
        loading = true
    end
end)

function stylizedClock(start, now)
    seconds = math.floor(now - start)
    minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    if seconds < 10 then seconds = "0" .. seconds end
    if minutes < 10 then minutes = "0" .. minutes end

    return minutes .. ":" .. seconds
end

-- places a block in the world
function placeBlock(x, y, z, name, data, relative)
    if relative then
        client.execute("execute /setblock ~" .. x .. " ~" .. y .. " ~" .. z .. " " .. name .. " " .. data)
    else
        client.execute("execute /setblock " .. x .. " " .. y .. " " .. z .. " " .. name .. " " .. data)
    end
end

--[[
    ! pressing 8 only works the first time for some reason (i gotta fix that)
    *use interpolation in render() to make playback smooth
    *save inventory information
    *save flags and figure out how to use them to do animations
]]
