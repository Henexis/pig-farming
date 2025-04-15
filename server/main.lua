local QBCore = exports['qb-core']:GetCoreObject()
local Pigs = {}
local HarvestedPigs = {}

-- Khởi tạo dữ liệu khi resource khởi động
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        InitializePigData()
    end
end)

function InitializePigData()
    local result = exports.oxmysql:executeSync('SELECT * FROM pig_farming')
    if result then
        for _, v in pairs(result) do
            local citizenid = v.citizenid
            local pigData = json.decode(v.pigs)
            local harvestedData = json.decode(v.harvested)
            
            Pigs[citizenid] = pigData or {}
            HarvestedPigs[citizenid] = harvestedData or {}
        end
    end
end

function SavePigData(citizenid)
    local pigData = Pigs[citizenid] or {}
    local harvestedData = HarvestedPigs[citizenid] or {}
    
    exports.oxmysql:execute('INSERT INTO pig_farming (citizenid, pigs, harvested) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE pigs = ?, harvested = ?',
        {citizenid, json.encode(pigData), json.encode(harvestedData), json.encode(pigData), json.encode(harvestedData)})
end

-- Event khi Player đăng nhập
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    
    if not Pigs[citizenid] then
        Pigs[citizenid] = {}
    end
    
    if not HarvestedPigs[citizenid] then
        HarvestedPigs[citizenid] = {}
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:GetPigs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    if not Pigs[citizenid] then
        Pigs[citizenid] = {}
    end
    
    cb(Pigs[citizenid])
end)

QBCore.Functions.CreateCallback('pig-farming:server:GetHarvestedPigs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    if not HarvestedPigs[citizenid] then
        HarvestedPigs[citizenid] = {}
    end
    
    cb(HarvestedPigs[citizenid])
end)

QBCore.Functions.CreateCallback('pig-farming:server:CanStartFarming', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    -- Thêm bất kỳ điều kiện nào bạn muốn ở đây
    cb(true)
end)

QBCore.Functions.CreateCallback('pig-farming:server:BuyPig', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    if not Pigs[citizenid] then
        Pigs[citizenid] = {}
    end
    
    -- Kiểm tra số lượng lợn hiện tại
    if #Pigs[citizenid] >= 10 then
        cb(false)
        return
    end
    
    -- Kiểm tra tiền
    if Player.Functions.RemoveMoney('cash', 500, "pig-farming-buy-pig") then
        -- Tạo lợn mới
        local pigId = #Pigs[citizenid] + 1
        local weight = math.random(Config.PigWeight.Min, Config.PigWeight.Max)
        
        local newPig = {
            id = pigId,
            bornTime = os.time(),
            lastFed = os.time(),
            lastWatered = os.time(),
            lastCleaned = os.time(),
            weight = weight,
            hunger = 100,
            thirst = 100,
            cleanliness = 100
        }
        
        table.insert(Pigs[citizenid], newPig)
        SavePigData(citizenid)
        TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
        
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:FeedPig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn không
    if not Pigs[citizenid] or not Pigs[citizenid][pigId] then
        cb(false)
        return
    end
    
    -- Kiểm tra xem có thức ăn không
    if Player.Functions.RemoveItem(Config.Items.Feed, 1) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Items.Feed], "remove")
        
        Pigs[citizenid][pigId].lastFed = os.time()
        Pigs[citizenid][pigId].hunger = 100
        SavePigData(citizenid)
        TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
        
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:WaterPig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn không
    if not Pigs[citizenid] or not Pigs[citizenid][pigId] then
        cb(false)
        return
    end
    
    -- Kiểm tra xem có nước không
    if Player.Functions.RemoveItem(Config.Items.Water, 1) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Items.Water], "remove")
        
        Pigs[citizenid][pigId].lastWatered = os.time()
        Pigs[citizenid][pigId].thirst = 100
        SavePigData(citizenid)
        TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
        
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:CleanPig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn không
    if not Pigs[citizenid] or not Pigs[citizenid][pigId] then
        cb(false)
        return
    end
    
    -- Kiểm tra xem có xà phòng không
    if Player.Functions.RemoveItem(Config.Items.Soap, 1) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Items.Soap], "remove")
        
        Pigs[citizenid][pigId].lastCleaned = os.time()
        Pigs[citizenid][pigId].cleanliness = 100
        SavePigData(citizenid)
        TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
        
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:AutoCarePig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn không
    if not Pigs[citizenid] or not Pigs[citizenid][pigId] then
        cb(false)
        return
    end
    
    -- Tổng chi phí
    local totalCost = Config.AutoCarePrice.Feed + Config.AutoCarePrice.Water + Config.AutoCarePrice.Clean
    
    -- Kiểm tra xem có đủ tiền không
    if Player.Functions.RemoveMoney('cash', totalCost, "pig-farming-auto-care") then
        Pigs[citizenid][pigId].lastFed = os.time()
        Pigs[citizenid][pigId].lastWatered = os.time()
        Pigs[citizenid][pigId].lastCleaned = os.time()
        Pigs[citizenid][pigId].hunger = 100
        Pigs[citizenid][pigId].thirst = 100
        Pigs[citizenid][pigId].cleanliness = 100
        SavePigData(citizenid)
        TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
        
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('pig-farming:server:HarvestPig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn không
    if not Pigs[citizenid] or not Pigs[citizenid][pigId] then
        cb(false)
        return
    end
    
    local pig = Pigs[citizenid][pigId]
    
    -- Kiểm tra xem lợn đã trưởng thành chưa
    local growthTime = Config.GrowthTime * 60 -- đổi sang giây
    if (os.time() - pig.bornTime) < growthTime then
        cb(false)
        return
    end
    
    -- Thêm lợn vào danh sách thu hoạch
    if not HarvestedPigs[citizenid] then
        HarvestedPigs[citizenid] = {}
    end
    
    table.insert(HarvestedPigs[citizenid], pig)
    
    -- Xóa lợn khỏi danh sách nuôi
    table.remove(Pigs[citizenid], pigId)
    
    -- Cập nhật lại ID của những lợn còn lại
    for i, p in ipairs(Pigs[citizenid]) do
        p.id = i
    end
    
    SavePigData(citizenid)
    TriggerClientEvent('pig-farming:client:UpdatePigs', source, Pigs[citizenid])
    
    cb(true)
end)

QBCore.Functions.CreateCallback('pig-farming:server:SellPig', function(source, cb, pigId)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn trong danh sách thu hoạch không
    if not HarvestedPigs[citizenid] then
        cb(false)
        return
    end
    
    local pigIndex = nil
    local selectedPig = nil
    
    for i, pig in ipairs(HarvestedPigs[citizenid]) do
        if pig.id == pigId then
            pigIndex = i
            selectedPig = pig
            break
        end
    end
    
    if not selectedPig then
        cb(false)
        return
    end
    
    -- Tính tiền dựa trên trọng lượng
    local money = selectedPig.weight * Config.PricePerKg
    
    -- Số lượng thịt lợn ngẫu nhiên
    local meatAmount = math.random(Config.Rewards.PorkMeat.Min, Config.Rewards.PorkMeat.Max)
    
    -- Thêm tiền và thịt lợn cho người chơi
    Player.Functions.AddMoney('cash', money, "pig-farming-sell-pig")
    Player.Functions.AddItem(Config.Rewards.PorkMeat.Item, meatAmount)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Rewards.PorkMeat.Item], "add")
    
    -- Xóa lợn khỏi danh sách thu hoạch
    table.remove(HarvestedPigs[citizenid], pigIndex)
    
    SavePigData(citizenid)
    
    cb(true, money, meatAmount)
end)

QBCore.Functions.CreateCallback('pig-farming:server:SellAllPigs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra xem có lợn trong danh sách thu hoạch không
    if not HarvestedPigs[citizenid] or #HarvestedPigs[citizenid] == 0 then
        cb(false)
        return
    end
    
    local totalMoney = 0
    local totalMeat = 0
    
    -- Tính tổng tiền và thịt lợn
    for _, pig in ipairs(HarvestedPigs[citizenid]) do
        totalMoney = totalMoney + (pig.weight * Config.PricePerKg)
        totalMeat = totalMeat + math.random(Config.Rewards.PorkMeat.Min, Config.Rewards.PorkMeat.Max)
    end
    
    -- Thêm tiền và thịt lợn cho người chơi
    Player.Functions.AddMoney('cash', totalMoney, "pig-farming-sell-all-pigs")
    Player.Functions.AddItem(Config.Rewards.PorkMeat.Item, totalMeat)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Rewards.PorkMeat.Item], "add")
    
    -- Xóa tất cả lợn khỏi danh sách thu hoạch
    HarvestedPigs[citizenid] = {}
    
    SavePigData(citizenid)
    
    cb(true, totalMoney, totalMeat)
end)

-- Tự động cập nhật trạng thái lợn
CreateThread(function()
    while true do
        Wait(60000) -- cập nhật mỗi phút
        
        for citizenid, pigs in pairs(Pigs) do
            local updated = false
            
            for i, pig in ipairs(pigs) do
                -- Giảm đói, khát và độ sạch
                local timeSinceLastFed = os.time() - pig.lastFed
                local timeSinceLastWatered = os.time() - pig.lastWatered
                local timeSinceLastCleaned = os.time() - pig.lastCleaned
                
                local newHunger = math.max(0, pig.hunger - (timeSinceLastFed / (Config.FeedTime * 60)) * 100)
                local newThirst = math.max(0, pig.thirst - (timeSinceLastWatered / (Config.WaterTime * 60)) * 100)
                local newCleanliness = math.max(0, pig.cleanliness - (timeSinceLastCleaned / (Config.CleanTime * 60)) * 100)
                
                if newHunger ~= pig.hunger or newThirst ~= pig.thirst or newCleanliness ~= pig.cleanliness then
                    pig.hunger = newHunger
                    pig.thirst = newThirst
                    pig.cleanliness = newCleanliness
                    updated = true
                end
            end
            
            if updated then
                SavePigData(citizenid)
                local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                if player then
                    TriggerClientEvent('pig-farming:client:UpdatePigs', player.PlayerData.source, pigs)
                end
            end
        end
    end
end)

-- Đảm bảo bảng cơ sở dữ liệu tồn tại
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `pig_farming` (
            `citizenid` varchar(50) NOT NULL,
            `pigs` longtext DEFAULT '[]',
            `harvested` longtext DEFAULT '[]',
            PRIMARY KEY (`citizenid`)
        )
    ]])
end)
