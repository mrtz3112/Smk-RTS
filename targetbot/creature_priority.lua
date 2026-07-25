if hasSpecialMob == nil then hasSpecialMob = false end
if previousChaseMode == nil then previousChaseMode = 0 end

TargetBot.Creature.calculatePriority = function(creature, config, path)

  if creature:isMonster() and path then
    local creatureName = creature:getName():lower()
    
    -- Lista de monstros especiais
    if creatureName:find("elite") or 
       creatureName:find("boss") or 
       creatureName:find("hollow capitan shinigami") or 
       creatureName:find("complete espada") or 
       creatureName:find("gotei 13 king") or 
       creatureName:find("oversaturated hollowed shinigami") then

      return (config.priority or 0) + 1000
    end
  end

  local priority = 0
  if g_game.getAttackingCreature() == creature then
    priority = priority + 1
  end
  
  priority = priority + (config.priority or 0)
  
  local path_length = path and #path or 0
  if path_length == 1 then
    priority = priority + 3
  elseif path_length <= 3 and path_length > 0 then
    priority = priority + 1
  end
  
  if config.chase and creature:getHealthPercent() < 30 then
    priority = priority + 5
  elseif creature:getHealthPercent() < 20 then
    priority = priority + 2.5
  elseif creature:getHealthPercent() < 40 then
    priority = priority + 1.5
  elseif creature:getHealthPercent() < 60 then
    priority = priority + 0.5
  elseif creature:getHealthPercent() < 80 then
    priority = priority + 0.2
  end
  
  return priority
end

macro(30, function()
  if not CaveBot or not CaveBot.isOn() then return end

  local pos = player:getPosition()
  local currentSpecs = g_map.getSpectatorsInRange(pos, false, 6, 6)
  
  local bossStillAlive = false
  for _, spec in ipairs(currentSpecs) do
    if spec:isMonster() then
      local name = spec:getName():lower()
      
      if name:find("elite") or 
         name:find("boss") or 
         name:find("hollow capitan shinigami") or 
         name:find("complete espada") or 
         name:find("gotei 13 king") or 
         name:find("oversaturated hollowed shinigami") then
         
        local hasPath = findPath(pos, spec:getPosition(), 7, {
          ignoreLastCreature = true, 
          ignoreNonPathable = true, 
          ignoreCost = true, 
          ignoreCreatures = true
        })
        
        if hasPath then
          bossStillAlive = true
          break
        end
      end
    end
  end
  
  if bossStillAlive then
    CaveBot.delay(500)
    
    if not hasSpecialMob then
      hasSpecialMob = true
      previousChaseMode = g_game.getChaseMode()
      g_game.setChaseMode(1)
    end
    
  elseif not bossStillAlive and hasSpecialMob then
    hasSpecialMob = false
    g_game.setChaseMode(previousChaseMode == 1 and 0 or previousChaseMode)
  end
end)
