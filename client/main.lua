local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local pigs = {}
local isInFarm = false
local farmBlip = nil
local sellBlip = nil
local npcPed = nil
local sellNpcPed = nil
local uiActive = false

-- Khởi tạo
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    LoadFarm()
    Wait(1000)  -- Đợi để đảm bảo server đã sẵn sàng
    FetchPigs()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveBlips()
    DeletePeds()
    PlayerData = {}
    pigs = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

function LoadFarm()
    -- Tạo Blip cho trang trại
    farmBlip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
    SetBlipSprite(farmBlip, 88)
    SetBlipDisplay(farmBlip, 4)
    SetBlipScale(farmBlip, 0.7)
    SetBlipAsShortRange(farmBlip, true)
    SetBlipColour(farmBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Trang Trại Lợn")
    EndTextCommandSetBlipName(farmBlip)

    -- Tạo Blip cho điểm bán
    sellBlip = AddBlipForCoord(Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z)
    SetBlipSprite(sellBlip, 605)
    SetBlipDisplay(sellBlip, 4)
    SetBlipScale(sellBlip, 0.7)
    SetBlipAsShortRange(sellBlip, true)
    SetBlipColour(sellBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bán Lợn")
    EndTextCommandSetBlipName(sellBlip)

    -- Tạo NPC
    if not DoesEntityExist(npcPed) then
        RequestModel(GetHashKey(Config.NPCModel))
        while not HasModelLoaded(GetHashKey(Config.NPCModel)) do
            Wait(1)
        end
        npcPed = CreatePed(4, GetHashKey(Config.NPCModel), Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1.0, Config.NPCLocation.w, false, true)
        FreezeEntityPosition(npcPed, true)
        SetEntityInvincible(npcPed, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
    end
    
    -- Tạo NPC bán lợn
    if not DoesEntityExist(sellNpcPed) then
        RequestModel(GetHashKey(Config.SellNPCModel))
        while not HasModelLoaded(GetHashKey(Config.SellNPCModel)) do
            Wait(1)
        end
        sellNpcPed = CreatePed(4, GetHashKey(Config.SellNPCModel), Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z - 1.0, Config.SellLocation.w, false, true)
        FreezeEntityPosition(sellNpcPed, true)
        SetEntityInvincible(sellNpcPed, true)
        SetBlockingOfNonTemporaryEvents(sellNpcPed, true)
    end
end

function RemoveBlips()
    if farmBlip then
        RemoveBlip(farmBlip)
        farmBlip = nil
    end
    if sellBlip then
        RemoveBlip(sellBlip)
        sellBlip = nil
    end
end

function DeletePeds()
    if DoesEntityExist(npcPed) then
        DeletePed(npcPed)
        npcPed = nil
    end
    if DoesEntityExist(sellNpcPed) then
        DeletePed(sellNpcPed)
        sellNpcPed = nil
    end
end

function FetchPigs()
    QBCore.Functions.TriggerCallback('pig-farming:server:GetPigs', function(pigData)
        if pigData then
            pigs = pigData
        end
    end)
end

-- DrawText3D function
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Menu functions
function OpenFarmMenu()
    local farmMenu = {
        {
            header = "Trang Trại Lợn - " .. Config.NPCName,
            isMenuHeader = true
        },
        {
            header = "Bắt đầu nuôi lợn",
            txt = "Bắt đầu công việc nuôi lợn",
            params = {
                event = "pig-farming:client:StartFarming",
            }
        },
        {
            header = "Thông tin nuôi lợn",
            txt = "Xem thông tin về việc nuôi lợn",
            params = {
                event = "pig-farming:client:ShowFarmInfo",
            }
        },
        {
            header = "Đóng",
            txt = "",
            params = {
                event = ""
            }
        }
    }
    exports['qb-menu']:openMenu(farmMenu)
end

function OpenPigPenMenu()
    if not isInFarm then
        QBCore.Functions.Notify("Bạn cần nói chuyện với " .. Config.NPCName .. " để bắt đầu công việc.", "error")
        return
    end

    FetchPigs()
    Wait(250)  -- Đợi để đảm bảo dữ liệu đã được lấy
    
    local pigPenMenu = {
        {
            header = "Chuồng Lợn",
            isMenuHeader = true
        },
        {
            header = "Mua lợn giống",
            txt = "Giá: $500",
            params = {
                event = "pig-farming:client:BuyPig",
            }
        },
        {
            header = "Xem lợn của tôi",
            txt = "Kiểm tra lợn đang nuôi",
            params = {
                event = "pig-farming:client:ViewMyPigs",
            }
        },
        {
            header = "Bảng điều khiển",
            txt = "Mở bảng điều khiển nuôi lợn",
            params = {
                event = "pig-farming:client:OpenDashboard",
            }
        },
        {
            header = "Đóng",
            txt = "",
            params = {
                event = ""
            }
        }
    }
    exports['qb-menu']:openMenu(pigPenMenu)
end

function OpenSellMenu()
    QBCore.Functions.TriggerCallback('pig-farming:server:GetHarvestedPigs', function(harvestedPigs)
        if not harvestedPigs or #harvestedPigs == 0 then
            QBCore.Functions.Notify("Bạn không có lợn nào để bán.", "error")
            return
        end
        
        local sellMenu = {
            {
                header = "Bán Lợn - " .. Config.SellNPCName,
                isMenuHeader = true
            },
        }
        
        for i, pig in ipairs(harvestedPigs) do
            local total = math.floor(pig.weight * Config.PricePerKg)
            
            sellMenu[#sellMenu+1] = {
                header = "Lợn #" .. pig.id .. " - " .. pig.weight .. "kg",
                txt = "Giá bán: $" .. total,
                params = {
                    event = "pig-farming:client:SellPig",
                    args = {
                        pigId = pig.id
                    }
                }
            }
        end
        
        sellMenu[#sellMenu+1] = {
            header = "Bán tất cả",
            txt = "Bán tất cả lợn đã thu hoạch",
            params = {
                event = "pig-farming:client:SellAllPigs"
            }
        }
        
        sellMenu[#sellMenu+1] = {
            header = "Đóng",
            txt = "",
            params = {
                event = ""
            }
        }
        
        exports['qb-menu']:openMenu(sellMenu)
    end)
end

-- Event handlers
RegisterNetEvent('pig-farming:client:StartFarming', function()
    QBCore.Functions.TriggerCallback('pig-farming:server:CanStartFarming', function(canStart)
        if canStart then
            isInFarm = true
            QBCore.Functions.Notify("Bạn đã bắt đầu công việc nuôi lợn. Hãy đến chuồng lợn để bắt đầu.", "success")
        else
            QBCore.Functions.Notify("Bạn không thể bắt đầu công việc nuôi lợn lúc này.", "error")
        end
    end)
end)

RegisterNetEvent('pig-farming:client:ShowFarmInfo', function()
    QBCore.Functions.Notify("Nuôi lợn: Cho lợn ăn, uống nước và tắm cho chúng. Lợn sẽ lớn lên sau " .. Config.GrowthTime .. " phút và bạn có thể bán chúng.", "primary", 10000)
end)

RegisterNetEvent('pig-farming:client:ViewMyPigs', function()
    FetchPigs()
    Wait(250)  -- Đợi để đảm bảo dữ liệu đã được lấy
    
    if #pigs == 0 then
        QBCore.Functions.Notify("Bạn chưa có lợn nào.", "error")
        return
    end
    
    local pigMenu = {
        {
            header = "Lợn Của Tôi",
            isMenuHeader = true
        },
    }
    
    for i, pig in ipairs(pigs) do
        local growthPercent = math.floor((os.time() - pig.bornTime) / (Config.GrowthTime * 60) * 100)
        if growthPercent > 100 then growthPercent = 100 end
        
        local status = "Đang lớn: " .. growthPercent .. "%"
        if growthPercent >= 100 then
            status = "Đã trưởng thành - Sẵn sàng bán"
        end
        
        pigMenu[#pigMenu+1] = {
            header = "Lợn #" .. i .. " - " .. status,
            txt = "Cân nặng: " .. pig.weight .. "kg | Sinh lúc: " .. os.date("%H:%M:%S %d/%m/%Y", pig.bornTime),
            params = {
                event = "pig-farming:client:PigOptions",
                args = {
                    pigId = pig.id
                }
            }
        }
    end
    
    pigMenu[#pigMenu+1] = {
        header = "Đóng",
        txt = "",
        params = {
            event = ""
        }
    }
    
    exports['qb-menu']:openMenu(pigMenu)
end)

RegisterNetEvent('pig-farming:client:PigOptions', function(data)
    local pigId = data.pigId
    local pig = nil
    
    for i, p in ipairs(pigs) do
        if p.id == pigId then
            pig = p
            break
        end
    end
    
    if not pig then
        QBCore.Functions.Notify("Không tìm thấy thông tin lợn.", "error")
        return
    end
    
    local growthPercent = math.floor((os.time() - pig.bornTime) / (Config.GrowthTime * 60) * 100)
    if growthPercent > 100 then growthPercent = 100 end
    
    local pigOptionsMenu = {
        {
            header = "Lợn #" .. pigId,
            isMenuHeader = true
        },
        {
            header = "Cho ăn",
            txt = "Cần: " .. Config.Items.Feed,
            params = {
                event = "pig-farming:client:FeedPig",
                args = {
                    pigId = pigId
                }
            }
        },
        {
            header = "Cho uống nước",
            txt = "Cần: " .. Config.Items.Water,
            params = {
                event = "pig-farming:client:WaterPig",
                args = {
                    pigId = pigId
                }
            }
        },
        {
            header = "Tắm rửa",
            txt = "Cần: " .. Config.Items.Soap,
            params = {
                event = "pig-farming:client:CleanPig",
                args = {
                    pigId = pigId
                }
            }
        },
        {
            header = "Tự động chăm sóc",
            txt = "Chi phí: $" .. (Config.AutoCarePrice.Feed + Config.AutoCarePrice.Water + Config.AutoCarePrice.Clean),
            params = {
                event = "pig-farming:client:AutoCarePig",
                args = {
                    pigId = pigId
                }
            }
        }
    }
    
    if growthPercent >= 100 then
        pigOptionsMenu[#pigOptionsMenu+1] = {
            header = "Thu hoạch lợn",
            txt = "Đem lợn đi bán",
            params = {
                event = "pig-farming:client:HarvestPig",
                args = {
                    pigId = pigId
                }
            }
        }
    end
    
    pigOptionsMenu[#pigOptionsMenu+1] = {
        header = "Quay lại",
        txt = "",
        params = {
            event = "pig-farming:client:ViewMyPigs"
        }
    }
    
    exports['qb-menu']:openMenu(pigOptionsMenu)
end)

RegisterNetEvent('pig-farming:client:BuyPig', function()
    QBCore.Functions.TriggerCallback('pig-farming:server:BuyPig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã mua một lợn giống. Hãy chăm sóc nó tốt nhé!", "success")
            FetchPigs()
        else
            QBCore.Functions.Notify("Bạn không thể mua thêm lợn. Kiểm tra lại số tiền hoặc số lượng lợn hiện tại.", "error")
        end
    end)
end)

RegisterNetEvent('pig-farming:client:FeedPig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:FeedPig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã cho lợn #" .. data.pigId .. " ăn.", "success")
        else
            QBCore.Functions.Notify("Bạn không có thức ăn cho lợn.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:WaterPig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:WaterPig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã cho lợn #" .. data.pigId .. " uống nước.", "success")
        else
            QBCore.Functions.Notify("Bạn không có nước cho lợn.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:CleanPig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:CleanPig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã tắm cho lợn #" .. data.pigId .. ".", "success")
        else
            QBCore.Functions.Notify("Bạn không có xà phòng để tắm cho lợn.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:AutoCarePig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:AutoCarePig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã tự động chăm sóc lợn #" .. data.pigId .. ".", "success")
        else
            QBCore.Functions.Notify("Bạn không đủ tiền để tự động chăm sóc lợn.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:HarvestPig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:HarvestPig', function(success)
        if success then
            QBCore.Functions.Notify("Bạn đã thu hoạch lợn #" .. data.pigId .. ". Hãy đến điểm bán lợn.", "success")
            FetchPigs()
        else
            QBCore.Functions.Notify("Không thể thu hoạch lợn này.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:OpenSellMenu', function()
    OpenSellMenu()
end)

RegisterNetEvent('pig-farming:client:SellPig', function(data)
    QBCore.Functions.TriggerCallback('pig-farming:server:SellPig', function(success, money, meatAmount)
        if success then
            QBCore.Functions.Notify("Bạn đã bán lợn #" .. data.pigId .. " và nhận được $" .. money .. " và " .. meatAmount .. " miếng thịt lợn.", "success")
        else
            QBCore.Functions.Notify("Không thể bán lợn này.", "error")
        end
    end, data.pigId)
end)

RegisterNetEvent('pig-farming:client:SellAllPigs', function()
    QBCore.Functions.TriggerCallback('pig-farming:server:SellAllPigs', function(success, totalMoney, totalMeat)
        if success then
            QBCore.Functions.Notify("Bạn đã bán tất cả lợn và nhận được $" .. totalMoney .. " và " .. totalMeat .. " miếng thịt lợn.", "success")
        else
            QBCore.Functions.Notify("Không thể bán lợn.", "error")
        end
    end)
end)

RegisterNetEvent('pig-farming:client:OpenDashboard', function()
    FetchPigs()
    
    if #pigs == 0 then
        QBCore.Functions.Notify("Bạn chưa có lợn nào để xem.", "error")
        return
    end
    
    uiActive = true
    SendNUIMessage({
        action = "openDashboard",
        pigs = pigs,
        config = {
            growthTime = Config.GrowthTime,
            feedTime = Config.FeedTime,
            waterTime = Config.WaterTime,
            cleanTime = Config.CleanTime
        }
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeDashboard', function()
    uiActive = false
    SetNuiFocus(false, false)
end)

-- Vòng lặp chính cho sự kiện tương tác
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        
        -- Tương tác với NPC chính
        local npcDist = #(pos - vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z))
        if npcDist < 5.0 then
            sleep = 0
            DrawText3D(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z + 1.0, "[E] Nói chuyện với " .. Config.NPCName)
            if npcDist < 2.0 and IsControlJustPressed(0, 38) then -- E key
                OpenFarmMenu()
            end
        end
        
        -- Tương tác với chuồng lợn
        local penDist = #(pos - vector3(Config.PigPenLocation.x, Config.PigPenLocation.y, Config.PigPenLocation.z))
        if penDist < 5.0 then
            sleep = 0
            DrawText3D(Config.PigPenLocation.x, Config.PigPenLocation.y, Config.PigPenLocation.z + 1.0, "[E] Tương tác với chuồng lợn")
            if penDist < 2.0 and IsControlJustPressed(0, 38) then -- E key
                OpenPigPenMenu()
            end
        end
        
        -- Tương tác với NPC bán lợn
        local sellDist = #(pos - vector3(Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z))
        if sellDist < 5.0 then
            sleep = 0
            DrawText3D(Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z + 1.0, "[E] Nói chuyện với " .. Config.SellNPCName)
            if sellDist < 2.0 and IsControlJustPressed(0, 38) then -- E key
                OpenSellMenu()
            end
        end
        
        Wait(sleep)
    end
end)

-- Update thông tin lợn liên tục khi UI đang mở
CreateThread(function()
    while true do
        Wait(1000)
        if uiActive then
            FetchPigs()
            SendNUIMessage({
                action = "updatePigs",
                pigs = pigs
            })
        end
    end
end)

-- Cập nhật thông tin lợn từ server
RegisterNetEvent('pig-farming:client:UpdatePigs', function(pigData)
    pigs = pigData
    if uiActive then
        SendNUIMessage({
            action = "updatePigs",
            pigs = pigs
        })
    end
end)

-- Tự động khởi tạo khi resource khởi động
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        PlayerData = QBCore.Functions.GetPlayerData()
        LoadFarm()
        FetchPigs()
    end
end)

