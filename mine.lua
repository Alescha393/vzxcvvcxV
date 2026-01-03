-- Скрипт для майнинга черепашкой
-- Colin's Survival Script v1.0

local tArgs = { ... }
local oreIds = {
  "minecraft:coal_ore",
  "minecraft:iron_ore",
  "minecraft:gold_ore",
  "minecraft:diamond_ore",
  "minecraft:emerald_ore",
  "minecraft:redstone_ore",
  "minecraft:lapis_ore",
  "minecraft:copper_ore",
  "minecraft:nether_quartz_ore",
  -- Добавь сюда ID рудов из модов как "modname:ore_id"
}

local function isOre(blockName)
  for _, id in ipairs(oreIds) do
    if blockName == id then
      return true
    end
  end
  return false
end

local function digUp()
  while turtle.detectUp() do
    turtle.digUp()
    sleep(0.5)
  end
end

local function digDown()
  while turtle.detectDown() do
    turtle.digDown()
    sleep(0.5)
  end
end

local function digForward()
  while turtle.detect() do
    turtle.dig()
    sleep(0.5)
  end
end

local function mineVein()
  local success, data = turtle.inspect()
  if success and isOre(data.name) then
    turtle.dig()
    sleep(0.3)
    -- Рекурсивно проверяем соседние блоки
    for i = 1, 4 do
      turtle.turnLeft()
      success, data = turtle.inspect()
      if success and isOre(data.name) then
        mineVein()
      end
    end
    turtle.turnRight()
    if turtle.detectUp() then
      turtle.digUp()
      mineVein()
    end
    if turtle.detectDown() then
      turtle.digDown()
      mineVein()
    end
  end
end

local function mainMiningLoop()
  print("Начало майнинга. Нажми Ctrl+T для остановки.")
  while true do
    for i = 1, 16 do
      local success, data = turtle.inspect()
      if success and isOre(data.name) then
        print("Найдена руда: " .. data.name)
        mineVein()
      end
      turtle.forward()
      sleep(0.2)
    end
    turtle.turnRight()
    turtle.forward()
    turtle.turnRight()
    for i = 1, 16 do
      local success, data = turtle.inspect()
      if success and isOre(data.name) then
        print("Найдена руда: " .. data.name)
        mineVein()
      end
      turtle.forward()
      sleep(0.2)
    end
    turtle.turnLeft()
    turtle.forward()
    turtle.turnLeft()
  end
end

local function testCommand()
  print("Тестовая команда. Ожидание 60 секунд...")
  os.sleep(60)
  print("Возврат из теста.")
  return true
end

-- Обработчик команд
if tArgs[1] == "test" then
  testCommand()
else
  print("Запуск скрипта майнинга. Добавь ID рудов из модов в таблицу 'oreIds'.")
  mainMiningLoop()
end
