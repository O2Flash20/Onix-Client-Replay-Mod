name = "Replay Mod Playback"
description = "Watch a recorded replay!"

workingDir = "RoamingState/OnixClient/Scripts/Data/ReplayMod"
savedReplays = fs.files(".")

importLib("logger")
importLib("blockFromId")

-- registerCommand("updateData", function () updateData() print("Updated data.") end)

-- registerCommand("getBlockName", function (args)
--     local name = blockNameFromID(args)
--     if name == nil then return print("No block with ID " .. args) end
--     print("Block with ID " .. args .. " is " .. name)
-- end)

start = false

-- function startRec()
--     start = true
-- end
-- client.settings.addFunction("start", "startRec", "START")

function readPosition(file)
    local x = file:readFloat()
    local y = file:readFloat()
    local z = file:readFloat()

    return x, y, z
end

function handleReplayFile(path)
    local file = fs.open(path, "r")
    if file == nil then return nil end

    while ~file:eof() do
        local packetId, packetData = readPacket(file)
        log(packetData)
        -- TODO: actually play back the replay
        -- probably in the update function though?
    end
end

function readPacket(file)
    local packetId = file:readByte()
    local data = {}
    if packetId == 1 then -- Blocks
        local blockslength = file:readUInt()
        for i = 0, blockslength do
            -- !blocks positions will be an Int, not a float
            local x, y, z = readPosition(file)
            local blockId = file:readUInt()
            local blockData = file:readByte()

            table.insert(data, { x = x, y = y, z = z, blockId = blockId, blockData = blockData })
        end
    elseif packetId == 2 then -- Player
        x, y, z = readPosition(file)
        data = {
            x = x, y = y, z = z,
            playerId = file:readUInt(),
            pitch = file:readByte(),
            yaw = file:readByte(),
        }
    end

    return packetId, data
end

-- testFile = io.open("initialScanOnly.replay", "r")
-- data = testFile:read("a")
-- log(data)
-- testFile:close()

-- blocks = string.split(data, ",")
-- blockIndex = 1

function update()
    if start == false then return nil end
    -- local x, y, z, id, data = string.split(blocks[blockIndex], " ")
    -- blockIndex = blockIndex + 1
    -- client.execute("execute /setblock " .. x .. " " .. y .. " " .. z .. " " .. blockNameFromID(id) .. " " .. data)
end
