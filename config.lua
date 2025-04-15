Config = {}

-- Vị trí NPC
Config.NPCLocation = vector4(2388.51, 5044.25, 45.99, 270.39)
Config.NPCModel = "a_m_m_farmer_01"
Config.NPCName = "Ông Năm"

-- Vị trí chuồng lợn
Config.PigPenLocation = vector3(2382.85, 5047.25, 45.34)
Config.PigPenRadius = 20.0

-- Vị trí bán lợn
Config.SellLocation = vector4(2343.91, 5007.34, 42.08, 129.17)
Config.SellNPCModel = "a_m_m_farmer_01"
Config.SellNPCName = "Chú Bảy"

-- Thời gian nuôi lợn (phút)
Config.GrowthTime = 10  -- thời gian để lợn lớn

-- Chu kỳ chăm sóc (phút)
Config.FeedTime = 2     -- chu kỳ cho ăn
Config.WaterTime = 3    -- chu kỳ cho uống
Config.CleanTime = 5    -- chu kỳ tắm rửa

-- Phần thưởng
Config.Rewards = {
    Money = {
        Min = 1000,
        Max = 5000
    },
    PorkMeat = {
        Item = "pork_meat",
        Min = 1,
        Max = 5
    }
}

-- Giá mỗi kg lợn
Config.PricePerKg = 100

-- Trọng lượng lợn (kg)
Config.PigWeight = {
    Min = 80,
    Max = 120
}

-- Vật phẩm cần thiết
Config.Items = {
    Feed = "pig_feed",
    Water = "water_bucket",
    Soap = "pig_soap"
}

-- Chi phí tự động chăm sóc (tiền)
Config.AutoCarePrice = {
    Feed = 200,
    Water = 100,
    Clean = 300
}

-- Thời gian hiển thị DrawText (ms)
Config.DrawTextDuration = 5000
