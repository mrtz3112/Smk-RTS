setDefaultTab("Main")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("      Smk Custom: v4.1      "):setColor('#C39BD3')
UI.Label("        Since 2022       "):setColor('#C39BD3')
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Button("Macro Editor", function(newText)
    UI.MultilineEditorWindow(storage.combos or "", {title="Macro Editor", description="Aqui voce pode editar os seus combos."}, function(text)
      storage.combos = text
      reload()
    end)
  end)
  for _, scripts in pairs({storage.combos}) do
    if type(scripts) == "string" and scripts:len() > 3 then
      local status, result = pcall(function()
        assert(load(scripts, "combos"))()
      end)
    end
  end
UI.Separator()
ModulesG = modules._G
local reconectEvent = nil
local ButtonT = nil

local function updateButtonReconectText()
    if ModulesG.ReconnectXD then
        ButtonT:setColoredText({"Reconnect:", "white", " ON", "green"})
    else
        ButtonT:setColoredText({"Reconnect:", "white", " OFF", "red"})
    end
end

ButtonT = UI.Button("Reconect", function()
    if not ModulesG.ReconnectXD then
        ModulesG.loadstring([[
            modules._G.ReconnectXD = true
            reconectEvent = cycleEvent(function()
                if not g_game.isOnline() then
                    CharacterList.doLogin()
                end
            end, 2500)
        ]])()
    else
        ModulesG.loadstring([[
            modules._G.ReconnectXD = false
            if reconectEvent then
                removeEvent(reconectEvent)
            end
        ]])()
    end
    updateButtonReconectText()
end)
updateButtonReconectText()
macro(100, "GrandFisher Mask", function()
    if not g_game.isAttacking() and not g_game.getAttackingCreature() then
        return
    end
    local helmet = getSlot(1)
    if helmet then
        use(helmet)
        delay(10000)
    end
end)
local effectIdToAvoid = 237
local flags = { ignoreNonPathable = true }

function hasEffect(tile, effectId)
    for _, effect in ipairs(tile:getEffects()) do
        if effect:getId() == effectId then
            return true
        end
    end
    return false
end
function findNearestSafePosition(playerPos, maxRange)
    maxRange = maxRange or 7  -- menos rango = más rápido
    for r = 1, maxRange do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local newPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
                    local tile = g_map.getTile(newPos)

                    if tile and tile:isWalkable() and not hasEffect(tile, effectIdToAvoid) then
                        -- Aquí recién verificamos path
                        if findPath(playerPos, newPos, 10, flags) then
                            return newPos
                        end
                    end
                end
            end
        end
    end
    return nil
end
macro(30, "Dodge Red SQM Spells", function()
    local playerPos = player:getPosition()

    if not hasEffect(g_map.getTile(playerPos), effectIdToAvoid) then
        return
    end

    local safePos = findNearestSafePosition(playerPos)
    if safePos then
        autoWalk(safePos, 15, flags)
        delay(100)
    end
end)
local window_name = "Dungeons"
macro(2000, "Enter Dungeons", function()
    for _, rootW in pairs(g_ui.getRootWidget():getChildren()) do
        if rootW:getText() and string.find(rootW:getText():lower(), window_name:lower()) then
            for _, child in pairs(rootW:getChildren()) do
                if child:getText() == "Start" then
                    child:onClick()
                    break
                end
            end
            break
        end
    end
end)
if not storage.trainerMacroPauseUntil then
  storage.trainerMacroPauseUntil = 0
end
onWalk(function(direction)
    storage.trainerMacroPauseUntil = os.time() + 1
end)

local trainerMacro = macro(100, "House Trainer", function(macroObj)
  if os.time() < storage.trainerMacroPauseUntil then
    return
  end
  if modules.game_npctrade and modules.game_npctrade.isOpen and modules.game_npctrade.isOpen() then
    return
  end
  local myPos = player:getPosition()
  if not myPos then return end
  local hasTrainer = false
  for _, creature in ipairs(getSpectators()) do
    if creature:getName():lower() == "house trainer" then
      hasTrainer = true
      break
    end
  end
  if not hasTrainer then 
    return 
  end
  if g_game.isAttacking() then
    local currentTarget = g_game.getAttackingCreature()
    
    if currentTarget and currentTarget:getName():lower() == "house trainer" then
      local targetPos = currentTarget:getPosition()
      if targetPos then
        local currentDistance = math.max(math.abs(myPos.x - targetPos.x), math.abs(myPos.y - targetPos.y))
        if currentDistance > 1 and currentDistance <= 2 then
          g_game.setChaseMode(0) 
          
          local diffX = targetPos.x - myPos.x
          local diffY = targetPos.y - myPos.y
          
          if diffX ~= 0 and math.abs(diffX) >= math.abs(diffY) then
              if diffX > 0 then g_game.walk(1) else g_game.walk(3) end
          elseif diffY ~= 0 then
              if diffY > 0 then g_game.walk(2) else g_game.walk(0) end
          end
        elseif currentDistance > 2 then
          g_game.cancelAttack()
        end
      end
    end
    return 
  end
  local closestTrainer = nil
  local shortestDistance = 7
  
  for _, creature in ipairs(getSpectators()) do
    if creature:getName():lower() == "house trainer" then
      local trainerPos = creature:getPosition()
      if trainerPos then
        local distance = math.max(math.abs(myPos.x - trainerPos.x), math.abs(myPos.y - trainerPos.y))
        if distance <= 2 and distance < shortestDistance then
          shortestDistance = distance
          closestTrainer = creature
        end
      end
    end
  end
  if closestTrainer then
    g_game.attack(closestTrainer)
  end
end)
macro(100, "Deposit Gold", function()
  local coinIds = {3031, 3035, 3043, 10137} 
  local minAmount = 1
  local shouldDeposit = false
  for _, id in ipairs(coinIds) do
    local item = findItem(id)
    if item and item:getCount() >= minAmount then
      shouldDeposit = true
      break
    end
  end
  if shouldDeposit then
    say("!deposit all")
    delay(500)
  end
end)
macro(250, "Stack Itens", function()
    local containers = g_game.getContainers()
    if not containers then return end
    local itensMapeados = {}
    for _, container in pairs(containers) do
        for slotIndex, item in ipairs(container:getItems()) do
            if item:isStackable() and item:getCount() < 1000 then
                local itemId = item:getId()
                local count = item:getCount()
                local posicaoAtual = container:getSlotPosition(slotIndex - 1)
                if not itensMapeados[itemId] or count > itensMapeados[itemId].count then
                    itensMapeados[itemId] = {
                        posicao = posicaoAtual,
                        count = count
                    }
                end
            end
        end
    end
    for _, container in pairs(containers) do
        for slotIndex, item in ipairs(container:getItems()) do
            if item:isStackable() and item:getCount() < 1000 then
                local itemId = item:getId()
                local destino = itensMapeados[itemId]
                if destino then
                    local posicaoAtual = container:getSlotPosition(slotIndex - 1)
                    if posicaoAtual.x ~= destino.posicao.x or posicaoAtual.y ~= destino.posicao.y or posicaoAtual.slot ~= destino.posicao.slot then
                        local moverQuantidade = math.min(item:getCount(), 1000 - destino.count)
                        if moverQuantidade > 0 then
                            g_game.move(item, destino.posicao, moverQuantidade)
                            return
                        end
                    end
                end
            end
        end
    end
end)
local botsDesligadosPeloPVP = false
local function definirSafeFightBox(deveAtivar)
    local mapPanel = modules.game_interface and modules.game_interface.gameMapPanel
    local root = mapPanel and mapPanel:getParent()
    if root then
        local pvpButton = root:recursiveGetChildById('safeFightBox')
        if pvpButton then
            local estaAtivo = pvpButton:isOn()
            if (deveAtivar and not estaAtivo) or (not deveAtivar and estaAtivo) then
                pcall(function() pvpButton:onClick() end)
            end
        end
    end
end
local function definirModoAtaque(modo)
    local rootWidget = g_ui.getRootWidget()
    if not rootWidget then return end
    
    local idBotao = ""
    if modo == "balanced" then
        idBotao = "fightBalancedBox"
    elseif modo == "offensive" then
        idBotao = "fightOffensiveBox"
    end
    
    local targetButton = rootWidget:recursiveGetChildById(idBotao)
    if targetButton then
        pcall(function() targetButton:onClick() end)
    end
end
macro(100, 'Revide PK', function()
    local myPos = pos()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    local agressorTarget = nil
    local agressorHp = 101
    local agressorDist = 10
    for _, creature in ipairs(getSpectators(myPos)) do
        if creature:isPlayer() and creature ~= localPlayer then
            
            local estaMeAtacando = false
            if creature.isAttacking then
                estaMeAtacando = creature:isAttacking()
            else
                estaMeAtacando = (g_game.getAttackingCreature() == creature or creature:isTimedSquareVisible())
            end
            if estaMeAtacando then
                local specHp = creature:getHealthPercent()
                local specPos = creature:getPosition()
                local specDist = getDistanceBetween(myPos, specPos)
                
                if specHp and specHp > 0 then
                    if creature:canShoot() then
                        if not agressorTarget or specHp < agressorHp or (specHp == agressorHp and specDist < agressorDist) then
                            agressorTarget = creature
                            agressorHp = specHp
                            agressorDist = specDist
                        end
                    end
                end
            end
        end
    end
    if agressorTarget then
        if not botsDesligadosPeloPVP then
            if CaveBot and CaveBot.setOff then CaveBot.setOff() end
            if TargetBot and TargetBot.setOff then TargetBot.setOff() end  
            definirModoAtaque("balanced")
            
            definirSafeFightBox(true)       
            if g_game.setChaseMode then pcall(function() g_game.setChaseMode(1) end) end

            botsDesligadosPeloPVP = true
        end
        if g_game.getAttackingCreature() ~= agressorTarget then
            pcall(function()
                modules.game_interface.processMouseAction(nil, 2, myPos, nil, agressorTarget, agressorTarget)
            end)
        end
    else
        if botsDesligadosPeloPVP then
            local alvoAtualJogo = g_game.getAttackingCreature()
            if not alvoAtualJogo or not alvoAtualJogo:isPlayer() then
                definirSafeFightBox(false)           
                definirModoAtaque("offensive")
                
                if g_game.setChaseMode then pcall(function() g_game.setChaseMode(0) end) end
                if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                if TargetBot and TargetBot.setOn then TargetBot.setOn() end   
                
                botsDesligadosPeloPVP = false
            end
        end
    end
end)
UI.Separator()
if type(storage.moneyItems) ~= "table" then
  storage.moneyItems = {}
end
if not storage.smartEatDelay then
  storage.smartEatDelay = 10000
end
macro(100, "Smart Eat", function()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local pzFlag = bit.band(player:getStates(), 1) == 1 or bit.band(player:getStates(), 16384) == 16384
  local isPz = pzFlag or (g_game.isInPz and g_game.isInPz())
  if isPz then return end

  local hasBattle = bit.band(player:getStates(), 128) == 128
  if not hasBattle then return end
  if #storage.moneyItems == 0 then return end 
  
  local containers = g_game.getContainers()
  for _, container in pairs(containers) do
    if not container.lootContainer then 
      for _, item in ipairs(container:getItems()) do
        for _, moneyId in ipairs(storage.moneyItems) do
          local targetId = type(moneyId) == "table" and moneyId.id or moneyId
          if item:getId() == targetId then
            g_game.use(item)
            return delay(storage.smartEatDelay) 
          end
        end
      end
    end
  end
end)
local moneyContainer = UI.Container(function(widget, items)
  storage.moneyItems = items
end, true)
moneyContainer:setHeight(35)
if #storage.moneyItems > 0 then
  moneyContainer:setItems(storage.moneyItems)
end
UI.Separator()
local Objects = {
    435, 1948, 432, 433, 412, 413, 421, 422, 423, 424, 425, 426, 476, 475, 479, 480, 
    369, 370, 411, 414, 434, 459, 469, 470, 8559, 8560, 1968, 7476, 482, 484, 485
}
local Doors = {7727, 8265, 1629, 1632, 5129, 5120, 8266, 7728, 5102, 5111}

if not storage.autoFollowConfig then 
    storage.autoFollowConfig = { player = "name" } 
end

local toFollowPos = {}
local followTE = UI.TextEdit(storage.autoFollowConfig.player, function(widget, newText)
    storage.autoFollowConfig.player = newText
end)
followTE:setHeight(25)

macro(30, "Smart Follow", function() 
    if not g_game.isOnline() then return end
    
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer or myPlayer:isWalking() then return end

    local leaderName = storage.autoFollowConfig.player
    local target = getCreatureByName(leaderName)
    local myPos = pos()
    if target then
        local tpos = target:getPosition()
        toFollowPos[tpos.z] = tpos
        if getDistanceBetween(myPos, tpos) <= 1 then 
            return 
        end
        if getDistanceBetween(myPos, tpos) > 2 then
            for _, doorId in ipairs(Doors) do
                for x = -1, 1 do
                    for y = -1, 1 do
                        local checkPos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
                        local tile = g_map.getTile(checkPos)
                        if tile then
                            for _, item in ipairs(tile:getItems()) do
                                if item:getId() == doorId then
                                    g_game.use(item)
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end

        autoWalk(tpos, 20, { ignoreNonPathable = true, precision = 1 })
        return
    end
    local lastLeaderPosInMyFloor = toFollowPos[myPos.z]
    if lastLeaderPosInMyFloor then
        if getDistanceBetween(myPos, lastLeaderPosInMyFloor) > 0 then
            autoWalk(lastLeaderPosInMyFloor, 20, { ignoreNonPathable = true, precision = 0 })
            return
        end
        for _, objectId in ipairs(Objects) do
            for x = -1, 1 do
                for y = -1, 1 do
                    local searchPos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
                    local tile = g_map.getTile(searchPos)
                    if tile then
                        for _, item in ipairs(tile:getItems()) do
                            if item:getId() == objectId then
                                g_game.use(item)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end)
onPlayerPositionChange(function(newPos, oldPos)
    if g_game.isFollowing() then
        local tfollow = g_game.getFollowingCreature()
        if tfollow then
            local currentTargetName = tfollow:getName()
            if currentTargetName ~= storage.autoFollowConfig.player then
                followTE:setText(currentTargetName)
                storage.autoFollowConfig.player = currentTargetName
            end
        end
    end
end)
onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos then return end
    if creature:getName() == storage.autoFollowConfig.player then
        toFollowPos[newPos.z] = newPos
    end
end)
UI.Separator()
if not storage.ignoredPlayers then
    storage.ignoredPlayers = "ignore1,ignore2"
end
local function isPlayerIgnored(name)
    local cleanedName = name:lower():trim()
    for ignoredName in string.gmatch(storage.ignoredPlayers, "[^,]+") do
        if ignoredName:lower():trim() == cleanedName then
            return true
        end
    end
    return false
end
local ignoreInput = UI.TextEdit(storage.ignoredPlayers or "", function(widget, text)
    storage.ignoredPlayers = text
end)
ignoreInput:setHeight(25)
enemy = macro(30, 'Enemy', "SHIFT+3", function()
    local myPos = pos()
    local actualTarget
    local actualTargetHp = 101
    local actualTargetDist = 10
    for _, creature in ipairs(getSpectators(myPos)) do
        local specHp = creature:getHealthPercent()
        local specPos = creature:getPosition()
        local specName = creature:getName()       
        if (creature:isPlayer() and specHp and specHp > 0) then
            local specSkull = creature:getSkull()
            if (specSkull == 1 or specSkull == 4) then
                if not isPlayerIgnored(specName) then
                    if (creature:getEmblem() ~= 1 and creature:getShield() < 3 and creature ~= player) then
                        if creature:canShoot() then
                            local specDist = getDistanceBetween(myPos, specPos)
                            if not actualTarget or specHp < actualTargetHp or (specHp == actualTargetHp and specDist < actualTargetDist) then
                                actualTarget = creature
                                actualTargetPos = specPos
                                actualTargetHp = specHp
                                actualTargetDist = specDist
                            end
                        end
                    end
                end
            end
        end
    end
    
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        modules.game_interface.processMouseAction(nil, 2, myPos, nil, actualTarget, actualTarget)
    end
end)
UI.Separator()
xsense = macro(30, "xSense", "SHIFT+4", function()
    local target = g_game.getAttackingCreature()
    if target and target:isPlayer() then
        storage.Sense = target:getName()
    end
    if storage.Sense and storage.Sense ~= "" and (manapercent() <= 50) then
        say('sense "' .. storage.Sense)
        delay(10000)
    end
end)

onTalk(function(...)
    local args = {...}
    local text = nil
    for i = 1, #args do
        if type(args[i]) == "string" and #args[i] > 0 then
            if not player or args[i] ~= player:getName() then
                text = args[i]
                break
            end
        end
    end
    if not text then return end
    local msg = text:trim()
 
    if string.sub(msg, 1, 1):lower() == 'x' then
        local checkMsg = string.sub(msg, 2, #msg):trim()
        
        if checkMsg == '0' then
            storage.Sense = false
        else
            storage.Sense = checkMsg
            say('sense "' .. storage.Sense)
        end
        return true
    end
end)

lastSense = {}
UI.Button('Configure xSense', function()
  if lastSense.senseBox then
    lastSense.senseBox:destroy()
  end
  storage.sensePositions = nil
  lastSense.init()
end)

lastSense.widget = [[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]]


lastSense.pointerWidget = setupUI([[
Panel
  image-source: /images/ui/panel_flat
  size: 40 40
]], g_ui.getRootWidget())

HTTP.downloadImage("https://i.imgur.com/Nq5O8WV.png", function(image)
    return lastSense.pointerWidget:setImageSource(image)
end)


lastSense.init = function()

  if not storage.sensePositions or table.size(storage.sensePositions) < 4 then
    lastSense.startMapeation = true
    storage.sensePositions = {}
  end


  if lastSense.startMapeation then


    lastSense.directions, lastSense.actualSense = {
      'Norte',
      'Sul',
      'Esquerda',
      'Direita'
    }, 1
    modules.game_textmessage.displayGameMessage('Configuring your Sense.')
    schedule(1500, function()
      modules.game_textmessage.displayGameMessage('Arraste a box para o Norte segurando CTRL  --  Drag the box to the North pressing CTRL')
      lastSense.senseBox = setupUI(lastSense.widget, g_ui.getRootWidget())

      lastSense.senseBox:setHeight(50)
      lastSense.senseBox:setWidth(50)
      lastSense.senseBox:setPosition({x = 1030, y = 380})
      lastSense.senseBox:setText('BOX')
      lastSense.senseBox.onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then
          return false
        end
        widget:breakAnchors()
        widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
        return true
      end
  
      lastSense.senseBox.onDragMove = function(widget, mousePos, moved)
        local parentRect = widget:getParent():getRect()
        local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
        local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())        
        widget:move(x, y)
        return true
      end
  
      lastSense.senseBox.onDragLeave = function(widget, pos)
        storage.sensePositions[
          lastSense.directions[lastSense.actualSense]
        ] = {x = widget:getX(), y = widget:getY()}
        schedule(500, function()
          lastSense.actualSense = lastSense.actualSense + 1
          if lastSense.actualSense > 4 then
            modules.game_textmessage.displayGameMessage('Sense ready to use.')
            lastSense.senseBox:destroy()
            lastSense.setup()
            return true
          end
          local actualDirection = lastSense.directions[lastSense.actualSense]
          local showText = '[PT] Arraste a box para ' .. actualDirection .. ', segurando CTRL -- [ENG] Drag the box to the ' .. actualDirection .. ', pressing CTRL'
          if string.sub(actualDirection, actualDirection:len(), actualDirection:len()) == 'a' then
            showText = '[PT] Arraste a box para ' .. actualDirection .. ', segurando CTRL -- [ENG] Drag the box to the ' .. actualDirection .. ', pressing CTRL'
          end
          modules.game_textmessage.displayGameMessage(showText)
        end)
        return true
      end
    end)
  else
    lastSense.setup()
  end
  
end

function lastSense.setup()
  macro(100, function()
      local sensePlayer = getCreatureByName(tostring(lastSense.actualSense))
      if (sensePlayer and getDistanceBetween(sensePlayer:getPosition(), pos()) < 6) or (not lastSense.elapsed or lastSense.elapsed < now) then
        lastSense.pointerWidget:hide()
      elseif lastSense.pointerWidget:isHidden() then
        lastSense.pointerWidget:show()
      end
    end
  )
  
  local north, south, west, east = storage.sensePositions['Norte'], storage.sensePositions['Sul'], storage.sensePositions['Esquerda'], storage.sensePositions['Direita']
  
  lastSense.savePos = {
    ['north'] = {x = north.x, y = north.y, rotation = 0},
    ['south'] = {x = south.x, y = south.y, rotation = 180},
    ['west'] = {x = west.x, y = west.y, rotation = 270},
    ['east'] = {x = east.x, y = east.y, rotation = 90},
    ['north-east'] = {x = east.x, y = north.y, rotation = 45},
    ['south-east'] = {x = east.x, y = south.y, rotation = 135},
    ['north-west'] = {x = west.x, y = north.y, rotation = 315},
    ['south-west'] = {x = west.x, y = south.y, rotation = 225}
  }
  
  
  lastSense.actualPosition = function(text)
    return lastSense.savePos[text]
  end

  lastSense.setPosition = function(position)
    lastSense.pointerWidget:setPosition(position)
    lastSense.pointerWidget:setRotation(position.rotation)
  end

  onTextMessage(
    function(mode, text)
      if mode == 20 then
        local regex = "([a-z A-Z]*) is ([a-z -A-Z]*)to the ([a-z -A-Z]*)."
        local lastSenseData = regexMatch(text, regex)[1]
        if lastSenseData then
          if lastSenseData[2] and lastSenseData[3] and lastSenseData[4] then
            lastSense.setPosition(lastSense.actualPosition(lastSenseData[4]:trim()))
            lastSense.actualSense = lastSenseData[2]:trim()
            lastSense['last'] = lastSense.actualSense:trim()
            lastSense.elapsed = now + 5000
            lastSense.lastPosition = player:getPosition()
          end
        end
      end
    end
  )
end
lastSense.init()
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Target HP Percentage
local showhp = macro(30, function() end)
onCreatureHealthPercentChange(function(creature, healthPercent)
  if showhp:isOff() then return end
  if creature:getName() == name() then return end
  if healthPercent >= 65 then
    creature:setText("\n\n\nTarget HP: " .. healthPercent .. "%", color)
    color = 'green'
  elseif healthPercent <= 64 then
    creature:setText("\n\n\nTarget HP: " .. healthPercent .. "%", color)
    color = 'yellow'
  elseif healthPercent <= 25 then
    creature:setText("\n\n\nTarget HP: " .. healthPercent .. "%", color)
    color = 'red'
  end
end)
onCreatureDisappear(function(creature)
  creature:setText()
end)
--Ice Hud HP Percent
macro(30, function()
local hp = g_ui.getRootWidget():recursiveGetChildById("healthCircleFront")
hp:setText("   ".. hppercent().. "             ") 
hp:setColor("white")
end)
--Ice Hud MP Percent
macro(30, function()
local hp = g_ui.getRootWidget():recursiveGetChildById("manaCircleFront")
hp:setText("                   ".. manapercent().. "          ") 
hp:setColor("white")
end)
--Auto Bless
if player:getBlessings() == 0 then
  say("!bless")
  schedule(1000, function()
    if player:getBlessings() == 0 then
      error("!! BLESS - ON !!")
    end
  end)
end
--CaveBot Creator Always Opened
macro(100, function()
  local botWindow = modules.game_bot.botWindow
  if not botWindow then return end
  local creatorPanel = botWindow:recursiveGetChildById('CaveBot.Editor')
  if creatorPanel and not creatorPanel:isVisible() then
    creatorPanel:show()
    local titleButton = botWindow:recursiveGetChildById('createCavebotBtn') or botWindow:recursiveGetChildById('createCavebot')
    if titleButton then
      titleButton:setOn(true)
    end
  end
end)
-- Magic wall & Wild growth timer
local magicWallId = 10980
local magicWallTime = 20000
local wildGrowthId = 2130
local wildGrowthTime = 45000
local activeTimers = {}
onAddThing(function(tile, thing)
  if not thing:isItem() then
    return
  end
  local timer = 0
  if thing:getId() == magicWallId then
    timer = magicWallTime
  elseif thing:getId() == wildGrowthId then
    timer = wildGrowthTime
  else
    return
  end
  local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z
  if not activeTimers[pos] or activeTimers[pos] < now then    
    activeTimers[pos] = now + timer
  end
  tile:setTimer(activeTimers[pos] - now)
end)
onRemoveThing(function(tile, thing)
  if not thing:isItem() then
    return
  end
  if (thing:getId() == magicWallId or thing:getId() == wildGrowthId) and tile:getGround() then
    local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z
    activeTimers[pos] = nil
    tile:setTimer(0)
  end  
end)
--anti-ks & monstros elite/boss
local modoPerseguicaoAtivo = false
local cavebotPausadoPorBoss = false
local previousChaseMode = 0
local monstrosEspeciais = {
    "elite",
    "boss",
    "hollow capitan shinigami",
    "complete espada",
    "gotei 13 king",
    "oversaturated hollowed shinigami"
}
local function isSpecialMob(creature)
    if not creature or not creature:isMonster() then return false end
    local name = creature:getName():lower()
    for _, specialName in ipairs(monstrosEspeciais) do
        if string.find(name, specialName) then
            return true
        end
    end
    return false
end
macro(100, function()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    local targetAtualPreCheck = g_game.getAttackingCreature()
    if targetAtualPreCheck and targetAtualPreCheck:isPlayer() then
        return
    end
    local myPos = pos()
    local spectators = getSpectators()
    if not spectators then return end
    local bossNaTela = nil
    for _, spec in ipairs(spectators) do
        if isSpecialMob(spec) then
            local hasPath = findPath(myPos, spec:getPosition(), 7, {
                ignoreLastCreature = true, 
                ignoreNonPathable = true, 
                ignoreCost = true, 
                ignoreCreatures = true
            })
            if hasPath then
                bossNaTela = spec
                break
            end
        end
    end
    if bossNaTela then
        if CaveBot and CaveBot.isOn() then
            CaveBot.delay(500)
            cavebotPausadoPorBoss = true
        end
        if not modoPerseguicaoAtivo then
            previousChaseMode = g_game.getChaseMode()
            if g_game.setChaseMode then pcall(function() g_game.setChaseMode(1) end) end
            modoPerseguicaoAtivo = true
        end
        if g_game.getAttackingCreature() ~= bossNaTela then
            if g_game.attack then
                g_game.attack(bossNaTela)
                print("[Hunter] MONSTRO ESPECIAL DETECTADO: " .. bossNaTela:getName() .. "! Focando com prioridade máxima.")
            end
        end
        return
    end
    if cavebotPausadoPorBoss and not bossNaTela then
        if CaveBot and CaveBot.delay then CaveBot.delay(0) end
        if g_game.setChaseMode then pcall(function() g_game.setChaseMode(previousChaseMode) end) end
        modoPerseguicaoAtivo = false
        cavebotPausadoPorBoss = false
        print("[Hunter] O monstro especial morreu. Cavebot despausado e modos restaurados.")
    end
    local meusMonstrosColados = 0
    for _, spec in ipairs(spectators) do
        if spec:isMonster() then
            if getDistanceBetween(myPos, spec:getPosition()) <= 1 then
                meusMonstrosColados = meusMonstrosColados + 1
            end
        end
    end
    local rivalPlayer = nil
    local monstrosNoRival = 0
    local listaMonstrosDoRival = {}

    for _, spec in ipairs(spectators) do
        if spec:isPlayer() and spec ~= localPlayer then
            rivalPlayer = spec
            local rivalPos = rivalPlayer:getPosition()
            
            for _, mob in ipairs(spectators) do
                if mob:isMonster() then
                    if getDistanceBetween(rivalPos, mob:getPosition()) <= 1 then
                        monstrosNoRival = monstrosNoRival + 1
                        table.insert(listaMonstrosDoRival, mob)
                    end
                end
            end
            break
        end
    end
    if rivalPlayer and monstrosNoRival > meusMonstrosColados and #listaMonstrosDoRival > 0 then
        local targetAtual = g_game.getAttackingCreature()
        local jaEstaAtacandoMonstroDoRival = false
        
        if targetAtual then
            for _, mobDoRival in ipairs(listaMonstrosDoRival) do
                if targetAtual:getId() == mobDoRival:getId() then
                    jaEstaAtacandoMonstroDoRival = true
                    break
                end
            end
        end
        if not jaEstaAtacandoMonstroDoRival then
            local monstroAlvo = listaMonstrosDoRival[1]
            if monstroAlvo and g_game.attack then
                if g_game.setChaseMode then pcall(function() g_game.setChaseMode(1) end) end
                modoPerseguicaoAtivo = true
                
                g_game.attack(monstroAlvo)
                print("[Smart Target] KS Detectado! Forçando Chase Mode e atacando alvo do rival.")
                return
            end
        end
    end
    local target = g_game.getAttackingCreature()
    if not target then
        if modoPerseguicaoAtivo then
            if g_game.setChaseMode then pcall(function() g_game.setChaseMode(0) end) end
            modoPerseguicaoAtivo = false
        end
        return
    end
    local distanciaAteOAlvo = getDistanceBetween(myPos, target:getPosition())
    local playerNaTela = (rivalPlayer ~= nil)
    if playerNaTela then
        if distanciaAteOAlvo > 1 then
            if g_game.setChaseMode and not modoPerseguicaoAtivo then 
                pcall(function() g_game.setChaseMode(1) end) 
                modoPerseguicaoAtivo = true
            end
        else
            if g_game.setChaseMode and modoPerseguicaoAtivo then
                pcall(function() g_game.setChaseMode(0) end) 
                modoPerseguicaoAtivo = false
            end
        end
    else
        if modoPerseguicaoAtivo then
            if g_game.setChaseMode then pcall(function() g_game.setChaseMode(0) end) end
            modoPerseguicaoAtivo = false
        end
    end
end)
--SafeFightSync
local ultimoEstadoSeguro = nil
macro(200, function()
    local rootWidget = g_ui.getRootWidget()
    if not rootWidget then return end
    local bBalanced = rootWidget:recursiveGetChildById("fightBalancedBox")
    local estaNoBalanced = bBalanced and (bBalanced:isOn() or bBalanced:isChecked())

    if estaNoBalanced then
        if ultimoEstadoSeguro ~= true then
            if g_game.setSafeFight then 
                pcall(function() g_game.setSafeFight(false) end) 
            end
            ultimoEstadoSeguro = true
            print("[PvP Protocol] Modo Balanced: SafeFight LIGADO.")
        end
    else
        if ultimoEstadoSeguro ~= false then
            if g_game.setSafeFight then 
                pcall(function() g_game.setSafeFight(true) end) 
            end
            ultimoEstadoSeguro = false
            print("[PvP Protocol] Modo Offensive: SafeFight DESLIGADO.")
        end
    end
end)
setDefaultTab("Fight")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Haste & Buff ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local function checkPz()
  local player = g_game.getLocalPlayer()
  if not player then return false end
  local pzFlag = bit.band(player:getStates(), 1) == 1 or bit.band(player:getStates(), 16384) == 16384
  local isPz = pzFlag or (g_game.isInPz and g_game.isInPz())
  return isPz
end
buffs = macro(100,"Haste", "CTRL+4", function()
  local isPz = checkPz()
  if isPz then return end
  if hasHaste() then
     delay(50100)
  else
     saySpell(storage.autobuff1)
  end
end) 
UI.TextEdit(storage.autobuff1 or "", function(widget, text)    
  storage.autobuff1 = text
end)
macro(100, "Buffs", "CTRL+4", function()
  local isPz = checkPz()
  if isPz then return end
  if not g_game.isAttacking() then return end
  say(storage.buffskill01)
  delay(100)
  say(storage.buffskill02)
  delay(65000)
end)
UI.TextEdit(storage.buffskill01 or "", function(widget, text)    
  storage.buffskill01 = text
end)
UI.TextEdit(storage.buffskill02 or "", function(widget, text)    
  storage.buffskill02 = text
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Spell at Target HP ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelName = "hpbelowconfig"
if not storage.specialCastData then
    storage.specialCastData = {
        cooldownEspecial = 2000
    }
end

if not storage[panelName] then
  storage[panelName] = {
      setting = true,
      hp = 20,
      enabled = false
  }
end
local ultimoDisparoEspecial = 0
local tomouExhaustNoEspecial = false
onTextMessage(function(mode, text)
    if not storage[panelName].enabled then return end
    local msg = text:lower()
    if string.find(msg, "exha") or string.find(msg, "exhaust") then
        tomouExhaustNoEspecial = true
        storage.specialCastData.cooldownEspecial = math.min(3000, storage.specialCastData.cooldownEspecial + 50)
        return true 
    end
end)
lowhp = macro(50, function()
    if not g_game.isAttacking() then
        return
    end  
    
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local agora = os.clock() * 1000
    if (agora - ultimoDisparoEspecial) < storage.specialCastData.cooldownEspecial then
        return
    end
    if target:getHealthPercent() <= storage[panelName].hp then
        if storage.hpspell and storage.hpspell ~= "" then
            say(storage.hpspell)
            ultimoDisparoEspecial = agora
            if not tomouExhaustNoEspecial then
                storage.specialCastData.cooldownEspecial = math.max(200, storage.specialCastData.cooldownEspecial - 10)
            else
                tomouExhaustNoEspecial = false
            end
        end
    end
end)
if storage[panelName].enabled then lowhp.setOn() else lowhp.setOff() end
local ui = setupUI([[
Panel
  height: 35
  BotSwitch
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.verticalCenter
    text-align: center
    !text: tr('Especial - Activate')

  HorizontalScrollBar
    id: HP
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.left:parent.left
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
]], parent)
ui:setId(panelName)
ui.title:setOn(storage[panelName].enabled)
ui.title.onClick = function(widget)
  storage[panelName].enabled = not storage[panelName].enabled
  widget:setOn(storage[panelName].enabled)
  if storage.painelSalvo then
      storage.painelSalvo.special = storage[panelName].enabled
  end
  
  if storage[panelName].enabled then lowhp.setOn() else lowhp.setOff() end
end
local updateHpText = function()
    if storage[panelName].setting then
        ui.HP:setText("HP: < " .. storage[panelName].hp .. "%")
    end
end
ui.HP.onValueChange = function(scroll, value)
  storage[panelName].hp = value
  updateHpText()
end
ui.HP:setValue(storage[panelName].hp)
updateHpText()
UI.TextEdit(storage.hpspell or "", function(widget, text) 
    storage.hpspell = text 
end)
macro(200, function()
    if lowhp and storage.painelSalvo and storage.painelSalvo.special ~= nil then
        if storage[panelName].enabled ~= storage.painelSalvo.special then
            storage[panelName].enabled = storage.painelSalvo.special
            if ui and ui.title then
                ui.title:setOn(storage[panelName].enabled)
            end
            if storage[panelName].enabled then lowhp.setOn() else lowhp.setOff() end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Smart Cast ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local distance = 2
local amountOfMonsters = 2
local COOLDOWN_MINIMO_ABSOLUTO = 1000 
local COOLDOWN_MAXIMO = 2000          
if not storage.smartCastData then
    storage.smartCastData = {
        menorCooldownSeguro = 2000,
        calibrando = true,
        ajusteFino = false
    }
else
    storage.smartCastData.calibrando = false
    storage.smartCastData.ajusteFino = false
end
local ultimoDisparoTime = 0
if storage.comboEnabled == nil then
    storage.comboEnabled = false
end
local function aplicarPenalidadeExhaust()
    if storage.smartCastData.calibrando then
        if not storage.smartCastData.ajusteFino then
            storage.smartCastData.menorCooldownSeguro = math.min(COOLDOWN_MAXIMO, storage.smartCastData.menorCooldownSeguro + 20)
            storage.smartCastData.ajusteFino = true
            print("[Smart Cast] Primeiro Exhausted! Recuando +20ms e iniciando Ajuste Fino (-1ms)...")
        else
            storage.smartCastData.calibrando = false
            storage.smartCastData.ajusteFino = false
            storage.smartCastData.menorCooldownSeguro = math.min(COOLDOWN_MAXIMO, storage.smartCastData.menorCooldownSeguro + 10)
            print("[Smart Cast] Calibração Concluída! Margem de +10ms adicionada. Valor SEGURO travado em: " .. math.floor(storage.smartCastData.menorCooldownSeguro) .. "ms")
        end
    end
end
onTextMessage(function(mode, text)
    local msg = text:lower()
    if string.find(msg, "exha") or string.find(msg, "exhaust") then
        aplicarPenalidadeExhaust()
        return true 
    end
end)
if modules.game_textmessage and modules.game_textmessage.onReceive then
    local oldOnReceive = modules.game_textmessage.onReceive
    modules.game_textmessage.onReceive = function(mode, text)
        if string.find(text:lower(), "exha") or string.find(text:lower(), "exhaust") then
            aplicarPenalidadeExhaust()
            return 
        end
        return oldOnReceive(mode, text)
    end
end
local indexArea = 1
local indexSingle = 1
combo = macro(50, "Smart Cast - Activate", function()
    if not g_game.isAttacking() then
        return
    end    
    local agora = os.clock() * 1000 
    if (agora - ultimoDisparoTime) < storage.smartCastData.menorCooldownSeguro then
        return
    end
    local target = g_game.getAttackingCreature()
    local atacandoPlayer = target and target:isPlayer()
    local specAmount = 0
    if not atacandoPlayer then
        for i, mob in ipairs(getSpectators()) do
            if (getDistanceBetween(pos(), mob:getPosition()) <= distance and mob:isMonster()) then
                specAmount = specAmount + 1
            end
        end
    end
    local enviouMagia = false
    if (specAmount >= amountOfMonsters and not atacandoPlayer) then
        local areaSpells = {}
        if storage.areaspell01 and storage.areaspell01 ~= "" then table.insert(areaSpells, storage.areaspell01) end
        if storage.areaspell02 and storage.areaspell02 ~= "" then table.insert(areaSpells, storage.areaspell02) end
        if #areaSpells > 0 then
            if indexArea > #areaSpells then indexArea = 1 end
            say(areaSpells[indexArea])
            indexArea = indexArea + 1
            enviouMagia = true
        end
    else
        local singleSpells = {}
        if storage.spell01 and storage.spell01 ~= "" then table.insert(singleSpells, storage.spell01) end
        if storage.spell02 and storage.spell02 ~= "" then table.insert(singleSpells, storage.spell02) end
        if storage.spell03 and storage.spell03 ~= "" then table.insert(singleSpells, storage.spell03) end
        if #singleSpells > 0 then
            if indexSingle > #singleSpells then indexSingle = 1 end
            say(singleSpells[indexSingle])
            indexSingle = indexSingle + 1
            enviouMagia = true
        end
    end
    if enviouMagia then
        ultimoDisparoTime = agora
        if storage.smartCastData.calibrando then
            if storage.smartCastData.menorCooldownSeguro > COOLDOWN_MINIMO_ABSOLUTO then
                if storage.smartCastData.ajusteFino then
                    storage.smartCastData.menorCooldownSeguro = math.max(COOLDOWN_MINIMO_ABSOLUTO, storage.smartCastData.menorCooldownSeguro - 1)
                else
                    storage.smartCastData.menorCooldownSeguro = math.max(COOLDOWN_MINIMO_ABSOLUTO, storage.smartCastData.menorCooldownSeguro - 10)
                end
            end
        end
    end
end)
if storage.comboEnabled then combo.setOn() else combo.setOff() end
macro(200, function()
    if combo then storage.comboEnabled = combo.isOn() end
end)
UI.Separator()
UI.Label("Area Spells (2+ Mobs)"):setColor('#FFEA99')
UI.Separator()
UI.TextEdit(storage.areaspell01 or "", function(widget, text) storage.areaspell01 = text end)
UI.TextEdit(storage.areaspell02 or "", function(widget, text) storage.areaspell02 = text end)
UI.Separator()
UI.Label("Single Spells"):setColor('#FFEA99')
UI.Separator()
UI.TextEdit(storage.spell01 or "", function(widget, text) storage.spell01 = text end)
UI.TextEdit(storage.spell02 or "", function(widget, text) storage.spell02 = text end)
UI.TextEdit(storage.spell03 or "", function(widget, text) storage.spell03 = text end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Wave ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
if storage.turnComboEnabled == nil then
    storage.turnComboEnabled = false
end
local COOLDOWN_MINIMO_ABSOLUTO = 1000
if not storage.smartCastData then
    storage.smartCastData = {
        menorCooldownSeguro = 2000,
        calibrando = false,
        ajusteFino = false
    }
end
local ultimoDisparoTurnWave = 0
turnCombo = macro(50, "Wave - Activate", function()
    local target = g_game.getAttackingCreature()
    if not target then return end
    local agora = os.clock() * 1000 
    local delaySmartCast = storage.smartCastData.menorCooldownSeguro or 2000
    if (agora - ultimoDisparoTurnWave) < delaySmartCast then
        return
    end
    local targetPos = target:getPosition()
    local myPos = pos()
    local diffX = targetPos.x - myPos.x
    local diffY = targetPos.y - myPos.y
    if math.abs(diffX) >= math.abs(diffY) then
        if diffX > 0 then
            g_game.turn(1)
        else
            g_game.turn(3)
        end
    else
        if diffY > 0 then
            g_game.turn(2)
        else
            g_game.turn(0)
        end
    end   
    delay(30)
    if storage.turnSpell and storage.turnSpell ~= "" then
        say(storage.turnSpell)
        ultimoDisparoTurnWave = agora
        if storage.smartCastData.calibrando then
            if storage.smartCastData.menorCooldownSeguro > COOLDOWN_MINIMO_ABSOLUTO then
                if storage.smartCastData.ajusteFino then
                    storage.smartCastData.menorCooldownSeguro = math.max(COOLDOWN_MINIMO_ABSOLUTO, storage.smartCastData.menorCooldownSeguro - 1)
                else
                    storage.smartCastData.menorCooldownSeguro = math.max(COOLDOWN_MINIMO_ABSOLUTO, storage.smartCastData.menorCooldownSeguro - 10)
                end
            end
        end
    end
end)
if storage.turnComboEnabled then turnCombo.setOn() else turnCombo.setOff() end
macro(200, function()
    if turnCombo then storage.turnComboEnabled = turnCombo.isOn() end
end)
addTextEdit("spellTurnConfig", storage.turnSpell or "", function(widget, text)
    storage.turnSpell = text:trim()
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.special == nil then storage.painelSalvo.special = false end
if storage.painelSalvo.spells == nil then storage.painelSalvo.spells = false end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end
if not storage.smartCastData then
    storage.smartCastData = { menorCooldownSeguro = 2000, calibrando = true, ajusteFino = false, jaCalibrouAlgumaVez = false }
end
local painelIconesUI = setupUI([[
MainWindow
  id: painelMacrosJanela
  !text: tr('Spells')
  size: 98 225
  focusable: false
  draggable: true
  phantom: false

  Panel
    id: containerIcones
    anchors.fill: parent
    phantom: false

    Button
      id: botaoSpecial
      !text: tr('Especial')
      size: 80 40
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-left: 1

    Button
      id: botaoSpells
      !text: tr('Area/Single')
      size: 80 40
      anchors.top: botaoSpecial.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      margin-left: 1

    Button
      id: botaoWave
      !text: tr('Wave')
      size: 80 40
      anchors.top: botaoSpells.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      margin-left: 1

    Label
      id: labelCdAtual
      text: Cast: 2.00s
      size: 80 16
      font: verdana-11px-rounded
      color: #FFEA99
      text-align: center
      anchors.top: botaoWave.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 6

    Button
      id: botaoRecalibrar
      !text: tr('Recalculate')
      size: 80 20
      anchors.top: labelCdAtual.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
]], modules.game_interface.getMapPanel())

painelIconesUI.onMousePress = function(widget, mousePos, button)
    return true
end
painelIconesUI.onMouseRelease = function(widget, mousePos, button)
    return true
end
local function isMacroActive(macroRef, storageKey)
    if macroRef and type(macroRef) == "table" and macroRef.isOn then
        return macroRef.isOn()
    end
    return storage.painelSalvo[storageKey]
end
local function alternarEstadoMacro(macroRef, storageKey)
    local novoEstado = not storage.painelSalvo[storageKey]
    storage.painelSalvo[storageKey] = novoEstado
    if macroRef and type(macroRef) == "table" and macroRef.setOn then
        macroRef.setOn(novoEstado)
    elseif macroRef and type(macroRef) == "function" then
        macroRef()
    end
end
if painelIconesUI then
    local container = painelIconesUI:getChildById("containerIcones")
    if container then
        local btnSpecial = container:getChildById("botaoSpecial")
        local btnSpells = container:getChildById("botaoSpells")
        local btnWave = container:getChildById("botaoWave")
        local lblCdAtual = container:getChildById("labelCdAtual")
        local btnRecalibrar = container:getChildById("botaoRecalibrar")
        if btnSpecial then btnSpecial.onClick = function() alternarEstadoMacro(lowhp, "special") end end
        if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
        if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end
        if btnRecalibrar then
            btnRecalibrar.onClick = function()
                storage.smartCastData.menorCooldownSeguro = 2000
                storage.smartCastData.calibrando = true
                storage.smartCastData.ajusteFino = false
                storage.smartCastData.jaCalibrouAlgumaVez = false
                print("[Smart Cast] Recalculate Clicado! Cooldown resetado para 2000ms. Iniciando nova calibração...")
            end
        end
        local jaSincronizou = false
        macro(100, function()
            if not jaSincronizou then
                if lowhp and lowhp.setOn then lowhp.setOn(storage.painelSalvo.special) end
                if combo and combo.setOn then combo.setOn(storage.painelSalvo.spells) end
                if turnCombo and turnCombo.setOn then turnCombo.setOn(storage.painelSalvo.wave) end
                jaSincronizou = true
            end
            if btnSpecial then btnSpecial:setColor(isMacroActive(lowhp, "special") and "green" or "red") end
            if btnSpells then btnSpells:setColor(isMacroActive(combo, "spells") and "green" or "red") end
            if btnWave then btnWave:setColor(isMacroActive(turnCombo, "wave") and "green" or "red") end
            if lblCdAtual then
                local cdSalvoMilissegundos = storage.smartCastData and storage.smartCastData.menorCooldownSeguro or 2000
                local cdEmSegundos = cdSalvoMilissegundos / 1000
                local sufixo = (storage.smartCastData and storage.smartCastData.calibrando) and "s [C]" or "s"
                lblCdAtual:setText("Cast: " .. string.format("%.2f", cdEmSegundos) .. sufixo)
            end
        end)
    end
end

setDefaultTab("HEAL")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Healing Spell ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelName = "selfregen"
local ui = setupUI([[
Panel
  height: 35
    
  BotSwitch
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.verticalCenter
    text-align: center
    !text: tr('Activate')

  HorizontalScrollBar
    id: HP
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.left:parent.left
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
    
]], parent)
ui:setId(panelName)
if not storage[panelName] then
  storage[panelName] = {
      title = enabled,
      enabled = false,
      setting = true,
      hp = 20
  }
end
ui.title:setOn(storage[panelName].enabled)
ui.title.onClick = function(widget)
  storage[panelName].enabled = not storage[panelName].enabled
  widget:setOn(storage[panelName].enabled)
end
local updateHpText = function()
    if storage[panelName].setting then
    ui.HP:setText("HP: < " .. storage[panelName].hp .. "%")
    end
end
updateHpText()
ui.HP.onValueChange = function(scroll, value)
  storage[panelName].hp = value
  updateHpText()
end
ui.HP:setValue(storage[panelName].hp)

UI.TextEdit(storage.autohealspell1 or "regeneration", function(widget, text)    
  storage.autohealspell1 = text
end)
macro(1100, function()
 if not storage[panelName].enabled then return end

 if storage[panelName].setting then
    if hppercent() <= storage[panelName].hp then
        say(storage.autohealspell1)
    end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Reiatsu Barrier ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelName = "manabarrier"
local ui = setupUI([[
Panel
  height: 35
    
  BotSwitch
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.verticalCenter
    text-align: center
    !text: tr('Activate')

  HorizontalScrollBar
    id: HP
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.left:parent.left
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
    
]], parent)
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
      title = enabled,
      enabled = false,
      setting = true,
      hp = 20
  }
end

ui.title:setOn(storage[panelName].enabled)
ui.title.onClick = function(widget)
  storage[panelName].enabled = not storage[panelName].enabled
  widget:setOn(storage[panelName].enabled)
end

local updateHpText = function()
    if storage[panelName].setting then
    ui.HP:setText("HP: < " .. storage[panelName].hp .. "%")
    end
end
updateHpText()

ui.HP.onValueChange = function(scroll, value)
  storage[panelName].hp = value
  updateHpText()
end
ui.HP:setValue(storage[panelName].hp)

UI.TextEdit(storage.autobarrier or "reiatsu barrier", function(widget, text)    
  storage.autobarrier = text
end)

local ultimoUsoBarreira = 0
local DELAY_SEGUNDOS = 46

macro(100, function()
  if not storage[panelName].enabled then return end
  if storage[panelName].setting then
    if hppercent() <= storage[panelName].hp then
        local tempoAgora = os.time()
        if (tempoAgora - ultimoUsoBarreira) >= DELAY_SEGUNDOS then
            say(storage.autobarrier)
            ultimoUsoBarreira = tempoAgora
            
            print("[Auto Barrier] Magia conjurada! Aguardando " .. DELAY_SEGUNDOS .. " segundos de recarga.")
        end
    end
  end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Pet ~")
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelName = "selfpetconfig"
local ui = setupUI([[
Panel
  height: 50
  
  BotItem
    id: item
    anchors.top: parent.top
    anchors.left: parent.left
    margin-top: 2
    
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: item.right
    anchors.bottom: item.verticalCenter
    text-align: center
    !text: tr('Activate')
    margin-left: 10
    width: 120
  
  BotLabel
    id: help
    anchors.top: item.verticalCenter
    anchors.left: item.right
    anchors.right: parent.right
    anchors.bottom: item.bottom
    text-align: center
    margin-left: 2

  HorizontalScrollBar
    id: HP
    anchors.top: item.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
    
]], parent)
ui:setId(panelName)
local allowedIds = {
    [2993]  = 120000, -- 120 segundos
    [10479] = 120000, -- 120 segundos
    [10481] = 120000, -- 120 segundos
    [10480] = 300000  -- 300 segundos
}
if not storage.petItemCooldowns then storage.petItemCooldowns = {} end
if not storage[panelName] then
  storage[panelName] = {
      id = 10481, 
      enabled = false,
      setting = true,
      hp = 100
  }
else
  if not storage[panelName].id or storage[panelName].id == 0 then
      storage[panelName].id = 10480
  end
end

ui.title:setOn(storage[panelName].enabled)
ui.title.onClick = function(widget)
  storage[panelName].enabled = not storage[panelName].enabled
  widget:setOn(storage[panelName].enabled)
end
local updateHpText = function()
    if storage[panelName].setting then
    ui.help:setText("Health: < " .. storage[panelName].hp .. "%")
	end
end
updateHpText()
ui.HP.onValueChange = function(scroll, value)
  storage[panelName].hp = value
  updateHpText()
end
ui.item:setItemId(storage[panelName].id)
ui.item.onItemChange = function(widget)
  local novaId = widget:getItemId()
  if novaId and novaId > 0 then
      storage[panelName].id = novaId
  end
end
ui.HP:setValue(storage[panelName].hp)
petMacro = macro(100, function()

    if ui and ui.title then
        ui.title:setOn(storage[panelName].enabled)
    end
    if not storage[panelName].enabled then return end
    if storage[panelName].setting then
        local currentId = storage[panelName].id
        local itemCooldown = allowedIds[currentId]
        
        if itemCooldown then
            if hppercent() <= storage[panelName].hp then
                local currentTime = now
                local lastUsedTime = storage.petItemCooldowns[currentId] or 0
                if currentTime - lastUsedTime >= itemCooldown then
                    use(currentId)
                    storage.petItemCooldowns[currentId] = currentTime 
                end
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Potions ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelNameFastPot = "selffastpot"
local panelNameManaPot = "selfmppot"
if not storage[panelNameFastPot] then
  storage[panelNameFastPot] = { id = 11211, enabled = false, setting = true, hp = 70 }
end
if not storage[panelNameManaPot] then
  storage[panelNameManaPot] = { id = 10271, enabled = false, setting = true, hp = 50 }
end
local containerPotions = UI.createWidget("Panel")
containerPotions:setHeight(110)

local uiFastPot = setupUI([[
Panel
  height: 50
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  
  BotItem
    id: item
    anchors.top: parent.top
    anchors.left: parent.left
    margin-top: 2
    
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: item.right
    anchors.right: parent.right
    text-align: center
    !text: tr('Activate HP')
    margin-left: 10
  
  BotLabel
    id: help
    anchors.top: title.bottom
    anchors.left: item.right
    anchors.right: parent.right
    text-align: center
    margin-top: 2

  HorizontalScrollBar
    id: HP
    anchors.top: item.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    minimum: 1
    maximum: 100
    step: 1
]], containerPotions)
uiFastPot:setId(panelNameFastPot)

local uiManaPot = setupUI([[
Panel
  height: 50
  anchors.top: prev.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  margin-top: 10
  
  BotItem
    id: item
    anchors.top: parent.top
    anchors.left: parent.left
    margin-top: 2
    
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: item.right
    anchors.right: parent.right
    text-align: center
    !text: tr('Activate MP')
    margin-left: 10
  
  BotLabel
    id: help
    anchors.top: title.bottom
    anchors.left: item.right
    anchors.right: parent.right
    text-align: center
    margin-top: 2

  HorizontalScrollBar
    id: HP
    anchors.top: item.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    minimum: 1
    maximum: 100
    step: 1
]], containerPotions)
uiManaPot:setId(panelNameManaPot)
uiFastPot.title:setOn(storage[panelNameFastPot].enabled)
uiFastPot.title.onClick = function(widget)
  storage[panelNameFastPot].enabled = not storage[panelNameFastPot].enabled
  widget:setOn(storage[panelNameFastPot].enabled)
end
local updateHpText = function()
    if storage[panelNameFastPot].setting then
        uiFastPot.help:setText("Health: < " .. storage[panelNameFastPot].hp .. "%")
    end
end
updateHpText()
uiFastPot.HP.onValueChange = function(scroll, value)
  storage[panelNameFastPot].hp = value
  updateHpText()
end
uiFastPot.item:setItemId(storage[panelNameFastPot].id)
uiFastPot.item.onItemChange = function(widget)
  local novaId = widget:getItemId()
  if novaId and novaId > 0 then storage[panelNameFastPot].id = novaId end
end
uiFastPot.HP:setValue(storage[panelNameFastPot].hp)
macro(1000, function()
    if not storage[panelNameFastPot].enabled then return end
    if storage[panelNameFastPot].setting then
        if hppercent() <= storage[panelNameFastPot].hp then
            use(storage[panelNameFastPot].id)
        end
    end
end)
uiManaPot.title:setOn(storage[panelNameManaPot].enabled)
uiManaPot.title.onClick = function(widget)
  storage[panelNameManaPot].enabled = not storage[panelNameManaPot].enabled
  widget:setOn(storage[panelNameManaPot].enabled)
end
local updateMpText = function()
    if storage[panelNameManaPot].setting then
        uiManaPot.help:setText("Mana: < " .. storage[panelNameManaPot].hp .. "%")
    end
end
updateMpText()
uiManaPot.HP.onValueChange = function(scroll, value)
  storage[panelNameManaPot].hp = value
  updateMpText()
end
uiManaPot.item:setItemId(storage[panelNameManaPot].id)
uiManaPot.item.onItemChange = function(widget)
  local novaId = widget:getItemId()
  if novaId and novaId > 0 then storage[panelNameManaPot].id = novaId end
end
uiManaPot.HP:setValue(storage[panelNameManaPot].hp)
macro(1000, function()
    if not storage[panelNameManaPot].enabled then return end
    if storage[panelNameManaPot].setting then
        if manapercent() <= storage[panelNameManaPot].hp then
            use(storage[panelNameManaPot].id)
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
setDefaultTab("Tools")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Extra ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--AutoRoll
local panelName = "roll"
storage[panelName] = storage[panelName] or {enabled = false}
local config = storage[panelName]
if type(storage.rollItem) == "table" then
  storage.rollItem = storage.rollItem or 10177
elseif type(storage.rollItem) ~= "number" then
  storage.rollItem = 10177
end
local itemStats = {
  ["Max HP"] = {{itemStat="Max HP"}},
  ["Armor Value"] = {{itemStat = "Armor Value"}},
  ["Healing"] = {{itemStat = "Healing"}},
  ["Loot Bonus"] = {{itemStat="Bonus Loot"}},
  ["Experience"] = {{itemStat="Experience"}},
  ["Elite Chance"] = {{itemStat="Elite Chance"}},
  ["Physical Damage"] = {{itemStat="Physical Damage"}},
  ["Reiatsu Damage"] = {{itemStat="Reiatsu Damage"}},
  ["Player Protection"] = {{itemStat="Player Protection"}},
  ["Attack Speed"] = {{itemStat="Attack Speed"}},
  ["Casting Speed"] = {{itemStat="Casting Speed"}},
  ["Critical Hit Chance"] = {{itemStat="Critical Hit Chance"}},
  ["DoT Damage"] = {{itemStat="DoT Damage"}},
  ["HP Regeneration"] = {{itemStat="HP Regeneration"}},
}
local ui = setupUI([[
RollItem < Panel
  height: 40
  margin-top: 2
  
  BotItem
    id: item1
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

Panel
  height: 65

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Item Roll')

  Button
    id: edit
    anchors.top: parent.top
    anchors.left: title.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
    
  RollItem
    id: items
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: title.bottom
    margin-top: 5
]])
local configWindow = setupUI([[
MainWindow
  id: configWindow
  !text: tr('Roll Setup')
  size: 200 410
  focusable: false
  draggable: true
  phantom: false

  ScrollablePanel
    id: itemStats
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: uberRoll.top
    margin-bottom: 8
    vertical-scrollbar: listaScroll
    layout:
      type: verticalBox
      spacing: 5

  VerticalScrollBar
    id: listaScroll
    anchors.top: itemStats.top
    anchors.bottom: itemStats.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true

  CheckBox
    id: uberRoll
    text: Use Uber Roll (12309)
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-bottom: 8

  Button
    id: closeButton
    text: Close
    width: 90
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
]], modules.game_interface.getMapPanel())
configWindow:hide()
configWindow:setId(panelName)
configWindow.onMousePress = function(widget, mousePos, button)
    return true
end
configWindow.onMouseRelease = function(widget, mousePos, button)
    return true
end
local panel = configWindow:getChildById("itemStats")
ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
  config.enabled = not config.enabled
  widget:setOn(config.enabled)
end
ui.edit.onClick = function()
  configWindow:show()
  configWindow:raise()
  configWindow:focus()
end
configWindow.closeButton.onClick = function(widget)
  configWindow:hide()
end
if ui.items and ui.items.item1 then
  ui.items.item1.onItemChange = function(widget)
    storage.rollItem = widget:getItemId()
  end
  ui.items.item1:setItemId(tonumber(storage.rollItem) or 10177)    
end
for itemStat, entry in pairs(itemStats) do
  local check = g_ui.createWidget("CheckBox", panel)
  if check then
    check:setText(itemStat)
    check:setChecked(config[itemStat] or false)
    check.onClick = function()
      config[itemStat] = not config[itemStat]
      check:setChecked(config[itemStat])
    end
  end
end
configWindow.uberRoll:setChecked(config.uberRoll or false)
configWindow.uberRoll.onClick = function(widget)
  config.uberRoll = not config.uberRoll
  widget:setChecked(config.uberRoll)
end
onTextMessage(function(mode, text)
  if not config.enabled then return end
    local selectedCount = 0
    for itemStat, _ in pairs(itemStats) do
      if config[itemStat] then
        selectedCount = selectedCount + 1
      end
    end
    if selectedCount > 4 then
      config.enabled = false
      ui.title:setOn(false)
      modules.game_textmessage.displayGameMessage("The maximum number of bonuses that can be rolled is 4.")
      return
    end
    local optionsFoundInMessage = 0 
    for itemStat, entry in pairs(itemStats) do
      if config[itemStat] then
        for i = 1, #entry do
          if string.find(text, entry[i].itemStat) then
            optionsFoundInMessage = optionsFoundInMessage + 1
          end
        end
      end
    end
    if optionsFoundInMessage > 0 then
      if (optionsFoundInMessage == 4 and selectedCount == 4) or 
         (optionsFoundInMessage == 3 and selectedCount == 3) or 
         (optionsFoundInMessage == 2 and selectedCount == 2) or 
         (optionsFoundInMessage == 1 and selectedCount == 1) then
        config.enabled = false
        ui.title:setOn(false)
        return
      end
    end
end)
macro(250, function()
  if not config.enabled then return end
  local useItem = nil
  if config.uberRoll then
    useItem = findItem(12309)
  else
    useItem = findItem(11060)
  end
  local eqItem = findItem(tonumber(storage.rollItem))
  if useItem and eqItem then
    if config.uberRoll then
      useWith(12309, eqItem)
    else
      useWith(11060, eqItem)
    end
  end
end)
UI.Separator()
--AutoLegendary
local panelName = "AutoLegendary"
storage[panelName] = storage[panelName] or {enabled = false}
local config = storage[panelName]
local scrollId = 11351
local ui = setupUI([[
Panel
  height: 58

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Auto Legendary

  BotItem
    id: item
    anchors.top: prev.bottom
    anchors.horizontalCenter: prev.horizontalCenter
    margin-top: 5
    width: 34
    height: 34
]])
storage.legendaryItem = storage.legendaryItem or 0
ui.item:setItemId(storage.legendaryItem)
ui.item.onItemChange = function(widget)
    storage.legendaryItem = widget:getItemId()
end
ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end
macro(1000, function()
    if not config.enabled then return end

    local scroll = findItem(scrollId)
    local item = findItem(storage.legendaryItem)

    if scroll and item then
        useWith(scroll, item)
    end
end)
onTextMessage(function(mode, text)
    text = text:upper()

    if text:find("NEW RARITY: LEGENDARY") then
        config.enabled = false
        ui.title:setOn(false)
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Guild Only ~")
UI.Label("-----------------------------------"):setColor('#C39BD3') 
invpt = macro(500, "Auto Invite PT", function()
    if not g_game.isOnline() then return end

    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    local spectators = getSpectators(pos())
    
    for _, v in ipairs(spectators) do

        if v and v:isPlayer() and v ~= myPlayer then

            if v:getShield() == 0 and v:getEmblem() == 1 then

                g_game.partyInvite(v:getId())
            end
        end
    end
end)

accpt = macro(1000, "Auto Join PT", function()
    if not g_game.isOnline() then return end

    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    local spectators = getSpectators(pos())
    
    for _, v in ipairs(spectators) do
        if v and v:isPlayer() and v ~= myPlayer then
            if v:getShield() == 1 and v:getEmblem() == 1 then
                g_game.partyAccept(v:getId())
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Screen ~")
UI.Label("-----------------------------------"):setColor('#C39BD3') 
UI.Button("+  Zoom", function() zoomIn() end)
UI.Button("-  Zoom", function() zoomOut() end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ HUD Hotkeys ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Start/Stop CaveBot
macro(1, "Start/Stop CaveBot", ("CTRL+1"), function(killcave)
if CaveBot.isOn() then
 CaveBot.setOff()
 killcave.setOff()
else
 CaveBot.setOn()
 killcave.setOff()
end
end)
--start/stop TargetBot
macro(1, "Start/Stop TargetBot", ("CTRL+2"), function(killtarget)
if TargetBot.isOn() then
 TargetBot.setOff()
 killtarget.setOff()
else
 TargetBot.setOn()
 killtarget.setOff()
end
end)
--BugMap AWSD/Setas/NumPad
local ladderIds = { 
    -- Escadas de Madeira e Pranchas Tradicionais
    1385, 1386, 1387, 1388, 369, 370, 434, 435, 1948, 5543, 7725, 19183, 19184,
    -- Bueiros (Sewers), Grelhas, Tampas de Esgoto e Grades de Bueiro
    411, 412, 413, 414, 432, 433, 459, 460, 475, 476, 479, 480, 2984, 2985, 5732,
    -- Rampas (Pedra, Barro, Areia, Gelo, Montanha, Cristal, Earth, Sandstone)
    1389, 1391, 1393, 1395, 1397, 1399, 1401, 1403, 1405, 3131, 3132, 3133, 3134,
    4526, 4527, 4528, 4529, 4530, 4531, 4532, 4533, 4534, 4535, 4536, 4537, 4538,
    4834, 4835, 4836, 4837, 6909, 6911, 6913, 6915, 8376, 8377, 8593, 8632, 15687,
    -- Spots de Corda, Buracos com Corda Enroscada e Estacas (Rope Places)
    384, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 
    482, 483, 484, 485, 1311, 1312, 1724, 1726, 2982, 5734, 8567, 10604, 10605,
    -- Escadas de Pedra, Escadas em Caracol, Pirâmides e Ruínas de Cidades
    361, 362, 363, 364, 365, 366, 367, 368, 471, 472, 473, 474, 1407, 1409, 1411, 
    1728, 1730, 1731, 1754, 1755, 6085, 6086, 6087, 6088, 6896, 6897, 6898, 6900,
    -- Escadas Metálicas, Andaimes, Corrimãos de Parede e Rungs
    6263, 6265, 11442, 11443, 20114, 20115, 22285, 22286, 24197, 24198, 24323
}
local function checkPos(x, y)
    local player = g_game.getLocalPlayer()
    if not player then return end
    local pos = player:getPosition()
    local dirX = (x ~= 0) and (x / math.abs(x)) or 0
    local dirY = (y ~= 0) and (y / math.abs(y)) or 0
    local nextTile = g_map.getTile({x = pos.x + dirX, y = pos.y + dirY, z = pos.z})
    if nextTile then
        local topThing = nextTile:getTopUseThing()
        if topThing then
            local currentId = topThing:getId()
            for i = 1, #ladderIds do
                if currentId == ladderIds[i] then
                    return g_game.use(topThing)
                end
            end
        end
    end
    local dashX = dirX * 2
    local dashY = dirY * 2
    local targetTile = g_map.getTile({x = pos.x + dashX, y = pos.y + dashY, z = pos.z})
    if targetTile then
        local targetThing = targetTile:getTopUseThing()
        if targetThing then 
            return g_game.use(targetThing) 
        end
    end
    return false
end
dash = macro(30, "BugMap", ('CTRL+3'), function()
    local k = modules.corelib.g_keyboard.isKeyPressed
    if k('w') or k('Up') or k('numpad8') then checkPos(0, -2)
    elseif k('e') then checkPos(2, -2)
    elseif k('d') or k('Right') or k('numpad6') then checkPos(2, 0)
    elseif k('c') then checkPos(2, 2)
    elseif k('s') or k('Down') or k('numpad2') then checkPos(0, 2)
    elseif k('z') then checkPos(-2, 2)
    elseif k('a') or k('Left') or k('numpad4') then checkPos(-2, 0)
    elseif k('q') then checkPos(-2, -2)
    end
end)
if dash and dash.setOff then dash.setOff() end
--HoldAttack
chaseatk = macro(100, "Hold Target", "SHIFT+2", function()
  if g_game.isAttacking() 
then
 oldTarget = g_game.getAttackingCreature()
  end
  if (oldTarget and oldTarget:getPosition()) 
then
 if (not g_game.isAttacking() and getDistanceBetween(pos(), oldTarget:getPosition()) <= 8) then

if (oldTarget:getPosition().z == posz()) then
        g_game.attack(oldTarget)
      end
    end
  end
end)

if chaseatk and chaseatk.setOff then
    chaseatk.setOff()
end
--Auto MWall na Frente do Alvo
local MW_ID = 10571
local ultimoUso = 0

mwall = macro(100, "MWall on Target", "SHIFT+1", function()
    if os.time() - ultimoUso < 5 then return end
    local player = g_game.getLocalPlayer()
    local target = g_game.getAttackingCreature()
    if not player or not target or target:getHealthPercent() <= 0 then return end
    local pPos = player:getPosition()
    local tPos = target:getPosition()
    if pPos.z ~= tPos.z then return end
    local dir = target:getDirection()
    local targetFrontPos = {x = tPos.x, y = tPos.y, z = tPos.z}
    if dir == 0 then -- Norte
        targetFrontPos.y = targetFrontPos.y - 2
    elseif dir == 1 then -- Leste
        targetFrontPos.x = targetFrontPos.x + 2
    elseif dir == 2 then -- Sul
        targetFrontPos.y = targetFrontPos.y + 2
    elseif dir == 3 then -- Oeste
        targetFrontPos.x = targetFrontPos.x - 2
    end
    local tile = g_map.getTile(targetFrontPos)
    if tile then
        g_game.useInventoryItemWith(MW_ID, tile:getTopUseThing())
        ultimoUso = os.time()
    end
end)

if mwall and mwall.setOff then
    mwall.setOff()
end
UI.Label("-----------------------------------"):setColor('#C39BD3')

local pvehud = setupUI([[
Panel
  id: pveMainPanel
  size: 14 14
  height: 500
  anchors.top: parent.top
  anchors.left: parent.left
  margin-left: 2
  margin-top: 5
  opacity: 1

  -- LABELS DO SCRIPT 1: CRÉDITOS
  Label
    id: iconlayer
    height: 12
    color: #C39BD3
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 25
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: iconlayer2
    height: 12
    color: #C39BD3
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 40
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  -- LABELS DO SCRIPT 2: ATALHOS PVE
  Label
    id: tab1
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 60
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: cave
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 75
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: target
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 90
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: dash
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 105
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: buffsinfo
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 120
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  -- LABELS DO SCRIPT 3: ATALHOS PVP
  Label
    id: tab2
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 140
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: mwallinfo
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 155
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: chaseatk
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 170
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: enemy
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 185
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: xsense
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 200
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  -- LABELS DO SCRIPT 4: STATUS DE SKILLS
  Label
    id: tab3
    height: 12
    color: white
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 220
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: skills1
    height: 12
    color: #87CEFA
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 235
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: skills3
    height: 12
    color: #C39BD3
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 250
    opacity: 0.87
    text-auto-resize: true
    text-align: center

  Label
    id: skills8
    height: 12
    color: #B0C4DE
    font: verdana-11px-rounded
    background-color: #00000090
    anchors.top: parent.top
    margin-top: 265
    opacity: 0.87
    text-auto-resize: true
    text-align: center

]], modules.game_interface.getMapPanel())

macro(100, function()
  if not pvehud then return end

  if pvehud.iconlayer then pvehud.iconlayer:setText("     ~ [Smk Custom - v4.1] ~   ") end
  if pvehud.iconlayer2 then pvehud.iconlayer2:setText(" ~ [Instagram: @cafeh_ofc] ~  ") end

  if pvehud.tab1 then pvehud.tab1:setText("           ~           [PvE]           ~       ") end
  
  if pvehud.cave then
    if CaveBot.isOn() then
      pvehud.cave:setText("~ CaveBot: [Ctrl+1]")
      pvehud.cave:setColor("#33ff99")
    else
      pvehud.cave:setText("~ CaveBot: [Ctrl+1]")
      pvehud.cave:setColor("#ff6666")
    end
  end
  
  if pvehud.target then
    if TargetBot.isOn() then
      pvehud.target:setText("~ Target: [Ctrl+2]")
      pvehud.target:setColor("#33ff99")
    else
      pvehud.target:setText("~ Target: [Ctrl+2]")
      pvehud.target:setColor("#ff6666")
    end
  end
  
  if pvehud.dash then
    if dash.isOn() then
      pvehud.dash:setText("~ BugMap: [Ctrl+3]")
      pvehud.dash:setColor("#33ff99")
    else
      pvehud.dash:setText("~ BugMap: [Ctrl+3]")
      pvehud.dash:setColor("#ff6666")
    end
  end
  
  if pvehud.buffsinfo then
    if buffs.isOn() then
      pvehud.buffsinfo:setText("~ Haste & Buff: [Ctrl+4]")
      pvehud.buffsinfo:setColor("#33ff99")
    else
      pvehud.buffsinfo:setText("~ Haste & Buff: [Ctrl+4]")
      pvehud.buffsinfo:setColor("#ff6666")
    end
  end

  if pvehud.tab2 then pvehud.tab2:setText("           ~           [PvP]           ~       ") end

  if pvehud.mwallinfo then
    if mwall.isOn() then
      pvehud.mwallinfo:setText("~ MWall on Target: [Shift+1]")
      pvehud.mwallinfo:setColor("#33ff99")
    else
      pvehud.mwallinfo:setText("~ MWall on Target: [Shift+1]")
      pvehud.mwallinfo:setColor("#ff6666")
    end
  end

  if pvehud.chaseatk then
    if chaseatk.isOn() then
      pvehud.chaseatk:setText("~ Hold Attack: [Shift+2]")
      pvehud.chaseatk:setColor("#33ff99")
    else
      pvehud.chaseatk:setText("~ Hold Attack: [Shift+2]")
      pvehud.chaseatk:setColor("#ff6666")
    end
  end

  if pvehud.enemy then
    if enemy.isOn() then
      pvehud.enemy:setText("~ Enemy: [Shift+3]")
      pvehud.enemy:setColor("#33ff99")
    else
      pvehud.enemy:setText("~ Enemy: [Shift+3]")
      pvehud.enemy:setColor("#ff6666")
    end
  end

  if pvehud.xsense then
    if xsense.isOn() then
      pvehud.xsense:setText("~ xSense: [Shift+4]")
      pvehud.xsense:setColor("#33ff99")
    else
      pvehud.xsense:setText("~ xSense: [Shift+4]")
      pvehud.xsense:setColor("#ff6666")
    end
  end

  if pvehud.tab3 then pvehud.tab3:setText("           ~         [Skills]        ~         ") end
  if pvehud.skills1 then pvehud.skills1:setText("~ Level: " .. player:getLevel() .. " - (" .. player:getLevelPercent() .. "%)") end
  if pvehud.skills3 then pvehud.skills3:setText("~ Reiatsu: " .. player:getMagicLevel() .. " - (" .. player:getMagicLevelPercent() .. "%)") end
  if pvehud.skills8 then pvehud.skills8:setText("~ Weapon: " .. player:getSkillLevel(2) .. " - (" .. player:getSkillLevelPercent(2) .. "%)") end
end)
local cavebotTab = "Cave"
local targetingTab = "Target"

setDefaultTab(cavebotTab)
CaveBot = {}
CaveBot.Extensions = {}
importStyle("/cavebot/cavebot.otui")
importStyle("/cavebot/config.otui")
importStyle("/cavebot/editor.otui")
importStyle("/cavebot/supply.otui")
dofile("/cavebot/actions.lua")
dofile("/cavebot/config.lua")
dofile("/cavebot/editor.lua")
dofile("/cavebot/example_functions.lua")
dofile("/cavebot/recorder.lua")
dofile("/cavebot/walking.lua")
dofile("/cavebot/depositer.lua")
dofile("/cavebot/supply.lua")
dofile("/cavebot/cavebot.lua")

setDefaultTab(targetingTab)
TargetBot = {} -- global namespace
importStyle("/targetbot/target.otui")
importStyle("/targetbot/creature_editor.otui")
dofile("/targetbot/creature.lua")
dofile("/targetbot/creature_attack.lua")
dofile("/targetbot/creature_editor.lua")
dofile("/targetbot/creature_priority.lua")
dofile("/targetbot/walking.lua")
dofile("/targetbot/target.lua")
