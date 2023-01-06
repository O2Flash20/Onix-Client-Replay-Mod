blockData = {}

find = function (table, iter)
    for key, value in pairs(table) do
        local success = iter(value, key, table)
        if success == true then return value end
    end
    return nil
end

function updateData()
    network.get("https://minecraft-ids.grahamedgecombe.com/items.json", "blocks")
end

function onNetworkData(_, id, data)
    if id == "blocks" then blockData = jsonToTable(data) end
end

function blockNameFromID(id)
    local block = find(blockData, function (x) return x.type == id end)
    if block ~= nil then return block.text_type else return nil end
end
