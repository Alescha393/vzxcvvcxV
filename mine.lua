-- Advanced Mining Turtle v2.0 (1.20.1+)
-- Universal fuel finder & smart ore scanner

-- ===== CONFIGURATION =====
local TARGET_ORE = "minecraft:iron_ore" -- Change to any ore ID
local SCAN_RADIUS = 6                   -- How far to search (3D cube)
local FUEL_ITEMS = {                    -- All possible fuel sources
    "minecraft:coal",
    "minecraft:coal_block",
    "minecraft:charcoal",
    "minecraft:lava_bucket",
    "minecraft:blaze_rod"
}

-- ===== MOVEMENT TRACKING =====
local pathHistory = {}
local startOrientation = 0

local function logMove(cmd)
    table.insert(pathHistory, 1, cmd)
end

local function returnToStart()
    print("Returning to start...")
    for _, move in ipairs(pathHistory) do
        if move == "F" then turtle.back()
        elseif move == "B" then turtle.forward()
        elseif move == "U" then turtle.down()
        elseif move == "D" then turtle.up()
        elseif move == "L" then turtle.turnRight()
        elseif move == "R" then turtle.turnLeft()
        end
        sleep(0.1)
    end
    -- Restore original facing
    for i = 1, startOrientation do turtle.turnRight() end
    pathHistory = {}
    print("Successfully returned!")
end

-- ===== IMPROVED FUEL SYSTEM =====
local function findAndRefuel()
    local currentFuel = turtle.getFuelLevel()
    if currentFuel > 500 then return true end
    
    print("Fuel low ("..currentFuel.."). Searching for fuel...")
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, fuelName in ipairs(FUEL_ITEMS) do
                if item.name == fuelName then
                    turtle.select(slot)
                    local needed = math.ceil((1000 - currentFuel) / 80)
                    local refuelAmount = math.min(needed, item.count)
                    
                    if turtle.refuel(refuelAmount) then
                        print("Refueled with "..item.name.." from slot "..slot)
                        print("Fuel now: "..turtle.getFuelLevel())
                        return true
                    end
                end
            end
        end
    end
    
    print("CRITICAL: No fuel found in inventory!")
    print("Please add: coal, charcoal, coal block, lava bucket or blaze rod")
    return false
end

-- ===== 3D ORE SCANNER =====
local function scanForOre(radius)
    print("Starting 3D scan (radius: "..radius..")...")
    
    -- Scan current position first (up/down)
    local checks = {
        {"Down", turtle.inspectDown}, {"Up", turtle.inspectUp},
        {"North", turtle.inspect}
    }
    
    for _, check in ipairs(checks) do
        local success, data = check[2]()
        if success and data.name == TARGET_ORE then
            print("Found "..TARGET_ORE.." "..check[1].."!")
            return check[1]
        end
    end
    
    -- Systematic 3D search pattern
    for r = 1, radius do
        print("Scanning layer "..r.."...")
        
        -- Search pattern: spiral + vertical
        for dir = 1, 4 do
            for step = 1, r * 2 do
                if not turtle.forward() then
                    if turtle.detect() then turtle.dig() end
                    turtle.forward()
                end
                logMove("F")
                
                -- Check all directions at each position
                local directions = {
                    {"Front", turtle.inspect},
                    {"Up", turtle.inspectUp},
                    {"Down", turtle.inspectDown}
                }
                
                for _, scan in ipairs(directions) do
                    local success, data = scan[2]()
                    if success and data.name == TARGET_ORE then
                        print("Found "..TARGET_ORE.." "..scan[1].." at distance "..r)
                        return scan[1]
                    end
                end
            end
            turtle.turnRight()
            logMove("R")
        end
    end
    
    return nil
end

-- ===== VEIN MINING =====
local minedBlocks = {}

local function mineVeinAt(x, y, z)
    local key = x..","..y..","..z
    if minedBlocks[key] then return end
    minedBlocks[key] = true
    
    local function checkDirection(dx, dy, dz, digFunc, inspectFunc, moveFunc, reverseFunc)
        -- Simplified position check
        local success, data = inspectFunc()
        if success and data.name == TARGET_ORE then
            digFunc()
            sleep(0.2)
            moveFunc()
            mineVeinAt(x+dx, y+dy, z+dz)
            reverseFunc()
        end
    end
    
    -- Check all 6 directions
    checkDirection(0, 1, 0, turtle.digUp, turtle.inspectUp, turtle.up, turtle.down)
    checkDirection(0, -1, 0, turtle.digDown, turtle.inspectDown, turtle.down, turtle.up)
    checkDirection(0, 0, 1, turtle.dig, turtle.inspect, turtle.forward, turtle.back)
    
    turtle.turnRight()
    checkDirection(1, 0, 0, turtle.dig, turtle.inspect, turtle.forward, turtle.back)
    turtle.turnRight();turtle.turnRight()
    checkDirection(-1, 0, 0, turtle.dig, turtle.inspect, turtle.forward, turtle.back)
    turtle.turnRight()
    checkDirection(0, 0, -1, turtle.dig, turtle.inspect, turtle.forward, turtle.back)
    turtle.turnRight()
end

-- ===== MAIN TEST FUNCTION =====
local function runAdvancedTest()
    print("=== ADVANCED ORE SCANNER ===")
    print("Target: "..TARGET_ORE)
    print("Fuel: "..turtle.getFuelLevel())
    
    if not findAndRefuel() then
        print("Aborting: no fuel available")
        return
    end
    
    startOrientation = 0
    minedBlocks = {}
    
    -- Phase 1: Initial scan around start
    local oreLocation = scanForOre(SCAN_RADIUS)
    
    if not oreLocation then
        print("No "..TARGET_ORE.." found within "..SCAN_RADIUS.." blocks")
        returnToStart()
        return
    end
    
    -- Phase 2: Mine the vein
    print("Mining vein...")
    mineVeinAt(0, 0, 0)
    
    -- Phase 3: Smart inventory cleanup
    print("Cleaning inventory...")
    local keptItems = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            -- Keep ALL ores and potential fuel
            if item.name:find("ore") or item.name:find("coal") or item.name:find("raw_") then
                keptItems = keptItems + 1
            else
                turtle.select(slot)
                turtle.dropDown()
            end
        end
    end
    print("Kept "..keptItems.." valuable items")
    
    -- Phase 4: Return
    returnToStart()
    print("Mining operation complete!")
end

-- ===== COMMAND HANDLER =====
local args = {...}

if args[1] == "test" then
    if args[2] then
        TARGET_ORE = args[2]
        print("New target ore: "..TARGET_ORE)
    end
    runAdvancedTest()
    
elseif args[1] == "scan" then
    local radius = tonumber(args[2]) or 3
    print("Quick scan mode...")
    local found = scanForOre(radius)
    if found then
        print("Located: "..found)
    else
        print("Nothing found")
    end
    returnToStart()
    
elseif args[1] == "fuel" then
    findAndRefuel()
    
else
    print("=== Mining Turtle OS ===")
    print("Commands:")
    print("  test [ore_id]  - Find & mine ore (default: iron)")
    print("  scan [radius]  - Scan area without mining")
    print("  fuel           - Refuel from inventory")
    print("  home           - Return to start position")
    print("\nExample: 'test minecraft:diamond_ore'")
end
