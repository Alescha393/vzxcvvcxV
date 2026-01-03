-- Скрипт для майнинга черепашкой с поддержкой модов
-- Colin's Survival Script v1.1 (Исправлено)

-- === КОНФИГУРАЦИЯ ===
local oreIds = {
    -- Ванильные руды
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
    -- Примеры модовых руд (добавьте свои!)
    -- "thermal:tin_ore",
    -- "immersiveengineering:ore_aluminum",
    -- "mekanism:osmium_ore",
    -- "create:zinc_ore",
    -- "tconstruct:cobalt_ore"
}

local MAIN_TUNNEL_LENGTH = 16
local TUNNEL_COUNT = 4
local FUEL_SLOT = 16

-- === СИСТЕМНЫЕ ФУНКЦИИ ===
local function isTurtle()
    return turtle ~= nil
end

local function checkFuel()
    if turtle.getFuelLevel() < MAIN_TUNNEL_LENGTH * TUNNEL_COUNT * 3 then
        print("Заправка...")
        turtle.select(FUEL_SLOT)
        if turtle.refuel(1) then
            print("Заправлено. Топлива: " .. turtle.getFuelLevel())
        else
            print("ОШИБКА: Нет топлива в слоте " .. FUEL_SLOT)
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

-- === ОСНОВНЫЕ ФУНКЦИИ МАЙНИНГА ===
local function mineVein()
    local success, data = turtle.inspect()
    if not success then return end
    
    if isOre(data.name) then
        turtle.dig()
        sleep(0.3)
        
        -- Рекурсивная проверка всех 6 сторон
        for i = 1, 4 do
            turtle.turnLeft()
            local sideSuccess, sideData = turtle.inspect()
            if sideSuccess and isOre(sideData.name) then
                mineVein()
            end
        end
        turtle.turnRight()
        
        -- Проверка сверху
        if turtle.detectUp() then
            local upSuccess, upData = turtle.inspectUp()
            if upSuccess and isOre(upData.name) then
                turtle.digUp()
                turtle.up()
                mineVein()
                turtle.down()
            end
        end
        
        -- Проверка снизу
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
        
        -- Добыча впереди
        if turtle.detect() then
            local success, data = turtle.inspect()
            if success and isOre(data.name) then
                print("Найдена руда: " .. data.name)
                mineVein()
            else
                turtle.dig()
            end
        end
        
        -- Добыча сверху
        if turtle.detectUp() then
            local success, data = turtle.inspectUp()
            if success and isOre(data.name) then
                print("Найдена руда сверху: " .. data.name)
                turtle.digUp()
            end
        end
        
        -- Добыча снизу
        if turtle.detectDown() then
            local success, data = turtle.inspectDown()
            if success and isOre(data.name) then
                print("Найдена руда снизу: " .. data.name)
                turtle.digDown()
            end
        end
        
        -- Сортировка лута
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
    print("=== СИСТЕМА МАЙНИНГА ЧЕРЕПАШКИ ===")
    print("Топливо: " .. turtle.getFuelLevel())
    print("Ищем руды: " .. #oreIds .. " типов")
    print("Нажмите Ctrl+T для остановки")
    print("================================")
    
    for tunnel = 1, TUNNEL_COUNT do
        print("Шахта #" .. tunnel .. "...")
        
        if not excavateTunnel(MAIN_TUNNEL_LENGTH) then
            print("Остановка: нет топлива")
            return
        end
        
        if tunnel < TUNNEL_COUNT then
            turtle.turnRight()
            turtle.forward()
            turtle.forward()
            turtle.turnRight()
        end
    end
    
    -- Возврат домой
    print("Возврат на базу...")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, TUNNEL_COUNT * 2 do turtle.forward() end
    turtle.turnLeft()
    turtle.turnLeft()
    
    -- Выгрузка ресурсов
    print("Выгрузка ресурсов...")
    for s = 1, 16 do
        turtle.select(s)
        turtle.drop()
    end
    
    print("Майнинг завершен. Ресурсы в сундуке.")
end

-- === КОМАНДА TEST ===
local function executeTest()
    print("[TEST] Активация тестового режима")
    print("[TEST] Выезд на 10 блоков вперед...")
    
    for i = 1, 10 do
        if turtle.detect() then turtle.dig() end
        turtle.forward()
        sleep(0.5)
    end
    
    print("[TEST] Ожидание 60 секунд...")
    for sec = 1, 60 do
        os.sleep(1)
        if sec % 10 == 0 then
            print("[TEST] Прошло " .. sec .. " сек.")
        end
    end
    
    print("[TEST] Возврат...")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, 10 do
        turtle.forward()
        sleep(0.3)
    end
    turtle.turnLeft()
    turtle.turnLeft()
    
    print("[TEST] Тест завершен успешно")
    return true
end

-- === ГЛАВНАЯ ПРОГРАММА ===
local args = { ... }

-- Проверка типа устройства
if not isTurtle() then
    print("ОШИБКА: Этот скрипт работает только на Mining Turtle!")
    print("1. Соберите черепашку: craft Mining Turtle")
    print("2. Поместите в слот " .. FUEL_SLOT .. " уголь/лаву")
    print("3. Запустите: mine")
    return
end

-- Обработка команд
if args[1] == "test" then
    if checkFuel() then
        executeTest()
    else
        print("ОШИБКА: Недостаточно топлива для теста")
    end
elseif args[1] == "addore" and args[2] then
    -- Добавление новой руды
    table.insert(oreIds, args[2])
    print("Добавлена руда: " .. args[2])
    print("Всего руд в списке: " .. #oreIds)
elseif args[1] == "list" then
    -- Список всех руд
    print("Загруженные ID руд:")
    for i, ore in ipairs(oreIds) do
        print(i .. ". " .. ore)
    end
else
    -- Основной режим майнинга
    if checkFuel() then
        mainMiningLoop()
    else
        print("ОШИБКА: Недостаточно топлива")
        print("Поместите топливо в слот " .. FUEL_SLOT)
    end
end
