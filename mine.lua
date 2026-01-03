-- Mining Turtle Script with Mod Support
-- Colin's Survival Script v1.2 (English only)

-- === CONFIGURATION ===
local oreIds = {
    -- Vanilla ores
    "minecraft:coal_ore",
    "minecraft:iron_ore",
    "minecraft:gold_ore",
    "minecraft:diamond_ore",
    "minecraft:emerald_ore",
    "minecraft:redstone_ore",
    "minecraft:lapis_ore",
    "minecraft:copper_ore",
    "minecraft:nether_quartz_ore",
    "minecraft:ancient_debris",
    -- Add mod ores below
    -- "thermal:tin_ore",
    -- "immersiveengineering:ore_aluminum",
    -- "mekanism:osmium_ore"
}

local MAIN_TUNNEL_LENGTH = 16
local TUNNEL_COUNT = 4
local FUEL_SLOT = 16

-- === SYSTEM FUNCTIONS ===
local function isTurtle()
    return turtle ~= nil
end

local function checkFuel()
    if turtle.getFuelLevel() < MAIN_TUNNEL_LENGTH * TUNNEL_COUNT * 3 then
        print("Refueling...")
        turtle.select(FUEL_SLOT)
        if turtle.refuel(1) then
            print("Fuel: " .. turtle.getFuelLevel())
        else
            print("ERROR: No fuel in slot " .. FUEL_SLOT)
            return false
        end
    end
    return true
end

local function isOre(blockName)
    for _, id in ipairs(oreIds) do
        if blockName == id then
            return true
        end
    end
    return false
end

-- === MINING FUNCTIONS ===
local function mineVein()
    local success, data = turtle.inspect()
    if not success then return end
    
    if isOre(data.name) then
        turtle.dig()
        sleep(0.3)
        
        for i = 1, 4 do
            turtle.turnLeft()
            local sideSuccess, sideData = turtle.inspect()
            if sideSuccess and isOre(sideData.name) then
                mineVein()
            end
        end
        turtle.turnRight()
        
        if turtle.detectUp() then
            local upSuccess, upData = turtle.inspectUp()
            if upSuccess and isOre(upData.name) then
                turtle.digUp()
                turtle.up()
                mineVein()
                turtle.down()
            end
        end
        
        if turtle.detectDown() then
            local downSuccess, downData = turtle.inspectDown()
            if downSuccess and isOre(downData.name) then
                turtle.digDown()
                turtle.down()
                mineVein()
                turtle.up()
            end
        end
    end
end

local function excavateTunnel(length)
    for i = 1, length do
        if not checkFuel() then return false end
        
        if turtle.detect() then
            local success, data = turtle.inspect()
            if success and isOre(data.name) then
                print("Found: " .. data.name)
                mineVein()
            else
                turtle.dig()
            end
        end
        
        if turtle.detectUp() then
            local success, data = turtle.inspectUp()
            if success and isOre(data.name) then
                print("Found above: " .. data.name)
                turtle.digUp()
            end
        end
        
        if turtle.detectDown() then
            local success, data = turtle.inspectDown()
            if success and isOre(data.name) then
                print("Found below: " .. data.name)
                turtle.digDown()
            end
        end
        
        for s = 1, 16 do
            local item = turtle.getItemDetail(s)
            if item and not isOre(item.name) and item.name:find("ore") == nil then
                turtle.select(s)
                turtle.dropDown()
            end
        end
        
        turtle.forward()
        sleep(0.2)
    end
    return true
end

local function mainMiningLoop()
    print("=== MINING TURTLE SYSTEM ===")
    print("Fuel: " .. turtle.getFuelLevel())
    print("Tracking: " .. #oreIds .. " ore types")
    print("Press Ctrl+T to stop")
    print("==========================")
    
    for tunnel = 1, TUNNEL_COUNT do
        print("Tunnel #" .. tunnel .. "...")
        
        if not excavateTunnel(MAIN_TUNNEL_LENGTH) then
            print("Stopping: low fuel")
            return
        end
        
        if tunnel < TUNNEL_COUNT then
            turtle.turnRight()
            turtle.forward()
            turtle.forward()
            turtle.turnRight()
        end
    end
    
    print("Returning to base...")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, TUNNEL_COUNT * 2 do turtle.forward() end
    turtle.turnLeft()
    turtle.turnLeft()
    
    print("Unloading resources...")
    for s = 1, 16 do
        turtle.select(s)
        turtle.drop()
    end
    
    print("Mining complete. Resources in chest.")
end

-- === TEST COMMAND ===
local function executeTest()
    print("[TEST] Test mode activated")
    print("[TEST] Moving forward 10 blocks...")
    
    for i = 1, 10 do
        if turtle.detect() then turtle.dig() end
        turtle.forward()
        sleep(0.5)
    end
    
    print("[TEST] Waiting 60 seconds...")
    for sec = 1, 60 do
        os.sleep(1)
        if sec % 10 == 0 then
            print("[TEST] " .. sec .. " seconds passed")
        end
    end
    
    print("[TEST] Returning...")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, 10 do
        turtle.forward()
        sleep(0.3)
    end
    turtle.turnLeft()
    turtle.turnLeft()
    
    print("[TEST] Test completed successfully")
    return true
end

-- === MAIN PROGRAM ===
local args = { ... }

if not isTurtle() then
    print("ERROR: This script requires a Mining Turtle!")
    print("1. Craft: Mining Turtle")
    print("2. Place fuel in slot " .. FUEL_SLOT)
    print("3. Run: mine")
    return
end

if args[1] == "test" then
    if checkFuel() then
        executeTest()
    else
        print("ERROR: Not enough fuel for test")
    end
elseif args[1] == "addore" and args[2] then
    table.insert(oreIds, args[2])
    print("Added ore: " .. args[2])
    print("Total ores: " .. #oreIds)
elseif args[1] == "list" then
    print("Loaded ore IDs:")
    for i, ore in ipairs(oreIds) do
        print(i .. ". " .. ore)
    end
else
    if checkFuel() then
        mainMiningLoop()
    else
        print("ERROR: Not enough fuel")
        print("Place fuel in slot " .. FUEL_SLOT)
    end
end
