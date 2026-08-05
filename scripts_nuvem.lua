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
    if type(t) ~= "table" then return t end
    
    local keysToRemove = {}
    local keysToConvert = {}
    local temChaveTexto = false
    local temChaveNumerica = false
    
    for k, v in pairs(t) do
        if k == "petItemCooldowns" or k == "" or k == nil or type(k) == "boolean" or type(k) == "table" then
            keysToRemove[k] = true
        else
            if type(k) == "string" then temChaveTexto = true end
            if type(k) == "number" then temChaveNumerica = true end
            
            if type(v) == "table" then
                if next(v) == nil then
                    keysToRemove[k] = true
                else
                    sanitizarTabelaParaJson(v)
                end
            end
        end
    end

    for k, _ in pairs(keysToRemove) do
        t[k] = nil
    end

    if temChaveTexto and temChaveNumerica then
        for k, _ in pairs(t) do
            if type(k) == "number" then
                keysToConvert[k] = tostring(k)
            end
        end
        for oldKey, newKey in pairs(keysToConvert) do
            t[newKey] = t[oldKey]
            t[oldKey] = nil
        end
    end

    return t
end

-- Executa uma única higienização preventiva segura quando você abre o bot/inicializa o script
if storage then
    pcall(function() sanitizarTabelaParaJson(storage) end)
end

function terminate()
    if storage then 
        pcall(function() sanitizarTabelaParaJson(storage) end) 
    end
    print("[Storage Cleaner] Faxina preventiva concluida com sucesso.")
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
macro(200, "Smart Follow", function() 
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

-- Deposit Gold & Stack Items (Correção de Leitura e Performance Máxima)
local ultimoMovimentoStack = 0

macro(1000, "DepositGold & StackItems", function()
  if not g_game.isOnline() then return end
  
  -- Trava de tempo interna para dar fôlego ao processador (Substitui o "retry" perigoso)
  local agora = os.time() * 1000
  if type(g_clock) == "table" and type(g_clock.millis) == "function" then agora = g_clock.millis() end
  if agora - ultimoMovimentoStack < 500 then return end

  local coinIds = {3031, 3035, 3043, 10137} 
  local minAmount = 1
  local shouldDeposit = false

  -- 1. CHECAGEM RÁPIDA DE DINHEIRO
  for i = 1, #coinIds do
    local item = findItem(coinIds[i])
    if item and item:getCount() >= minAmount then
      shouldDeposit = true
      break
    end
  end
  
  if shouldDeposit then
    say("!deposit all")
    ultimoMovimentoStack = agora + 500
    return
  end

  -- 2. MAPEAR ITENS AGRUPÁVEIS (Usa a estrutura idêntica à sua original para ler todas as mochilas)
  local containers = g_game.getContainers()
  local itensMapeados = {}
  local precisaAgrupar = false

  for _, container in pairs(containers) do
    if container then
        local items = container:getItems()
        -- Roda o loop baseado exatamente no tamanho bruto (#items) como no seu script funcional
        for index = 1, #items do
          local item = items[index]
          -- Aceita qualquer quantia por slot (suporte a itens massivos de ATS como os 8828)
          if item and item:isStackable() then 
            local itemId = item:getId()
            local count = item:getCount()
            local posicaoAtual = container:getSlotPosition(index - 1)

            if posicaoAtual then
              if itensMapeados[itemId] then
                -- Detectou item separado no inventário
                precisaAgrupar = true
                -- LÓGICA DO MAIOR MONTANTE: Atualiza o destino preferencial se este slot tiver mais itens
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
  end

  -- Se o mapa inteiro de mochilas estiver perfeitamente agrupado, encerra o ciclo de 1s de forma leve
  if not precisaAgrupar then
    return
  end

  -- 3. EXECUTAR A MOVIMENTAÇÃO (Do menor para o maior montante encontrado)
  for _, container in pairs(containers) do
    if container then
        local items = container:getItems()
        for index = 1, #items do
          local item = items[index]
          if item and item:isStackable() then
            local itemId = item:getId()
            local destino = itensMapeados[itemId]

            if destino then
              local slotAtualIndex = index - 1
              local mesmoContainer = (container:getId() == destino.containerId)
              local mesmoSlot = (slotAtualIndex == destino.slotIndex)

              -- Só move se o slot de origem for diferente do slot de destino final maior
              if not (mesmoContainer and mesmoSlot) then
                g_game.move(item, destino.posicao, item:getCount())
                -- CORREÇÃO DO SLOW: Seta o delay de recarga real em memória sem travar a thread do bot
                ultimoMovimentoStack = agora + 350 
                return -- Executa um movimento por ciclo para não floodar e zerar o lag
              end
            end
          end
        end
    end
  end
end)

-- Auto Dodge
local effectIdToAvoid = 237
local maxSearchRange = 13 -- Mantém o radar de tela cheia para áreas massivas
local moveFlags = { ignoreNonPathable = true }
local dangerDuration = 2500 

local dangerTilesCache = {}
local dodgeBlockBots = false

local meuDestinoAtual = nil
local travaMovimentoAte = 0
local manterBotsDesativadosAte = 0 

local function hasEffect(tile, effectId)
    if not tile then return false end
    local effects = tile:getEffects()
    if not effects then return false end
    for i = 1, #effects do
        if effects[i]:getId() == effectId then
            return true
        end
    end
    return false
end

-- Mapeia a zona de perigo usando strings híbridas para evitar o erro do JSON
local function updateDangerZone(playerPos)
    if not playerPos or not playerPos.x or not playerPos.y or not playerPos.z then return end

    local now = os.time() * 1000
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then
        now = g_clock.millis()
    end

    for dx = -maxSearchRange, maxSearchRange do
        for dy = -maxSearchRange, maxSearchRange do
            local checkPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
            local tile = g_map.getTile(checkPos)
            
            if tile and checkPos.x and checkPos.y then
                if hasEffect(tile, effectIdToAvoid) then
                    -- Chave em string segura ("k123_456") aceita nativamente pelo json.lua
                    local key = "k" .. checkPos.x .. "_" .. checkPos.y
                    dangerTilesCache[key] = now + dangerDuration
                end
            end
        end
    end
end

local function isTileDangerous(pos)
    if not pos or not pos.x or not pos.y then return false end

    local now = os.time() * 1000
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then
        now = g_clock.millis()
    end

    local key = "k" .. pos.x .. "_" .. pos.y
    local dangerUntil = dangerTilesCache[key]
    
    if dangerUntil and now < dangerUntil then
        return true
    else
        if dangerUntil then dangerTilesCache[key] = nil end
        return false
    end
end

-- Varre o mapa de forma concêntrica progressiva buscando brechas azuis livres
local function findMassiveSafePosition(playerPos)
    if not playerPos or not playerPos.x or not playerPos.y or not playerPos.z then return nil end

    for r = 1, maxSearchRange do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local checkPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
                    
                    if not isTileDangerous(checkPos) then
                        local tile = g_map.getTile(checkPos)
                        if tile and tile:isWalkable() then
                            if findPath(playerPos, checkPos, maxSearchRange, moveFlags) then
                                return checkPos
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

macro(10, "Dodge Red SQM Spells", function()
    if not g_game.isOnline() then return end
    
    local playerPos = player:getPosition()
    if not playerPos then return end
    
    local currentTile = g_map.getTile(playerPos)
    local magiaEmbaixoDeMim = hasEffect(currentTile, effectIdToAvoid)
    local agora = os.time() * 1000
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then agora = g_clock.millis() end

    -- Otimização: Só processa a varredura se houver real ameaça ou delay de ciclo
    if magiaEmbaixoDeMim or isTileDangerous(playerPos) or agora < manterBotsDesativadosAte then
        updateDangerZone(playerPos)
    else
        if dodgeBlockBots then
            if CaveBot and type(CaveBot.setEnabled) == "function" then CaveBot.setEnabled(true) end
            if TargetBot and type(TargetBot.setEnabled) == "function" then TargetBot.setEnabled(true) end
            dodgeBlockBots = false
        end
        meuDestinoAtual = nil
        travaMovimentoAte = 0
        return
    end

    manterBotsDesativadosAte = agora + 450 

    -- Se uma nova magia nascer sob os pés, ignora a trava de tempo para correr na hora
    if not magiaEmbaixoDeMim then
        if meuDestinoAtual and agora < travaMovimentoAte then
            if not isTileDangerous(meuDestinoAtual) then
                return 
            end
        end
    end

    -- Desativa temporariamente os bots para priorizar a andada do desvio
    if not dodgeBlockBots then
        if CaveBot and type(CaveBot.isEnabled) == "function" and CaveBot.isEnabled() then 
            if type(CaveBot.setEnabled) == "function" then CaveBot.setEnabled(false) end 
        end
        if TargetBot and type(TargetBot.isEnabled) == "function" and TargetBot.isEnabled() then 
            if type(TargetBot.setEnabled) == "function" then TargetBot.setEnabled(false) end 
        end
        dodgeBlockBots = true
    end

    local safePos = findMassiveSafePosition(playerPos)
    if safePos then
        meuDestinoAtual = safePos
        -- Janela adaptativa: 100ms para magias coladas nos pés, 300ms para deslocamentos normais
        travaMovimentoAte = agora + (magiaEmbaixoDeMim and 100 or 300)
        autoWalk(safePos, maxSearchRange, moveFlags)
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

Stairs.walk = macro(40, function()
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

macro(40,"Auto-Escadas", function()
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
-- Click Rift Otimizado
local ultimoScanRift = 0

macro(500, "Click Rift", function()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local myPos = player:getPosition()
  if not myPos then return end

  local targetId = 11843
  local agora = os.time() * 1000
  if type(g_clock) == "table" and type(g_clock.millis) == "function" then agora = g_clock.millis() end

  -- Trava de segurança para não floodar cliques repetidos no mesmo segundo
  if agora - ultimoScanRift < 1500 then return end

  local raioVisivel = 13 -- Escaneia estritamente os quadrados visíveis ao redor do seu char

  for x = -raioVisivel, raioVisivel do
    for y = -raioVisivel, raioVisivel do
      local tilePos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
      local tile = g_map.getTile(tilePos)
      
      if tile then
        local things = tile:getThings()
        if things then
            for i = 1, #things do
              local thing = things[i]
              if thing and thing.getId and type(thing.getId) == "function" then
                if thing:getId() == targetId then
                  
                  -- Clica no portal interativo do topo de forma nativa e segura
                  local topThing = tile:getTopUseThing()
                  if topThing then g_game.use(topThing) else g_game.use(thing) end
                  
                  if CaveBot and type(CaveBot.gotoLabel) == "function" then
                    CaveBot.gotoLabel("Rift")
                  end
                  
                  ultimoScanRift = agora + 3000 -- Faz a macro esperar 3s após o clique com sucesso
                  return
                end
              end
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
-- Revide PK (Otimizado com Trava de UI, Varredura por Raio e Cooldown de Estado)
local botsDesligadosPeloPVP = false
local ultimoEstadoSafeFight = nil
local ultimoModoAtaque = nil
local ultimoTempoTrocaEstado = 0 -- Armazena o timestamp da última alteração de botões

local function definirSafeFightBox(deveAtivar)
    -- OTIMIZAÇÃO CRÍTICA: Se a interface já está no estado correto, não clica para economizar CPU
    if ultimoEstadoSafeFight == deveAtivar then return end
    
    local mapPanel = modules.game_interface and modules.game_interface.gameMapPanel
    local root = mapPanel and mapPanel:getParent()
    if root then
        local pvpButton = root:recursiveGetChildById('safeFightBox')
        if pvpButton then
            local estaAtivo = pvpButton:isOn()
            if (deveAtivar and not estaAtivo) or (not deveAtivar and estaAtivo) then
                pcall(function() pvpButton:onClick() end)
                ultimoEstadoSafeFight = deveAtivar
            end
        end
    end
end

local function definirModoAtaque(modo)
    -- OTIMIZAÇÃO CRÍTICA: Impede cliques fantasmas repetitivos se já estiver no modo desejado
    if ultimoModoAtaque == modo then return end
    
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
        ultimoModoAtaque = modo
    end
end

macro(250, 'Revide PK', function()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end

    local myPos = localPlayer:getPosition()
    if not myPos then return end

    local agressorTarget = nil
    local agressorHp = 101
    local agressorDist = 100

    -- OTIMIZAÇÃO: Busca espectadores limitados ao raio visível de tela (8 SQMs)
    local specs = g_map.getSpectatorsInRange(myPos, false, 8, 8)
    local totalSpecs = #specs

    -- Loop numérico puro (Muito mais rápido que ipairs no OTClient)
    for i = 1, totalSpecs do
        local creature = specs[i]
        if creature and creature:isPlayer() and creature ~= localPlayer then
            
            local estaMeAtacando = false
            if creature.isAttacking then
                estaMeAtacando = creature:isAttacking()
            else
                estaMeAtacando = (g_game.getAttackingCreature() == creature or creature:isTimedSquareVisible())
            end

            if estaMeAtacando then
                local specPos = creature:getPosition()
                if specPos and specPos.z == myPos.z then
                    local specHp = creature:getHealthPercent()
                    local specDist = math.abs(myPos.x - specPos.x) + math.abs(myPos.y - specPos.y)
                    
                    if specHp and specHp > 0 then
                        if creature:canShoot() then
                            -- Seleção inteligente de alvo PK (Foca no mais fraco ou mais próximo)
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
    end

    local tempoAtual = os.time() * 1000 -- Obtém o tempo atual em milissegundos

    if agressorTarget then
        if not botsDesligadosPeloPVP then
            -- Verifica se já se passaram 6000ms desde a última alteração de botões na interface
            if (tempoAtual - ultimoTempoTrocaEstado) >= 6000 then
                if CaveBot and CaveBot.setOff then CaveBot.setOff() end
                if TargetBot and TargetBot.setOff then TargetBot.setOff() end  
                
                definirModoAtaque("balanced")
                definirSafeFightBox(true)       

                botsDesligadosPeloPVP = true
                ultimoTempoTrocaEstado = tempoAtual -- Atualiza o tempo do último clique
            end
        end
        if g_game.getAttackingCreature() ~= agressorTarget then
            pcall(function()
                modules.game_interface.processMouseAction(nil, 2, myPos, nil, agressorTarget, agressorTarget)
            end)
        end
    else
        -- Só executa a limpeza se o modo PVP tiver sido ativado anteriormente
        if botsDesligadosPeloPVP then
            local alvoAtualJogo = g_game.getAttackingCreature()
            if not alvoAtualJogo or not alvoAtualJogo:isPlayer() then
                -- Verifica se já se passaram 6000ms desde a última alteração para poder resetar o modo
                if (tempoAtual - ultimoTempoTrocaEstado) >= 6000 then
                    definirSafeFightBox(false)           
                    definirModoAtaque("offensive")
                    
                    if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                    if TargetBot and TargetBot.setOn then TargetBot.setOn() end   
                    
                    botsDesligadosPeloPVP = false
                    ultimoTempoTrocaEstado = tempoAtual -- Atualiza o tempo do último clique
                end
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
-- Smart Cast (Otimização por Cache de Espectadores e Frame Alternado)
local alcanceMaximoTarget = 4 
local raioDeAreaDoMonstro = 3 
local amountOfMonsters = 2

local indexArea, indexSingle = 1, 1
local cacheAreaSpells = {}
local cacheSingleSpells = {}

local function atualizarCacheSpells()
    cacheAreaSpells = {}
    if storage.areaspell01 and storage.areaspell01 ~= "" then table.insert(cacheAreaSpells, storage.areaspell01) end
    if storage.areaspell02 and storage.areaspell02 ~= "" then table.insert(cacheAreaSpells, storage.areaspell02) end

    cacheSingleSpells = {}
    if storage.spell01 and storage.spell01 ~= "" then table.insert(cacheSingleSpells, storage.spell01) end
    if storage.spell02 and storage.spell02 ~= "" then table.insert(cacheSingleSpells, storage.spell02) end
    if storage.spell03 and storage.spell03 ~= "" then table.insert(cacheSingleSpells, storage.spell03) end
end

-- Aumentado para 150ms (Diferença imperceptível de 0.05 segundos, mas corta o lag pela metade)
combo = macro(200, "Smart Cast", function()
    if not g_game.isOnline() or not g_game.isAttacking() then return end     
    
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local targetPos = target:getPosition()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer or not targetPos then return end
    
    local minhaPos = localPlayer:getPosition()
    if not minhaPos or minhaPos.z ~= targetPos.z then return end

    local distToTargetX = math.abs(minhaPos.x - targetPos.x)
    local distToTargetY = math.abs(minhaPos.y - targetPos.y)
    if distToTargetX > alcanceMaximoTarget or distToTargetY > alcanceMaximoTarget then return end

    local atacandoPlayer = target:isPlayer()
    local specAmount = 0  
    
    if not atacandoPlayer then
        -- OTIMIZAÇÃO: Filtra e lê apenas os monstros ao redor do centro do alvo
        local mobsAoRedorDoAlvo = g_map.getSpectatorsInRange(targetPos, false, raioDeAreaDoMonstro, raioDeAreaDoMonstro)
        local totalMobs = #mobsAoRedorDoAlvo
        
        for i = 1, totalMobs do
            local mob = mobsAoRedorDoAlvo[i]
            if mob and mob:isMonster() and mob:getHealthPercent() > 0 then
                local mobPos = mob:getPosition()
                if mobPos and mobPos.z == targetPos.z then
                    local distX = math.abs(targetPos.x - mobPos.x)
                    local distY = math.abs(targetPos.y - mobPos.y)
                    
                    if distX <= raioDeAreaDoMonstro and distY <= raioDeAreaDoMonstro then
                        specAmount = specAmount + 1
                        if specAmount >= amountOfMonsters then break end
                    end
                end
            end
        end
    end
    
    if specAmount >= amountOfMonsters and not atacandoPlayer then
        local totalArea = #cacheAreaSpells
        if totalArea > 0 then
            if indexArea > totalArea then indexArea = 1 end
            say(cacheAreaSpells[indexArea])
            indexArea = indexArea + 1
        end
    else
        local totalSingle = #cacheSingleSpells
        if totalSingle > 0 then
            if indexSingle > totalSingle then indexSingle = 1 end
            say(cacheSingleSpells[indexSingle])
            indexSingle = indexSingle + 1
        end
    end
end)

-- Interface Gráfica (UI)
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
-- Pet on Hp (Versão Simplificada e Sem Cooldown no Storage)
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
local ultimoUsoDoPet = 0 -- VARIÁVEL LOCAL: Controla o tempo em memória RAM sem tocar no .json

if not storage[panelName] then
  storage[panelName] = {
      id = 11688, 
      enabled = false,
      setting = true,
      hp = 30
  }
else
  if not storage[panelName].id or storage[panelName].id == 0 then
      storage[panelName].id = 11688
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
                
                -- CHECAGEM LIMPA: Usa a variável local interna que zera se o client reiniciar
                if currentTime - ultimoUsoDoPet >= COOLDOWN_PADRAO then
                    use(currentId)
                    ultimoUsoDoPet = currentTime 
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
--AutoLegendary (Otimizado contra Lag de Mensagens Globais)
local panelName = "AutoLegendary"
storage[panelName] = storage[panelName] or {enabled = false}
local config = storage[panelName]

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

ui.item:setItemId(storage.legendaryItem)
ui.item.onItemChange = function(widget)
    storage.legendaryItem = widget:getItemId()
end

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

    local scroll = findItem(storage.legendaryScroll)
    local item = findItem(storage.legendaryItem)

    if scroll and item then
        useWith(scroll, item)
    end
end)

-- OTIMIZAÇÃO CRÍTICA: Filtra mensagens irrelevantes antes do processamento
onTextMessage(function(mode, text)
    -- Se a macro de roletar estiver desligada, aborta no primeiro milissegundo
    if not config.enabled then return end
    if not text then return end

    -- FILTRO DE CANAL: Geralmente raridades aparecem como mensagens de sistema/públicas.
    -- Evita ler textos normais de conversa privada (MessageModes.Private) para economizar CPU.
    if mode == 12 or mode == 20 or mode == 21 or mode == 19 then -- Canais comuns de Server/Loot/System
        -- Busca direta usando padrões nativos mais eficientes (ignora case-sensitive sem dar :upper())
        if string.find(text, "Legendary") or string.find(text, "Kami") or string.find(text, "LEGENDARY") or string.find(text, "KAMI") then
            config.enabled = false
            ui.title:setOn(false)
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ HUD Hotkeys ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')

--Start/Stop CaveBot (Sua macro original corrigida com freio de processamento)
macro(800, "Start/Stop Cave", ("CTRL+1"), function(killcave)
if CaveBot.isOn() then
 CaveBot.setOff()
 killcave.setOff()
else
 CaveBot.setOn()
 killcave.setOff()
end
end)

--start/stop TargetBot (Sua macro original corrigida com freio de processamento)
macro(800, "Start/Stop Target", ("CTRL+2"), function(killtarget)
if TargetBot.isOn() then
 TargetBot.setOff()
 killtarget.setOff()
else
 TargetBot.setOn()
 killtarget.setOff()
end
end)

-- BugMap AWSD/Setas/NumPad Otimizado (Sem onMacroToggle e Sem Slow)
local consoleModule = modules.game_console

local function checkPos(x, y)
    local player = g_game.getLocalPlayer()
    if not player or (consoleModule and type(consoleModule.isChatEnabled) == "function" and consoleModule:isChatEnabled()) then 
        return false 
    end

    -- CORREÇÃO 1: Variáveis locais blindadas para não vazar memória global
    local xyz = player:getPosition()
    if not xyz then return false end

    xyz.x = xyz.x + x
    xyz.y = xyz.y + y

    local tile = g_map.getTile(xyz)
    if tile then
        local topThing = tile:getTopUseThing()
        if topThing then
            return g_game.use(topThing)
        end
    end
    return false
end

-- CORREÇÃO 2: Loop inteligente de baixa frequência (100ms). Só lê se a macro estiver ativa!
dash = macro(40, 'Bug Map', 'CTRL+3', function()
    -- Se o chat estiver aberto, não faz nada para poupar processamento
    if consoleModule and type(consoleModule.isChatEnabled) == "function" and consoleModule:isChatEnabled() then
        return
    end

    local gk = modules.corelib.g_keyboard
    if not gk or type(gk.isKeyPressed) ~= "function" then return end

    -- Varredura condicional: só gasta processamento no milissegundo em que você segurar a tecla
    if gk.isKeyPressed('w') then checkPos(0, -5)
    elseif gk.isKeyPressed('e') then checkPos(3, -3)
    elseif gk.isKeyPressed('d') then checkPos(5, 0)
    elseif gk.isKeyPressed('c') then checkPos(3, 3)
    elseif gk.isKeyPressed('s') then checkPos(0, 5)
    elseif gk.isKeyPressed('z') then checkPos(-3, 3)
    elseif gk.isKeyPressed('a') then checkPos(-5, 0)
    elseif gk.isKeyPressed('q') then checkPos(-3, -3)
    end
end)

-- Inicializa o botão desligado por padrão conforme a estrutura original do seu cliente
if dash and type(dash.setOff) == "function" then 
    dash:setOff() 
end


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
  local player = g_game.getLocalPlayer()
  if not player then return end

  local currentTarget = g_game.getAttackingCreature()

  -- 1. Se você está atacando alguém ativamente, atualiza a memória
  if currentTarget then
    storage.uiTargetId = currentTarget:getId()
    storage.manualStop = false
    return
  end

  -- 2. Trava para o ESC / Stop: Se você não está atacando e o jogo não reporta target ativo
  -- ao mesmo tempo em que a tecla ESC foi pressionada ou a ação de parar foi acionada
  if g_keyboard.isKeyPressed("Escape") then
    storage.uiTargetId = nil
    storage.manualStop = true
    return
  end

  -- 3. Se você cancelou manualmente (parou de atacar), não tenta re-atacar
  if storage.manualStop then
    return
  end

  -- 4. Se perdeu o target sem você apertar ESC (ex: monstro/player correu, tomou desinstância/poof)
  if storage.uiTargetId then
    local reattackDone = false

    if modules.game_battle and modules.game_battle.battleButtons then
      for _, button in pairs(modules.game_battle.battleButtons) do
        -- Verifica se o botão pertence ao alvo salvo
        if button and button.creature and button.creature:getId() == storage.uiTargetId then
          if button.creature:getHealthPercent() > 0 then
            
            -- Simula o clique/soltura no botão da Battle para re-atacar
            if modules.game_battle.onBattleButtonMouseRelease then
              modules.game_battle.onBattleButtonMouseRelease(button, { x = 0, y = 0 }, 1)
              reattackDone = true
            end

            if not reattackDone and button.onClick then
              button:onClick()
              reattackDone = true
            end

          end
          break
        end
      end
    end

    -- Fallback caso a lista de battle falhar no momento
    if not reattackDone then
      for _, spec in ipairs(g_map.getSpectators(player:getPosition(), false)) do
        if spec:getId() == storage.uiTargetId and spec:getHealthPercent() > 0 then
          g_game.attack(spec)
          break
        end
      end
    end
  end
end)

if chaseatk and chaseatk.setOff then
    chaseatk.setOff()
end
-- Enemy (Versão Corrigida Definitiva - Sem Erros e Sem Slow)
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

local function alternarBotsNativos(ligar)
    if ligar then
        if TargetBot then
            if type(TargetBot.setOn) == "function" then TargetBot.setOn()
            elseif type(TargetBot.start) == "function" then TargetBot.start()
            end
        end
    else
        if CaveBot then
            if type(CaveBot.setOff) == "function" then CaveBot.setOff()
            elseif type(CaveBot.stop) == "function" then CaveBot.stop()
            end
        end
        if TargetBot then
            if type(TargetBot.setOff) == "function" then TargetBot.setOff()
            elseif type(TargetBot.stop) == "function" then TargetBot.stop()
            end
        end
    end
end

local estadoAnteriorMacro = false

-- Configurada em 150ms: Velocidade perfeita de PVP/Target sem travar a CPU
enemy = macro(150, 'Enemy', "ALT+3", function()
    if not g_game.isOnline() then return end

    -- CORREÇÃO CRÍTICA: Se a macro estiver ativa mas o estado ainda não foi configurado, liga a trava
    if not estadoAnteriorMacro then
        alternarBotsNativos(false) 
        definirModoAtaque("balanced")
        estadoAnteriorMacro = true
        print("[Enemy] TargetBot Desligado.")
    end
    
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    
    local myPos = localPlayer:getPosition()
    if not myPos then return end
    
    local actualTarget = nil
    local actualTargetHp = 101
    local actualTargetDist = 10
    
    local espectadores = g_map.getSpectators(myPos, false)
    if not espectadores then return end

    for i = 1, #espectadores do
        local creature = espectadores[i]
        if creature and creature:isPlayer() and creature ~= localPlayer then
            local specHp = creature:getHealthPercent()
            local specPos = creature:getPosition()
            
            if specHp and specHp > 0 and specPos and specPos.z == myPos.z then
                local specSkull = creature:getSkull()
                local specShield = creature:getShield()
                
                -- Filtro de PK (White Skull = 1, Red Skull = 4)
                if (specSkull == 1 or specSkull == 4) and specShield == 0 and creature:getEmblem() ~= 1 then
                    if type(creature.canShoot) ~= "function" or creature:canShoot() then
                        local specDist = getDistanceBetween(myPos, specPos)
                        
                        if not actualTarget or specHp < actualTargetHp or (specHp == actualTargetHp and specDist < actualTargetDist) then
                            actualTarget = creature
                            actualTargetHp = specHp
                            actualTargetDist = specDist
                        end
                    end
                end
            end
        end
    end
    
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        if modules.game_interface and type(modules.game_interface.processMouseAction) == "function" then
            modules.game_interface.processMouseAction(nil, 2, myPos, nil, actualTarget, actualTarget)
        else
            g_game.attack(actualTarget) 
        end
    end
end)

-- AUTO-RESET SEGURO: Monitora em segundo plano se você desligou o botão da macro.
-- Se desligar, reseta a variável local imediatamente sem usar funções globais inexistentes!
macro(500, function()
    if enemy and type(enemy.isOn) == "function" then
        if not enemy.isOn() and estadoAnteriorMacro then
            estadoAnteriorMacro = false
        end
    end
end)

--X-Sense (Correção de Extração Bruta e Sem Lag)
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
    -- 1. Varredura bruta convertendo tudo para texto (Força o client a extrair strings de objetos)
    for i = 1, #args do
        if args[i] then
            local strConvertida = tostring(args[i])
            -- Procura pela string que começa com 'x' ou 'X' de forma direta e sem lag
            local primeiroChar = string.sub(strConvertida, 1, 1)
            if primeiroChar == 'x' or primeiroChar == 'X' then
                text = strConvertida
                break
            end
        end
    end
    -- 2. Se nenhuma das mensagens capturadas começou com 'x', descarta instantaneamente (CPU em 0%)
    if not text then return end
    -- 3. Execução segura do comando "x"
    local msg = text:trim()
    local checkMsg = string.sub(msg, 2, #msg):trim()
    if checkMsg == '0' then
        storage.Sense = ""
        modules.game_textmessage.displayStatusMessage("[xSense] Alvo limpado com sucesso!")
    else
        storage.Sense = checkMsg
        say('sense "' .. storage.Sense)
    end
    return true
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

-- Magic wall & Wild growth timer (Otimizado contra Gargalo de CPU)
local magicWallId = 10980
local magicWallTime = 20000
local wildGrowthId = 2130
local wildGrowthTime = 45000
local activeTimers = {}
local function tempoAtual()
  return now or (os.time() * 1000)
end
local function obterChaveTile(tile)
  if not tile then return 0 end
  local pos = tile:getPosition()
  if not pos then return 0 end
  return (pos.x * 100000) + pos.y
end
-- EVENTO DE ADICIONAR: Mostra o tempo imediatamente na tela
onAddThing(function(tile, thing)
  -- FILTRO DE PERFORMANCE ABSOLUTO: Se não for um objeto válido ou não for um ITEM, aborta na hora.
  -- Isso impede o bot de tentar ler propriedades de Criaturas, Efeitos e Tiros, eliminando os 103ms de lag.
  if not thing or type(thing) ~= "userdata" or not thing.isItem or not thing:isItem() then return end
  if not tile then return end
  local itemId = thing:getId()
  if itemId ~= magicWallId and itemId ~= wildGrowthId then return end

  local timer = (itemId == magicWallId) and magicWallTime or wildGrowthTime
  local tileKey = obterChaveTile(tile)
  if tileKey == 0 then return end
  local tempoAgora = tempoAtual()
  -- Impede o reset visual se o timer já estiver rodando perfeitamente neste piso
  if activeTimers[tileKey] and activeTimers[tileKey] > tempoAgora then
    return
  end
  activeTimers[tileKey] = tempoAgora + timer
  -- Injeta o tempo regressivo de forma estável na tela
  tile:setTimer(timer)
end)
-- EVENTO DE REMOVER: Apaga o tempo se a barreira sumir antes da hora
onRemoveThing(function(tile, thing)
  -- Aplica o mesmo filtro rápido de tipo na remoção
  if not thing or type(thing) ~= "userdata" or not thing.isItem or not thing:isItem() then return end
  if not tile then return end

  local itemId = thing:getId()
  if itemId ~= magicWallId and itemId ~= wildGrowthId then return end

  local tileKey = obterChaveTile(tile)
  if tileKey ~= 0 then
    activeTimers[tileKey] = nil
    tile:setTimer(0) -- Reseta o visor do piso
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
dofile("/cavebot/pos_check.lua")
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

-- CreaturePriority
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

-- CaveBot - Interceptador de Passos Inteligente (Fim do Slow por FindPath)
if CaveBot and type(CaveBot.delay) == "function" then
    -- CORREÇÃO 1: Proteção real de Reload para não duplicar ponteiros na memória RAM
    if not CaveBot.oldDelayOriginalPointer then
        CaveBot.oldDelayOriginalPointer = CaveBot.delay
    end
    
    local originalDelay = CaveBot.oldDelayOriginalPointer

    CaveBot.delay = function(ms, ...)
        if ms and type(ms) == "number" then
            -- CORREÇÃO 2: Altera apenas os delays de andada comuns (entre 200ms e 500ms)
            -- Força 250ms: É o tempo perfeito de resposta da andada sem fazer o C++ recalcular rota à toa
            if ms >= 200 and ms <= 500 then
                ms = 250 
            end
        end
        return originalDelay(ms, ...)
    end
end

-- TargetBot
local function obterTempoReal()
    return math.floor(os.clock() * 1000)
end

-- CORREÇÃO 1: Removeu a macro global que atropelava a variável 'now' do target.lua
-- Se o bot precisar atualizar o tempo, ele fará de forma isolada localmente.

-- 1. SEQUESTRO RESTRITO DO ADAPTADOR DE MACROS NATIVAS (Suporte a nomes como String)
if type(macro) == "function" then
    local oldMacro = macro
    macro = function(delayTime, name, callback, ...)
        local targetFunc = nil
        local macroName = "Target Control"

        -- CORREÇÃO 2: Identifica se a macro veio no formato macro(100, function) ou macro(100, "nome", function)
        if delayTime == 100 then
            if type(name) == "function" then
                targetFunc = name
            elseif type(callback) == "function" then
                targetFunc = callback
                if type(name) == "string" then macroName = name end
            end
        end

        -- Se interceptou o loop de 100ms do target.lua, aplica a vacina de freio de CPU
        if targetFunc then
            local ultimoTickExecutado = 0
            local ultimoAndarX = 0

            -- Forçamos a macro nativa a rodar com um delay maior de 200ms para poupar o motor do bot
            local minhaMacroTarget = oldMacro(200, macroName, function()
                local player = g_game.getLocalPlayer()
                if not player then return end
                
                local playerPos = player:getPosition()
                if not playerPos then return end

                -- DETECÇÃO E LIMPEZA DE BUFFER DE ESCADA/TELEPORT
                if ultimoAndarX ~= playerPos.z then
                    ultimoAndarX = playerPos.z
                    ultimoTickExecutado = obterTempoReal() + 1500
                    pcall(function()
                        g_game.cancelAttack()
                        if TargetBot and type(TargetBot.walkTo) == "function" then TargetBot.walkTo(nil) end
                        collectgarbage("collect")
                    end)
                    return
                end

                local agora = obterTempoReal()
                
                -- BLOQUEIO RIGIDO: Força a função pesada da linha 50 a processar apenas a cada 450ms cravados.
                -- Isso reduz drasticamente as checagens por segundo e extingue o Slow Macro.
                if agora - ultimoTickExecutado < 450 then
                    return
                end
                
                ultimoTickExecutado = agora
                return targetFunc()
            end, callback, ...)

            if minhaMacroTarget and type(minhaMacroTarget) == "table" then
                minhaMacroTarget.delay = 450
            end

            return minhaMacroTarget
        end
        return oldMacro(delayTime, name, callback, ...)
    end
end

-- 2. INTERCEPTADOR RESTRITO DE CRIATURAS DO TARGETBOT (Filtro de Área)
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
        local limiteMaximoMonstros = 2 -- Calcula apenas as duas criaturas mais coladas no seu char

        for i = 1, #listaOriginal do
            local creature = listLine and listaOriginal[i] or listaOriginal[i]
            if creature and creature:isMonster() and creature:getHealthPercent() > 0 then
                local cPos = creature:getPosition()
                
                if cPos and cPos.z == playerPos.z then
                    local distX = math.abs(playerPos.x - cPos.x)
                    local distY = math.abs(playerPos.y - cPos.y)
                    
                    -- Limita o radar de alvos para 4 quadrados (Foca estritamente na sua Box de combate)
                    if distX <= 4 and distY <= 4 then
                        totalAdicionados = totalAdicionados + 1
                        listaFiltrada[totalAdicionados] = creature
                        
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
print("[Loader] TargetBot otimizado com sucesso.")
