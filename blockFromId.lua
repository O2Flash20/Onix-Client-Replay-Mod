-- This goes in libs

blockData = {}

table.find = function (table, iter)
    for key, value in pairs(table) do
        local success = iter(value, key, table)
        if success == true then return value end
    end
    return nil
end

function updateData()
    network.get("https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/dataPaths.json", "filepaths")
end

function onNetworkData(_, id, data)
    -- log(id)
    if id == "filepaths" then
        local pathData = jsonToTable(data)
        local latestBedrock = pathData.bedrock["1.19.50"] -- TODO: use client.mcversion

        network.get("https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/" .. latestBedrock.blocks .. "/blocks.json", "blockdata")
    elseif id == "blockdata" then
        blockData = jsonToTable(data)
    end
end

function blockNameFromID(id)
    local block = table.find(blockData, function (x) return toString(x.id) == id end)
    if block ~= nil then return block.name else return nil end
end
