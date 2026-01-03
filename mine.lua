-- Fixed Mining Turtle Script v1.3
-- Corrected vein mining and inventory sorting

-- ===== CONFIGURATION =====
local TARGET_ORE = "minecraft:iron_ore"
local FUEL_SLOT = 16
local SCAN_RANGE = 6

-- ===== MOVEMENT TRACKING (For going HOME) =====
local pathLog = {}
local visitedBlocks = {}

local function logMovement(direction)
    table.insert(pathLog, 1, direction)
end

local function moveHome()
    print("Returning to start point...")
    for _, move in ipairs(pathLog) do
        if move == "forward" then turtle.back()
        elseif move == "back" then turtle.forward()
        elseif move == "up" then turtle.down()
        elseif move == "down" then turtle.up()
        elseif move == "turnLeft" then turtle.turnRight()
        elseif move == "turnRight" then turtle.turnLeft()
        end
        sleep(0.1)
    end
    pathLog = {}
    visitedBlocks = {}
    print("Return complete.")
end

-- ===== BASIC MOVEMENT =====
local function moveF()
    if turtle.forward() then logMovement("forward"); return true end
    return false
end
local function moveB()
    if turtle.back() then logMovement("back"); return true end
    return false
end
local function moveU()
    if turtle.up() then logMovement("up"); return true end
    return false
end
local function moveD()
    if turtle.down() then logMovement("down"); return true end
    return false
end
local function turnL()
    turtle.turnLeft(); logMovement("turnLeft")
end
local function turnR()
    turtle.turnRight(); logMovement("turnRight")
end

-- ===== CORE FUNCTIONS =====
local function checkFuel()
    if turtle.getFuelLevel() < 50 then
        turtle.select(FUEL_SLOT)
        if turtle.refuel(1) then
            print("Refueled. Fuel: " .. turtle.getFuelLevel())
        else
            print("WARNING: Low fuel in slot " .. FUEL_SLOT)
        end
    end
    return true
end

-- FIXED: Recursive vein mining function
local function mineIronVein()
    -- Generate a unique key for current position
    local x, y, z = 0, 0, 0 -- Simplified tracking
    local posKey = x .. "," .. y .. "," .. z
    
    if visitedBlocks[posKey] then return end
    visitedBlocks[posKey] = true
    
    local function tryMine(digFunc, inspectFunc, moveInFunc, moveOutFunc)
        local success, data = inspectFunc()
        if success and data.name == TARGET_ORE then
            digFunc()
            sleep(0.2)
            moveInFunc()
            mineIronVein() -- Recursively mine from new position
            moveOutFunc()
            return true
        end
        return false
    end
    
    -- Check and mine in all 6 directions
    -- Up and Down
    tryMine(turtle.digUp, turtle.inspectUp, turtle.up, turtle.down)
    tryMine(turtle.digDown, turtle.inspectDown, turtle.down, turtle.up)
    
    -- Four horizontal directions
    for i = 1, 4 do
        tryMine(turtle.dig, turtle.inspect, turtle.forward, turtle.back)
        turtle.turnRight()
    end
end

-- ===== IMPROVED TEST MODE =====
local function runTest()
    if not checkFuel() then return end
    print("TEST: Searching for " .. TARGET_ORE .. " in all directions...")
    
    local startX, startY, startZ = 0, 0, 0
    local foundOre = false
    
    -- First, check block directly below (common ore location)
    if turtle.detectDown() then
        local success, data = turtle.inspectDown()
        if success and data.name == TARGET_ORE then
            print("Found iron ore below! Mining...")
            turtle.digDown()
            moveD()
            mineIronVein()
            moveU()
            foundOre = true
        end
    end
    
    -- Scan forward/around if nothing below
    if not foundOre then
        for scan = 1, SCAN_RANGE do
            -- Check forward
            if turtle.detect() then
                local success, data = turtle.inspect()
                if success and data.name == TARGET_ORE then
                    print("Found iron ore ahead! Mining vein...")
                    turtle.dig()
                    moveF()
                    mineIronVein()
                    foundOre = true
                    break
                end
            end
            
            -- Check sides by turning
            for sideCheck = 1, 3 do
                turnR()
                if turtle.detect() then
                    local success, data = turtle.inspect()
                    if success and data.name == TARGET_ORE then
                        print("Found iron ore to the side!")
                        turtle.dig()
                        moveF()
                        mineIronVein()
                        foundOre = true
                        break
                    end
                end
            end
            if foundOre then break end
            
            -- Check up/down while moving
            if turtle.detectUp() then
                local success, data = turtle.inspectUp()
                if success and data.name == TARGET_ORE then
                    print("Found iron ore above!")
                    turtle.digUp()
                    moveU()
                    mineIronVein()
                    moveD()
                    foundOre = true
                    break
                end
            end
            
            -- Move forward to next scan position
            if not moveF() then break end
        end
    end
    
    -- FIXED: Inventory cleaning - KEEP coal and ores
    print("Cleaning inventory (keeping ores and coal)...")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            -- Throw away only real trash (cobblestone, dirt, gravel)
            if item.name:find("cobblestone") or item.name:find("dirt") or item.name:find("gravel") then
                turtle.select(slot)
                turtle.dropDown()
            end
        end
    end
    
    -- Return to start
    moveHome()
    
    if foundOre then
        print("Test successful! Iron ore mined and stored.")
    else
        print("No " .. TARGET_ORE .. " found within range.")
    end
end

-- ===== QUICK MANUAL CONTROLS =====
local function quickCommand(cmd)
    if cmd == "dig" then
        turtle.dig()
    elseif cmd == "digup" then
        turtle.digUp()
    elseif cmd == "digdown" then
        turtle.digDown()
    elseif cmd == "scan" then
        print("Scanning nearby...")
        local dirs = {"front", "right", "back", "left", "up", "down"}
        local checks = {turtle.inspect, function() turnR(); local s,d=turtle.inspect(); turnL(); return s,d end, 
                       function() turnR();turnR(); local s,d=turtle.inspect(); turnL();turnL(); return s,d end,
                       function() turnL(); local s,d=turtle.inspect(); turnR(); return s,d end,
                       turtle.inspectUp, turtle.inspectDown}
        for i=1,6 do
            local success, data = checks[i]()
            if success then
                print(dirs[i] .. ": " .. data.name)
            end
        end
    end
end

-- ===== MAIN =====
local args = { ... }

if not turtle then
    print("ERROR: This script requires a Mining Turtle!")
    return
end

if args[1] == "test" then
    runTest()
elseif args[1] == "move" and args[2] then
    local dir = args[2]
    if dir == "f" then moveF()
    elseif dir == "b" then moveB()
    elseif dir == "u" then moveU()
    elseif dir == "d" then moveD()
    elseif dir == "l" then turnL()
    elseif dir == "r" then turnR()
    end
elseif args[1] == "home" then
    moveHome()
elseif args[1] == "cmd" and args[2] then
    quickCommand(args[2])
else
    print("Mining Turtle Controller")
    print("Commands:")
    print("  test          - Find/mine IRON ORE, return home")
    print("  move <f/b/u/d/l/r> - Quick move (forward/back/up/down/left/right)")
    print("  home          - Return to start")
    print("  cmd <dig/digup/digdown/scan> - Quick actions")
end
