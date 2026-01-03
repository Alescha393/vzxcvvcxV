-- Advanced Mining Turtle Script with Iron Ore Test Mode
-- Based on vein mining principles and return-to-home function

-- ===== CONFIGURATION =====
local TARGET_ORE = "minecraft:iron_ore" -- Ore to find in test mode
local FUEL_SLOT = 16                    -- Slot for coal/charcoal
local SCAN_RANGE = 5                    -- How far to look for ore in test mode

-- ===== MOVEMENT TRACKING (For going HOME) =====
local pathLog = {} -- Tracks every move to reverse it later

local function logMovement(direction)
    table.insert(pathLog, 1, direction) -- Add to start to reverse later
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
    pathLog = {} -- Clear log after returning
    print("Return complete.")
end

-- ===== BASIC MOVEMENT WITH TRACKING =====
local function moveForward()
    if turtle.forward() then logMovement("forward"); return true end
    return false
end
local function moveBack()
    if turtle.back() then logMovement("back"); return true end
    return false
end
local function moveUp()
    if turtle.up() then logMovement("up"); return true end
    return false
end
local function moveDown()
    if turtle.down() then logMovement("down"); return true end
    return false
end
local function turnL()
    turtle.turnLeft(); logMovement("turnLeft")
end
local function turnR()
    turtle.turnRight(); logMovement("turnRight")
end

-- ===== CORE MINING FUNCTIONS =====
local function checkFuel()
    if turtle.getFuelLevel() < 100 then
        turtle.select(FUEL_SLOT)
        if turtle.refuel(1) then
            print("Refueled. Fuel: " .. turtle.getFuelLevel())
        else
            print("ERROR: No fuel in slot " .. FUEL_SLOT)
            return false
        end
    end
    return true
end

-- Advanced vein mining function for IRON ORE
local function mineIronVein()
    local function isTargetOre(blockName)
        return blockName == TARGET_ORE
    end

    local function tryMine(digFunc, inspectFunc, moveInFunc, moveOutFunc)
        local success, data = inspectFunc()
        if success and isTargetOre(data.name) then
            digFunc()
            sleep(0.3)
            moveInFunc()
            mineIronVein() -- Recurse to mine connected ores
            moveOutFunc()
            return true
        end
        return false
    end

    -- Check and mine in all 6 directions
    if tryMine(turtle.digUp, turtle.inspectUp, turtle.up, turtle.down) then return end
    if tryMine(turtle.digDown, turtle.inspectDown, turtle.down, turtle.up) then return end

    -- Check 4 horizontal directions by turning
    for i = 1, 4 do
        if tryMine(turtle.dig, turtle.inspect, turtle.forward, turtle.back) then
            -- Found ore in front, mine the vein from there
        end
        turtle.turnRight()
    end
end

-- ===== TEST MODE: FIND AND MINE IRON =====
local function runTest()
    if not checkFuel() then return end
    print("TEST MODE: Searching for " .. TARGET_ORE .. "...")

    local foundOre = false
    -- Scan nearby blocks for iron ore
    for check = 1, SCAN_RANGE do
        -- Check in front first
        local success, data = turtle.inspect()
        if success and data.name == TARGET_ORE then
            print("Found iron ore in front! Mining vein...")
            mineIronVein()
            foundOre = true
            break
        end

        -- Check other sides by turning
        for side = 1, 3 do
            turtle.turnRight()
            local sideSuccess, sideData = turtle.inspect()
            if sideSuccess and sideData.name == TARGET_ORE then
                print("Found iron ore to the side! Turning to mine...")
                turtle.turnLeft() -- Face the ore
                mineIronVein()
                foundOre = true
                break
            end
        end
        if foundOre then break end

        -- Move forward and check up/down
        if not moveForward() then break end

        local upSuccess, upData = turtle.inspectUp()
        if upSuccess and upData.name == TARGET_ORE then
            print("Found iron ore above! Mining...")
            turtle.digUp(); turtle.up(); mineIronVein(); turtle.down()
            foundOre = true
            break
        end

        local downSuccess, downData = turtle.inspectDown()
        if downSuccess and downData.name == TARGET_ORE then
            print("Found iron ore below! Mining...")
            turtle.digDown(); turtle.down(); mineIronVein(); turtle.up()
            foundOre = true
            break
        end
    end

    -- Clean inventory in test mode (keep only ores)
    for s = 1, 16 do
        local item = turtle.getItemDetail(s)
        if item and not item.name:find("ore") then
            turtle.select(s)
            turtle.dropDown()
        end
    end

    if not foundOre then
        print("No " .. TARGET_ORE .. " found in scanning range.")
    end

    -- ALWAYS return home after test
    moveHome()
    print("Test mode finished.")
end

-- ===== MANUAL MOVEMENT CONTROLS =====
local function manualMove(direction)
    if not checkFuel() then return end
    local moved = false

    if direction == "forward" then moved = moveForward()
    elseif direction == "back" then moved = moveBack()
    elseif direction == "up" then moved = moveUp()
    elseif direction == "down" then moved = moveDown()
    elseif direction == "left" then turnL(); moved = true
    elseif direction == "right" then turnR(); moved = true
    else print("Unknown direction. Use: forward, back, up, down, left, right")
    end

    if moved then
        print("Moved " .. direction .. ". Position logged.")
    else
        print("Failed to move " .. direction .. ". Blocked or no fuel.")
    end
end

-- ===== MAIN PROGRAM =====
local args = { ... }

if args[1] == "test" then
    runTest()
elseif args[1] == "move" and args[2] then
    manualMove(args[2])
elseif args[1] == "home" then
    moveHome()
elseif args[1] == "fuel" then
    print("Current fuel: " .. turtle.getFuelLevel())
else
    print("Usage:")
    print("  mine test           - Find/mine iron ore, then return")
    print("  mine move <dir>     - Move (forward|back|up|down|left|right)")
    print("  mine home           - Return to start position")
    print("  mine fuel           - Check fuel level")
end
