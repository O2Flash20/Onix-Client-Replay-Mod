-- Use replayMod.lua instead

name = "Replay Mod Playback"
description = "Watch a recorded replay!"

-- workingDir = "RoamingState/OnixClient/Scripts/Data/ReplayMod"
-- savedReplays = fs.files(".")

-- importLib("logger")
-- importLib("blockFromId")

-- -- registerCommand("updateData", function () updateData() print("Updated data.") end)

-- -- registerCommand("getBlockName", function (args)
-- --     local name = blockNameFromID(args)
-- --     if name == nil then return print("No block with ID " .. args) end
-- --     print("Block with ID " .. args .. " is " .. name)
-- -- end)

-- start = false
-- replayFile = nil

-- -- function handleReplayFile(path)
-- --     local file = fs.open(path, "r")
-- --     if file == nil then return nil end

-- --     while not file:eof() do
-- --         local packetId, packetData = readPacket(file)
-- --         log(packetData)
-- --         -- TODO: actually play back the replay
-- --         -- probably in the update function though?
-- --     end
-- -- end

-- function readPacket(file)
--     local packetId = file:readByte()
--     local data = {}
--     if packetId == 1 then -- Blocks
--         local blockslength = file:readUInt()
--         for i = 0, blockslength do
--             local x, y, z = file:readInt(), file:readInt(), file:readInt()
--             local blockId = file:readUShort()
--             local blockData = file:readByte()

--             table.insert(data, { x = x, y = y, z = z, id = blockId, data = blockData })
--         end
--     elseif packetId == 2 then -- Player
--         x, y, z = file:readFloat(), file:readFloat(), file:readFloat()
--         data = {
--             x = x, y = y, z = z,
--             playerId = file:readUInt(),
--             pitch = file:readByte(),
--             yaw = file:readByte(),
--         }
--     end

--     return packetId, data
-- end

-- function onEnable()
--     print("This sucks - use replayMod.lua")

--     -- updateData()
--     -- print("Block data updated")
-- end

-- registerCommand("togglereplay", function ()
--     start = not start
--     -- updateData()
--     replayFile = fs.open("InitialScanTest.replay", "r")
--     print("Replay toggled " .. (start and "on." or "off."))
-- end)

-- blockList = {}

-- function update()
--     if start == false then return nil end
--     if replayFile == nil then return nil end
--     if replayFile:eof() then return replayFile:close() end

--     -- This is super slow but it works
--     if #blockList > 0 then
--         local block = table.remove(blockList, 1)
--         client.execute("execute /setblock " .. block.x .. " " .. block.y .. " " .. block.z .. " " .. blockNameFromID(block.id) .. " " .. block.data)
--         return
--     end

--     local packetId, data = readPacket(replayFile)
--     if packetId == 1 then
--         -- Blocks
--         blockList = table.clone(data)
--         -- for _, block in pairs(data) do
--         --     -- print(tableToJson(block))
--         --     -- print(blockNameFromID(block.id))
--         --     client.execute("execute /setblock " .. block.x .. " " .. block.y .. " " .. block.z .. " " .. blockNameFromID(block.id) .. " " .. block.data)
--         --     -- sleep(10)
--         -- end
--     end
-- end
