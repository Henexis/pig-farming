Config = {}

-- Locations
Config.NPCLocation = vector4(2388.52, 5044.39, 45.99, 174.25) -- Vị trí NPC chính
Config.PigPenLocation = vector3(2385.39, 5047.23, 46.40) -- Vị trí chuồng lợn
Config.SellLocation = vector4(972.12, -2111.56, 31.39, 82.56) -- Vị trí bán lợn

-- NPC Info
Config.NPCName = "Ông Năm"
Config.NPCModel = "a_m_m_farmer_01"
Config.SellNPCName = "Bác Sáu"
Config.SellNPCModel = "s_m_m_cntrybar_01"

-- Pig Farming Settings
Config.GrowthTime = 10 -- Thời gian lợn phát triển (phút)
Config.FeedTime = 2 -- Thời gian lợn đói (phút)
Config.WaterTime = 3 -- Thời gian lợn khát (phút)
Config.CleanTime = 5 -- Thời gian lợn bẩn (phút)

-- Pig Weight Range
Config.PigWeight = {
    Min = 80,
    Max = 150
}

-- Prices
Config.PricePerKg = 12 -- Giá tiền mỗi kg lợn
Config.AutoCarePrice = {
    Feed = 50,
    Water = 30,
    Clean = 40
}

-- Items
Config.Items = {
    Feed = "pig_feed",  -- Thức ăn lợn
    Water = "water_bucket", -- Xô nước
    Soap = "pig_soap"   -- Xà phòng tắm lợn
}

-- Rewards
Config.Rewards = {
    PorkMeat = {
        Item = "pork_meat",
        Min = 5,
        Max = 15
    }
}
