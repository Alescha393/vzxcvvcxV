-- ===== Turtle 2D Printer v1.0 =====
-- Builds walls from a blueprint file
-- Usage: printer build <filename>

-- ===== CONFIGURATION =====
local CHEST_SLOT = 16          -- Slot for fuel/extra blocks

-- ===== CORE FUNCTIONS =====
local function refuelNeeded()
    if turtle.getFuelLevel() < 100 then
        turtle.select(CHEST_SLOT)
        if turtle.refuel(1) then
            print("Refueled. Fuel: "..turtle.getFuelLevel())
        else
            print("Warning: Low fuel in slot "..CHEST_SLOT)
        end
    end
    return turtle.getFuelLevel() > 50
end

local function loadBlueprint(filename)
    if not fs.exists(filename) then
        print("Error: File '"..filename.."' not found!")
        print("Create it with: edit "..filename)
        return nil
    end
    
    local file = fs.open(filename, "r")
    local blueprint = {}
    local width = 0
    
    while true do
        local line = file.readLine()
        if not line then break end
        line = line:gsub("[\n\r]", "")
        if #line > 0 then
            table.insert(blueprint, line)
            if #line > width then width = #line end
        end
    end
    file.close()
    
    print("Loaded blueprint: "..#blueprint.." lines x "..width.." columns")
    return blueprint, width, #blueprint
end

local function findBlockInInventory(blockChar)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            -- Simple mapping: char '1' = block in slot 1, '2' = slot 2, etc.
            if tostring(slot) == blockChar then
                turtle.select(slot)
                return true
            end
            -- For advanced use: map chars to specific block names
        end
    end
    print("Error: No blocks for char '"..blockChar.."' in inventory!")
    return false
end

local function printLayer(blueprint, width, height)
    local startX, startY, startZ = 0, 0, 0
    local dir = 1 -- 1=right, -1=left
    
    for row = 1, height do
        local line = blueprint[row]
        
        for col = 1, width do
            if not refuelNeeded() then
                print("Aborting: out of fuel!")
                return false
            end
            
            local char = line:sub(col, col)
            if char ~= " " and char ~= "." then
                if findBlockInInventory(char) then
                    turtle.place()
                end
            end
            
            -- Move to next position (except last column)
            if col < width then
                if dir == 1 then
                    turtle.turnRight()
                    if not turtle.forward() then
                        turtle.dig(); turtle.forward()
                    end
                    turtle.turnLeft()
                else
                    turtle.turnLeft()
                    if not turtle.forward() then
                        turtle.dig(); turtle.forward()
                    end
                    turtle.turnRight()
                end
            end
        end
        
        -- Move to next row
        if row < height then
            turtle.back()
            turtle.turnRight()
            if not turtle.forward() then
                turtle.dig(); turtle.forward()
            end
            turtle.turnLeft()
            dir = -dir -- Reverse direction for next row
        end
    end
    
    return true
end

-- ===== MAIN FUNCTION =====
local function buildFromFile(filename)
    print("=== TURTLE PRINTER ===")
    
    local blueprint, width, height = loadBlueprint(filename)
    if not blueprint then return end
    
    print("Starting print job...")
    print("Make sure inventory has blocks in correct slots!")
    print("Press any key to start or Ctrl+T to cancel")
    os.pullEvent("key")
    
    if printLayer(blueprint, width, height) then
        print("Print job completed successfully!")
        print("Returning to start...")
        -- Simple return (for actual use would need path tracking)
        for i = 1, height-1 do turtle.back() end
        turtle.turnRight()
        for i = 1, width-1 do turtle.back() end
        turtle.turnLeft()
    else
        print("Print job failed!")
    end
end

-- ===== COMMAND HANDLER =====
local args = {...}

if args[1] == "build" and args[2] then
    buildFromFile(args[2])
elseif args[1] == "test" then
    -- Create a test blueprint
    local testFile = "test_blueprint"
    local file = fs.open(testFile, "w")
    file.writeLine("111111")
    file.writeLine("1    1")
    file.writeLine("1    1")
    file.writeLine("1    1")
    file.writeLine("111111")
    file.close()
    print("Created test blueprint: "..testFile)
    print("Place 64 blocks in slot 1, then run: printer build "..testFile)
else
    print("Turtle 2D Printer Commands:")
    print("  printer build <filename>  - Build from blueprint file")
    print("  printer test              - Create test blueprint")
    print("")
    print("Blueprint format:")
    print("  '1' = place block from slot 1")
    print("  '2' = place block from slot 2")
    print("  ' ' or '.' = skip (don't place)")
    print("")
    print("Example simple blueprint (save as 'wall'):")
    print("  11111")
    print("  1   1")
    print("  1   1")
    print("  11111")
end
