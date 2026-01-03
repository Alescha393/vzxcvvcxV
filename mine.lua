-- Advanced Mining Turtle v3.1 (Fixed)
-- Usage: miner start 60  (dig for 60 minutes)

-- ===== CONFIGURATION =====
local MINING_DEPTH = 15           -- How deep to go before digging tunnels
local TUNNEL_LENGTH = 30          -- Length of each tunnel branch
local MAIN_SHAFT_WIDTH = 1        -- Width of main shaft (1 or 2)
local MAX_MISSION_TIME = 180 * 60 -- Maximum mission time (3 hours)

-- Fuel items for auto-refuel (Minecraft 1.20.1)
local FUEL_ITEMS = {
    "minecraft:coal",
    "minecraft:coal_block",
    "minecraft:charcoal",
    "minecraft:lava_bucket",
    "minecraft:blaze_rod"
}

-- Valuable items (won't be thrown away)
local VALUABLE_ITEMS = {
    "ore", "raw_", "coal", "diamond", "emerald",
    "iron", "gold", "copper", "quartz", "lapis",
    "redstone", "ancient_debris", "netherite"
}

-- ===== SYSTEM VARIABLES =====
local startTime = 0
local missionDuration = 0
local pathHistory = {}  -- Movement history for return

-- ===== FUEL MANAGEMENT =====
local function findAndRefuel()
    local currentFuel = turtle.getFuelLevel()
    if currentFuel > 500 then return true end
    
    print("Low fuel ("..currentFuel.."). Searching...")
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, fuelName in ipairs(FUEL_ITEMS) do
                if item.name == fuelName then
                    turtle.select(slot)
                    local needed = math.ceil((1000 - currentFuel) / 80)
                    local toRefuel = math.min(needed, item.count)
                    
                    if turtle.refuel(toRefuel) then
                        print("Refueled with "..item.name.." (Fuel: "..turtle.getFuelLevel()..")")
                        return true
                    end
                end
            end
        end
    end
    
    print("WARNING: No fuel found! Add coal/charcoal to inventory.")
    return false
end

-- ===== PATH TRACKING =====
local function logMove(direction)
    table.insert(pathHistory, direction)
end

local function returnToStart()
    print("Returning to start point...")
    
    -- Follow reverse path
    for i = #pathHistory, 1, -1 do
        local move = pathHistory[i]
        
        if not findAndRefuel() then
            print("CRITICAL: Not enough fuel for return!")
            break
        end
        
        if move == "down" then turtle.up()
        elseif move == "up" then turtle.down()
        elseif move == "forward" then turtle.back()
        elseif move == "back" then turtle.forward()
        elseif move == "turnLeft" then turtle.turnRight()
        elseif move == "turnRight" then turtle.turnLeft()
        end
        
        sleep(0.1)
    end
    
    -- Unload resources to chest (must be behind at start)
    print("Unloading inventory...")
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.drop()
    end
    
    pathHistory = {}
    print("Mission complete!")
end

-- ===== BASIC MOVEMENT =====
local function moveDown()
    if turtle.down() then logMove("down"); return true end
    if turtle.detectDown() then turtle.digDown(); return moveDown() end
    return false
end

local function moveUp()
    if turtle.up() then logMove("up"); return true end
    if turtle.detectUp() then turtle.digUp(); return moveUp() end
    return false
end

local function moveForward()
    if turtle.forward() then logMove("forward"); return true end
    if turtle.detect() then turtle.dig(); return moveForward() end
    return false
end

local function turnLeft()
    turtle.turnLeft()
    logMove("turnLeft")
end

local function turnRight()
    turtle.turnRight()
    logMove("turnRight")
end

-- ===== DESCEND TO MINING LEVEL =====
local function descendToMiningLevel()
    print("Descending to mining level...")
    
    for level = 1, MINING_DEPTH do
        if not findAndRefuel() then
            print("Cannot descend: no fuel!")
            return false
        end
        
        if not moveDown() then
            print("Cannot go deeper at level "..level)
            return false
        end
        
        -- Widen shaft if needed
        if MAIN_SHAFT_WIDTH > 1 then
            turnRight()
            if turtle.detect() then turtle.dig() end
            turnLeft(); turnLeft()
            if turtle.detect() then turtle.dig() end
            turnRight()
        end
    end
    
    return true
end

-- ===== ORE CHECK =====
local function isValuable(blockName)
    for _, valuable in ipairs(VALUABLE_ITEMS) do
        if blockName:find(valuable) then
            return true
        end
    end
    return false
end

-- ===== VEIN MINING =====
local function mineVein()
    local function checkDirection(inspectFunc, digFunc, moveInFunc, moveOutFunc)
        local success, data = inspectFunc()
        if success and isValuable(data.name) then
            digFunc()
            sleep(0.2)
            moveInFunc()
            mineVein()  -- Recursively check from new position
            moveOutFunc()
            return true
        end
        return false
    end
    
    -- Check all 6 directions
    checkDirection(turtle.inspectUp, turtle.digUp, turtle.up, turtle.down)
    checkDirection(turtle.inspectDown, turtle.digDown, turtle.down, turtle.up)
    
    for i = 1, 4 do
        checkDirection(turtle.inspect, turtle.dig, turtle.forward, turtle.back)
        turtle.turnRight()
    end
end

-- ===== DIG TUNNEL =====
local function digTunnel(length)
    print("Digging tunnel ("..length.." blocks)...")
    
    for i = 1, length do
        -- Check time
        if os.time() - startTime >= missionDuration then
            print("Time's up! Starting return...")
            return false
        end
        
        if not findAndRefuel() then
            print("Out of fuel! Returning...")
            return false
        end
        
        -- Dig forward
        if not moveForward() then
            print("Cannot move forward. Returning...")
            return false
        end
        
        -- Check blocks around for ores
        local function checkAround()
            -- Above
            local success, data = turtle.inspectUp()
            if success and isValuable(data.name) then
                turtle.digUp()
                turtle.up()
                mineVein()
                turtle.down()
            end
            
            -- Below
            success, data = turtle.inspectDown()
            if success and isValuable(data.name) then
                turtle.digDown()
                turtle.down()
                mineVein()
                turtle.up()
            end
            
            -- Sides
            for side = 1, 4 do
                turtle.turnRight()
                success, data = turtle.inspect()
                if success and isValuable(data.name) then
                    turtle.dig()
                    turtle.forward()
                    mineVein()
                    turtle.back()
                end
            end
        end
        
        checkAround()
        
        -- Inventory cleanup every 5 blocks
        if i % 5 == 0 then
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    local keep = false
                    for _, valuable in ipairs(VALUABLE_ITEMS) do
                        if item.name:find(valuable) then
                            keep = true
                            break
                        end
                    end
                    
                    if not keep then
                        turtle.select(slot)
                        turtle.dropDown()
                    end
                end
            end
        end
        
        -- Progress report every 10 blocks
        if i % 10 == 0 then
            local elapsed = os.time() - startTime
            local remaining = missionDuration - elapsed
            print("Progress: "..i.."/"..length..", Time left: "..math.floor(remaining/60).."m")
        end
    end
    
    return true
end

-- ===== MINING PATTERN =====
local function minePattern()
    local patterns = {
        {"straight", TUNNEL_LENGTH},
        {"right", 10},
        {"back", TUNNEL_LENGTH},
        {"right", 10},
        {"straight", TUNNEL_LENGTH}
    }
    
    for _, pattern in ipairs(patterns) do
        if os.time() - startTime >= missionDuration then break end
        
        if pattern[1] == "straight" then
            if not digTunnel(pattern[2]) then return false end
        elseif pattern[1] == "right" then
            turnRight()
            if not digTunnel(pattern[2]) then return false end
            turnLeft()
        end
    end
    
    return true
end

-- ===== MAIN FUNCTION =====
local function startMiningMission(minutes)
    print("=== MINING MISSION STARTED ===")
    print("Duration: "..minutes.." minutes")
    print("Target depth: "..MINING_DEPTH.." blocks")
    print("Preparing...")
    
    startTime = os.time()
    missionDuration = minutes * 60
    pathHistory = {}
    
    -- Initial fuel check
    if not findAndRefuel() then
        print("ABORT: Not enough fuel to start mission!")
        return
    end
    
    -- Phase 1: Descend
    if not descendToMiningLevel() then
        returnToStart()
        return
    end
    
    -- Phase 2: Mine until time runs out
    local lastCheck = os.time()
    while os.time() - startTime < missionDuration do
        if not minePattern() then
            break
        end
        
        -- Turn around to mine new area
        turnRight(); turnRight()
        
        -- Time check every minute
        if os.time() - lastCheck >= 60 then
            local elapsed = os.time() - startTime
            local remaining = missionDuration - elapsed
            print("Mining... "..math.floor(elapsed/60).."m elapsed, "..math.floor(remaining/60).."m left")
            lastCheck = os.time()
        end
    end
    
    -- Phase 3: Return
    returnToStart()
end

-- ===== COMMAND HANDLER =====
local args = {...}

if args[1] == "start" then
    local minutes = tonumber(args[2]) or 60
    if minutes < 1 then minutes = 1 end
    if minutes > 180 then minutes = 180 end
    
    startMiningMission(minutes)
    
elseif args[1] == "test" then
    print("Test: Digging small tunnel...")
    startTime = os.time()
    missionDuration = 60  -- 1 minute test
    descendToMiningLevel()
    digTunnel(5)
    returnToStart()
    
elseif args[1] == "fuel" then
    findAndRefuel()
    
else
    print("=== MINING TURTLE ===")
    print("Commands:")
    print("  start [minutes]  - Start mining mission (default: 60)")
    print("  test             - Quick 1-minute test")
    print("  fuel             - Refuel from inventory")
    print("")
    print("Example: 'start 75' - mine for 75 minutes")
    print("Place a CHEST behind turtle before starting!")
end
