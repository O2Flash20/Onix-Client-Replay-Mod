name = "Replay Mod"
description = "Record a section of your world/server, then watch it back later!"

workingDir = "RoamingState/OnixClient/Scripts/Data/ReplayMod"

importLib("logger")

---@type BinaryFile|nil
updatesFile = nil
---@type BinaryFile|nil
saveFile = nil

-- starts starts the coroutine to load the world into the file
status = "Waiting to record."
recording = false
blockList = {}
function startRecording()
    recording = true
    startRecordingButton.visible = false
    endRecordingButton.visible = true
    status = "Recording..."

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
    updatesFile:close()
end

endRecordingButton = client.settings.addFunction("End Recording", "endRecording", "Save")
endRecordingButton.visible = false


client.settings.addTitle("status")
fileName = client.settings.addNamelessTextbox("Save file name:", "Untitled")


-- making a file that is readable for degugging
function test()
    --reading the updates file
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
end

client.settings.addFunction("Convert .replay to .txt", "test", "Enter")


-- reads the file for a single block returns position and hash
---@param file BinaryFile
function readSingleBlockData(file)
    local output = {}

    output.x = file:readInt()
    output.y = file:readInt()
    output.z = file:readInt()
    output.hash = file:readLong() --block hash -> to get name and data from registry

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
function worldFromFile()
    local file = fs.open(fileName.value .. ".replay", "r")
    if file == nil then return nil end

    -- Get block list
    local blockRegistry = readBlockRegistry(file)

    print("Packet ID (should be 1): " .. file:readByte())
    local amountOfBlocks = file:readUInt()
    print("Amount of blocks: " .. amountOfBlocks)

    for i = 1, amountOfBlocks do
        data = readSingleBlockData(file)
        -- print(blockRegistry[data[4]].name)
        client.execute(
            "execute /setblock ~" ..
            data.x ..
            " ~" ..
            data.y ..
            " ~" ..
            data.z ..
            " " ..
            blockRegistry[data.hash].name ..
            " " ..
            blockRegistry[data.hash].data
        )
    end

    file:close()
end

loadWorld = false
client.settings.addFunction("Load World", "worldFromFile", "Enter")
registerCommand("loadworld", function() loadWorld = true end) -- I'm on touchpad atm so this is less painful


initialBlocksScannedPerUpdate = 100
function update()
    pxInt, pyInt, pzInt = player.position()
    px, py, pz = player.pposition()
    pYaw, pPitch = player.rotation()

    -- initial scan
    if recording then
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
        updatesFile:writeFloat(px)
        updatesFile:writeFloat(py)
        updatesFile:writeFloat(pz)
        updatesFile:writeByte(math.floor(pYaw / 1.44))
        updatesFile:writeByte(math.floor(pPitch))
    end

    if loadWorld then loadWorld = false worldFromFile() end

    -- log(#blockChangesThisUpdate)
    log({ math.floor(pYaw / 1.44), math.floor(pPitch) })
    blockChangesThisUpdate = {}
end

blockChangesThisUpdate = {}
-- detecting block changes
event.listen("BlockChanged", function(x, y, z, newBlock, oldBlock)
    print(newBlock.hash)
    if blockList[newBlock] == nil then
        --  get block id and name, add to blocklist
        local block = dimension.getBlock(x, y, z)
        blockList[newBlock] = { name = block.name, data = block.data }
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
initialScan = coroutine.create(function(...)
    for r = 1, 10000 do
        -- Z-axis
        for x = centerX - (r - 1), centerX + (r - 1) do
            for y = math.max(centerY - math.floor((r - 1) / 2), worldMinHeight), math.min(centerY +
                math.floor((r - 1) / 2), worldMaxHeight) do
                for i = -1, 1, 2 do
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
end)

--[[
    save the block update data for the initial load in one temp file
    save all the updates into another temp file
    then, when the save button is pressed, a new file is created (this will be the file that the user keeps to play back) it includes (in order)
        the amount of blocks in the inital update (included in the block update packet)
        the block updates to complete the packet
        all of the updates from the second temp file

    *add a grahpic telling you if you're recording and for how long

    !add a way to stop the world scan coroutine so that you can record two times in a row (something with errors?)
        !now, stopping recording and restarting it will just continue the same loop
]]
