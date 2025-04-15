local QBCore = exports['qb-core']:GetCoreObject()

local pigs = {}

-- Load pigs from database
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM pigs', {}, function(result)
        if result then
            for _, pig in ipairs(result) do
                pigs[pig.id] = pig
            end
        end
    end)
end)

-- Get pigs for a player
QBCore.Functions.CreateCallback('pig-farming:server:GetPigs', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local playerPigs = {}

    for _, pig in pairs(pigs) do
        if pig.owner == Player.PlayerData.citizenid then
            table.insert(playerPigs, pig)
        end
    end

    cb(playerPigs)
end)

-- Buy a pig
QBCore.Functions.CreateCallback('pig-farming:server:BuyPig', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveMoney('cash', 500) then
        local pigId = #pigs + 1
        local weight = math.random(Config.PigWeight.Min, Config.PigWeight.Max)
        local bornTime = os.time()

        pigs[pigId] = {
            id = pigId,
            owner = Player.PlayerData.citizenid,
            weight = weight,
            bornTime = bornTime
        }

        MySQL.Async.execute('INSERT INTO pigs (id, owner, weight, bornTime) VALUES (@id, @owner, @weight, @bornTime)', {
            ['@id'] = pigId,
            ['@owner'] = Player.PlayerData.citizenid,
            ['@weight'] = weight,
            ['@bornTime'] = bornTime
        })

        cb(true)
    else
        cb(false)
    end
end)

-- Feed a pig
QBCore.Functions.CreateCallback('pig-farming:server:FeedPig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem(Config.Items.Feed, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.Feed], "remove")
        cb(true)
    else
        cb(false)
    end
end)

-- Water a pig
QBCore.Functions.CreateCallback('pig-farming:server:WaterPig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem(Config.Items.Water, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.Water], "remove")
        cb(true)
    else
        cb(false)
    end
end)

-- Clean a pig
QBCore.Functions.CreateCallback('pig-farming:server:CleanPig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem(Config.Items.Soap, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.Soap], "remove")
        cb(true)
    else
        cb(false)
    end
end)

-- Auto care a pig
QBCore.Functions.CreateCallback('pig-farming:server:AutoCarePig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalCost = Config.AutoCarePrice.Feed + Config.AutoCarePrice.Water + Config.AutoCarePrice.Clean

    if Player.Functions.RemoveMoney('cash', totalCost) then
        cb(true)
    else
        cb(false)
    end
end)

-- Harvest a pig
QBCore.Functions.CreateCallback('pig-farming:server:HarvestPig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if pigs[pigId] and pigs[pigId].owner == Player.PlayerData.citizenid then
        local growthTime = Config.GrowthTime * 60
        if os.time() - pigs[pigId].bornTime >= growthTime then
            pigs[pigId] = nil
            MySQL.Async.execute('DELETE FROM pigs WHERE id = @id', { ['@id'] = pigId })
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

-- Sell a pig
QBCore.Functions.CreateCallback('pig-farming:server:SellPig', function(source, cb, pigId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if pigs[pigId] and pigs[pigId].owner == Player.PlayerData.citizenid then
        local weight = pigs[pigId].weight
        local money = weight * Config.PricePerKg
        local meatAmount = math.random(Config.Rewards.PorkMeat.Min, Config.Rewards.PorkMeat.Max)

        Player.Functions.AddMoney('cash', money)
        Player.Functions.AddItem(Config.Rewards.PorkMeat.Item, meatAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Rewards.PorkMeat.Item], "add")

        pigs[pigId] = nil
        MySQL.Async.execute('DELETE FROM pigs WHERE id = @id', { ['@id'] = pigId })

        cb(true, money, meatAmount)
    else
        cb(false)
    end
end)

-- Sell all pigs
QBCore.Functions.CreateCallback('pig-farming:server:SellAllPigs', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalMoney = 0
    local totalMeat = 0

    for pigId, pig in pairs(pigs) do
        if pig.owner == Player.PlayerData.citizenid then
            local weight = pig.weight
            local money = weight * Config.PricePerKg
            local meatAmount = math.random(Config.Rewards.PorkMeat.Min, Config.Rewards.PorkMeat.Max)

            totalMoney = totalMoney + money
            totalMeat = totalMeat + meatAmount

            pigs[pigId] = nil
            MySQL.Async.execute('DELETE FROM pigs WHERE id = @id', { ['@id'] = pigId })
        end
    end

    if totalMoney > 0 then
        Player.Functions.AddMoney('cash', totalMoney)
        Player.Functions.AddItem(Config.Rewards.PorkMeat.Item, totalMeat)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Rewards.PorkMeat.Item], "add")
        cb(true, totalMoney, totalMeat)
    else
        cb(false)
    end
end)
