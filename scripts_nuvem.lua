-- ====================================================================
-- [INÍCIO DA ABA] GERADOR DE ARQUIVO .OTUI AUTOMÁTICO (SLIM LINE)
-- ====================================================================

-- Todo o conteúdo do alarms.otui compactado em uma linha linear para não travar o interpretador
local textoPuroDoLayoutOtui = "AlarmCheckBox < Panel\n  height: 20\n  margin-top: 2\n  CheckBox\n    id: tick\n    anchors.fill: parent\n    margin-top: 4\n    font: verdana-11px-rounded\n    text: Player Attack\n    text-offset: 17 -3\n\nAlarmCheckBoxAndSpinBox < Panel\n  height: 20\n  margin-top: 2\n  CheckBox\n    id: tick\n    anchors.fill: parent\n    anchors.right: next.left\n    margin-top: 4\n    font: verdana-11px-rounded\n    text: Player Attack\n    text-offset: 17 -3\n  SpinBox\n    id: value\n    anchors.top: parent.top\n    margin-top: 1\n    margin-bottom: 1\n    anchors.bottom: parent.bottom\n    anchors.right: parent.right\n    width: 40\n    minimum: 0\n    maximum: 100\n    step: 1\n    editable: true\n    focusable: true\n\nAlarmCheckBoxAndTextEdit < Panel\n  height: 20\n  margin-top: 2\n  CheckBox\n    id: tick\n    anchors.fill: parent\n    anchors.right: next.left\n    margin-top: 4\n    font: verdana-11px-rounded\n    text: Creature Name\n    text-offset: 17 -3\n  BotTextEdit\n    id: text\n    anchors.right: parent.right\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    width: 150\n    font: terminus-10px\n    margin-top: 1\n    margin-bottom: 1\n\nAlarmsWindow < MainWindow\n  !text: tr('Alarms')\n  size: 330 400\n  padding: 15\n  @onEscape: self:hide()\n  FlatPanel\n    id: list\n    anchors.fill: parent\n    anchors.bottom: settingsList.top\n    margin-bottom: 20\n    margin-top: 10\n    layout: verticalBox\n    padding: 10\n    padding-top: 5\n  FlatPanel\n    id: settingsList\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.bottom: separator.top\n    margin-bottom: 5\n    margin-top: 10\n    padding: 5\n    padding-left: 10\n    layout:\n      type: verticalBox\n      fit-children: true\n  Label\n    anchors.verticalCenter: settingsList.top\n    anchors.left: settingsList.left\n    margin-left: 5\n    width: 200\n    text: Alarms Settings\n    font: verdana-11px-rounded\n    color: #9f5031\n  Label\n    anchors.verticalCenter: list.top\n    anchors.left: list.left\n    margin-left: 5\n    width: 200\n    text: Active Alarms\n    font: verdana-11px-rounded\n    color: #9f5031\n  HorizontalSeparator\n    id: separator\n    anchors.right: parent.right\n    anchors.left: parent.left\n    anchors.bottom: closeButton.top\n    margin-bottom: 8\n  ResizeBorder\n    id: bottomResizeBorder\n    anchors.fill: separator\n    height: 3\n    minimum: 260\n    maximum: 600\n    margin-left: 3\n    margin-right: 3\n    background: #ffffff88\n  Button\n    id: closeButton\n    !text: tr('Close')\n    font: cipsoftFont\n    anchors.right: parent.right\n    anchors.bottom: parent.bottom\n    size: 45 21\n    margin-right: 5\n    @onClick: self:getParent():hide()"

-- Escrita segura em background assíncrono usando a raiz virtual autorizada do client
schedule(10, function()
    local targetMod = g_modules.getModule('game_bot') or g_modules.getCurrentModule()
    if targetMod then
        local targetPath = "/" .. targetMod:getName() .. "/alarms.otui"
        
        if not g_resources.fileExists(targetPath) then
            pcall(function()
                g_resources.writeFile(targetPath, textoPuroDoLayoutOtui)
            end)
        end
    end
end)



setDefaultTab("Main")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("      Smk Custom: v4.1      "):setColor('#C39BD3')
UI.Label("        Since 2025       "):setColor('#C39BD3')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Macro Editor
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
UI.Separator()
--Auto Boost
local panelName = "AutoBoost"
storage[panelName] = storage[panelName] or {enabled = false}
local config = storage[panelName]

local ui = setupUI([[
Panel
  height: 58

  BotSwitch
    id: titleBoost
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Auto Boost

  BotItem
    id: boostItem2
    anchors.top: titleBoost.bottom
    anchors.horizontalCenter: titleBoost.horizontalCenter
    margin-top: 5
    width: 34
    height: 34

  BotItem
    id: boostItem1
    anchors.top: titleBoost.bottom
    anchors.right: boostItem2.left
    margin-top: 5
    margin-right: 2
    width: 34
    height: 34

  BotItem
    id: boostItem3
    anchors.top: titleBoost.bottom
    anchors.left: boostItem2.right
    margin-top: 5
    margin-left: 2
    width: 34
    height: 34
]])

-- Inicialização dos Storages específicos para os Boosts (Todos iniciam vazios em 0)
storage.boostId1 = storage.boostId1 or 0
storage.boostId2 = storage.boostId2 or 0
storage.boostId3 = storage.boostId3 or 0

ui.boostItem1:setItemId(storage.boostId1)
ui.boostItem2:setItemId(storage.boostId2)
ui.boostItem3:setItemId(storage.boostId3)

-- Gerenciadores de mudança de item por clique/arraste
ui.boostItem1.onItemChange = function(widget)
    storage.boostId1 = widget:getItemId()
end

ui.boostItem2.onItemChange = function(widget)
    storage.boostId2 = widget:getItemId()
end

ui.boostItem3.onItemChange = function(widget)
    storage.boostId3 = widget:getItemId()
end

-- Botão de Ativar/Desativar
ui.titleBoost:setOn(config.enabled)
ui.titleBoost.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end

-- Tabela interna para controlar o tempo de reuso (1 hora e 10 segundos por slot)
local boostCooldowns = {0, 0, 0}

-- Execução da Macro rodando a cada 100ms para precisão de clique
macro(100, function()
    -- Não faz nada se estiver desativado ou se o personagem estiver em PZ
    if not config.enabled or isInPz() then return end

    local currentTime = now
    local boostIds = {storage.boostId1, storage.boostId2, storage.boostId3}

    for index, id in ipairs(boostIds) do
        -- Apenas processa se o slot tiver um ID válido maior que 0
        if id and id > 0 then
            -- Cooldown: 1 hora (3600000ms) + 10 segundos (10000ms) = 3610000ms
            if currentTime - boostCooldowns[index] >= 3610000 then
                local boostItem = findItem(id)
                if boostItem then
                    g_game.use(boostItem)
                    boostCooldowns[index] = currentTime -- Registra o milissegundo de uso do boost
                    break -- Uso único por ciclo de 100ms para manter o intervalo solicitado entre itens distintos
                end
            end
        end
    end
end)
UI.Separator()
--Deposit Gold & Stack Items
macro(250, "DepositGold & StackItems", function()
  if not g_game.isOnline() then return end
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
    return
  end
  local containers = g_game.getContainers()
  local itensMapeados = {}
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
--Auto Dodge
local effectIdToAvoid = 237
local flags = { ignoreNonPathable = true }
function hasEffect(tile, effectId)
    if not tile then return false end
    for _, effect in ipairs(tile:getEffects()) do
        if effect:getId() == effectId then
            return true
        end
    end
    return false
end
function findNearestSafePosition(playerPos, maxRange)
    maxRange = maxRange or 7
    for r = 1, maxRange do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local newPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
                    local tile = g_map.getTile(newPos)

                    if tile and tile:isWalkable() and not hasEffect(tile, effectIdToAvoid) then
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
    if player:isWalking() then return end

    local playerPos = player:getPosition()
    local currentTile = g_map.getTile(playerPos)

    if not currentTile or not hasEffect(currentTile, effectIdToAvoid) then
        return
    end

    local safePos = findNearestSafePosition(playerPos)
    if safePos then
        autoWalk(safePos, 3, flags) 
        delay(200)
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
-- Revide PK
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
--Smart Follow
local Objects = { 
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
local Doors = {7727, 8265, 1629, 1632, 5129, 5120, 8266, 7728, 5102, 5111}

local toFollowPos = {}
local activeLeaderName = ""

macro(30, "Follow Party Leader", function() 
    if not g_game.isOnline() then return end
    
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer or myPlayer:isWalking() then return end

    local myPos = pos()
    local target = nil

    -- Procura automaticamente pelo Líder da Party na tela
    for _, spec in ipairs(getSpectators(myPos)) do
        if spec:isPlayer() and spec:isPartyLeader() then
            target = spec
            activeLeaderName = spec:getName() -- Armazena o nome para o rastreador de passos
            break
        end
    end

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

    -- Se o líder sumiu da tela ou mudou de andar, segue o rastro dele
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
        if tfollow and tfollow:isPartyLeader() then
            activeLeaderName = tfollow:getName()
        end
    end
end)

onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos then return end
    if activeLeaderName ~= "" and creature:getName() == activeLeaderName then
        toFollowPos[newPos.z] = newPos
    end
end)
--auto invite pt from guild
macro(100, "Auto Party Invite", function()
for i,v in ipairs (getSpectators(posz())) do
    if v ~= player and v:isPlayer() and v:getShield() == 0 and v:getEmblem() == 1 then
        g_game.partyInvite(v:getId())
    end
end
end)
--auto accept pt from guild
macro(100, "Auto Party Join", function()
for i,v in ipairs (getSpectators(posz())) do
    if v ~= player and v:isPlayer() and v:getShield() == 1 and v:getEmblem() == 1 then
        g_game.partyJoin(v:getId())
    end
end
end)
UI.Separator()
UI.Button("Screen: +  Zoom", function() zoomIn() end)
UI.Button("Screen: -  Zoom", function() zoomOut() end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Ice Hud HP Percent
macro(100, function()
local hp = g_ui.getRootWidget():recursiveGetChildById("healthCircleFront")
hp:setText("   ".. hppercent().. "             ") 
hp:setColor("white")
end)
--Ice Hud MP Percent
macro(100, function()
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
--Target Health Bar
local lifeColors = {
    { percent = 35, color = 'red' },
    { percent = 75, color = 'yellow' },
    { percent = 100, color = 'green' }
}

local widgetTarget = [[
UIWidget
  id: targetPanelFixed
  background-color: #1a1a1aef
  border: 1 #3a3a3a
  border-radius: 4
  size: 300 50
  focusable: false
  phantom: true
  draggable: false

  UILabel
    id: targetTitle
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 5
    color: #e8e8e8
    font: verdana-11px-rounded
    text-auto-resize: true

  ProgressBar
    id: progressBar
    height: 14
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin: 6
    background-color: #880000
    text-align: center
    text-color: white
]]

local panel = {}
panel['targetWidget'] = setupUI(widgetTarget, g_ui.getRootWidget())
panel['targetWidget']:setVisible(false)
local function getColorByPercent(percent, colorList)
    for i = 1, #colorList do
        if percent <= colorList[i].percent then
            return colorList[i].color
        end
    end
    return colorList[#colorList].color
end
local function updateTargetWidget(targetNameText, percent, hasTarget)
    local target = panel['targetWidget']
    if not target then return end
    target:setVisible(hasTarget)
    if not hasTarget then return end
    local rootWidth = g_ui.getRootWidget():getWidth()
    local posX = (rootWidth / 2) - (target:getWidth() / 2) + 90
    local posY = 80 
    target:setPosition({ x = posX, y = posY })
    target.targetTitle:setText(targetNameText)    
    target.progressBar:setText(string.format("%d%%", percent))
    target.progressBar:setPercent(percent)
    target.progressBar:setBackgroundColor(getColorByPercent(percent, lifeColors))
end
macro(100, function()
    local name, percent = "", 100
    local hasTarget = false   
    if g_game.isAttacking() then
        local target = g_game.getAttackingCreature()
        if target then
            name = target:getName()
            percent = target:getHealthPercent()
            hasTarget = true
        end
    end 
    updateTargetWidget(name, percent, hasTarget)
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
local proximoHasteTime = 0
local proximoBuffTime = 0
buffs = macro(100, "Haste", "CTRL+4", function()
  if storage.smartCastData and storage.smartCastData.calibrando then 
    return 
  end
  local agora = os.clock() * 1000
  if agora < proximoHasteTime then return end
  local isPz = checkPz()
  if isPz then return end
  if hasHaste() then
     proximoHasteTime = agora + 55000 
  else
     saySpell(storage.autobuff1)
     proximoHasteTime = os.clock() * 1000 + 55000 
  end
end) 
UI.TextEdit(storage.autobuff1 or "", function(widget, text)    
  storage.autobuff1 = text
end)
macro(100, "Buffs", "CTRL+4", function()
  if storage.smartCastData and storage.smartCastData.calibrando then 
    return 
  end
  local agora = os.clock() * 1000
  if agora < proximoBuffTime then return end
  local isPz = checkPz()
  if isPz then return end
  if not g_game.isAttacking() then return end
  say(storage.buffskill01)
  schedule(100, function()
    if storage.smartCastData and storage.smartCastData.calibrando then return end
    if not g_game.isAttacking() then return end
    say(storage.buffskill02)
  end)
  proximoBuffTime = os.clock() * 1000 + 65000 
end)
UI.TextEdit(storage.buffskill01 or "", function(widget, text)    
  storage.buffskill01 = text
end)
UI.TextEdit(storage.buffskill02 or "", function(widget, text)    
  storage.buffskill02 = text
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Smart Cast ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local distance = 2
local amountOfMonsters = 2
local COOLDOWN_MINIMO_ABSOLUTO = 50
local COOLDOWN_MAXIMO = 2000          
if not storage.smartCastData then storage.smartCastData = {} end
if not storage.smartCastData.menorCooldownSeguro then storage.smartCastData.menorCooldownSeguro = 2000 end 
if storage.smartCastData.faseCalibracao == nil then storage.smartCastData.faseCalibracao = 1 end
if storage.smartCastData.estadoAnteriorMacro == nil then storage.smartCastData.estadoAnteriorMacro = false end
if storage.smartCastData.ultimoDisparoTime == nil then storage.smartCastData.ultimoDisparoTime = 0 end
if storage.comboEnabled == nil then storage.comboEnabled = false end

local function aplicarPenalidadeExhaust()
    if storage.smartCastData.calibrando then
        local cdAtual = storage.smartCastData.menorCooldownSeguro
        
        if storage.smartCastData.faseCalibracao == 1 then
            local novoCd = math.min(COOLDOWN_MAXIMO, cdAtual + 200) -- Adiciona margem rápida
            storage.smartCastData.faseCalibracao = 2
            storage.smartCastData.menorCooldownSeguro = novoCd
            print("[Smart Cast] Exhaust Detectado! Ajustando +150ms. Iniciando Calibração Fina (-10ms)...")
        
        elseif storage.smartCastData.faseCalibracao == 2 then
            local valorFinal = math.min(COOLDOWN_MAXIMO, cdAtual + 25) -- Margem de segurança de 40ms sobre o exaust real
            storage.smartCastData.calibrando = false
            storage.smartCastData.faseCalibracao = 1 
            storage.smartCastData.menorCooldownSeguro = valorFinal
            print("[Smart Cast] Cooldown Perfeito Encontrado! Travado de forma estável em: " .. math.floor(valorFinal) .. "ms")
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
local indexArea = 1
local indexSingle = 1
combo = macro(20, "Smart Cast", function()
    if not g_game.isOnline() then return end
    if not storage.smartCastData.estadoAnteriorMacro then
        storage.smartCastData.faseCalibracao = 1
        storage.smartCastData.calibrando = true
        storage.smartCastData.ultimoDisparoTime = os.clock() * 1000
        storage.smartCastData.menorCooldownSeguro = 2000
        print("[Smart Cast] Iniciando Calibração Rápida a partir de 2000ms...")
        storage.smartCastData.estadoAnteriorMacro = true
    end
    if not g_game.isAttacking() then return end     
    local agora = os.clock() * 1000 
    local cdSeguroAtual = storage.smartCastData.menorCooldownSeguro
    if (agora - storage.smartCastData.ultimoDisparoTime) < cdSeguroAtual then
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
    -- Pós-disparo: Ajusta calibração se necessário
    if enviouMagia then
        storage.smartCastData.ultimoDisparoTime = agora
        if storage.smartCastData.calibrando then
            if cdSeguroAtual > COOLDOWN_MINIMO_ABSOLUTO then
                local redutor = 5 -- Redução fina ajustada para 5ms
                if storage.smartCastData.faseCalibracao == 1 then
                    redutor = 50 -- Redução rápida ajustada para 50ms
                end
                local novoCd = math.max(COOLDOWN_MINIMO_ABSOLUTO, cdSeguroAtual - redutor)
                storage.smartCastData.menorCooldownSeguro = novoCd
            end
        end
    end
end)
macro(250, function()
    if combo and not combo.isOn() then
        storage.smartCastData.estadoAnteriorMacro = false
    end
end)
if storage.comboEnabled then combo.setOn() else combo.setOff() end
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

-- Força sincronia inicial
if storage.comboEnabled then combo.setOn() else combo.setOff() end
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Others ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
local panelName = "hpbelowconfig"
if not storage[panelName] then
  storage[panelName] = {
      setting = true,
      hp = 80,
      enabled = false
  }
end
local ultimoDisparoEspecial = 0
local cooldownFixoEspecial = 50000 
lowhp = macro(100, function()
    if storage.smartCastData and storage.smartCastData.calibrando then 
        return 
    end
    if not g_game.isAttacking() then
        return
    end  
    local target = g_game.getAttackingCreature()
    if not target then return end
    if not target:isPlayer() then 
        return 
    end
    local agora = os.clock() * 1000
    if (agora - ultimoDisparoEspecial) < cooldownFixoEspecial then
        return
    end
    if target:getHealthPercent() <= storage[panelName].hp then
        if storage.hpspell and storage.hpspell ~= "" then
            say(storage.hpspell)
            ultimoDisparoEspecial = agora -- Registra o momento exato do disparo
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
    !text: tr('Spell at Target HP')

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
UI.Separator()
if storage.turnComboEnabled == nil then
    storage.turnComboEnabled = false
end
local COOLDOWN_MINIMO_ABSOLUTO = 100
-- 1. ESTRUTURAÇÃO DO BANCO DE DADOS (Garante que as tabelas existam em sincronia)
if not storage.smartCastData then storage.smartCastData = {} end
if not storage.smartCastData.cdPvE then storage.smartCastData.cdPvE = 2000 end 
if not storage.smartCastData.cdPvP then storage.smartCastData.cdPvP = 2000 end 
-- Função de suporte para ler qual botão de combate nativo está marcado no client
local function obterModoAtaqueNativo()
    local root = g_ui.getRootWidget()
    if root then
        local boxOffensive = root:recursiveGetChildById('fightOffensiveBox')
        if boxOffensive and boxOffensive:isChecked() then
            return "offensive"
        end
    end
    return "balanced"
end
-- Função para ler o valor de CD do modo que está ativo AGORA
local function obterCooldownAtivo()
    local modo = obterModoAtaqueNativo()
    if modo == "offensive" then
        return storage.smartCastData.cdPvE
    else
        return storage.smartCastData.cdPvP
    end
end
-- Função para salvar o novo valor calibrado de forma isolada no respectivo set
local function salvarCooldownCalibrado(novoCd)
    local modo = obterModoAtaqueNativo()
    if modo == "offensive" then
        storage.smartCastData.cdPvE = novoCd
    else
        storage.smartCastData.cdPvP = novoCd
    end
    -- Sincroniza o valor de leitura do painel de botões
    storage.smartCastData.menorCooldownSeguro = novoCd
end

local ultimoDisparoTurnWave = 0

-- 2. MACRO PRINCIPAL DA WAVE COGNITIVA
turnCombo = macro(50, "Spell Wave (Reta)", function()
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local agora = os.clock() * 1000
    -- Lê o cooldown do set ativo atualmente (PvE ou PvP)
    local delaySmartCast = obterCooldownAtivo()
    
    if (agora - ultimoDisparoTurnWave) < delaySmartCast then
        return
    end
    
    -- Mecânica de girar em direção ao Target (Vira o boneco automaticamente)
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
    -- Solta a magia configurada se houver texto válido
    if storage.turnSpell and storage.turnSpell ~= "" then
        say(storage.turnSpell)
        ultimoDisparoTurnWave = agora
        
        -- 3. CALIBRAÇÃO EXCLUSIVA DO MODO ATIVO (AJUSTADO PARA -5ms)
        if storage.smartCastData.calibrando then
            if delaySmartCast > COOLDOWN_MINIMO_ABSOLUTO then
                -- CORREÇÃO CIRÚRGICA: Reduz a velocidade do set atual estritamente de 5 em 5ms
                local novoCd = math.max(COOLDOWN_MINIMO_ABSOLUTO, delaySmartCast - 5)
                salvarCooldownCalibrado(novoCd)
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
    storage.smartCastData = {}
end
local painelIconesUI = setupUI([[
MainWindow
  id: painelMacrosJanela
  !text: tr('Fight')
  size: 98 200
  focusable: false
  draggable: true
  phantom: false

  Panel
    id: containerIcones
    anchors.fill: parent
    phantom: false

    Button
      id: botaoSpells
      !text: tr('Area/Single')
      size: 80 40
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-left: 1

    Button
      id: botaoSpecial
      !text: tr('Target HP')
      size: 80 40
      anchors.top: botaoSpells.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      margin-left: 1

    Button
      id: botaoWave
      !text: tr('Wave (Reta)')
      size: 80 40
      anchors.top: botaoSpecial.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      margin-left: 1

    Label
      id: labelCdAtual
      text: Cast: 0.00s
      size: 80 16
      font: verdana-11px-rounded
      color: #FFEA99
      text-align: center
      anchors.top: botaoWave.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 6
]], modules.game_interface.getMapPanel())
painelIconesUI.onMousePress = function(widget, mousePos, button) return true end
painelIconesUI.onMouseRelease = function(widget, mousePos, button) return true end
local function isMacroActive(macroRef, storageKey)
    if macroRef and type(macroRef) == "table" and macroRef.isOn and type(macroRef.isOn) == "function" then
        local success, result = pcall(function() return macroRef.isOn() end)
        if success then return result end
    end
    return storage.painelSalvo and storage.painelSalvo[storageKey] or false
end
local function alternarEstadoMacro(macroRef, storageKey)
    if not storage.painelSalvo then storage.painelSalvo = {} end
    local novoEstado = not storage.painelSalvo[storageKey]
    storage.painelSalvo[storageKey] = novoEstado
    if macroRef and type(macroRef) == "table" and macroRef.setOn then
        pcall(function() macroRef.setOn(novoEstado) end)
    elseif macroRef and type(macroRef) == "function" then
        pcall(macroRef)
    end
end
if painelIconesUI then
    local container = painelIconesUI:getChildById("containerIcones")
    if container then
        local btnSpecial = container:getChildById("botaoSpecial")
        local btnSpells = container:getChildById("botaoSpells")
        local btnWave = container:getChildById("botaoWave")
        local lblCdAtual = container:getChildById("labelCdAtual")
        if btnSpecial then btnSpecial.onClick = function() alternarEstadoMacro(lowhp, "special") end end
        if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
        if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end
        local jaSincronizou = false
        local hooksConfigurados = false
        local ultimoEstadoBot = false
        if TargetBot and TargetBot.isEnabled then ultimoEstadoBot = TargetBot.isEnabled() end     
        macro(100, function()
            if not g_game.isOnline() then return end
            if not jaSincronizou then
                if lowhp and type(lowhp) == "table" and lowhp.setOn then pcall(function() lowhp.setOn(storage.painelSalvo.special) end) end
                if combo and type(combo) == "table" and combo.setOn then pcall(function() combo.setOn(storage.painelSalvo.spells) end) end
                if turnCombo and type(turnCombo) == "table" and turnCombo.setOn then pcall(function() turnCombo.setOn(storage.painelSalvo.wave) end) end
                jaSincronizou = true
            end
            if not hooksConfigurados then
                hooksConfigurados = true
            end       
            if btnSpecial then btnSpecial:setColor(isMacroActive(lowhp, "special") and "green" or "red") end
            if btnSpells then btnSpells:setColor(isMacroActive(combo, "spells") and "green" or "red") end
            if btnWave then btnWave:setColor(isMacroActive(turnCombo, "wave") and "green" or "red") end
            if lblCdAtual then
                local cdSalvoMilissegundos = storage.smartCastData and storage.smartCastData.menorCooldownSeguro or 0
                local cdEmSegundos = cdSalvoMilissegundos / 1000
                local sufixo = (storage.smartCastData and storage.smartCastData.calibrando) and "s [C]" or "s"
                lblCdAtual:setText("Cast: " .. string.format("%.2f", cdEmSegundos) .. sufixo)
            end
        end)
    end
end
setDefaultTab("HEAL")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Survival ~"):setColor('#EBDEF0')
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
    !text: tr('Healing')

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
      hp = 95
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
UI.Separator()
--Mana Shield
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
    !text: tr('Mana Shield')

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
      hp = 70
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
  if storage.smartCastData and storage.smartCastData.calibrando then 
    return 
  end
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
UI.Separator()
--Eat Food
local panelName = "AutoFood"
storage[panelName] = storage[panelName] or {enabled = false}
local config = storage[panelName]

local ui = setupUI([[
Panel
  height: 58

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Auto Food

  BotItem
    id: item1
    anchors.top: title.bottom
    anchors.right: title.horizontalCenter
    margin-top: 5
    margin-right: 2
    width: 34
    height: 34

  BotItem
    id: item2
    anchors.top: title.bottom
    anchors.left: title.horizontalCenter
    margin-top: 5
    margin-left: 2
    width: 34
    height: 34
]])
storage.foodItem1 = storage.foodItem1 or 3577
storage.foodItem2 = 0
ui.item1:setItemId(storage.foodItem1)
ui.item2:setItemId(storage.foodItem2)

ui.item1.onItemChange = function(widget)
    storage.foodItem1 = widget:getItemId()
end
ui.item2.onItemChange = function(widget)
    storage.foodItem2 = widget:getItemId()
end
ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end
local foodCooldowns = {0, 0}

macro(100, function()
    if not config.enabled or isInPz() then return end
    
    local currentTime = now
    local foodIds = {storage.foodItem1, storage.foodItem2}
    for index, id in ipairs(foodIds) do
        if id and id > 0 then
            if currentTime - foodCooldowns[index] >= 10000 then
                local food = findItem(id)
                if food then
                    g_game.use(food)
                    foodCooldowns[index] = currentTime
                    break
                end
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Potions & Pet ~"):setColor('#EBDEF0')
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
      hp = 70
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
      hp = 50
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
--Pet on Hp
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
local COOLDOWN_PADRAO = 120000 
if not storage.petItemCooldowns then storage.petItemCooldowns = {} end
if not storage[panelName] then
  storage[panelName] = {
      id = 10480, 
      enabled = false,
      setting = true,
      hp = 70
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
        if currentId and currentId > 0 then
            if hppercent() <= storage[panelName].hp then
                local currentTime = now
                local lastUsedTime = storage.petItemCooldowns[currentId] or 0
                if currentTime - lastUsedTime >= COOLDOWN_PADRAO then
                    use(currentId)
                    storage.petItemCooldowns[currentId] = currentTime 
                end
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
setDefaultTab("Extra")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Items Upgrader ~"):setColor('#EBDEF0')
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
-- Inicializa os storages com valores padrão seguros
storage.legendaryItem = storage.legendaryItem or 0
storage.legendaryScroll = storage.legendaryScroll or 11351
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
    anchors.right: parent.horizontalCenter
    margin-top: 5
    margin-right: 5
    width: 34
    height: 34

  BotItem
    id: scroll
    anchors.top: title.bottom
    anchors.left: parent.horizontalCenter
    margin-top: 5
    margin-left: 5
    width: 34
    height: 34
]])
-- Configura o primeiro quadradinho (Item Alvo)
ui.item:setItemId(storage.legendaryItem)
ui.item.onItemChange = function(widget)
    storage.legendaryItem = widget:getItemId()
end
-- Configura o segundo quadradinho (Scroll)
ui.scroll:setItemId(storage.legendaryScroll)
ui.scroll.onItemChange = function(widget)
    storage.legendaryScroll = widget:getItemId()
end
ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end
macro(1000, function()
    if not config.enabled then return end
    -- Usa os IDs dinâmicos salvos no storage
    local scroll = findItem(storage.legendaryScroll)
    local item = findItem(storage.legendaryItem)
    if scroll and item then
        useWith(scroll, item)
    end
end)
onTextMessage(function(mode, text)
    text = text:upper()
    if text:find("NEW RARITY: LEGENDARY") or text:find("NEW RARITY: KAMI") then
        config.enabled = false
        ui.title:setOn(false)
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ HUD Hotkeys ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--Start/Stop CaveBot
macro(1, "Start/Stop Cave", ("CTRL+1"), function(killcave)
if CaveBot.isOn() then
 CaveBot.setOff()
 killcave.setOff()
else
 CaveBot.setOn()
 killcave.setOff()
end
end)
--start/stop TargetBot
macro(1, "Start/Stop Target", ("CTRL+2"), function(killtarget)
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
--enemy
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
local estadoAnteriorMacro = false
enemy = macro(30, 'Enemy', "SHIFT+3", function()
    if not estadoAnteriorMacro then
        definirModoAtaque("balanced")
        estadoAnteriorMacro = true
        print("[Enemy] Macro Ligada! Modo Balanced Setado.")
    end
    local myPos = pos()
    local localPlayer = g_game.getLocalPlayer()
    local actualTarget
    local actualTargetHp = 101
    local actualTargetDist = 10
    for _, creature in ipairs(getSpectators(myPos)) do
        local specHp = creature:getHealthPercent()
        local specPos = creature:getPosition()
        
        if (creature:isPlayer() and specHp and specHp > 0) then
            local specSkull = creature:getSkull()
            local specShield = creature:getShield() -- Detecta o escudo de Party
            
            -- Verifica se o player tem alguma skull de PK (1 = White, 4 = Red)
            if (specSkull == 1 or specSkull == 4) then
                -- REGRA DA PARTY: Só ataca se o jogador NÃO tiver escudo de party (specShield == 0)
                if (specShield == 0 and creature:getEmblem() ~= 1 and creature ~= localPlayer) then
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
    
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        modules.game_interface.processMouseAction(nil, 2, myPos, nil, actualTarget, actualTarget)
    end
end)
macro(250, function()
    if enemy and not enemy.isOn() and estadoAnteriorMacro then
        definirModoAtaque("offensive")
        estadoAnteriorMacro = false
        print("[Enemy] Macro Desligada! Modo Offensive Restaurado.")
    end
end)
--X-Sense
if type(storage.Sense) ~= "string" then
    storage.Sense = ""
end
xsense = macro(30, "xSense", "SHIFT+4", function()
    local target = g_game.getAttackingCreature()
    if target and target:isPlayer() then
        storage.Sense = target:getName()
    end
    if storage.Sense and storage.Sense ~= "" and (manapercent() >= 35) then
        say('sense "' .. storage.Sense)
        delay(5000)
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
            storage.Sense = ""
            modules.game_textmessage.displayStatusMessage("[xSense] Alvo limpado com sucesso!")
        else
            storage.Sense = checkMsg
            say('sense "' .. storage.Sense)
        end
        return true
    end
end)
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
      pvehud.xsense:setText("~ Auto xSense: [Shift+4]")
      pvehud.xsense:setColor("#33ff99")
    else
      pvehud.xsense:setText("~ Auto xSense: [Shift+4]")
      pvehud.xsense:setColor("#ff6666")
    end
  end

  if pvehud.tab3 then pvehud.tab3:setText("           ~         [Skills]        ~         ") end
  if pvehud.skills1 then pvehud.skills1:setText("~ Level: " .. player:getLevel() .. " - (" .. player:getLevelPercent() .. "%)") end
  if pvehud.skills3 then pvehud.skills3:setText("~ Reiatsu: " .. player:getMagicLevel() .. " - (" .. player:getMagicLevelPercent() .. "%)") end
  if pvehud.skills8 then pvehud.skills8:setText("~ Weapon: " .. player:getSkillLevel(2) .. " - (" .. player:getSkillLevelPercent(2) .. "%)") end
end)

--CaveBotConfigs
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

--NewTarget
local specialMonsters = {
  ["elite"] = true,
  ["boss"] = true,
  ["hollow capitan shinigami"] = true,
  ["complete espada"] = true,
  ["gotei 13 king"] = true,
  ["dungeon"] = true,
  ["oversaturated hollowed shinigami"] = true
}
local function isInside8x8(myPos, creaturePos)
    if not myPos or not creaturePos then return false end
    return math.abs(myPos.x - creaturePos.x) <= 3 and math.abs(myPos.y - creaturePos.y) <= 3
end
local currentWalkState = "normal"
macro(150, function()
    if not g_game.isOnline() then return end
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    local myPos = localPlayer:getPosition()
    local myId = localPlayer:getId()
    local currentTarget = g_game.getAttackingCreature()
    if currentTarget and currentTarget:isMonster() then
        local mTargetId = currentTarget.getTargetId and currentTarget:getTargetId() or 0
        if mTargetId > 0 and mTargetId ~= myId then
            g_game.cancelAttack()
        end
    end
    local spectators = g_map.getSpectators(myPos, false)
    local existeSpecialVivoNaArea = false
    if spectators then
        for _, specCreature in ipairs(spectators) do
            if specCreature:isMonster() and specCreature:getHealthPercent() > 0 then
                local mTargetId = specCreature.getTargetId and specCreature:getTargetId() or 0
                local attackingOtherPlayer = mTargetId > 0 and mTargetId ~= myId
                if not attackingOtherPlayer and isInside8x8(myPos, specCreature:getPosition()) then
                    local name = specCreature:getName():lower()
                    if name:find("elite") or 
                       name:find("boss") or 
                       name:find("hollow capitan shinigami") or 
                       name:find("complete espada") or 
                       name:find("gotei 13 king") or 
                       name:find("dungeon") or 
                       name:find("oversaturated hollowed shinigami") then
                       existeSpecialVivoNaArea = true
                       break 
                    end
                end
            end
        end
    end
    if existeSpecialVivoNaArea then
        if CaveBot and CaveBot.delay then 
            CaveBot.delay(1000) -- [ATUALIZADO] Reduzido de 2000ms para 1000ms
        end
        currentWalkState = "delayed"
    else
        if currentWalkState == "delayed" then
            if g_game.setWalkDelay then g_game.setWalkDelay(1) end
            if CaveBot and CaveBot.delay then CaveBot.delay(0) end 
            currentWalkState = "normal"
        end
    end
end)
schedule(400, function()
  if not TargetBot or not TargetBot.Creature then 
      print("[Loader] Erro: TargetBot nao encontrado para injetar prioridades.")
      return 
  end
  TargetBot.Creature.calculatePriority = function(creature, config, path)
    local priority = 0
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return priority end
    local myId = localPlayer:getId() 
    if creature:isMonster() then
      local mTargetId = creature.getTargetId and creature:getTargetId() or 0
      if mTargetId > 0 and mTargetId ~= myId then
        return -1000 
      end
    end 
    if g_game.getAttackingCreature() == creature then
      priority = priority + 1
    end  
    if #path > config.maxDistance then
      return priority
    end
    local hasSpecialInArea = false
    local myPos = localPlayer:getPosition()
    local spectators = g_map.getSpectators(myPos, false)
    for _, spec in ipairs(spectators) do
      if spec:isMonster() then
        local specTargetId = spec.getTargetId and spec:getTargetId() or 0
        local behaviorOtherPlayer = specTargetId > 0 and specTargetId ~= myId
        if not behaviorOtherPlayer and isInside8x8(myPos, spec:getPosition()) then
          local specName = spec:getName():lower()
          if specName:find("elite") or 
             specName:find("boss") or 
             specName:find("hollow capitan shinigami") or 
             specName:find("complete espada") or 
             specName:find("gotei 13 king") or 
             specName:find("dungeon") or 
             specName:find("oversaturated hollowed shinigami") then
             hasSpecialInArea = true
             break
          end
        end
      end
    end  
    if hasSpecialInArea then
      if CaveBot and CaveBot.delay then
        CaveBot.delay(1000) -- [ATUALIZADO] Reduzido de 2000ms para 1000ms
      end
    else
      if CaveBot and CaveBot.delay then
        CaveBot.delay(0)
      end
    end 
    if creature:isMonster() then
      local creatureName = creature:getName():lower()
      if creatureName:find("elite") or 
         creatureName:find("boss") or 
         creatureName:find("hollow capitan shinigami") or 
         creatureName:find("complete espada") or 
         creatureName:find("gotei 13 king") or 
         creatureName:find("dungeon") or 
         creatureName:find("oversaturated hollowed shinigami") then
         return 1000 
      end
    end
    priority = priority + config.priority 
    local path_length = #path
    if path_length == 1 then
      priority = priority + 3
    elseif path_length <= 3 then
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
  print("[Loader] Sistema de prioridade estrutural e foco injetado com sucesso!")
end)

--New CaveBot
if _G then _G.warn = function() end end
local warn = function() end
schedule(500, function()
    local realCavebotMacro = nil
    if CaveBot and CaveBot.actionList then
        local oldDoWalking = CaveBot.doWalking
        if oldDoWalking then
            CaveBot.doWalking = function()
                local isWalking = oldDoWalking()
                if isWalking and cavebotMacro then
                    cavebotMacro.delay = now + 40
                end
                return isWalking
            end
        end
        print("[Loader] CaveBot otimizado e estabilizado com sucesso de forma nativa!")
    else
        print("[Loader] Erro: CaveBot original não foi encontrado para ser modificado.")
    end
end)
