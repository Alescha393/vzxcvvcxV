-- Mine Shaft Miner v3.0 - Digs tunnels underground and returns
-- Usage: mine start 60  (dig for 60 minutes)

-- ===== CONFIGURATION =====
local MINING_DEPTH = 15           -- How deep to go before digging tunnels (Y level)
local TUNNEL_LENGTH = 30          -- Length of each tunnel branch
local MAIN_SHAFT_WIDTH = 2        -- Width of main shaft (1 or 2)
local RETURN_TIMER = 60 * 60      -- Default return time (60 minutes in seconds)

-- Fuel items for auto-refuel (supports 1.20.1)
local FUEL_ITEMS = {
    "minecraft:coal",
    "minecraft:coal_block", 
    "minecraft:charcoal",
    "minecraft:lava_bucket",
    "minecraft:blaze_rod"
}

-- Ores to keep (won't be thrown away)
local VALUABLE_ITEMS = {
    "ore", "raw_", "coal", "diamond", "emerald",
    "iron", "gold", "copper", "quartz", "lapis",
    "redstone", "ancient_debris", "netherite"
}

-- ===== SYSTEM VARIABLES =====
local startTime = 0
local miningTime = 0
local isReturning = false
local pathStack = {}  -- Stores movement path for return

-- ===== FUEL MANAGEMENT =====
local function refuelIfNeeded()
    local current = turtle.getFuelLevel()
    if current > 1000 then return true end
    
    print("Low fuel ("..current.."). Searching...")
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            for _, fuel in ipairs(FUEL_ITEMS) do
                if item.name == fuel then
                    turtle.select(slot)
                    local needed = math.ceil((2000 - current) / 80)
                    local toRefuel = math.min(needed, item.count)
                    
                    if turtle.refuel(toRefuel) then
                        print("Refueled with "..item.name.." ("..turtle.getFuelLevel()..")")
                        return true
                    end
                end
            end
        end
    end
    
    print("WARNING: No fuel found! Add coal/charcoal to inventory.")
    return current > 100
end

-- ===== PATH TRACKING (LIFO Stack) =====
local function pushMove(direction)
    table.insert(pathStack, direction)
end

local function popMove()
    if #pathStack == 0 then return nil end
    return table.remove(pathStack)
end

local function reversePath()
    local reversed = {}
    for i = #pathStack, 1, -1 do
        local move = pathStack[i]
        local reverseMove = ""
        
        if move == "down" then reverseMove = "up"
        elseif move == "up" then reverseMove = "down"
        elseif move == "forward" then reverseMove = "back"
        elseif move == "back" then reverseMove = "forward"
        elseif move == "turnLeft" then reverseMove = "turnRight"
        elseif move == "turnRight" then reverseMove = "turnLeft"
        end
        
        table.insert(reversed, reverseMove)
    end
    return reversed
end

-- ===== MOVEMENT FUNCTIONS =====
local function moveDown()
    if turtle.down() then pushMove("down"); return true end
    return false
end

local function moveUp()
    if turtle.up() then pushMove("up"); return true end
    return false

local function moveForward()
    if turtle.forward() then pushMove("forward"); return true end
    return false
end

local function moveBack()
    if turtle.back() then pushMove("back"); return true end
    return false
end

local function turnLeft()
    turtle.turnLeft(); pushMove("turnLeft")
end

local function turnRight()
    turtle.turnRight(); pushMove("turnRight")
end

-- ===== DIGGING FUNCTIONS =====
local function digAndMove(direction)
    if direction == "down" then
        while turtle.detectDown() do turtle.digDown() end
        return moveDown()
    elseif direction == "up" then
        while turtle.detectUp() do turtle.digUp() end
        return moveUp()
    elseif direction == "forward" then
        while turtle.detect() do turtle.dig() end
        return moveForward()
    end
    return false
end

-- ===== GO TO MINING LEVEL =====
local function descendToMiningLevel()
    print("Descending to mining level...")
    
    -- Dig main shaft (2x1 or 3x1)
    for i = 1, MINING_DEPTH do
        if not refuelIfNeeded() then
            print("Cannot descend: out of fuel!")
            return false
        end
        
        -- Dig down
        if not digAndMove("down") then
            print("Cannot go deeper at level "..i)
            break
        end
        
        -- Optional: widen shaft
        if MAIN_SHAFT_WIDTH > 1 then
            turnRight()
            turtle.dig()
            turnLeft()
            turnLeft()
            turtle.dig()
            turnRight()
        end
        
        print("Depth: "..i..", Fuel: "..turtle.getFuelLevel())
    end
    
    return true
end

-- ===== DIG TUNNEL BRANCH =====
local function digTunnelBranch(length)
    print("Digging tunnel ("..length.." blocks)...")
    
    for i = 1, length do
        -- Check time
        if os.time() - startTime >= miningTime then
            print("Time's up! Starting return...")
            return false
        end
        
        if not refuelIfNeeded() then
            print("Out of fuel! Returning...")
            return false
        end
        
        -- Dig forward
        digAndMove("forward")
        
        -- Mine ore veins around
        local function checkAndMine(checkFunc, digFunc)
            local success, data = checkFunc()
            if success then
                for _, valuable in ipairs(VALUABLE_ITEMS) do
                    if data.name:find(valuable) then
                        digFunc()
                        sleep(0.2)
                        return true
                    end
                end
            end
            return false
        end
        
        -- Check sides for ores
        turnLeft()
        checkAndMine(turtle.inspect, turtle.dig)
        turnRight(); turnRight()
        checkAndMine(turtle.inspect, turtle.dig)
        turnLeft()
        
        -- Check up/down for ores
        checkAndMine(turtle.inspectUp, turtle.digUp)
        checkAndMine(turtle.inspectDown, turtle.digDown)
        
        -- Every 5 blocks, check inventory
        if i % 5 == 0 then
            -- Throw away non-valuable blocks
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    local isValuable = false
                    for _, valuable in ipairs(VALUABLE_ITEMS) do
                        if item.name:find(valuable) then
                            isValuable = true
                            break
                        end
                    end
                    
                    if not isValuable then
                        turtle.select(slot)
                        turtle.dropDown()  -- Drop cobblestone/dirt/etc
                    end
                end
            end
        end
        
        -- Display progress every 10 blocks
        if i % 10 == 0 then
            local elapsed = os.time() - startTime
            local remaining = miningTime - elapsed
            print("Progress: "..i.."/"..length..", Time left: "..math.floor(remaining/60).."m")
        end
    end
    
    return true
end

-- ===== RETURN TO SURFACE =====
local function returnToSurface()
    print("Returning to surface...")
    isReturning = true
    
    -- Follow reverse path
    local returnPath = reversePath()
    
    for _, move in ipairs(returnPath) do
        if not refuelIfNeeded() then
            print("Critical: No fuel for return!")
            break
        end
        
        if move == "up" then moveUp()
        elseif move == "down" then moveDown()
        elseif move == "forward" then moveForward()
        elseif move == "back" then moveBack()
        elseif move == "turnLeft" then turnLeft()
        elseif move == "turnRight" then turnRight()
        end
        
        sleep(0.1)
    end
    
    -- Empty inventory into chest (place chest behind turtle at start)
    print("Unloading inventory...")
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.drop()
    end
    
    print("=== MISSION COMPLETE ===")
    print("Total time: "..math.floor((os.time()-startTime)/60).." minutes")
    print("Fuel remaining: "..turtle.getFuelLevel())
end

-- ===== PATTERN MINING =====
local function minePattern(patternTime)
    local patterns = {
        {"straight", TUNNEL_LENGTH},
        {"right", 10},
        {"back", TUNNEL_LENGTH},
        {"right", 10},
        {"straight", TUNNEL_LENGTH}
    }
    
    for _, pattern in ipairs(patterns) do
        if os.time() - startTime >= patternTime then break end
        
        if pattern[1] == "straight" then
            if not digTunnelBranch(pattern[2]) then return false end
        elseif pattern[1] == "right" then
            turnRight()
            if not digTunnelBranch(pattern[2]) then return false end
            turnLeft()
        elseif pattern[1] == "left" then
            turnLeft()
            if not digTunnelBranch(pattern[2]) then return false end
            turnRight()
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
    miningTime = minutes * 60
    pathStack = {}
    isReturning = false
    
    -- Initial refuel check
    if not refuelIfNeeded() then
        print("ABORT: Not enough fuel to start mission!")
        return
    end
    
    -- Phase 1: Descend
    if not descendToMiningLevel() then
        returnToSurface()
        return
    end
    
    -- Phase 2: Mine in pattern until time runs out
    local lastCheck = os.time()
    while os.time() - startTime < miningTime do
        if not minePattern(miningTime) then
            break
        end
        
        -- Turn around to mine new area
        turnRight(); turnRight()
        
        -- Time check every minute
        if os.time() - lastCheck >= 60 then
            local elapsed = os.time() - startTime
            local remaining = miningTime - elapsed
            print("Mining... "..math.floor(elapsed/60).."m elapsed, "..math.floor(remaining/60).."m left")
            lastCheck = os.time()
        end
    end
    
    -- Phase 3: Return
    returnToSurface()
end

-- ===== COMMAND HANDLER =====
local args = {...}

if args[1] == "start" then
    local minutes = tonumber(args[2]) or 60
    if minutes < 1 then minutes = 1 end
    if minutes > 180 then minutes = 180 end
    
    startMiningMission(minutes)
    
elseif args[1] == "dig" then
    -- Quick manual controls
    if args[2] == "down" then digAndMove("down")
    elseif args[2] == "forward" then digAndMove("forward")
    elseif args[2] == "test" then
        print("Test: Digging small tunnel...")
        startTime = os.time()
        miningTime = 60  -- 1 minute test
        descendToMiningLevel()
        digTunnelBranch(5)
        returnToSurface()
    end
    
elseif args[1] == "fuel" then
    refuelIfNeeded()
    
else
    print("=== UNDERGROUND MINING TURTLE ===")
    print("Commands:")
    print("  start [minutes]  - Start mining mission (default: 60)")
    print("  dig test         - Quick 1-minute test")
    print("  fuel             - Refuel from inventory")
    print("  dig down/forward - Manual control")
    print("")
    print("Example: 'start 75' - mine for 75 minutes")
    print("Place a CHEST behind turtle before starting!")
end
