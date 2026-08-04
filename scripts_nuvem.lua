-- 1. HIGIENIZAÇÃO DE STORAGE AUTOMÁTICA VIA REPOSITÓRIO ONLINE (HTTP)
local URL_REPOSITORIO_ONLINE = "https://raw.githubusercontent.com/mrtz3112/Smk-RTS/refs/heads/main/scripts_nuvem.lua"

local chavesPermitidasLoader = {}
local carregamentoConcluido = false

local function processarConteudo(content)
    for word in content:gmatch('["\']([%a%d_%s%-]+)["\']') do 
        if word and word:len() > 0 then chavesPermitidasLoader[word] = true end
    end
    for word in content:gmatch('%.([%a%d_]+)') do 
        if word and word:len() > 0 then chavesPermitidasLoader[word] = true end
    end
    
    chavesPermitidasLoader["alarms"] = true
    chavesPermitidasLoader["_macros"] = true
    chavesPermitidasLoader["_configs"] = true
    chavesPermitidasLoader["painelSalvo"] = true
    chavesPermitidasLoader["petItemCooldowns"] = true
    chavesPermitidasLoader[""] = nil
    carregamentoConcluido = true
end

if type(HTTP) == "table" and type(HTTP.get) == "function" then
    HTTP.get(URL_REPOSITORIO_ONLINE, function(content, err)
        if not err and content and type(content) == "string" then
            processarConteudo(content)
            print("[Loader] Storage Cleaner habilitado com sucesso.")
        else
            print("[Loader] Erro ao conectar ao repositório online: " .. tostring(err))
        end
    end)
elseif type(g_http) == "table" and type(g_http.get) == "function" then
    g_http.get(URL_REPOSITORIO_ONLINE, function(content, err)
        if not err and content then
            processarConteudo(content)
            print("[Loader] Storage Cleaner importada com sucesso via g_http.")
        end
    end)
end

-- INTERCEPTADOR E CORRETOR AUTOMÁTICO DE TABELAS INVÁLIDAS
local function sanitizarTabelaParaJson(t)
    if type(t) ~= "table" then return end
    
    local temChaveTexto = false
    local temChaveNumerica = false
    local chavesParaRemover = {}

    for k, v in pairs(t) do
        -- Remove chaves vazias imediatas
        if k == "" then
            table.insert(chavesParaRemover, k)
        else
            if type(k) == "string" then temChaveTexto = true end
            if type(k) == "number" then temChaveNumerica = true end
            if type(v) == "table" then sanitizarTabelaParaJson(v) end
        end
    end

    -- Remove chaves vazias detectadas
    for _, chave in ipairs(chavesParaRemover) do t[chave] = nil end

    -- CORREÇÃO CRÍTICA: Se a tabela misturar texto e número (mista), converte números para texto
    if temChaveTexto and temChaveNumerica then
        local mudancas = {}
        for k, v in pairs(t) do
            if type(k) == "number" then
                mudancas[tostring(k)] = v
                t[k] = nil
            end
        end
        for k, v in pairs(mudancas) do t[k] = v end
    end
end

-- Intercepta a função de salvar do Cavebot para limpar a estrutura corrompida antes do crash
if CaveBot and type(CaveBot.save) == "function" then
    local oldCavebotSave = CaveBot.save
    CaveBot.save = function(...)
        if storage then
            sanitizarTabelaParaJson(storage)
        end
        return oldCavebotSave(...)
    end
elseif type(g_resources) == "table" and type(g_resources.setOption) == "function" then
    -- Alternativa genérica caso use o sistema de opções padrão do OTClient
    local oldSetOption = g_resources.setOption
    g_resources.setOption = function(key, value, ...)
        if type(value) == "table" then sanitizarTabelaParaJson(value) end
        return oldSetOption(key, value, ...)
    end
end

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
--Alarms
local panelName = "alarms"
local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Alarms')

  Button
    id: alerts
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Edit

]])
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {}
end

local config = storage[panelName]

ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
  config.enabled = not config.enabled
  widget:setOn(config.enabled)
end

local window = UI.createWindow("AlarmsWindow")
window:hide()

ui.alerts.onClick = function()
  window:show()
  window:raise()
  window:focus()
end

local widgets = 
{
  "AlarmCheckBox", 
  "AlarmCheckBoxAndSpinBox", 
  "AlarmCheckBoxAndTextEdit"
}

local parents = 
{
  window.list, 
  window.settingsList
}


-- type
addAlarm = function(id, title, defaultValue, alarmType, parent, tooltip)
  local widget = UI.createWidget(widgets[alarmType], parents[parent])
  widget:setId(id)

  if type(config[id]) ~= 'table' then
    config[id] = {}
  end

  widget.tick:setText(title)
  widget.tick:setChecked(config[id].enabled)
  widget.tick:setTooltip(tooltip)
  widget.tick.onClick = function()
    config[id].enabled = not config[id].enabled
    widget.tick:setChecked(config[id].enabled)
  end

  if alarmType > 1 and type(config[id].value) == 'nil' then
    config[id].value = defaultValue
  end

  if alarmType == 2 then
    widget.value:setValue(config[id].value)
    widget.value.onValueChange = function(widget, value)
      config[id].value = value
    end
  elseif alarmType == 3 then
    widget.text:setText(config[id].value)
    widget.text.onTextChange = function(widget, newText)
      config[id].value = newText
    end
  end

end

-- settings
addAlarm("ignoreFriends", "Ignore Friends", true, 1, 2)
addAlarm("flashClient", "Flash Client", true, 1, 2)

-- alarm list
addAlarm("damageTaken", "Damage Taken", false, 1, 1)
addAlarm("lowHealth", "Low Health", 20, 2, 1)
addAlarm("lowMana", "Low Mana", 20, 2, 1)
addAlarm("playerAttack", "Player Attack", false, 1, 1)

UI.Separator(window.list)

addAlarm("privateMsg", "Private Message", false, 1, 1)
addAlarm("defaultMsg", "Default Message", false, 1, 1)
addAlarm("customMessage", "Custom Message:", "", 3, 1, "You can add text, that if found in any incoming message will trigger alert.\n You can add many, just separate them by comma.")

UI.Separator(window.list)

addAlarm("creatureDetected", "Creature Detected", false, 1, 1)
addAlarm("playerDetected", "Player Detected", false, 1, 1)
addAlarm("creatureName", "Creature Name:", "", 3, 1, "You can add a name or part of it, that if found in any visible creature name will trigger alert.\nYou can add many, just separate them by comma.")


local lastCall = now
local function alarm(file, windowText)
  if now - lastCall < 2000 then return end -- 2s delay
  lastCall = now

  if not g_resources.fileExists(file) then
    file = "/sounds/alarm.ogg"
    lastCall = now + 4000 -- alarm.ogg length is 6s
  end

  
  if modules.game_bot.g_app.getOs() == "windows" and config.flashClient.enabled then
    g_window.flash()
  end
  g_window.setTitle(player:getName() .. " - " .. windowText)
  playSound(file)
end

-- damage taken & custom message
onTextMessage(function(mode, text)
  if not config.enabled then return end
  if mode == 22 and config.damageTaken.enabled then
    return alarm('/sounds/magnum.ogg', "Damage Received!")
  end

  if config.customMessage.enabled then
    local alertText = config.customMessage.value
    if alertText:len() > 0 then
      text = text:lower()
      local parts = string.split(alertText, ",")

      for i=1,#parts do
        local part = parts[i]
        part = part:trim()
        part = part:lower()

        if text:find(part) then
          return alarm('/sounds/magnum.ogg', "Special Message!")
        end
      end
    end
  end
end)

-- default & private message
onTalk(function(name, level, mode, text, channelId, pos)
  if not config.enabled then return end
  if name == player:getName() then return end -- ignore self messages
  if config.ignoreFriends.enabled and isFriend(name) then return end -- ignore friends if enabled

  if mode == 1 and config.defaultMsg.enabled then
    return alarm("/sounds/magnum.ogg", "Default Message!")
  end

  if mode == 4 and config.privateMsg.enabled then
    return alarm("/sounds/Private_Message.ogg", "Private Message!")
  end
end)

-- health & mana
macro(100, function() 
  if not config.enabled then return end
  if config.lowHealth.enabled then
    if hppercent() < config.lowHealth.value then
      return alarm("/sounds/Low_Health.ogg", "Low Health!")
    end
  end

  if config.lowMana.enabled then
    if hppercent() < config.lowMana.value then
      return alarm("/sounds/Low_Mana.ogg", "Low Mana!")
    end
  end

  for i, spec in ipairs(getSpectators()) do
    if not spec:isLocalPlayer() and not (config.ignoreFriends.enabled and isFriend(spec)) then

      if config.creatureDetected.enabled then
        return alarm("/sounds/magnum.ogg", "Creature Detected!")
      end

      if spec:isPlayer() then 
        if spec:isTimedSquareVisible() and config.playerAttack.enabled then
          return alarm("/sounds/Player_Attack.ogg", "Player Attack!")
        end
        if config.playerDetected.enabled then
          return alarm("/sounds/Player_Detected.ogg", "Player Detected!")
        end
      end

      if config.creatureName.enabled then
        local name = spec:getName():lower()
        local fragments = string.split(config.creatureName.value, ",")
        
        for i=1,#fragments do
          local frag = fragments[i]:trim():lower()

          if name:lower():find(frag) then
            return alarm("/sounds/alarm.ogg", "Special Creature Detected!")
          end
        end
      end
    end
  end
end)
UI.Separator()
-- Smart Follow por Nome - Versão com Layout Invertido
local Objects = { 
    1385, 1386, 1387, 1388, 369, 370, 434, 435, 1948, 5543, 7725, 19183, 19184,
    411, 412, 413, 414, 432, 433, 459, 460, 475, 476, 479, 480, 2984, 2985, 5732,
    1389, 1391, 1393, 1395, 1397, 1399, 1401, 1403, 1405, 3131, 3132, 3133, 3134,
    4526, 4527, 4528, 4529, 4530, 4531, 4532, 4533, 4534, 4535, 4536, 4537, 4538,
    4834, 4835, 4836, 4837, 6909, 6911, 6913, 6915, 8376, 8377, 8593, 8632, 15687,
    384, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 
    482, 483, 484, 485, 1311, 1312, 1724, 1726, 2982, 5734, 8567, 10604, 10605,
    361, 362, 363, 364, 365, 366, 367, 368, 471, 472, 473, 474, 1407, 1409, 1411, 
    1728, 1730, 1731, 1754, 1755, 6085, 6086, 6087, 6088, 6896, 6897, 6898, 6900,
    6263, 6265, 11442, 11443, 20114, 20115, 22285, 22286, 24197, 24198, 24323
}
local Doors = {7727, 8265, 1629, 1632, 5129, 5120, 8266, 7728, 5102, 5111}
local toFollowPos = {}
local lastWalkTarget = nil

-- Função de caminhada estável que respeita o corpo dos monstros
local function stableWalk(targetPos)
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    if myPlayer:isWalking() and lastWalkTarget and lastWalkTarget.x == targetPos.x and lastWalkTarget.y == targetPos.y and lastWalkTarget.z == targetPos.z then
        return
    end

    lastWalkTarget = targetPos

    if type(autoWalk) == "function" then
        autoWalk(targetPos, 20, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    elseif g_game.autoWalk then
        g_game.autoWalk(targetPos, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    end
end

-- 1. DECLARAÇÃO DO MACRO (Aparecerá primeiro na interface)
macro(40, "Smart Follow", function() 
    if not g_game.isOnline() then return end
    
    local targetName = tostring(storage.followTargetName or "")
    targetName = targetName:gsub("^%s*(.-)%s*$", "%1"):lower()
    
    if targetName == "" or targetName == "nome do player" then return end
    
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    local myPos = pos()
    local target = nil

    -- Localiza o jogador na tela pelo nome digitado
    for _, spec in ipairs(getSpectators(myPos)) do
        if spec:isPlayer() and spec:getName():lower() == targetName then
            target = spec
            break
        end
    end

    if target then
        local tpos = target:getPosition()
        toFollowPos[tpos.z] = tpos
        
        local dist = getDistanceBetween(myPos, tpos)
        
        -- Se já estiver colado, descansa o pathfinder
        if dist <= 1 then
            lastWalkTarget = nil
            return
        end

        stableWalk(tpos)

        -- Verificação de portas trancadas no trajeto
        if dist > 1 then
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
        return
    end

    -- Se o jogador alvo sumiu ou mudou de andar, segue o rastro
    local lastLeaderPosInMyFloor = toFollowPos[myPos.z]
    if lastLeaderPosInMyFloor then
        if getDistanceBetween(myPos, lastLeaderPosInMyFloor) > 0 then
            stableWalk(lastLeaderPosInMyFloor)
            return
        end
        
        -- Busca por escadas/portais no fim do rastro
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

-- 2. CRIAÇÃO DA INTERFACE ABAIXO DO BOTÃO (Movido para o final)
addTextEdit("followTargetName", storage.followTargetName or "Nome do Player", function(widget, text)
    storage.followTargetName = text
end)

-- Listener de rastreamento de passos em segundo plano
onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos then return end
    local targetName = tostring(storage.followTargetName or "")
    targetName = targetName:gsub("^%s*(.-)%s*$", "%1"):lower()
    
    if targetName ~= "" and creature:getName():lower() == targetName then
        toFollowPos[newPos.z] = newPos
    end
end)
UI.Separator()
--Deposit Gold & Stack Items
macro(1000, "DepositGold & StackItems", function()
  if not g_game.isOnline() then return end
  
  local coinIds = {3031, 3035, 3043, 10137} 
  local minAmount = 1
  local shouldDeposit = false

  -- 1. CHECAGEM RÁPIDA DE DINHEIRO
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

  -- 2 e 3. MAPEAR ITENS AGRUPÁVEIS (Varredura Única Otimizada)
  local containers = g_game.getContainers()
  local itensMapeados = {}
  local precisaAgrupar = false

  for _, container in pairs(containers) do
    local items = container:getItems()
    for index = 1, #items do
      local item = items[index]
      if item and item:isStackable() and item:getCount() < 10000 then 
        local itemId = item:getId()
        local count = item:getCount()
        local posicaoAtual = container:getSlotPosition(index - 1)

        if posicaoAtual then
          if itensMapeados[itemId] then
            -- Se já mapeamos esse ID antes, detectamos itens divididos
            precisaAgrupar = true
            -- Define o destino preferencial como o slot que já tiver mais itens acumulados
            if count > itensMapeados[itemId].count then
              itensMapeados[itemId] = {
                posicao = {x = posicaoAtual.x, y = posicaoAtual.y, z = posicaoAtual.z, slot = posicaoAtual.slot},
                count = count,
                containerId = container:getId(),
                slotIndex = index - 1
              }
            end
          else
            -- Primeiro registro do item
            itensMapeados[itemId] = {
              posicao = {x = posicaoAtual.x, y = posicaoAtual.y, z = posicaoAtual.z, slot = posicaoAtual.slot},
              count = count,
              containerId = container:getId(),
              slotIndex = index - 1
            }
          end
        end
      end
    end
  end

  -- Se não houver itens duplicados espalhados, encerra
  if not precisaAgrupar then
    return
  end

  -- 4. EXECUTAR A MOVIMENTAÇÃO
  for _, container in pairs(containers) do
    local items = container:getItems()
    for index = 1, #items do
      local item = items[index]
      if item and item:isStackable() and item:getCount() < 10000 then
        local itemId = item:getId()
        local destino = itensMapeados[itemId]

        if destino then
          local slotAtualIndex = index - 1
          local mesmoContainer = (container:getId() == destino.containerId)
          local mesmoSlot = (slotAtualIndex == destino.slotIndex)

          -- Só move se NÃO for exatamente o mesmo slot físico
          if not (mesmoContainer and mesmoSlot) then
            g_game.move(item, destino.posicao, item:getCount())
            delay(300) -- Um delay ligeiramente maior garante que o servidor processe o stack
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
                        if findPath(playerPos, newPos, 7, flags) then
                            return newPos
                        end
                    end
                end
            end
        end
    end
    return nil
end
macro(1, "Dodge Red SQM Spells", function()
    if player:isWalking() then return end

    local playerPos = player:getPosition()
    local currentTile = g_map.getTile(playerPos)

    if not currentTile or not hasEffect(currentTile, effectIdToAvoid) then
        return
    end

    local safePos = findNearestSafePosition(playerPos)
    if safePos then
        autoWalk(safePos, 7, flags)
    end
end)
--AutoEscadas
Stairs = {}

excludeIds = {}

stairsIds = {
    1666,
    6207,
    1948,
    435,
    7771,
    5542,
    8657,
    6264,
    1646,
    1648,
    1678,
    5291,
    1680,
    6905,
    6262,
    1664,
    13296,
    1067,
    13861,
    11931,
    1949,
    6896,
    6205,
    13926,
    1947,
    1968,
    5111,
    5102,
    7725,
    7727,
    5229,
}


for index, id in ipairs(stairsIds) do
    stairsIds[tostring(id)] = true
    stairsIds[index] = nil
end

for index, id in ipairs(excludeIds) do
    excludeIds[tostring(id)] = true
    excludeIds[index] = nil
end

Stairs = {}

Stairs.saveStatus = {}

Stairs.checkTile = function(tile)
    if not tile then
        return false
    end

    local tilePos = tile:getPosition()

    if not tilePos then
        return
    end

    local onString = Stairs.postostring(tilePos)

    local checkStatus = Stairs.saveStatus[onString]

    local itemsOnTile = tile:getItems()

    if checkStatus and ((type(checkStatus[1]) == "number" and #itemsOnTile == checkStatus[1]) or checkStatus[1] == true) then
        return checkStatus[2]
    end

    local topThing = tile:getTopUseThing()

    if not topThing then
        return false
    end

    for _, x in ipairs(itemsOnTile) do
        if excludeIds[tostring(x:getId())] then
            Stairs.saveStatus[onString] = {#itemsOnTile, false}
            return false
        end
    end

    if stairsIds[tostring(topThing:getId())] then
        Stairs.saveStatus[onString] = {true, true}
        return true
    end

    local cor = g_map.getMinimapColor(tile:getPosition())
    if cor >= 210 and cor <= 213 and not tile:isPathable() and tile:isWalkable() then
        Stairs.saveStatus[onString] = {true, true}
        return true
    else
        Stairs.saveStatus[onString] = {#itemsOnTile, false}
        return false
    end
end

Stairs.postostring = function(pos)
    return pos.x .. "," .. pos.y .. "," .. pos.z
end

function Stairs.accurateDistance(p1, p2)
    if type(p1) == "userdata" then
        p1 = p1:getPosition()
    end
    if type(p2) ~= "table" then
        p2 = pos()
    end
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

Stairs.getPosition = function(pos, dir)
    if dir == 0 then
        pos.y = pos.y - 1
    elseif dir == 1 then
        pos.x = pos.x + 1
    elseif dir == 2 then
        pos.y = pos.y + 1
    else
        pos.x = pos.x - 1
    end

    return pos
end

function table.reverse(t)
  local newTable = {}
  local j = 0
  for i = #t, 1, -1 do
    j = j + 1
    newTable[j] = t[i]
  end
  return newTable
end

function reverseDirection(dir)
  if dir == 0 then
    return 2
  elseif dir == 1 then
    return 3
  elseif dir == 2 then
    return 0
  elseif dir == 3 then
    return 1
  end
end

Stairs.goUse = function(pos)
    local playerPos = player:getPosition()
    local path = findPath(pos, playerPos)
    if not path then
        return
    end
  path = table.reverse(path)
    for i, v in ipairs(path) do
        if i > 5 then
            break
        end
        playerPos = Stairs.getPosition(playerPos, reverseDirection(v))
    end
    local tile = g_map.getTile(playerPos)
    local topThing = tile and tile:getTopUseThing()
    if topThing then
    g_game.use(topThing)
    if table.equals(tile:getPosition(), pos) then
      return delay(300)
    end
  end
end

Stairs.checkAll = function(n)
    n = n and n + 1 or 1
    if n > 9 then
        return
    end
    local pos = pos()
    local tiles = {}
    for x = -n, n do
        for y = -n, n do
            local stairPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
            local tile = g_map.getTile(stairPos)
            if Stairs.checkTile(tile) and findPath(stairPos, pos) then
                table.insert(tiles, {tile = tile, distance = Stairs.accurateDistance(pos, stairPos)})
            end
        end
    end
    if #tiles == 0 then
        return Stairs.checkAll(n)
    end
    table.sort(
        tiles,
        function(a, b)
            return a.distance < b.distance
        end
    )
    return tiles[1].tile
end

stand = now
onPlayerPositionChange(
    function(newPos, oldPos)
        stand = now
        tryWalk = nil
        if newPos.z ~= oldPos.z or getDistanceBetween(oldPos, newPos) > 1 or table.equals(Stairs.pos, newPos) then
            Stairs.walk.setOff()
        end
        if Stairs.walk.isOff() then
            checked = nil
        end
    end
)

timeInPos = function()
    return now - stand
end

onAddThing(
    function(tile, thing)
        if type(Stairs.pos) == "table" then
            if table.equals(tile:getPosition(), Stairs.pos) then
                Stairs.bestTile = tile
            end
        end
    end
)

markOnThing = function(thing, color)
    if thing then
        if thing:getPosition() then
            local useThing = thing:getTopUseThing()
            if color == "#00FF00" then
                thing:setText("AQUI", "green")
            elseif color == "#FF0000" then
                thing:setText("AQUI", "red")
            else
                thing:setText("")
            end
            return true
        end
    end
    return false
end

Stairs.walk = macro(1, function()
        if modules.corelib.g_keyboard.isKeyPressed("Escape") then
            return Stairs.walk.setOff()
        end
        player:lockWalk(300)
        if tryWalk then
            return
        end
        markOnThing(Stairs.bestTile, "#00FF00")
        if Stairs.bestTile:isWalkable() then
            if not Stairs.bestTile:isPathable() then
                if autoWalk(Stairs.pos, 1) then
                    tryWalk = true
                    return
                end
            end
        end
        return Stairs.goUse(Stairs.pos)
    end)

Stairs.walk.setOff()

macro(1,"Auto-Escadas", function()
        if Stairs.walk.isOn() then
            return
        end
        local pos = Stairs.postostring(pos())
        if pos ~= Stairs.lastPos then
            markOnThing(Stairs.bestTile, "")
            Stairs.bestTile = Stairs.checkAll()
            Stairs.pos = Stairs.bestTile and Stairs.bestTile:getPosition()
            markOnThing(Stairs.bestTile, "#FF0000")
            Stairs.lastPos = pos
        end
        if
            modules.corelib.g_keyboard.isKeyPressed("Space") and Stairs.bestTile and
                not modules.game_console:isChatEnabled()
         then
            Stairs.walk.setOn()
            return
        else
            return markOnThing(Stairs.bestTile, "#FF0000")
        end
    end)

function checkPos(x, y)
    local xyz = g_game.getLocalPlayer():getPosition()
    xyz.x = xyz.x + x
    xyz.y = xyz.y + y
    local tile = g_map.getTile(xyz)
    return tile and g_game.use(tile:getTopUseThing())
end

function getClosest(table)
    local closest
    if type(table) ~= "table" then
        return
    end
    for v, x in pairs(table) do
        if not closest or Stairs.accurateDistance(closest) > Stairs.accurateDistance(x:getPosition()) then
            closest = x
        end
    end
    return closest and Stairs.accurateDistance(closest) or false
end

function hasNonWalkable(direc)
    local tabela = {}
    for i = 1, #direc do
        local tile =
            g_map.getTile(
            {
                x = player:getPosition().x + direc[i][1],
                y = player:getPosition().y + direc[i][2],
                z = player:getPosition().z
            }
        )
        if tile and not tile:isWalkable(false) and tile:canShoot() then
            table.insert(tabela, tile)
        end
    end
    return tabela
end

function getClosestBetween(x, y)
    if not x and not y then
        return false
    end
    if x and not y then
        return 1
    elseif y and not x then
        return 2
    end
    if x < y then
        return 1
    else
        return 2
    end
end

function getDash(dir)
    if not dir then
        return false
    end
    local dirs = {}
    local tiles = {}
    local dirs = {}
    if dir == "n" then
        dirs = {{0, -1}, {0, -2}, {0, -3}, {0, -4}, {0, -5}, {0, -6}, {0, -7}, {0, -8}}
    elseif dir == "s" then
        dirs = {{0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}, {0, 7}, {0, 8}}
    elseif dir == "w" then
        dirs = {{-1, 0}, {-2, 0}, {-3, 0}, {-4, 0}, {-5, 0}, {-6, 0}}
    elseif dir == "e" then
        dirs = {{1, 0}, {2, 0}, {3, 0}, {4, 0}, {5, 0}, {6, 0}}
    end
    for i = 1, #dirs do
        local tile =
            g_map.getTile(
            {
                x = player:getPosition().x + dirs[i][1],
                y = player:getPosition().y + dirs[i][2],
                z = player:getPosition().z
            }
        )
        if tile and Stairs.checkTile(tile) and tile:canShoot() then
            table.insert(tiles, tile)
        end
    end
    if not tiles[1] or getClosestBetween(getClosest(hasNonWalkable(dirs)), getClosest(tiles)) == 1 then
        return false
    else
        return true
    end
end
-- Click Rift (Super Otimizado com Cooldown e Redução de Varredura)
macro(1000, "Click Rift", function()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local myPos = player:getPosition()
  if not myPos then return end

  local targetId = 11843
  local raio = 7 -- Vasculha apenas a área útil da tela visível ao redor do jogador

  -- Loops numéricos puros focados na coordenada do personagem
  for x = -raio, raio do
    for y = -raio, raio do
      local tilePos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
      local tile = g_map.getTile(tilePos)
      
      if tile then
        local items = tile:getItems()
        for i = 1, #items do
          local item = items[i]
          
          if item and item:getId() == targetId then
            g_game.use(item)
            
            if CaveBot and type(CaveBot.gotoLabel) == "function" then
              CaveBot.gotoLabel("Rift")
            end
            
            -- TRAVA CRÍTICA DE COOLDOWN: Força a macro a dormir por 2 segundos 
            -- para evitar loops repetitivos e spam de pacotes no mesmo frame
            delay(2000) 
            return
          end
        end
      end
    end
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
  -- Se já estiver atacando qualquer criatura, o macro apenas pausa para não interromper o combate
  if g_game.isAttacking() then
    return 
  end
  local closestTrainer = nil
  local shortestDistance = 3 -- Filtro de raio máximo de 2 SQMs (raio menor que 3)
  -- Varre os arredores para encontrar o Trainer mais próximo colado em você
  for _, creature in ipairs(getSpectators()) do
    if creature:getName():lower() == "house trainer" then
      local trainerPos = creature:getPosition()
      if trainerPos then
        local distance = math.max(math.abs(myPos.x - trainerPos.x), math.abs(myPos.y - trainerPos.y))
        -- Garante o ataque apenas se o Trainer estiver a no máximo 2 blocos de distância
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
                
                if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                if TargetBot and TargetBot.setOn then TargetBot.setOn() end   
                
                botsDesligadosPeloPVP = false
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
storage.foodItem2 = storage.foodItem2 or 0

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
macro(1000, function()
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

-- Tabela interna para controlar o tempo de reuso (10 segundos individual por slot)
local boostCooldowns = {0, 0, 0}

-- Execução da Macro rodando a cada 100ms para precisão de clique
macro(100, function()
    -- Não faz nada se estiver desativado ou se o personagem estiver em PZ
    if not config.enabled or isInPz() then return end

    local currentTime = now
    local boostIds = {storage.boostId1, storage.boostId2, storage.boostId3}

    -- Percorre a lista de IDs configurados na ordem exata (Slot 1 -> Slot 2 -> Slot 3)
    for index, id in ipairs(boostIds) do
        -- Apenas processa se o slot tiver um ID válido maior que 0
        if id and id > 0 then
            -- Verifica se já se passaram 10000ms (10 segundos) desde o último uso DESTE slot específico
            if currentTime - boostCooldowns[index] >= 10000 then
                
                -- BUSCA EXCLUSIVA EM CONTAINERS: Vasculha todas as backpacks abertas na tela
                local itemFound = nil
                local containers = g_game.getContainers()
                
                for _, container in pairs(containers) do
                    for _, item in ipairs(container:getItems()) do
                        if item:getId() == id then
                            itemFound = item
                            break
                        end
                    end
                    if itemFound then break end
                end

                -- Se encontrou o item dentro de alguma backpack aberta, dá Use nele
                if itemFound then
                    g_game.use(itemFound)
                    boostCooldowns[index] = currentTime -- Atualiza o tempo do cooldown com o milissegundo atual
                    break -- Interrompe o loop atual. O próximo item da ordem só será processado nos próximos ciclos de 100ms
                end
            end
        end
    end
end)
UI.Separator()
UI.Button("Screen: +  Zoom", function() zoomIn() end)
UI.Button("Screen: -  Zoom", function() zoomOut() end)
UI.Label("-----------------------------------"):setColor('#C39BD3')

setDefaultTab("Fight")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Smart Cast ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- Smart Cast
local distance = 2
local amountOfMonsters = 2

local indexArea, indexSingle = 1, 1

-- Tabelas em cache (Evita criar tabelas a cada 100ms)
local cacheAreaSpells = {}
local cacheSingleSpells = {}

-- Função interna para atualizar o cache de magias apenas quando o texto mudar
local function atualizarCacheSpells()
    cacheAreaSpells = {}
    if storage.areaspell01 and storage.areaspell01 ~= "" then table.insert(cacheAreaSpells, storage.areaspell01) end
    if storage.areaspell02 and storage.areaspell02 ~= "" then table.insert(cacheAreaSpells, storage.areaspell02) end

    cacheSingleSpells = {}
    if storage.spell01 and storage.spell01 ~= "" then table.insert(cacheSingleSpells, storage.spell01) end
    if storage.spell02 and storage.spell02 ~= "" then table.insert(cacheSingleSpells, storage.spell02) end
    if storage.spell03 and storage.spell03 ~= "" then table.insert(cacheSingleSpells, storage.spell03) end
end

combo = macro(100, "Smart Cast", function()
    if not g_game.isOnline() or not g_game.isAttacking() then return end     
    
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local atacandoPlayer = target:isPlayer()
    local specAmount = 0  
    
    -- Conta monstros ao redor apenas se o alvo não for Player
    if not atacandoPlayer then
        local minhaPos = pos()
        for _, mob in ipairs(getSpectators()) do
            if mob:isMonster() and getDistanceBetween(minhaPos, mob:getPosition()) <= distance then
                specAmount = specAmount + 1
                -- Otimização: Se já atingiu a quantidade necessária, não precisa continuar contando os outros
                if specAmount >= amountOfMonsters then break end
            end
        end
    end
    
    -- Condição 1: Solta área (2 ou mais monstros e alvo não é Player)
    if specAmount >= amountOfMonsters and not atacandoPlayer then
        local totalArea = #cacheAreaSpells
        if totalArea > 0 then
            if indexArea > totalArea then indexArea = 1 end
            say(cacheAreaSpells[indexArea])
            indexArea = indexArea + 1
        end
    -- Condição 2: Solta Single
    else
        local totalSingle = #cacheSingleSpells
        if totalSingle > 0 then
            if indexSingle > totalSingle then indexSingle = 1 end
            say(cacheSingleSpells[indexSingle])
            indexSingle = indexSingle + 1
        end
    end
end)

-- Interface Gráfica (UI) com gatilho de atualização de cache
UI.Separator()
UI.Label("Area Spells (2+ Mobs)"):setColor('#FFEA99')
UI.Separator()
UI.TextEdit(storage.areaspell01 or "", function(widget, text) storage.areaspell01 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.areaspell02 or "", function(widget, text) storage.areaspell02 = text; atualizarCacheSpells() end)
UI.Separator()
UI.Label("Single Spells"):setColor('#FFEA99')
UI.Separator()
UI.TextEdit(storage.spell01 or "", function(widget, text) storage.spell01 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.spell02 or "", function(widget, text) storage.spell02 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.spell03 or "", function(widget, text) storage.spell03 = text; atualizarCacheSpells() end)

-- Executa uma vez ao iniciar o script para carregar as magias já salvas
atualizarCacheSpells()
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Others ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- [INICIALIZAÇÃO] CONFIGURAÇÃO DE MEMÓRIA DO PAINEL FIGHT
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.special == nil then storage.painelSalvo.special = false end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end

-- SPELL AT TARGET HP (Apenas em Players)
local panelName = "hpbelowconfig"
-- Garante que as tabelas de armazenamento existam com segurança
if storage[panelName] == nil then storage[panelName] = { hp = 80 } end
if storage.painelSalvo == nil then storage.painelSalvo = { special = false } end
-- Cache da magia para evitar leitura de disco/storage a cada 100ms
local cacheHpSpell = storage.hpspell or ""
-- [PADRÃO SMART CAST]: Registro nativo. Cria o botão verde automático sincronizado com o painel
lowhp = macro(100, "Spell at Target HP", function()
    -- Checagens rápidas de segurança
    if not g_game.isOnline() or not g_game.isAttacking() then return end  
    local target = g_game.getAttackingCreature()
    if not target or not target:isPlayer() then return end
    
    -- Executa se a vida do alvo for menor ou igual e o cache da magia não estiver vazio
    if target:getHealthPercent() <= storage[panelName].hp and cacheHpSpell ~= "" then
        say(cacheHpSpell)
    end
end)
-- Interface Gráfica (UI) - Contém APENAS a barra de rolagem (Sem o botão duplicado)
local uiHP = setupUI([[
Panel
  height: 20
  HorizontalScrollBar
    id: HP
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.left: parent.left
    margin-top: 0
    minimum: 1
    maximum: 100
    step: 1
]], parent)

uiHP:setId(panelName)

local updateHpText = function()
    uiHP.HP:setText("HP: < " .. storage[panelName].hp .. "%")
end

uiHP.HP.onValueChange = function(scroll, value)
    storage[panelName].hp = value
    updateHpText()
end

uiHP.HP:setValue(storage[panelName].hp)
updateHpText()

-- Atualiza o cache imediatamente quando você digita a magia
UI.TextEdit(storage.hpspell or "", function(widget, text) 
    storage.hpspell = text 
    cacheHpSpell = text
end)

UI.Separator()

-- [SINCRONIZADOR NATÍVO]: Mantém a macro e o seu Painel de Botões central 100% em sincronia
macro(200, function()
    if not g_game.isOnline() then return end
    storage.painelSalvo.special = lowhp.isOn()
end)

UI.Separator()

-- SPELL AT SELF HP
local panelName = "selfhpbelowconfig"

-- Garante que as tabelas de armazenamento existam com segurança
if storage[panelName] == nil then storage[panelName] = { hp = 80 } end
if storage.painelSalvo == nil then storage.painelSalvo = { selfSpecial = false } end

-- Cache da magia na memória RAM para evitar leituras repetidas de storage a cada 100ms
local cacheSelfHpSpell = storage.selfhpspell or ""

-- [PADRÃO SMART CAST]: Registro nativo. Cria o botão verde automático sincronizado com o painel
selflowhp = macro(100, "Spell at Self HP", function()
    if not g_game.isOnline() then return end  
    
    -- Executa apenas se o seu HP estiver abaixo do limite e você tiver uma magia configurada
    if hppercent() <= storage[panelName].hp and cacheSelfHpSpell ~= "" then
        say(cacheSelfHpSpell)
    end
end)

-- Interface Gráfica (UI) - Contém APENAS a barra de rolagem (Sem o botão duplicado)
local uiSelfHP = setupUI([[
Panel
  height: 20
  HorizontalScrollBar
    id: HP
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.left: parent.left
    margin-top: 0
    minimum: 1
    maximum: 100
    step: 1
]], parent)

uiSelfHP:setId(panelName)

local updateHpText = function()
    uiSelfHP.HP:setText("HP: < " .. storage[panelName].hp .. "%")
end

uiSelfHP.HP.onValueChange = function(scroll, value)
    storage[panelName].hp = value
    updateHpText()
end

uiSelfHP.HP:setValue(storage[panelName].hp)
updateHpText()

-- Atualiza o cache de texto na memória instantaneamente ao digitar
UI.TextEdit(storage.selfhpspell or "", function(widget, text) 
    storage.selfhpspell = text 
    cacheSelfHpSpell = text
end)

UI.Separator()

-- [SINCRONIZADOR NATÍVO]: Mantém a macro e o seu Painel de Botões central 100% em sincronia
macro(200, function()
    if not g_game.isOnline() then return end
    storage.painelSalvo.selfSpecial = selflowhp.isOn()
end)

-- SPELL WAVE (Gira e Conjura na Reta)
-- Garante que as tabelas de armazenamento existam para o painel de botões ler
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end

-- Cache local da magia para poupar processamento
local cacheTurnSpell = storage.turnSpell or ""

-- [PADRÃO SMART CAST]: Registro nativo. Cria o botão automático e vincula ao Painel
turnCombo = macro(100, "Auto Wave", function()
    if not g_game.isOnline() then return end
    
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local targetPos = target:getPosition()
    local myPos = pos()
    if not targetPos or not myPos then return end
    
    local diffX = targetPos.x - myPos.x
    local diffY = targetPos.y - myPos.y
    
    -- Calcula a direção correta teórica baseado na posição do alvo
    local direcaoDesejada = 0
    if math.abs(diffX) >= math.abs(diffY) then
        direcaoDesejada = (diffX > 0) and 1 or 3 -- 1: Direita, 3: Esquerda
    else
        direcaoDesejada = (diffY > 0) and 2 or 0 -- 2: Baixo, 0: Cima
    end   
    
    -- Só envia o pacote de virar se você já não estiver na direção certa
    if g_game.getLocalPlayer():getDirection() ~= direcaoDesejada then
        g_game.turn(direcaoDesejada)
        delay(50)
    end
    
    -- Solta a magia de Wave se configurada
    if cacheTurnSpell ~= "" then
        say(cacheTurnSpell)
    end
end)

-- Adiciona apenas a caixa de texto para configurar a magia na aba lateral
addTextEdit("spellTurnConfig", storage.turnSpell or "", function(widget, text)
    local textoLimpo = text:trim()
    storage.turnSpell = textoLimpo
    cacheTurnSpell = textoLimpo
end)

-- [SINCRONIZADOR NATÍVO]: Garante que o estado da macro alimente a variável que seu Painel lê
macro(200, function()
    if not g_game.isOnline() then return end
    storage.painelSalvo.wave = turnCombo.isOn()
end)

UI.Label("-----------------------------------"):setColor('#C39BD3')
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.special == nil then storage.painelSalvo.special = false end
if storage.painelSalvo.selfSpecial == nil then storage.painelSalvo.selfSpecial = false end
if storage.painelSalvo.spells == nil then storage.painelSalvo.spells = false end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end
if storage.painelSalvo.horizontal == nil then storage.painelSalvo.horizontal = false end

local painelIconesUI = nil

-- LAYOUT MODO VERTICAL (Compactado e Enxuto)
local layoutVertical = [[
MainWindow
  id: painelMacrosJanela
  !text: tr('Spell Caster')
  size: 92 180
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
      size: 78 24
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-left: 1

    Button
      id: botaoSpecial
      !text: tr('Target HP')
      size: 78 24
      anchors.top: botaoSpells.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
      margin-left: 1

    Button
      id: botaoSelfSpecial
      !text: tr('Self HP')
      size: 78 24
      anchors.top: botaoSpecial.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
      margin-left: 1

    Button
      id: botaoWave
      !text: tr('Wave (Reta)')
      size: 78 24
      anchors.top: botaoSelfSpecial.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
      margin-left: 1

    Button
      id: botaoGirar
      !text: tr('Girar')
      size: 78 18
      anchors.top: botaoWave.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 10
      margin-left: 1
]]

-- LAYOUT MODO HORIZONTAL (Calibrado: Janela em 410px e Botões em 80px)
local layoutHorizontal = [[
MainWindow
  id: painelMacrosJanela
  !text: tr('Spell Caster')
  size: 410 75
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
      size: 80 24
      anchors.top: parent.top
      anchors.left: parent.left
      margin-top: 0
      margin-left: 2

    Button
      id: botaoSpecial
      !text: tr('Target HP')
      size: 80 24
      anchors.top: parent.top
      anchors.left: botaoSpells.right
      margin-top: 0
      margin-left: 4

    Button
      id: botaoSelfSpecial
      !text: tr('Self HP')
      size: 80 24
      anchors.top: parent.top
      anchors.left: botaoSpecial.right
      margin-top: 0
      margin-left: 4

    Button
      id: botaoWave
      !text: tr('Wave (Reta)')
      size: 80 24
      anchors.top: parent.top
      anchors.left: botaoSelfSpecial.right
      margin-top: 0
      margin-left: 4

    Button
      id: botaoGirar
      !text: tr('Girar')
      size: 44 24
      anchors.top: parent.top
      anchors.left: botaoWave.right
      margin-top: 0
      margin-left: 4
]]

-- Função de vinculação nativa de cliques e cores
local function conectarComponentesPainel()
    if not painelIconesUI then return end
    
    painelIconesUI.onMousePress = function(widget, mousePos, button) return true end
    painelIconesUI.onMouseRelease = function(widget, mousePos, button) return true end
    
    local container = painelIconesUI:getChildById("containerIcones")
    if not container then return end
    
    local btnSpecial = container:getChildById("botaoSpecial")
    local btnSelfSpecial = container:getChildById("botaoSelfSpecial")
    local btnSpells = container:getChildById("botaoSpells")
    local btnWave = container:getChildById("botaoWave")
    local btnGirar = container:getChildById("botaoGirar")
    
    -- Vincula os cliques chamando as funções globais com segurança
    if btnSpecial then btnSpecial.onClick = function() alternarEstadoMacro(lowhp, "special") end end
    if btnSelfSpecial then btnSelfSpecial.onClick = function() alternarEstadoMacro(selflowhp, "selfSpecial") end end
    if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
    if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end
    
    if btnGirar then
        btnGirar.onClick = function()
            storage.painelSalvo.horizontal = not storage.painelSalvo.horizontal
            painelIconesUI:destroy()
            local layout = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
            painelIconesUI = setupUI(layout, modules.game_interface.getMapPanel())
            conectarComponentesPainel()
        end
    end
end

-- Inicialização com base no estado salvo do personagem
local layoutInicial = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
painelIconesUI = setupUI(layoutInicial, modules.game_interface.getMapPanel())

-- CONTROLADORES NATIVOS DAS MACROS
local function isMacroActive(macroRef)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        return macroRef.isOn()
    end
    return false
end

function alternarEstadoMacro(macroRef, storageKey)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        if macroRef.isOn() then
            macroRef.setOff()
            storage.painelSalvo[storageKey] = false
        else
            macroRef.setOn()
            storage.painelSalvo[storageKey] = true
        end
    -- [CORREÇÃO] Se a macro ainda não foi carregada na memória, altera apenas o estado salvo para o outro script ler
    else
        storage.painelSalvo[storageKey] = not storage.painelSalvo[storageKey]
    end
end

-- Inicializa as conexões
conectarComponentesPainel()

-- Loop otimizado para sincronia de cores e estados
local jaSincronizou = false
macro(100, function()
    if not g_game.isOnline() or not painelIconesUI then return end
    
    local container = painelIconesUI:getChildById("containerIcones")
    if not container then return end
    
    -- Sincronização inicial executada de forma segura
    if not jaSincronizou then
        if lowhp and type(lowhp) == "table" and type(lowhp.setOn) == "function" then 
            if storage.painelSalvo.special then lowhp.setOn() else lowhp.setOff() end 
        end
        if selflowhp and type(selflowhp) == "table" and type(selflowhp.setOn) == "function" then 
            if storage.painelSalvo.selfSpecial then selflowhp.setOn() else selflowhp.setOff() end 
        end
        if combo and type(combo) == "table" and type(combo.setOn) == "function" then 
            if storage.painelSalvo.spells then combo.setOn() else combo.setOff() end 
        end
        if turnCombo and type(turnCombo) == "table" and type(turnCombo.setOn) == "function" then 
            if storage.painelSalvo.wave then turnCombo.setOn() else turnCombo.setOff() end 
        end
        jaSincronizou = true
    end
    
    local btnSpecial = container:getChildById("botaoSpecial")
    local btnSelfSpecial = container:getChildById("botaoSelfSpecial")
    local btnSpells = container:getChildById("botaoSpells")
    local btnWave = container:getChildById("botaoWave")

    -- Atualiza as cores dinamicamente baseando-se no motor real de cada macro
    if btnSpecial then btnSpecial:setColor(isMacroActive(lowhp) and "green" or "red") end
    if btnSelfSpecial then btnSelfSpecial:setColor(isMacroActive(selflowhp) and "green" or "red") end
    if btnSpells then btnSpells:setColor(isMacroActive(combo) and "green" or "red") end
    if btnWave then btnWave:setColor(isMacroActive(turnCombo) and "green" or "red") end
end)

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
macro(500, function()
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
  
  if storage[panelName].setting then
    if hppercent() <= storage[panelName].hp then
        local tempoAgora = os.time()
        -- Executa puramente com base no delay estático de 46 segundos
        if (tempoAgora - ultimoUsoBarreira) >= DELAY_SEGUNDOS then
            say(storage.autobarrier)
            ultimoUsoBarreira = tempoAgora
            
            print("[Barrier] Magia conjurada! Aguardando " .. DELAY_SEGUNDOS .. " segundos de recarga.")
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
    !text: tr('Health Potion')
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
		delay(500)
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
    !text: tr('Mana Potion')
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
		delay(500)
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
    !text: tr('Pet')
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
UI.Label("~ Haste & Buff ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
buffs = macro(100, "Haste", "CTRL+4", function()
    if isInPz() then 
        return 
    end
    if not hasHaste() then
        saySpell(storage.autobuff1)
        delay(40000)
    end
end) 
UI.TextEdit(storage.autobuff1 or "", function(widget, text)    
    storage.autobuff1 = text
end)
-- Buff
local function hasStrengthened()
    local rootWidget = g_ui.getRootWidget()
    if rootWidget then
        local buffIcon = rootWidget:recursiveGetChildById('condition_strengthened')
        if buffIcon and buffIcon:isVisible() then
            return true
        end
    end
    return false
end
macro(100, "Buff", "CTRL+4", function()
if isInPz() or not g_game.isAttacking() then return end
    if not hasStrengthened() then
        say(storage.buffskill01)
	    say(storage.buffskill02)
		delay(10000)
	end
end)
UI.TextEdit(storage.buffskill01 or "", function(widget, text)    
    storage.buffskill01 = text
end)
UI.TextEdit(storage.buffskill02 or "", function(widget, text)    
    storage.buffskill02 = text
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')

setDefaultTab("Extra")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Utility ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
--automsgtrade
macro(100, "Trade Channel", function()
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
UI.Separator()
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
    !text: tr('Roll Urahara Card')

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
    text: Roll Scrolls

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

consoleModule = modules.game_console
dash = macro(1, 'Bug Map', ('CTRL+3'), function() 
 if modules.corelib.g_keyboard.isKeyPressed('w') and not consoleModule:isChatEnabled() then
  checkPos(0, -5)
 elseif modules.corelib.g_keyboard.isKeyPressed('e') and not consoleModule:isChatEnabled() then
  checkPos(3, -3)
 elseif modules.corelib.g_keyboard.isKeyPressed('d') and not consoleModule:isChatEnabled() then
  checkPos(5, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('c') and not consoleModule:isChatEnabled() then
  checkPos(3, 3)
 elseif modules.corelib.g_keyboard.isKeyPressed('s') and not consoleModule:isChatEnabled() then
  checkPos(0, 5)
 elseif modules.corelib.g_keyboard.isKeyPressed('z') and not consoleModule:isChatEnabled() then
  checkPos(-3, 3)
 elseif modules.corelib.g_keyboard.isKeyPressed('a') and not consoleModule:isChatEnabled() then
  checkPos(-5, 0)
 elseif modules.corelib.g_keyboard.isKeyPressed('q') and not consoleModule:isChatEnabled() then
  checkPos(-3, -3)
 end
end)
if dash and dash.setOff then dash.setOff() end
--Auto MWall na Frente do Alvo
local MW_ID = 10571
local ultimoUso = 0

mwall = macro(100, "MWall on Target", "ALT+1", function()
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
chaseatk = macro(100, "Hold Target", "ALT+2", function()
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

-- FUNÇÃO AUXILIAR PARA CONTROLAR O CAVEBOT E TARGETBOT NATIVOS
local function alternarBotsNativos(ligar)
    if ligar then
        -- MODIFICAÇÃO: Lógica para ligar o TargetBot automaticamente
        if TargetBot then
            if type(TargetBot.setOn) == "function" then TargetBot.setOn()
            elseif type(TargetBot.start) == "function" then TargetBot.start()
            elseif TargetBot.macro and type(TargetBot.macro.setOn) == "function" then TargetBot.macro.setOn()
            end
        end
    else
        -- Desliga o CaveBot
        if CaveBot then
            if type(CaveBot.setOff) == "function" then CaveBot.setOff()
            elseif type(CaveBot.stop) == "function" then CaveBot.stop()
            elseif CaveBot.macro and type(CaveBot.macro.setOff) == "function" then CaveBot.macro.setOff()
            end
        end
        
        -- Desliga o TargetBot
        if TargetBot then
            if type(TargetBot.setOff) == "function" then TargetBot.setOff()
            elseif type(TargetBot.stop) == "function" then TargetBot.stop()
            elseif TargetBot.macro and type(TargetBot.macro.setOff) == "function" then TargetBot.macro.setOff()
            end
        end
    end
end

local estadoAnteriorMacro = false
enemy = macro(30, 'Enemy', "ALT+3", function()
    if not estadoAnteriorMacro then
        alternarBotsNativos(false) -- Desliga os bots ao ativar o Enemy
        definirModoAtaque("balanced")
        estadoAnteriorMacro = true
        print("[Enemy] TargetBot Desligado.")
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
            local specShield = creature:getShield()
            
            if (specSkull == 1 or specSkull == 4) then
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

-- Macro secundária que monitora o desligamento do Enemy
macro(30, function()
    if enemy and not enemy.isOn() and estadoAnteriorMacro then
        -- MODIFICAÇÃO: Executa ações imediatas assim que a macro desliga
        alternarBotsNativos(true) -- Religa o TargetBot automaticamente
        definirModoAtaque("offensive")
        estadoAnteriorMacro = false
        print("[Enemy] TargetBot Ativado.")
    end
end)


--X-Sense
if type(storage.Sense) ~= "string" then
    storage.Sense = ""
end
xsense = macro(30, "xSense", "ALT+4", function()
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
      pvehud.mwallinfo:setText("~ MWall on Target: [Alt+1]")
      pvehud.mwallinfo:setColor("#33ff99")
    else
      pvehud.mwallinfo:setText("~ MWall on Target: [Alt+1]")
      pvehud.mwallinfo:setColor("#ff6666")
    end
  end

  if pvehud.chaseatk then
    if chaseatk.isOn() then
      pvehud.chaseatk:setText("~ Hold Attack: [Alt+2]")
      pvehud.chaseatk:setColor("#33ff99")
    else
      pvehud.chaseatk:setText("~ Hold Attack: [Alt+2]")
      pvehud.chaseatk:setColor("#ff6666")
    end
  end

  if pvehud.enemy then
    if enemy.isOn() then
      pvehud.enemy:setText("~ Enemy: [Alt+3]")
      pvehud.enemy:setColor("#33ff99")
    else
      pvehud.enemy:setText("~ Enemy: [Alt+3]")
      pvehud.enemy:setColor("#ff6666")
    end
  end

  if pvehud.xsense then
    if xsense.isOn() then
      pvehud.xsense:setText("~ Auto xSense: [Alt+4]")
      pvehud.xsense:setColor("#33ff99")
    else
      pvehud.xsense:setText("~ Auto xSense: [Alt+4]")
      pvehud.xsense:setColor("#ff6666")
    end
  end

  if pvehud.tab3 then pvehud.tab3:setText("           ~         [Skills]        ~         ") end
  if pvehud.skills1 then pvehud.skills1:setText("~ Level: " .. player:getLevel() .. " - (" .. player:getLevelPercent() .. "%)") end
  if pvehud.skills3 then pvehud.skills3:setText("~ Reiatsu: " .. player:getMagicLevel() .. " - (" .. player:getMagicLevelPercent() .. "%)") end
  if pvehud.skills8 then pvehud.skills8:setText("~ Weapon: " .. player:getSkillLevel(2) .. " - (" .. player:getSkillLevelPercent(2) .. "%)") end
end)

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
      print("[Loader] Bless automatica habilitada com sucesso.")
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
            print("[Loader] PvP ativado.")
        end
    else
        if ultimoEstadoSeguro ~= false then
            if g_game.setSafeFight then 
                pcall(function() g_game.setSafeFight(true) end) 
            end
            ultimoEstadoSeguro = false
            print("[Loader] PvP desativado.")
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

-- ANTI-KS SEGURO COM TRAVA DE LURE INTELIGENTE (FILTRO DE PROXIMIDADE)
local function isMonsterOfOtherPlayer(creature, myId, localPlayer)
    if not creature or not creature:isMonster() then return false end
    
    -- Captura com segurança o ID do alvo do monstro
    local mTargetId = 0
    if type(creature.getTargetId) == "function" then
        mTargetId = creature:getTargetId() or 0
    elseif creature.targetId then
        mTargetId = creature.targetId
    elseif type(creature.getTarget) == "function" then
        local tgt = creature:getTarget()
        if tgt then mTargetId = tgt:getId() end
    end

    -- CASO 1: O monstro está focando outro jogador explicitamente
    local hasOtherTarget = (mTargetId > 0 and mTargetId ~= myId)
    
    -- CASO 2: O monstro está perdendo vida (AoE de terceiros) e o alvo NÃO é você
    local isDamagedByOthers = (mTargetId ~= myId and creature:getHealthPercent() < 100)

    -- CASO 3: SENSOR DE PROXIMIDADE (Bicho com 100% de vida colado em outro player)
    local coladoEmOutroPlayer = false
    if not hasOtherTarget and not isDamagedByOthers and localPlayer then
        local cPos = creature:getPosition()
        local myPos = localPlayer:getPosition()
        
        if cPos and myPos then
            local specs = g_map.getSpectators(cPos, false)
            for i = 1, #specs do
                local spec = specs[i]
                if spec:isPlayer() and spec:getId() ~= myId and not spec:isPartyMember() then
                    local pPos = spec:getPosition()
                    if pPos and pPos.z == cPos.z then
                        local distX = math.abs(pPos.x - cPos.x)
                        local distY = math.abs(pPos.y - cPos.y)
                        
                        if distX <= 1 and distY <= 1 then
                            local meuDistX = math.abs(myPos.x - cPos.x)
                            local meuDistY = math.abs(myPos.y - cPos.y)
                            if meuDistX > 1 or meuDistY > 1 then
                                coladoEmOutroPlayer = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if hasOtherTarget or isDamagedByOthers or coladoEmOutroPlayer then
        local cName = creature:getName() or ""
        local cNameLower = cName:lower()
        if cNameLower:find("trainer") or cNameLower:find("guild boss") then
            return false
        end
        return true
    end
    return false
end

-- INTERCEPTADOR 1: SOME COM OS BICHOS ALHEIOS DA LISTA DO TARGET
if TargetBot and type(TargetBot.getCreatures) == "function" then
    local oldGetCreatures = TargetBot.getCreatures
    TargetBot.getCreatures = function(...)
        local list = oldGetCreatures(...)
        local localPlayer = g_game.getLocalPlayer()
        
        if not localPlayer or localPlayer:isPartyMember() then 
            return list 
        end
        
        local myId = localPlayer:getId()
        local playerTarget = g_game.getAttackingCreature()
        local filteredList = {}
        
        for i = 1, #list do
            local creature = list[i]
            local isTargetAlheio = isMonsterOfOtherPlayer(creature, myId, localPlayer)
            local isMeuTargetManual = (playerTarget and playerTarget:getId() == creature:getId())
            
            if not isTargetAlheio or isMeuTargetManual then
                table.insert(filteredList, creature)
            end
        end
        
        return filteredList
    end
end

-- INTERCEPTADOR 2: CONTROLADOR DE MOVIMENTO (SOMA APENAS OS SEUS MONSTROS)
if CaveBot and type(CaveBot.doWalking) == "function" then
    local oldDoWalking = CaveBot.doWalking
    CaveBot.doWalking = function(...)
        local localPlayer = g_game.getLocalPlayer()
        if localPlayer and not localPlayer:isPartyMember() then
            local myId = localPlayer:getId()
            local playerPos = localPlayer:getPosition()
            
            if playerPos then
                local totalMonstersBox = 0
                local spectators = g_map.getSpectators(playerPos, false)
                
                for i = 1, #spectators do
                    local spec = spectators[i]
                    if spec:isMonster() and spec:getHealthPercent() > 0 then
                        local mPos = spec:getPosition()
                        if mPos and mPos.z == playerPos.z then
                            -- CORREÇÃO DA VARIÁVEL AQUI (distToMeY corrigido)
                            local distToMeX = math.abs(playerPos.x - mPos.x)
                            local distToMeY = math.abs(playerPos.y - mPos.y)
                            
                            if distToMeX <= 4 and distToMeY <= 4 then
                                if not isMonsterOfOtherPlayer(spec, myId, localPlayer) then
                                    totalMonstersBox = totalMonstersBox + 1
                                end
                            end
                        end
                    end
                end
                
                if totalMonstersBox >= 5 then
                    if type(CaveBot.delay) == "function" then
                        CaveBot.delay(500)
                    end
                    return false 
                end
            end
        end
        return oldDoWalking(...)
    end
end

print("[Loader] Anti-KS habilitado com sucesso.")

-- CREATURE_PRIORITY
local specialMonsters = {"elite", "boss", "unleashed", "gotei 13 king", "oversaturated", "true bankai", "dungeon"}
local lastCheck = 0

-- Ao remover o 'local' da frente, a função vira global automaticamente no ambiente do bot
checkSpecialMonstersLure = function()
    local cNow = now or (os.clock() * 1000)
    if cNow - lastCheck < 100 then return end
    lastCheck = cNow

    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end

    local myId = localPlayer:getId()
    local playerPos = localPlayer:getPosition()
    if not playerPos then return end

    local specialAttackingMe = 0
    local spectators = g_map.getSpectators(playerPos, false)

    for _, spec in ipairs(spectators) do
        if spec:isMonster() and spec:getHealthPercent() > 0 then
            local creatureName = string.lower(spec:getName() or "")
            local isSpecial = false
            
            for _, name in ipairs(specialMonsters) do
                if string.find(creatureName, name, 1, true) then
                    isSpecial = true
                    break
                end
            end

            if isSpecial then
                local mTargetId = 0
                if type(spec.getTargetId) == "function" then
                    mTargetId = spec:getTargetId() or 0
                elseif spec.targetId then
                    mTargetId = spec.targetId
                elseif type(spec.getTarget) == "function" then
                    local tgt = spec:getTarget()
                    if tgt then mTargetId = tgt:getId() end
                end

                if mTargetId == myId then
                    specialAttackingMe = specialAttackingMe + 1
                end
            end
        end
    end

    if specialAttackingMe >= 2 then
        if cavebotMacro and type(cavebotMacro) == "table" then
            cavebotMacro.delay = cNow + 1000
        elseif CaveBot and type(CaveBot.macro) == "table" then
            CaveBot.macro.delay = cNow + 1000
        elseif CaveBot and type(CaveBot.delay) == "function" then
            CaveBot.delay(1000)
        end
    end
end

-- INTERCEPTADOR DO TARGETBOT COM PRIORIDADE CORRIGIDA (BOX EM 1º LUGAR)
if TargetBot and TargetBot.Creature then
    TargetBot.Creature.calculatePriority = function(creature, config, path)
      -- Executa a função global de segurança diretamente
      if type(checkSpecialMonstersLure) == "function" then
          checkSpecialMonstersLure()
      end

      local priority = 0
      local path_length = #path

      if g_game.getAttackingCreature() == creature then
        priority = priority + 1
      end

      local creatureName = string.lower(creature:getName() or "")
      local isSpecial = false
      
      for _, name in ipairs(specialMonsters) do
        if string.find(creatureName, name, 1, true) then
          isSpecial = true
          break
        end
      end

      if isSpecial then
        local localPlayer = g_game.getLocalPlayer()
        local myId = localPlayer and localPlayer:getId() or 0
        
        local mTargetId = 0
        if type(creature.getTargetId) == "function" then
            mTargetId = creature:getTargetId() or 0
        elseif creature.targetId then
            mTargetId = creature.targetId
        elseif type(creature.getTarget) == "function" then
            local tgt = creature:getTarget()
            if tgt then mTargetId = tgt:getId() end
        end

        local attackingOtherPlayer = (mTargetId > 0 and mTargetId ~= myId)
        if not attackingOtherPlayer then
          if path_length == 1 then
            priority = priority + 1000
          end
        end
      end

      if path_length > config.maxDistance then
        return priority
      end

      priority = priority + config.priority
      
      if path_length == 1 then
        priority = priority + 500
      elseif path_length <= 3 then
        priority = priority + 2
      end

      local hp = creature:getHealthPercent() or 100
      if hp < 20 then
        priority = priority + 5
      elseif hp < 40 then
        priority = priority + 2.5
      elseif hp < 60 then
        priority = priority + 1.5
      elseif hp < 80 then
        priority = priority + 0.5
      end

      return priority
    end
end

-- CONTROLADOR DE DELAY ENTRE WAYPOINTS (FAST WAYPOINT)
-- 1. Interceptador de loop para diminuir pausas longas entre os pontos
if CaveBot and type(CaveBot.delay) == "function" then
    if not CaveBot.oldDelay then
        CaveBot.oldDelay = CaveBot.delay
    end
    
    CaveBot.delay = function(ms, ...)
        -- Se o bot pedir uma pausa de transição entre waypoints,
        -- o script reduz esse tempo para apenas 20ms.
        if ms and ms <= 500 then
            ms = 100 
        end
        return CaveBot.oldDelay(ms, ...)
    end
end

-- ====================================================================
-- INJEÇÃO DE ALTA PERFORMANCE PARA TARGETBOT VIA LOADER.LUA (V2)
-- ====================================================================

-- 1. Alimentação da variável global 'now' com motor de tempo compatível
local function obterTempoReal()
    if os and type(os.milliSeconds) == "function" then return os.milliSeconds()
    elseif os and type(os.milliseconds) == "function" then return os.milliseconds()
    elseif g_clock and type(g_clock.realMillis) == "function" then return g_clock.realMillis()
    elseif g_clock and type(g_clock.millis) == "function" then return g_clock.millis()
    else return math.floor(os.clock() * 1000) end
end

macro(1, function()
    now = obterTempoReal()
end)

-- 2. Interceptador cirúrgico de criaturas (Remove o excesso ANTES da linha 50)
if TargetBot and type(TargetBot.getCreatures) == "function" then
    local oldGetCreatures = TargetBot.getCreatures
    TargetBot.getCreatures = function(...)
        local listaOriginal = oldGetCreatures(...)
        if not listaOriginal or #listaOriginal == 0 then return listaOriginal end

        local player = g_game.getLocalPlayer()
        if not player then return listaOriginal end
        
        local playerPos = player:getPosition()
        if not playerPos then return listaOriginal end

        local listaFiltrada = {}
        local totalAdicionados = 0
        local limiteMaximoMonstros = 4 -- Reduzimos o loop para calcular no máximo os 4 monstros mais perigosos/próximos

        for i = 1, #listaOriginal do
            local creature = listaOriginal[i]
            if creature and creature:isMonster() and creature:getHealthPercent() > 0 then
                local cPos = creature:getPosition()
                
                -- OTIMIZAÇÃO CRÍTICA: Ignora instantaneamente monstros em outros andares (Z diferente)
                if cPos and cPos.z == playerPos.z then
                    local distX = math.abs(playerPos.x - cPos.x)
                    local distY = math.abs(playerPos.y - cPos.y)
                    
                    -- Só aceita monstros dentro da área de combate real (até 4 quadrados de distância)
                    if distX <= 4 and distY <= 4 then
                        totalAdicionados = totalAdicionados + 1
                        listaFiltrada[totalAdicionados] = creature
                        
                        -- Se já atingiu o limite de monstros para processar neste frame, encerra a busca
                        if totalAdicionados >= limiteMaximoMonstros then
                            break
                        end
                    end
                end
            end
        end

        return listaFiltrada
    end
end

-- 3. Cache global para a função findPath nativa do bot
local ultimoCalculoPath = 0
local cachePaths = {}

if type(findPath) == "function" then
    local oldFindPath = findPath
    findPath = function(startPos, endPos, maxDist, params, ...)
        local atual = obterTempoReal()
        if atual - ultimoCalculoPath > 300 then
            cachePaths = {}
            ultimoCalculoPath = atual
        end

        if endPos then
            local hashChave = string.format("%d,%d,%d", endPos.x, endPos.y, endPos.z)
            if cachePaths[hashChave] ~= nil then
                return cachePaths[hashChave]
            end
            
            local rota = oldFindPath(startPos, endPos, maxDist, params, ...)
            cachePaths[hashChave] = rota or false
            return rota
        end
        return oldFindPath(startPos, endPos, maxDist, params, ...)
    end
end

print("[Loader] TargetBot otimizado com sucesso.")
