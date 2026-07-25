local targetbotMacro = nil
local config = nil
local lastAction = 0
local cavebotAllowance = 0

-- ui
local configWidget = UI.Config()
local ui = UI.createWidget("TargetBotPanel")

ui.list = ui.listPanel.list -- shortcut
TargetBot.targetList = ui.list

ui.status.left:setText("Status:")
ui.status.left:setColor("white")
ui.status.right:setText("OFF")
ui.status.right:setColor("green")
ui.target.left:setText("Target:")
ui.target.left:setColor("white")
ui.target.right:setText("-")
ui.target.right:setColor("green")
ui.config.left:setText("Config:")
ui.config.left:setColor("white")
ui.config.right:setColor("green")
ui.config.right:setText("-")
ui.danger.left:setText("Danger:")
ui.danger.left:setColor("white")
ui.danger.right:setText("0")
ui.danger.right:setColor("green")

ui.editor.debug.onClick = function()
  local on = ui.editor.debug:isOn()
  ui.editor.debug:setOn(not on)
  if on then
    for _, spec in ipairs(getSpectators()) do
      spec:clearText()
    end
  end
end

-- main loop, controlado por config (OTIMIZADO CONTRA LAG E SLOW MACRO)
targetbotMacro = macro(100, function()
  local pos = player:getPosition()
  local creatures = g_map.getSpectatorsInRange(pos, false, 6, 6) -- 12x12 area
  local highestPriority = 0
  local dangerLevel = 0
  local targets = 0
  local highestPriorityParams = nil
  
  for i, creature in ipairs(creatures) do
    if creature:isMonster() and creature:getHealthPercent() > 0 then
      local creaturePos = creature:getPosition()
      local dist = getDistanceBetween(pos, creaturePos)
      
      -- OTIMIZAÇÃO: Só calcula o pathfinding se o monstro estiver a uma distância plausível (Evita checar monstros fora do alcance)
      if dist <= 8 then 
        local path = findPath(pos, creaturePos, 7, {ignoreLastCreature=true, ignoreNonPathable=true, ignoreCost=true})
        
        if path then
          local params = TargetBot.Creature.calculateParams(creature, path) -- return {creature, config, danger, priority}
          dangerLevel = dangerLevel + params.danger
          
          if params.priority > 0 then
            targets = targets + 1
            if params.priority > highestPriority then
              highestPriority = params.priority
              highestPriorityParams = params
            end
            if ui.editor.debug:isOn() then
              creature:setText(params.config.name .. "\n" .. params.priority)
            end
          end
        end
      end
    end
  end

  ui.danger.right:setText(dangerLevel)
  if highestPriorityParams and not isInPz() then
    ui.target.right:setText(highestPriorityParams.creature:getName())
    ui.config.right:setText(highestPriorityParams.config.name)
    
    -- Passa falso diretamente no parâmetro de looting do ataque
    TargetBot.Creature.attack(highestPriorityParams, targets, false)    
    
    if cavebotAllowance > now then
      TargetBot.setStatus("Luring using CaveBot")
    else
      TargetBot.setStatus("Attacking")
    end
    TargetBot.walk()
    lastAction = now
    return
  end

  ui.target.right:setText("-")
  ui.config.right:setText("-")
  TargetBot.setStatus("Waiting")
  
  -- Garante o recuo/parada do andar se não houver monstros na tela
  TargetBot.walkTo(nil)
end)

-- config, its callback is called immediately, data can be nil
config = Config.setup("targetbot_configs", configWidget, "json", function(name, enabled, data)
  if not data then
    ui.status.right:setText("Off")
    return targetbotMacro.setOff() 
  end
  TargetBot.Creature.resetConfigs()
  for _, value in ipairs(data["targeting"] or {}) do
    TargetBot.Creature.addConfig(value)
  end

  -- add configs
  if enabled then
    ui.status.right:setText("On")
  else
    ui.status.right:setText("Off")
  end

  targetbotMacro.setOn(enabled)
  targetbotMacro.delay = nil
end)

-- setup ui
ui.editor.buttons.add.onClick = function()
  TargetBot.Creature.edit(nil, function(newConfig)
    TargetBot.Creature.addConfig(newConfig, true)
    TargetBot.save()
  end)
end

ui.editor.buttons.edit.onClick = function()
  local entry = ui.list:getFocusedChild()
  if not entry then return end
  TargetBot.Creature.edit(entry.value, function(newConfig)
    entry:setText(newConfig.name)
    entry.value = newConfig
    TargetBot.Creature.resetConfigsCache()
    TargetBot.save()
  end)
end

ui.editor.buttons.remove.onClick = function()
  local entry = ui.list:getFocusedChild()
  if not entry then return end
  entry:destroy()
  TargetBot.Creature.resetConfigsCache()
  TargetBot.save()
end

-- public function, you can use them in your scripts
TargetBot.isActive = function() 
  return lastAction + 300 > now
end

TargetBot.isCaveBotActionAllowed = function()
  return cavebotAllowance > now
end

TargetBot.setStatus = function(text)
  return ui.status.right:setText(text)
end

TargetBot.isOn = function()
  return config.isOn()
end

TargetBot.isOff = function()
  return config.isOff()
end

TargetBot.setOn = function(val)
  if val == false then  
    return TargetBot.setOff(true)
  end
  config.setOn()
end

TargetBot.setOff = function(val)
  if val == false then  
    return TargetBot.setOn(true)
  end
  config.setOff()
end

TargetBot.delay = function(value)
  targetbotMacro.delay = now + value
end

TargetBot.save = function()
  local data = {targeting={}}
  for _, entry in ipairs(ui.list:getChildren()) do
    table.insert(data.targeting, entry.value)
  end
  config.save(data)
end

TargetBot.allowCaveBot = function(time)
  cavebotAllowance = now + time
end

-- attacks
local lastSpell = 0
local lastAttackSpell = 0

TargetBot.saySpell = function(text, delay)
  if type(text) ~= 'string' or text:len() < 1 then return end
  if not delay then delay = 500 end
  if g_game.getProtocolVersion() < 1090 then
    lastAttackSpell = now 
  end
  if lastSpell + delay < now then
    say(text)
    lastSpell = now
    return true
  end
  return false
end

TargetBot.sayAttackSpell = function(text, delay)
  if type(text) ~= 'string' or text:len() < 1 then return end
  if not delay then delay = 2000 end
  if lastAttackSpell + delay < now then
    say(text)
    lastAttackSpell = now
    return true
  end
  return false
end

local lastItemUse = 0
local lastRuneAttack = 0

TargetBot.useItem = function(item, subType, target, delay)
  if not delay then delay = 200 end
  if lastItemUse + delay < now then
    local thing = g_things.getThingType(item)
    if not thing or not thing:isFluidContainer() then
      subType = g_game.getClientVersion() >= 860 and 0 or 1
    end
    if g_game.getClientVersion() < 780 then
      local tmpItem = g_game.findPlayerItem(item, subType)
      if not tmpItem then return end
      g_game.useWith(tmpItem, target, subType) 
    else
      g_game.useInventoryItemWith(item, target, subType) 
    end
    lastAction = now
    lastItemUse = now
  end
end

TargetBot.useAttackItem = function(item, subType, target, delay)
  if not delay then delay = 2000 end
  if lastRuneAttack + delay < now then
    local thing = g_things.getThingType(item)
    if not thing or not thing:isFluidContainer() then
      subType = g_game.getClientVersion() >= 860 and 0 or 1
    end
    if g_game.getClientVersion() < 780 then
      local tmpItem = g_game.findPlayerItem(item, subType)
      if not tmpItem then return end
      g_game.useWith(tmpItem, target, subType)   
    else
      g_game.useInventoryItemWith(item, target, subType) 
    end
    lastAction = now
    lastRuneAttack = now
  end
end
