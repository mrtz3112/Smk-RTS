setDefaultTab("Main")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("      Smk Custom: v3.5      "):setColor('#C39BD3')
UI.Label("        Since 2025       "):setColor('#C39BD3')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Macro Editor
UI.Button("teste", function(newText)
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
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Auto Reconnect
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
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Auto Dodge
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

-- Recorre en círculos concéntricos desde 1 sqm hasta maxRange
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
--Auto Enter Dungeon
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
--Auto Attack House Trainer
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
--AutoDeposit
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
--AutoStack
macro(100, "Stack Itens", function()
    local containers = g_game.getContainers()
    local itensMapeados = {} -- Tabela para rastrear o melhor destino de cada ID

    for _, container in pairs(containers) do
        for slotIndex, item in ipairs(container:getItems()) do

            if item:isStackable() and item:getCount() < 10000 then
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
            if item:isStackable() and item:getCount() < 10000 then
                local itemId = item:getId()
                local destino = itensMapeados[itemId]

                if destino then
                    local posicaoAtual = container:getSlotPosition(slotIndex - 1)

                    if posicaoAtual.x ~= destino.posicao.x or posicaoAtual.y ~= destino.posicao.y or posicaoAtual.slot ~= destino.posicao.slot then
                        g_game.move(item, destino.posicao, item:getCount())
                        delay(150)
                        return "retry"
                    end
                end
            end
        end
    end
end)
--Auto GrandFisher Mask
gfmask = macro(100, "GrandFisher Mask", function()
    if not g_game.isAttacking() and not g_game.getAttackingCreature() then
        return
    end
    local helmet = getSlot(1)
    if helmet then
        use(helmet)
        delay(10000)
    end
end)
-- Auto-Defesa PVP Totalmente Automatizada (Especial Road to Shinigami)
local botsDesligadosPeloPVP = false

enemy = macro(100, 'Revide PK', function()
    local myPos = pos()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    
    local agressorTarget = nil
    local agressorHp = 101
    local agressorDist = 100

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
            
            if g_game.setFightMode then pcall(function() g_game.setFightMode(2) end) end
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
                
                if g_game.setFightMode then pcall(function() g_game.setFightMode(1) end) end
                if g_game.setChaseMode then pcall(function() g_game.setChaseMode(0) end) end
                
                if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                if TargetBot and TargetBot.setOn then TargetBot.setOn() end
                
                botsDesligadosPeloPVP = false
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Eat Food
if type(storage.moneyItems) ~= "table" then
  storage.moneyItems = {}
end
if not storage.smartEatDelay then
  storage.smartEatDelay = 10000 -- Altere aqui o valor em ms se quiser mudar o tempo fixo
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
  if #items == 0 and #storage.moneyItems > 0 then return end
  storage.moneyItems = items
end, true)
moneyContainer:setHeight(35)
moneyContainer:setItems(storage.moneyItems)
UI.Label("-----------------------------------"):setColor('#C39BD3')
--AutoFollow
local Objects = {
    435, 1948, 432, 433, 412, 413, 421, 422, 423, 424, 425, 426, 476, 475, 479, 480, 
    369, 370, 411, 414, 434, 459, 469, 470, 8559, 8560, 1968, 7476, 482, 484, 485
} -- IDs de Escadas, Buracos abertos, Cordas, Bueiros, Rampas e Portais
local Doors = {7727, 8265, 1629, 1632, 5129, 5120, 8266, 7728, 5102, 5111} -- IDs de Portas

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

    -- 1. Se o líder está na tela, atualiza o rastro e verifica distância
    if target then
        local tpos = target:getPosition()
        toFollowPos[tpos.z] = tpos -- Grava a última posição conhecida deste andar
        
        -- Se estiver perto (até 1 de distância), não precisa andar
        if getDistanceBetween(myPos, tpos) <= 1 then 
            return 
        end
        
        -- Tenta abrir portas adjacentes se estiver trancado perto do líder
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

        -- Executa o caminhar em direção ao líder na mesma tela
        autoWalk(tpos, 20, { ignoreNonPathable = true, precision = 1 })
        return
    end

    -- 2. Se o líder SUMIU da tela (Mudou de andar / Usou escada)
    local lastLeaderPosInMyFloor = toFollowPos[myPos.z]
    if lastLeaderPosInMyFloor then
        -- Se o bot ainda não chegou no ponto exato onde o líder sumiu, ele caminha até lá
        if getDistanceBetween(myPos, lastLeaderPosInMyFloor) > 0 then
            autoWalk(lastLeaderPosInMyFloor, 20, { ignoreNonPathable = true, precision = 0 })
            return
        end

        -- Se o bot JÁ CHEGOU no ponto exato onde o líder sumiu, procura escadas/bueiros ao redor para usar
        for _, objectId in ipairs(Objects) do
            for x = -1, 1 do
                for y = -1, 1 do
                    local searchPos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
                    local tile = g_map.getTile(searchPos)
                    if tile then
                        for _, item in ipairs(tile:getItems()) do
                            if item:getId() == objectId then
                                g_game.use(item) -- Clica na escada/bueiro/rampa
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end)

UI.Separator()

-- Listener: Se você der "Follow" nativo (Clique direito -> Follow) em alguém, o macro atualiza o nome automaticamente
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

-- Listener: Monitora os passos do líder pela tela para mapear o rastro perfeitamente
onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos then return end
    if creature:getName() == storage.autoFollowConfig.player then
        toFollowPos[newPos.z] = newPos
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Enemy
-- Inicializa a configuração da lista de ignorados no storage se não existir
if not storage.ignoredPlayers then
    storage.ignoredPlayers = "ignore1,ignore2"
end
-- Função auxiliar para verificar se o player está na lista de ignorados
local function isPlayerIgnored(name)
    local cleanedName = name:lower():trim()
    for ignoredName in string.gmatch(storage.ignoredPlayers, "[^,]+") do
        if ignoredName:lower():trim() == cleanedName then
            return true
        end
    end
    return false
end
-- Painel Visual: Cria o rótulo e a caixa de texto na interface do Bot
local ignoreInput = UI.TextEdit(storage.ignoredPlayers or "", function(widget, text)
    storage.ignoredPlayers = text
end)
ignoreInput:setHeight(25)
-- Macro ajustado para priorizar Menor HP e Menor Distância
enemy = macro(1, 'Enemy', "SHIFT+3", function()
    local myPos = pos()
    local actualTarget
    local actualTargetHp = 101 -- Inicializa com HP acima do máximo para a comparação funcionar
    local actualTargetDist = 100 -- Inicializa com distância alta

    for _, creature in ipairs(getSpectators(myPos)) do
        local specHp = creature:getHealthPercent()
        local specPos = creature:getPosition()
        local specName = creature:getName()       
        if (creature:isPlayer() and specHp and specHp > 0) then
            if not isPlayerIgnored(specName) then
                if (creature:getEmblem() ~= 1 and creature:getShield() < 3 and creature ~= player) then
                    if creature:canShoot() then
                        local specDist = getDistanceBetween(myPos, specPos)
                        
                        -- CRITÉRIO DE ESCOLHA:
                        -- 1. Se não houver alvo ainda OU
                        -- 2. Se o HP do novo player for MENOR que o do alvo atual OU
                        -- 3. Se o HP for IGUAL, escolhe quem tiver a MENOR distância (mais perto)
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
    
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        modules.game_interface.processMouseAction(nil, 2, myPos, nil, actualTarget, actualTarget)
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
--X-Sense
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
      --changeColor(lastSense.senseBox, {r = 255, g = 255, b = 255, a = 255}) -> Inutilizado.
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

setDefaultTab("Fight")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Haste & Buff ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- Função auxiliar interna para calcular a variável local isPz
local function checkPz()
  local player = g_game.getLocalPlayer()
  if not player then return false end
  local pzFlag = bit.band(player:getStates(), 1) == 1 or bit.band(player:getStates(), 16384) == 16384
  local isPz = pzFlag or (g_game.isInPz and g_game.isInPz())
  return isPz
end
--buffs e haste
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
macro(100, "Buff Lv250", "CTRL+4", function()
  local isPz = checkPz()
  if isPz then return end
  if not g_game.isAttacking() then return end
  say(storage.buffskill01)
  delay(60100)
end)
UI.TextEdit(storage.buffskill01 or "", function(widget, text)    
  storage.buffskill01 = text
end)
macro(100, "Buff Lv450", "CTRL+4", function()
  local isPz = checkPz()
  if isPz then return end
  if not g_game.isAttacking() then return end
  say(storage.buffskill02)
  delay(30100)
end)
UI.TextEdit(storage.buffskill02 or "", function(widget, text)    
  storage.buffskill02 = text
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Spell at Target HP ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- HP Spell on HP Below
local panelName = "hpbelowconfig"
storage.dynamicCooldownHP = storage.dynamicCooldownHP or 2000 

if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.special == nil then storage.painelSalvo.special = false end

if not storage[panelName] then
  storage[panelName] = {
      setting = true,
      hp = 20
  }
end

onTextMessage(function(mode, text)
    local msg = text:lower()
    if string.find(msg, "exha") or string.find(msg, "exhaust") then
        storage.dynamicCooldownHP = storage.dynamicCooldownHP + 10
        if storage.dynamicCooldownHP > 2000 then storage.dynamicCooldownHP = 2000 end 
        if lowhp then lowhp.delay = storage.dynamicCooldownHP end
        return true 
    end
end)

if modules.game_textmessage and modules.game_textmessage.onReceive then
    local oldOnReceive = modules.game_textmessage.onReceive
    modules.game_textmessage.onReceive = function(mode, text)
        if string.find(text:lower(), "exha") or string.find(text:lower(), "exhaust") then
            storage.dynamicCooldownHP = storage.dynamicCooldownHP + 10
            if storage.dynamicCooldownHP > 2000 then storage.dynamicCooldownHP = 2000 end
            if lowhp then lowhp.delay = storage.dynamicCooldownHP end
            return 
        end
        return oldOnReceive(mode, text)
    end
end

lowhp = macro(storage.dynamicCooldownHP, function()
    if not g_game.isAttacking() then
        return
    end  
    local target = g_game.getAttackingCreature()
    if target and target:getPosition() then 
        if target:getHealthPercent() <= storage[panelName].hp then
            if storage.hpspell and storage.hpspell ~= "" then
                say(storage.hpspell)
                storage.dynamicCooldownHP = math.max(200, storage.dynamicCooldownHP - 10)
                lowhp.delay = storage.dynamicCooldownHP
            end
        end
    end
end)

macro(200, function()
    if lowhp and uiMacrosAviso then
        storage.painelSalvo.special = lowhp.isOn()
    end
end)

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

macro(100, function()
    if ui and ui.title then
        ui.title:setOn(storage.painelSalvo.special)
    end
end)

ui.title.onClick = function(widget)
  storage.painelSalvo.special = not storage.painelSalvo.special
  widget:setOn(storage.painelSalvo.special)
  if storage.painelSalvo.special then lowhp.setOn() else lowhp.setOff() end
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
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Smart Cast ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local distance = 2
local amountOfMonsters = 2
storage.dynamicCooldown = 2000 

if storage.comboEnabled == nil then
    storage.comboEnabled = false
end

macro(50, function() end)

onTextMessage(function(mode, text)
    local msg = text:lower()
    if string.find(msg, "exha") or string.find(msg, "exhaust") then
        storage.dynamicCooldown = storage.dynamicCooldown + 10
        if storage.dynamicCooldown > 2000 then storage.dynamicCooldown = 2000 end 
        if combo then combo.delay = storage.dynamicCooldown end
        return true 
    end
end)

if modules.game_textmessage and modules.game_textmessage.onReceive then
    local oldOnReceive = modules.game_textmessage.onReceive
    modules.game_textmessage.onReceive = function(mode, text)
        if string.find(text:lower(), "exha") or string.find(text:lower(), "exhaust") then
            storage.dynamicCooldown = storage.dynamicCooldown + 10
            if storage.dynamicCooldown > 2000 then storage.dynamicCooldown = 2000 end
            if combo then combo.delay = storage.dynamicCooldown end
            return 
        end
        return oldOnReceive(mode, text)
    end
end

combo = macro(storage.dynamicCooldown, "Activate", function()
    if not g_game.isAttacking() then
        return
    end  
    
    local localPlayer = g_game.getLocalPlayer()
    local target = g_game.getAttackingCreature()
    local attackingPlayer = target and target:isPlayer()
    
    local haPlayersNaTela = false
    for _, spectator in ipairs(getSpectators()) do
        if spectator:isPlayer() and spectator ~= localPlayer then
            haPlayersNaTela = true
            break
        end
    end

    local specAmount = 0
    if not attackingPlayer then
        for i, mob in ipairs(getSpectators()) do
            if (getDistanceBetween(pos(), mob:getPosition()) <= distance and mob:isMonster()) then
                specAmount = specAmount + 1
            end
        end
    end

    if (specAmount >= amountOfMonsters and not attackingPlayer and not haPlayersNaTela) then
        local castedArea = false
        if storage.areaspell01 and storage.areaspell01 ~= "" then
            say(storage.areaspell01)
            castedArea = true
        end
        delay(50)
        if storage.areaspell02 and storage.areaspell02 ~= "" then
            say(storage.areaspell02)
            castedArea = true
        end
        if castedArea then
            storage.dynamicCooldown = math.max(200, storage.dynamicCooldown - 10)
            combo.delay = storage.dynamicCooldown
        end
    else
        local castedSingle = false     
        if storage.spell01 and storage.spell01 ~= "" then
            say(storage.spell01)
            castedSingle = true
        end
        delay(50)
        if storage.spell02 and storage.spell02 ~= "" then
            say(storage.spell02)
            castedSingle = true
        end    
        delay(50)
        if storage.spell03 and storage.spell03 ~= "" then
            say(storage.spell03)
            castedSingle = true
        end
        if castedSingle then
            storage.dynamicCooldown = math.max(200, storage.dynamicCooldown - 10)
            combo.delay = storage.dynamicCooldown
        end
    end
end)

if storage.comboEnabled then
    combo.setOn()
else
    combo.setOff()
end

macro(200, function()
    if combo then
        storage.comboEnabled = combo.isOn()
    end
end)

UI.Label("Area Spells (If 2+ Mobs)"):setColor('#FFEA99')
UI.TextEdit(storage.areaspell01 or "", function(widget, text) storage.areaspell01 = text end)
UI.TextEdit(storage.areaspell02 or "", function(widget, text) storage.areaspell02 = text end)
UI.Label("Single Spells"):setColor('#FFEA99')
UI.TextEdit(storage.spell01 or "", function(widget, text) storage.spell01 = text end)
UI.TextEdit(storage.spell02 or "", function(widget, text) storage.spell02 = text end)
UI.TextEdit(storage.spell03 or "", function(widget, text) storage.spell03 = text end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Turn Wave ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
storage.dynamicCooldown = storage.dynamicCooldown or 2000 
if storage.turnComboEnabled == nil then
    storage.turnComboEnabled = false
end

onTextMessage(function(mode, text)
    local msg = text:lower()
    if string.find(msg, "exha") or string.find(msg, "exhaust") then
        storage.dynamicCooldown = math.min(2000, storage.dynamicCooldown + 10)
        if turnCombo then turnCombo.delay = storage.dynamicCooldown end
        return true 
    end
end)

if modules.game_textmessage and modules.game_textmessage.onReceive then
    local oldOnReceive = modules.game_textmessage.onReceive
    modules.game_textmessage.onReceive = function(mode, text)
        if string.find(text:lower(), "exha") or string.find(text:lower(), "exhaust") then
            storage.dynamicCooldown = math.min(2000, storage.dynamicCooldown + 10)
            if turnCombo then turnCombo.delay = storage.dynamicCooldown end
            return 
        end
        return oldOnReceive(mode, text)
    end
end

turnCombo = macro(storage.dynamicCooldown, "Activate", function()
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local localPlayer = g_game.getLocalPlayer()
    local targetPos = target:getPosition()
    local myPos = pos()
    
    local atacandoPlayerReal = target:isPlayer()

    local haPlayersNaTela = false
    for _, spectator in ipairs(getSpectators()) do
        if spectator:isPlayer() and spectator ~= localPlayer then
            haPlayersNaTela = true
            break
        end
    end

    if haPlayersNaTela and not atacandoPlayerReal then
        return
    end

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
        storage.dynamicCooldown = math.max(200, storage.dynamicCooldown - 10)
        turnCombo.delay = storage.dynamicCooldown
    end
end)
if storage.turnComboEnabled then
    turnCombo.setOn()
else
    turnCombo.setOff()
end
macro(200, function()
    if turnCombo then
        storage.turnComboEnabled = turnCombo.isOn()
    end
end)
addTextEdit("spellTurnConfig", storage.turnSpell or "", function(widget, text)
    storage.turnSpell = text:trim()
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.special == nil then storage.painelSalvo.special = false end
if storage.painelSalvo.spells == nil then storage.painelSalvo.spells = false end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end

local painelIconesUI = setupUI([[
MainWindow
  id: painelMacrosJanela
  !text: tr('Fight')
  size: 80 230
  focusable: false
  draggable: true

  Panel
    id: containerIcones
    anchors.fill: parent
    padding: 5

    Button
      id: botaoSpecial
      !text: tr('Special')
      size: 60 45
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 5

    Button
      id: botaoSpells
      !text: tr('Spells')
      size: 60 45
      anchors.top: prev.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 15

    Button
      id: botaoWave
      !text: tr('Wave')
      size: 60 45
      anchors.top: prev.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 15
]], modules.game_interface.getMapPanel())

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

        if btnSpecial then btnSpecial.onClick = function() alternarEstadoMacro(lowhp, "special") end end
        if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
        if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end

        local jaSincronizou = false

        macro(100, function()
            if not jaSincronizou then
                if lowhp and lowhp.setOn then lowhp.setOn(storage.painelSalvo.special) end
                if combo and combo.setOn then combo.setOn(storage.painelSalvo.spells) end
                if turnCombo and turnCombo.setOn then turnCombo.setOn(storage.painelSalvo.wave) end
                jaSincronizou = true
            end

            -- Atualização visual das cores dos botões
            if btnSpecial then btnSpecial:setColor(isMacroActive(lowhp, "special") and "green" or "red") end
            if btnSpells then btnSpells:setColor(isMacroActive(combo, "spells") and "green" or "red") end
            if btnWave then btnWave:setColor(isMacroActive(turnCombo, "wave") and "green" or "red") end
        end)
    end
end

setDefaultTab("HEAL")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Healing Spell ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--fast regen
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

macro(100, function()
  if not storage[panelName].enabled then return end

  if storage[panelName].setting then
    if hppercent() <= storage[panelName].hp then
        say(storage.autobarrier)
    end
  end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Pet ~")
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Pet on Hp
local panelName = "selfpetconfig" -- Alterado para evitar conflito com as poções e salvar permanentemente
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

-- Configuração de Delays por ID Permitida (em milissegundos)
local allowedIds = {
    [2993]  = 120000, -- 120 segundos
    [10479] = 120000, -- 120 segundos
    [10481] = 120000, -- 120 segundos
    [10480] = 300000  -- 300 segundos
}

-- Inicializa o histórico de uso dos itens se não existir
if not storage.petItemCooldowns then storage.petItemCooldowns = {} end

-- CORREÇÃO: Removido o 'title = enabled' que quebrava o script, e adicionada trava de persistência
if not storage[panelName] then
  storage[panelName] = {
      id = 10480, 
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

-- Carrega o ID do item salvo na interface visual
ui.item:setItemId(storage[panelName].id)

-- CORREÇÃO: Impede que o slot salve o ID como 0 ao fechar/reiniciar o jogo de forma abrupta
ui.item.onItemChange = function(widget)
  local novaId = widget:getItemId()
  if novaId and novaId > 0 then
      storage[panelName].id = novaId
  end
end

ui.HP:setValue(storage[panelName].hp)

-- Registrado explicitamente como petMacro para funcionar com o painel de botões coloridos
petMacro = macro(100, function()
    -- Sincroniza o botão visual com o estado atual da macro externa
    if ui and ui.title then
        ui.title:setOn(storage[panelName].enabled)
    end

    if not storage[panelName].enabled then return end
    if storage[panelName].setting then
        local currentId = storage[panelName].id
        local itemCooldown = allowedIds[currentId]
        
        -- VALIDAÇÃO: Só executa se o ID do item estiver registrado na lista permitida
        if itemCooldown then
            if hppercent() <= storage[panelName].hp then
                local currentTime = now
                local lastUsedTime = storage.petItemCooldowns[currentId] or 0
                -- Verifica se o tempo de recarga específico deste item já expirou
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
--fast potion
local panelNameFastPot = "selffastpot" -- Alterado para não conflitar com "selfpet"
local uiFastPot = setupUI([[
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
uiFastPot:setId(panelNameFastPot)

if not storage[panelNameFastPot] then
  storage[panelNameFastPot] = {
      id = 3600,
      enabled = false,
      setting = true,
      hp = 100
  }
else
  if not storage[panelNameFastPot].id or storage[panelNameFastPot].id == 0 then
      storage[panelNameFastPot].id = 3600
  end
end

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
  if novaId and novaId > 0 then
      storage[panelNameFastPot].id = novaId
  end
end

uiFastPot.HP:setValue(storage[panelNameFastPot].hp)

macro(100, function()
 if not storage[panelNameFastPot].enabled then return end

 if storage[panelNameFastPot].setting then
    if hppercent() <= storage[panelNameFastPot].hp then
        use(storage[panelNameFastPot].id)
		delay(1000)
    end
	end
end)


--fast mana potion
local panelNameManaPot = "selfmppot"
local uiManaPot = setupUI([[
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
uiManaPot:setId(panelNameManaPot)

if not storage[panelNameManaPot] then
  storage[panelNameManaPot] = {
      id = 11860,
      enabled = false,
      setting = true,
      hp = 20
  }
else
  if not storage[panelNameManaPot].id or storage[panelNameManaPot].id == 0 then
      storage[panelNameManaPot].id = 11860
  end
end

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
  if novaId and novaId > 0 then
      storage[panelNameManaPot].id = novaId
  end
end

uiManaPot.HP:setValue(storage[panelNameManaPot].hp)

macro(100, function()
 if not storage[panelNameManaPot].enabled then return end

 if storage[panelNameManaPot].setting then
    if manapercent() <= storage[panelNameManaPot].hp then
        use(storage[panelNameManaPot].id)
		delay(1000)
    end
	end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')

setDefaultTab("Tools")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Extra ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--automsgtrade
macro(100, "Auto Trade Msg", function()
  local trade = getChannelId("Trade")
  if not trade then
    trade = getChannelId("Trade")
  end
  if trade and storage.autotrademsg:len() > 0 then    
    sayChannel(trade, storage.autotrademsg)
	delay(60000)
  end
end)
UI.TextEdit(storage.autotrademsg or "", function(widget, text)    
  storage.autotrademsg = text
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Guild Only ~")
UI.Label("-----------------------------------"):setColor('#C39BD3') 
--auto invite pt from guild
invpt = macro(500, "Auto Invite PT", function()
    if not g_game.isOnline() then return end

    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    -- Pega todos os espectadores ao redor da posição atual (X, Y, Z) do seu boneco
    local spectators = getSpectators(pos())
    
    for _, v in ipairs(spectators) do
        -- Garante que o alvo é um jogador válido na tela e não é você mesmo
        if v and v:isPlayer() and v ~= myPlayer then
            -- v:getShield() == 0 (Sem Party) e v:getEmblem() == 1 (Verifica o emblema específico da sua guilda/aliança se houver)
            if v:getShield() == 0 and v:getEmblem() == 1 then
                -- Envia o convite utilizando a ID de criatura nativa do OTClientv8
                g_game.partyInvite(v:getId())
            end
        end
    end
end)
--auto accept pt from guild
-- Intervalo de 1000ms (1 segundo) mantido para uma resposta rápida ao convite
accpt = macro(1000, "Auto Join PT", function()
    if not g_game.isOnline() then return end

    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    -- CORREÇÃO: Usa pos() para pegar as coordenadas completas (X,Y,Z)
    local spectators = getSpectators(pos())
    
    for _, v in ipairs(spectators) do
        -- Garante que o alvo é um jogador válido e não é você mesmo
        if v and v:isPlayer() and v ~= myPlayer then
            -- v:getShield() == 1 significa que ele é o Líder da Party que te convidou
            if v:getShield() == 1 and v:getEmblem() == 1 then
                -- CORREÇÃO: O comando correto da engine do OTCv8 para aceitar é partyAccept
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
--start/stop CaveBot
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
local function checkPos(x, y)
 xyz = g_game.getLocalPlayer():getPosition()
 xyz.x = xyz.x + x
 xyz.y = xyz.y + y
 tile = g_map.getTile(xyz)
 if tile then
  return g_game.use(tile:getTopUseThing())  
 else
  return false
 end
end
dash = macro(100, "BugMap", ('CTRL+3'), function()
 if modules.corelib.g_keyboard.isKeyPressed('w') or modules.corelib.g_keyboard.isKeyPressed('Up') or modules.corelib.g_keyboard.isKeyPressed('numpad8') then
  checkPos(0, -3)
 elseif modules.corelib.g_keyboard.isKeyPressed('e') then
  checkPos(2, -2)
 elseif modules.corelib.g_keyboard.isKeyPressed('d') or modules.corelib.g_keyboard.isKeyPressed('Right') or modules.corelib.g_keyboard.isKeyPressed('numpad6') then
  checkPos(3, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('c') then
  checkPos(2, 2)
 elseif modules.corelib.g_keyboard.isKeyPressed('s') or modules.corelib.g_keyboard.isKeyPressed('Down') or modules.corelib.g_keyboard.isKeyPressed('numpad2') then
  checkPos(0, 3)
 elseif modules.corelib.g_keyboard.isKeyPressed('z') then
  checkPos(-2, 2)
 elseif modules.corelib.g_keyboard.isKeyPressed('a') or modules.corelib.g_keyboard.isKeyPressed('Left') or modules.corelib.g_keyboard.isKeyPressed('numpad4') then
  checkPos(-3, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('q') then
  checkPos(-2, -2)
 end
end)

if dash and dash.setOff then
    dash.setOff()
end
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
