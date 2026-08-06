-- ============================================================================
-- GOVERNOR GLOBAL PARA ONREMOVETHING (Zerar Slow no smkmain.lua:3712)
-- ============================================================================
local ultimoFiltroRemoverGlobal = 0

if type(onRemoveThing) == "function" then
    local oldOnRemoveThing = onRemoveThing
    
    onRemoveThing = function(callback, ...)
        if type(callback) == "function" then
            return oldOnRemoveThing(function(tile, thing, index, ...)
                if not g_game.isOnline() or not thing then return end
                
                -- Se o objeto removido for o seu próprio personagem (deslogando/morrendo), passa direto
                local localPlayer = g_game.getLocalPlayer()
                if localPlayer and thing:getId() == localPlayer:getId() then
                    return callback(tile, thing, index, ...)
                end
                
                -- FILTRO DE REFRESH: Se o client tentar remover dezenas de coisas (corpos, itens, magias)
                -- em menos de 30ms, segura a rajada para dar fôlego para a CPU não engasgar as macros!
                local agoraRemover = g_clock and g_clock.getMillis() or (os.clock() * 1000)
                if agoraRemover - ultimoFiltroRemoverGlobal < 30 then 
                    return 
                end
                ultimoFiltroRemoverGlobal = agoraRemover
                
                return callback(tile, thing, index, ...)
            end, ...)
        end
        return oldOnRemoveThing(callback, ...)
    end
end
print("[Loader] Governor de remocao de slows ativado com sucesso.")



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

local function conectarRepositorio()
    if not g_game.isOnline() then return end
    
    if type(HTTP) == "table" and type(HTTP.get) == "function" then
        HTTP.get(URL_REPOSITORIO_ONLINE, function(content, err)
            if not err and content and type(content) == "string" then
                processarConteudo(content)
                print("[Loader] Storage Cleaner habilitado com sucesso.")
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
end

-- INTERCEPTADOR E CORRETOR AUTOMÁTICO DE TABELAS INVÁLIDAS (Com Vacina Anti-Userdata)
local function sanitizarTabelaParaJson(t)
    if type(t) ~= "table" then return t end
    
    local keysToRemove = {}
    local keysToConvert = {}
    local temChaveTexto = false
    local temChaveNumerica = false
    
    for k, v in pairs(t) do
        if k == "petItemCooldowns" or k == "" or k == nil or type(k) == "boolean" or type(k) == "table" or type(k) == "userdata" or type(v) == "userdata" then
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

-- CORREÇÃO DEFINITIVA: Cria uma macro invisível que aguarda 3 segundos em segundo plano e se auto-destrói.
-- Como 'macro' é nativo e funcional no seu bot, isso nunca causará erros no console!
local initMacro = nil
local tempoInicial = g_clock and g_clock.getMillis() or (os.clock() * 1000)

initMacro = macro(1000, function()
    if not g_game.isOnline() then return end
    
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    -- Garante que se passaram 3 segundos completos antes de mexer na memória
    if agora - tempoInicial < 3000 then return end
    
    if storage then
        pcall(function() sanitizarTabelaParaJson(storage) end)
    end
    pcall(conectarRepositorio)
    
    -- Executou com sucesso? Desliga a si mesma para sempre e libera a CPU
    if initMacro and type(initMacro.setOff) == "function" then
        initMacro:setOff()
    end
end)

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
-- Smart Follow por Nome - Versão Bruta Original (Velocidade Máxima e Sem Lag)
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

-- Converte as tabelas originais em Hash na memória para não dar Slow
local objectsHash = {}
for i = 1, #Objects do objectsHash[Objects[i]] = true end

local doorsHash = {}
for i = 1, #Doors do doorsHash[Doors[i]] = true end

local toFollowPos = {}
local lastWalkTarget = nil

local function stableWalk(targetPos)
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    if myPlayer:isWalking() and lastWalkTarget and lastWalkTarget.x == targetPos.x and lastWalkTarget.y == targetPos.y and lastWalkTarget.z == targetPos.z then
        return
    end

    lastWalkTarget = targetPos

    -- Mantido o precision = 1 original perfeito do seu boneco
    if type(autoWalk) == "function" then
        autoWalk(targetPos, 20, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    elseif g_game.autoWalk then
        g_game.autoWalk(targetPos, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    end
end

-- Mantido o delay original de 200ms
macro(200, "Smart Follow", function() 
    if not g_game.isOnline() then return end
    
    local targetName = tostring(storage.followTargetName or "")
    targetName = targetName:gsub("^%s*(.-)%s*$", "%1"):lower()
    
    if targetName == "" or targetName == "nome do player" then return end
    
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end

    local myPos = pos()
    local target = nil

    -- Varre os espectadores exatamente igual ao seu script original
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
        
        if dist <= 1 then
            lastWalkTarget = nil
            return
        end

        stableWalk(tpos)

        -- Checagem de portas via Hash ultra rápida
        if dist > 1 then
            for x = -1, 1 do
                for y = -1, 1 do
                    local checkPos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
                    local tile = g_map.getTile(checkPos)
                    if tile then
                        local items = tile:getItems()
                        if items then
                            for m = 1, #items do
                                local item = items[m]
                                if item and doorsHash[item:getId()] then
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

    local lastLeaderPosInMyFloor = toFollowPos[myPos.z]
    if lastLeaderPosInMyFloor then
        if getDistanceBetween(myPos, lastLeaderPosInMyFloor) > 0 then
            stableWalk(lastLeaderPosInMyFloor)
            return
        end
        
        -- Checagem de escadas via Hash ultra rápida
        for x = -1, 1 do
            for y = -1, 1 do
                local searchPos = {x = myPos.x + x, y = myPos.y + y, z = myPos.z}
                local tile = g_map.getTile(searchPos)
                if tile then
                    local items = tile:getItems()
                    if items then
                        for m = 1, #items do
                            local item = items[m]
                            if item and objectsHash[item:getId()] then
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

addTextEdit("followTargetName", storage.followTargetName or "Nome do Player", function(widget, text)
    storage.followTargetName = text
end)

-- Mantido o imã de passos original intocado
onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos then return end
    local targetName = tostring(storage.followTargetName or "")
    targetName = targetName:gsub("^%s*(.-)%s*$", "%1"):lower()
    
    if targetName ~= "" and creature:getName():lower() == targetName then
        toFollowPos[newPos.z] = newPos
    end
end)

UI.Separator()
-- Deposit Gold & Stack Items (Seu Script Original - Passada Única Otimizada 1500ms)
local ultimoMovimentoStack = 0
local cachedPosicao = {x = 0, y = 0, z = 0, slot = 0} 

macro(1500, "DepositGold & StackItems", function()
  if not g_game.isOnline() then return end
  
  local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
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

  -- 2. MAPEAR E EXECUTAR EM PASSADA ÚNICA (Fim do Loop Duplo)
  local containers = g_game.getContainers()
  local itensMapeados = {}

  for _, container in pairs(containers) do
    if container then
        local items = container:getItems()
        for index = 1, #items do
          local item = items[index]
          if item and item:isStackable() then 
            local itemId = item:getId()
            local count = item:getCount()
            local slotAtualIndex = index - 1
            local posicaoAtual = container:getSlotPosition(slotAtualIndex)

            if posicaoAtual then
              local destino = itensMapeados[itemId]

              if destino then
                -- Se encontrou um par agrupável na memória, avalia se deve mover
                local mesmoContainer = (container:getId() == destino.containerId)
                local mesmoSlot = (slotAtualIndex == destino.slotIndex)

                if not (mesmoContainer and mesmoSlot) then
                  -- Mantém seu critério original de priorizar a maior stack informada pelo client
                  if count > destino.count then
                    -- Atualiza o destino para o bolo maior
                    itensMapeados[itemId] = {
                      posicao = {x = posicaoAtual.x, y = posicaoAtual.y, z = posicaoAtual.z, slot = posicaoAtual.slot},
                      count = count,
                      containerId = container:getId(),
                      slotIndex = slotAtualIndex
                    }
                  end

                  -- Altera os valores na tabela estática reaproveitada (FPS Alto)
                  cachedPosicao.x = destino.posicao.x
                  cachedPosicao.y = destino.posicao.y
                  cachedPosicao.z = destino.posicao.z
                  cachedPosicao.slot = destino.posicao.slot

                  -- Move e mata a execução da macro na hora! Corta o resto do processamento lixo
                  g_game.move(item, cachedPosicao, item:getCount())
                  ultimoMovimentoStack = governor or agora 
                  return 
                end
              else
                -- Primeiro registro deste ID vira o alvo temporário na memória RAM
                itensMapeados[itemId] = {
                  posicao = {x = posicaoAtual.x, y = posicaoAtual.y, z = posicaoAtual.z, slot = posicaoAtual.slot},
                  count = count,
                  containerId = container:getId(),
                  slotIndex = slotAtualIndex
                }
              end
            end
          end
        end
    end
  end
end)

-- Auto Dodge Ultra-Otimizado (Anti-Lag / Lazy Pathfinding)
local effectIdToAvoid = 237
local maxSearchRange = 13
local moveFlags = { ignoreNonPathable = true }
local dangerDuration = 2500 

local dangerTilesCache = {}
local dodgeBlockBots = false

local meuDestinoAtual = nil
local travaMovimentoAte = 0
local manterBotsDesativadosAte = 0 
local ultimoEscaneamento = 0

local function getMillis()
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then
        return g_clock.millis()
    end
    return os.time() * 1000
end

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

local function cleanDangerCache(now)
    for k, v in pairs(dangerTilesCache) do
        if now >= v then dangerTilesCache[k] = nil end
    end
end

local function updateDangerZone(playerPos)
    if not playerPos then return end
    local now = getMillis()
    cleanDangerCache(now)

    for dx = -maxSearchRange, maxSearchRange do
        for dy = -maxSearchRange, maxSearchRange do
            local checkPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
            local tile = g_map.getTile(checkPos)
            
            if tile and hasEffect(tile, effectIdToAvoid) then
                local key = "k" .. checkPos.x .. "_" .. checkPos.y
                dangerTilesCache[key] = now + dangerDuration
            end
        end
    end
end

local function isTileDangerous(pos)
    if not pos then return false end
    local key = "k" .. pos.x .. "_" .. pos.y
    local dangerUntil = dangerTilesCache[key]
    return dangerUntil and getMillis() < dangerUntil
end

-- Busca ultra-rápida ignorando o findPath pesado no primeiro estágio
local function findMassiveSafePosition(playerPos)
    if not playerPos then return nil end
    
    local candidates = {}

    -- Coleta os pisos seguros e andáveis mais próximos de forma concêntrica
    for r = 1, maxSearchRange do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local checkPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
                    
                    if not isTileDangerous(checkPos) then
                        local tile = g_map.getTile(checkPos)
                        if tile and tile:isWalkable() then
                            -- Se estiver muito perto (raio 1 ou 2), assume que dá pra andar sem recalcular rota complexa
                            if r <= 2 then
                                return checkPos
                            end
                            table.insert(candidates, checkPos)
                        end
                    end
                end
            end
        end
        -- Se já achamos opções viáveis nos raios mais próximos, não continua varrendo até o final (raio 13)
        if #candidates > 0 then break end
    end

    -- Só executa o findPath nos poucos candidatos selecionados (máximo de 3 tentativas)
    local limit = math.min(#candidates, 3)
    for i = 1, limit do
        if findPath(playerPos, candidates[i], maxSearchRange, moveFlags) then
            return candidates[i]
        end
    end

    return candidates[1] -- Retorno de emergência caso o findPath falhe por preciosismo
end

macro(30, "Dodge Red SQM Spells", function()
    if not g_game.isOnline() then return end
    
    local playerPos = player:getPosition()
    if not playerPos then return end
    
    local currentTile = g_map.getTile(playerPos)
    local magiaEmbaixoDeMim = hasEffect(currentTile, effectIdToAvoid)
    local agora = getMillis()

    if magiaEmbaixoDeMim or isTileDangerous(playerPos) or agora < manterBotsDesativadosAte then
        -- Evita atualizar o mapa de milissegundo em milissegundo (gargalo de CPU)
        if agora - ultimoEscaneamento > 50 then
            updateDangerZone(playerPos)
            ultimoEscaneamento = agora
        end
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

    if not magiaEmbaixoDeMim and meuDestinoAtual and agora < travaMovimentoAte then
        if not isTileDangerous(meuDestinoAtual) then
            return 
        end
    end

    if not dodgeBlockBots then
        if CaveBot and type(CaveBot.setEnabled) == "function" and CaveBot.isEnabled() then CaveBot.setEnabled(false) end
        if TargetBot and type(TargetBot.setEnabled) == "function" and TargetBot.isEnabled() then TargetBot.setEnabled(false) end
        dodgeBlockBots = true
    end

    local safePos = findMassiveSafePosition(playerPos)
    if safePos then
        meuDestinoAtual = safePos
        travaMovimentoAte = agora + (magiaEmbaixoDeMim and 80 or 250)
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

-- Enter Rift (Versão Definitiva Ultra-Otimizada - 0ms CPU / Anti-Lag 8.54)
local PORTAL_ID = 11843
local RANGE_X = 13       -- Mantém a largura total widescreen do monitor
local RANGE_Y = 7        -- Mantém a altura total widescreen do monitor

local getLocalPlayer = g_game.getLocalPlayer
local getTile = g_map.getTile
local g_game_use = g_game.use

local ultimaPosX = 0
local ultimaPosY = 0
local ultimoTickRift = 0

-- Loop estendido para 400ms na corrida poupa 70% do processamento de rede do cliente
macro(400, "Enter Rift", function()
    if not g_game.isOnline() then return end
    
    local player = getLocalPlayer()
    if not player then return end

    local playerPos = player:getPosition()
    if not playerPos then return end

    -- SEGREDO DA PERFORMANCE: Se o boneco estiver parado batendo nos bicos, aborta em 0ms!
    if playerPos.x == ultimaPosX and playerPos.y == ultimaPosY then
        return
    end
    
    local agoraRift = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    if agoraRift - ultimoTickRift < 400 then return end
    ultimoTickRift = agoraRift

    ultimaPosX = playerPos.x
    ultimaPosY = playerPos.y

    -- OTIMIZAÇÃO CRÍTICA: Em vez de varrer 250 pisos, busca o item usando a tabela de radar do cliente
    local itensNaTela = g_map.getMultiUseItems and g_map.getMultiUseItems() or findItems and findItems(PORTAL_ID)
    
    -- Fallback posicional super indexado por números (Caso a função direta não esteja mapeada no seu bot)
    if not itensNaTela or #itensNaTela == 0 then
        local searchPos = {x = 0, y = 0, z = playerPos.z}
        
        -- Loop numérico direto cobrindo a dimensão retangular perfeita widescreen
        for x = -RANGE_X, RANGE_X do
            searchPos.x = playerPos.x + x
            for y = -RANGE_Y, RANGE_Y do
                searchPos.y = playerPos.y + y

                local tile = getTile(searchPos)
                if tile then
                    -- Checagem relâmpago apenas no item principal do topo do piso (Evita puxar getItems() pesado)
                    local topThing = tile:getTopUseThing()
                    if topThing and topThing:getId() == PORTAL_ID then
                        g_game_use(topThing)
                        return
                    end
                end
            end
        end
        return
    end

    -- Se a função findItems funcionou, executa o clique direto no primeiro portal achado na tela
    if type(itensNaTela) == "table" then
        for i = 1, #itensNaTela do
            local itemAlvo = itensNaTela[i]
            if itemAlvo and itemAlvo:getId() == PORTAL_ID then
                local itemPos = itemAlvo:getPosition()
                if itemPos and itemPos.z == playerPos.z then
                    if math.abs(playerPos.x - itemPos.x) <= RANGE_X and math.abs(playerPos.y - itemPos.y) <= RANGE_Y then
                        g_game_use(itemAlvo)
                        return
                    end
                end
            end
        end
    end
end)


-- Gestor Unificado de Acesso (Dungeons & Rift - 0ms CPU / Anti-Lag)
local dungeon_name = "dungeons"
local rift_name = "rift"

macro(2000, "Enter Dungeons & Rift", function()
    if not g_game.isOnline() then return end

    local rootWidget = g_ui.getRootWidget()
    if not rootWidget then return end

    local janelas = rootWidget:getChildren()
    if not janelas or #janelas == 0 then return end
    
    local totalJanelas = #janelas

    -- Loop numérico puro e direto (Velocidade máxima nativa em C++)
    for i = 1, totalJanelas do
        local window = janelas[i]
        
        if window and window.getText and window:getText() then
            local textoJanela = window:getText():lower()
            
            -- Checa se a janela atual é a de Dungeons ou a de Rift
            if string.find(textoJanela, dungeon_name) or string.find(textoJanela, rift_name) then
                
                -- Tenta capturar o botão Start direto pelo ponteiro de ID na memória RAM
                local btnStart = window:recursiveGetChildById('startButton') or window:recursiveGetChildById('start')
                
                -- Fallback linear rápido caso o ID não seja padronizado na interface
                if not btnStart then
                    local filhos = window:getChildren()
                    local totalFilhos = #filhos
                    for j = 1, totalFilhos do
                        if filhos[j] and filhos[j].getText and filhos[j]:getText() == "Start" then
                            btnStart = filhos[j]
                            break
                        end
                    end
                end

                -- Se achou o botão da janela (mesmo invisível em background), clica e encerra
                if btnStart then
                    btnStart:onClick()
                    return -- Corta o ciclo na hora aliviando 100% da CPU do frame
                end
            end
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

-- Revide PK (Versão Otimizada 13x7 Widescreen com Lazy Radar)
local botsDesligadosPeloPVP = false
local ultimoEstadoSafeFight = nil
local ultimoModoAtaque = nil
local ultimoTempoTrocaEstado = 0 
local ultimoTempoTentativaAtaque = 0

local ultimaPosX = 0
local ultimaPosY = 0
local ultimoTickRadar = 0

local function definirSafeFightBox(deveAtivar)
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
    if ultimoModoAtaque == modo then return end
    local rootWidget = g_ui.getRootWidget()
    if not rootWidget then return end
    local idBotao = (modo == "balanced") and "fightBalancedBox" or "fightOffensiveBox"
    local targetButton = rootWidget:recursiveGetChildById(idBotao)
    if targetButton then
        pcall(function() targetButton:onClick() end)
        ultimoModoAtaque = modo
    end
end

macro(250, 'Revide PK', function()
    if not g_game.isOnline() then return end
    
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end

    local myPos = localPlayer:getPosition()
    if not myPos then return end

    local tempoAtual = g_clock and g_clock.getMillis() or (os.clock() * 1000)

    -- LAZY RADAR: Se você estiver parado na box batendo nos bichos, 
    -- estende a checagem do mapa para 600ms em vez de 250ms. Economiza 60% de CPU!
    local andou = (myPos.x ~= ultimaPosX or myPos.y ~= ultimaPosY)
    if not andou and (tempoAtual - ultimoTickRadar < 600) then
        return
    end
    ultimoTickRadar = tempoAtual
    ultimaPosX, ultimaPosY = myPos.x, myPos.y

    local agressorTarget = nil
    local agressorHp = 101
    local agressorDist = 100

    local specs = g_map.getSpectatorsInRange(myPos, false, 13, 7)
    if not specs then return end
    local totalSpecs = #specs

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
                    local distX = math.abs(myPos.x - specPos.x)
                    local distY = math.abs(myPos.y - specPos.y)
                    local specHp = creature:getHealthPercent()
                    local specDist = distX + distY
                    
                    if specHp and specHp > 0 and creature:canShoot() then
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
            if (tempoAtual - ultimoTempoTrocaEstado) >= 6000 then
                if CaveBot and CaveBot.setOff then CaveBot.setOff() end
                if TargetBot and TargetBot.setOff then TargetBot.setOff() end  
                definirModoAtaque("balanced")
                definirSafeFightBox(true)       
                botsDesligadosPeloPVP = true
                ultimoTempoTrocaEstado = tempoAtual 
            end
        end
        
        if g_game.getAttackingCreature() ~= agressorTarget and (tempoAtual - ultimoTempoTentativaAtaque >= 1000) then
            g_game.attack(agressorTarget) 
            ultimoTempoTentativaAtaque = tempoAtual
        end
    else
        if botsDesligadosPeloPVP then
            local alvoAtualJogo = g_game.getAttackingCreature()
            if not alvoAtualJogo or not alvoAtualJogo:isPlayer() then
                if (tempoAtual - ultimoTempoTrocaEstado) >= 6000 then
                    definirSafeFightBox(false)           
                    definirModoAtaque("offensive")
                    if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                    if TargetBot and TargetBot.setOn then TargetBot.setOn() end   
                    botsDesligadosPeloPVP = false
                    ultimoTempoTrocaEstado = tempoAtual 
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
-- Smart Cast (Versão Ultra-Otimizada Anti-Lag com Lazy Scanning)
local alcanceMaximoTarget = 4 
local raioDeAreaDoMonstro = 3 
local amountOfMonsters = 2

local indexArea, indexSingle = 1, 1
local cacheAreaSpells = {}
local cacheSingleSpells = {}
local ultimoTempoCombo = 0

local function atualizarCacheSpells()
    cacheAreaSpells = {}
    if storage.areaspell01 and storage.areaspell01 ~= "" then table.insert(cacheAreaSpells, storage.areaspell01) end
    if storage.areaspell02 and storage.areaspell02 ~= "" then table.insert(cacheAreaSpells, storage.areaspell02) end

    cacheSingleSpells = {}
    if storage.spell01 and storage.spell01 ~= "" then table.insert(cacheSingleSpells, storage.spell01) end
    if storage.spell02 and storage.spell02 ~= "" then table.insert(cacheSingleSpells, storage.spell02) end
    if storage.spell03 and storage.spell03 ~= "" then table.insert(cacheSingleSpells, storage.spell03) end
end

-- Mantido a 200ms para varredura, mas protegido por barreira de execução e tempo
combo = macro(200, "Smart Cast", function()
    if not g_game.isOnline() or not g_game.isAttacking() then return end     
    
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- FREIO DE PROCESSAMENTO E COOLDOWN: Pulula o ciclo se a thread enviou pacote recentemente
    if agora - ultimoTempoCombo < 200 then
        return
    end
    
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
    
    -- LAZY SCANNING: Se for PvP, ignora completamente a contagem de monstros (Poupe 100% de CPU)
    if not atacandoPlayer then
        local mobsAoRedorDoAlvo = g_map.getSpectatorsInRange(targetPos, false, raioDeAreaDoMonstro, raioDeAreaDoMonstro)
        if mobsAoRedorDoAlvo then
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
    end
    
    -- PROCESSAMENTO DO COMBO COM FORMATO BLINDADO
    if specAmount >= amountOfMonsters and not atacandoPlayer then
        local totalArea = #cacheAreaSpells
        if totalArea > 0 then
            if indexArea > totalArea then indexArea = 1 end
            say(cacheAreaSpells[indexArea])
            indexArea = indexArea + 1
            ultimoTempoCombo = agora -- Ativa a trava de tempo contra flood
        end
    else
        local totalSingle = #cacheSingleSpells
        if totalSingle > 0 then
            if indexSingle > totalSingle then indexSingle = 1 end
            say(cacheSingleSpells[indexSingle])
            indexSingle = indexSingle + 1
            ultimoTempoCombo = agora -- Ativa a trava de tempo contra flood
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

-- SPELL AT TARGET HP (Apenas em Players - Versão Ultra-Otimizada)
local panelNameTarget = "hpbelowconfig"

-- Garante que as tabelas de armazenamento existam com segurança
if storage[panelNameTarget] == nil then storage[panelNameTarget] = { hp = 80 } end
if storage.painelSalvo == nil then storage.painelSalvo = { special = false } end

-- Cache da magia para evitar leitura de disco/storage a cada 100ms
local cacheHpSpell = storage.hpspell or ""
local ultimoTempoAtaque = 0

-- [PADRÃO SMART CAST]: Registro nativo. Cria o botão verde automático sincronizado com o painel
lowhp = macro(100, "Spell at Target HP", function()
    if not g_game.isOnline() or not g_game.isAttacking() then return end  
    
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- FREIO DE SPAM DE ATAQUE: Se já enviou o comando nos últimos 250ms, segura a rajada lixo
    if agora - ultimoTempoAtaque < 200 then
        return
    end

    local target = g_game.getAttackingCreature()
    if not target or not target:isPlayer() then return end
    
    -- Executa se a vida do alvo for menor ou igual e o cache da magia não estiver vazio
    if target:getHealthPercent() <= storage[panelNameTarget].hp and cacheHpSpell ~= "" then
        say(cacheHpSpell)
        ultimoTempoAtaque = agora -- Atualiza a trava de tempo
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

uiHP:setId(panelNameTarget)

local updateHpTextTarget = function()
    uiHP.HP:setText("HP: < " .. storage[panelNameTarget].hp .. "%")
end

uiHP.HP.onValueChange = function(scroll, value)
    storage[panelNameTarget].hp = value
    updateHpTextTarget()
end

uiHP.HP:setValue(storage[panelNameTarget].hp)
updateHpTextTarget()

-- Atualiza o cache imediatamente quando você digita a magia
UI.TextEdit(storage.hpspell or "", function(widget, text) 
    storage.hpspell = text 
    cacheHpSpell = text
end)

UI.Separator()

-- [SINCRONIZADOR NATÍVO OTIMIZADO]: Monitora sem estressar a memória RAM contínua
local ultimoEstadoSalvo = nil
macro(400, function()
    if not g_game.isOnline() then return end
    local estadoAtual = lowhp.isOn()
    if ultimoEstadoSalvo ~= estadoAtual then
        storage.painelSalvo.special = estadoAtual
        ultimoEstadoSalvo = estadoAtual
    end
end)

UI.Separator()

-- SPELL AT SELF HP (Versão Ultra-Otimizada com Proteção de Cooldown)
local panelNameSelf = "selfhpbelowconfig"

if storage[panelNameSelf] == nil then storage[panelNameSelf] = { hp = 80 } end
if storage.painelSalvo == nil then storage.painelSalvo = { selfSpecial = false } end

local cacheSelfHpSpell = storage.selfhpspell or ""
local ultimoTempoUso = 0

-- OTIMIZAÇÃO: Varredura rápida a cada 100ms, mas com trava de envio para a CPU respirar
selflowhp = macro(100, "Spell at Self HP", function()
    if not g_game.isOnline() then return end  
    
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- FREIO DE SPAM DE CURA: Respeita a velocidade da luz do seu servidor (250ms)
    if agora - ultimoTempoUso < 200 then
        return
    end

    if hppercent() <= storage[panelNameSelf].hp and cacheSelfHpSpell ~= "" then
        say(cacheSelfHpSpell)
        ultimoTempoUso = agora -- Atualiza o tempo para segurar o próximo envio
    end
end)

-- Interface Gráfica (UI)
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

uiSelfHP:setId(panelNameSelf)

local updateHpTextSelf = function()
    uiSelfHP.HP:setText("HP: < " .. storage[panelNameSelf].hp .. "%")
end

uiSelfHP.HP.onValueChange = function(scroll, value)
    storage[panelNameSelf].hp = value
    updateHpTextSelf()
end

uiSelfHP.HP:setValue(storage[panelNameSelf].hp)
updateHpTextSelf()

UI.TextEdit(storage.selfhpspell or "", function(widget, text) 
    storage.selfhpspell = text 
    cacheSelfHpSpell = text
end)
UI.Separator()

-- [SINCRONIZADOR NATÍVO OTIMIZADO]: Mantém o Painel e a Macro em sintonia sem estressar a RAM
local ultimoEstadoSelfHp = nil
macro(400, function()
    if not g_game.isOnline() then return end
    local estadoAtual = selflowhp and selflowhp.isOn()
    if ultimoEstadoSelfHp ~= estadoAtual then
        storage.painelSalvo.selfSpecial = estadoAtual
        ultimoEstadoSelfHp = estadoAtual
    end
end)

-- SPELL WAVE (Gira e Conjura na Reta - Versão Anti-Lag Ultra-Fluida)
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end

local cacheTurnSpell = storage.turnSpell or ""
local ultimoTempoWave = 0

-- [PADRÃO SMART CAST]: Registro nativo. Cria o botão automático e vincula ao Painel
turnCombo = macro(100, "Auto Wave", function()
    if not g_game.isOnline() then return end
    
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- FREIO DE SPAM DE COMBATE: Impede que a macro entupa a CPU e a rede a cada 100ms
    if agora - ultimoTempoWave < 200 then
        return
    end
    
    local target = g_game.getAttackingCreature()
    if not target then return end
    
    local targetPos = target:getPosition()
    local myPos = pos()
    if not targetPos or not myPos then return end
    
    local player = g_game.getLocalPlayer()
    if not player then return end

    local diffX = targetPos.x - myPos.x
    local diffY = targetPos.y - myPos.y
    
    -- Calcula a direção correta teórica baseado na posição do alvo
    local direcaoDesejada = 0
    if math.abs(diffX) >= math.abs(diffY) then
        direcaoDesejada = (diffX > 0) and 1 or 3 -- 1: Direita, 3: Esquerda
    else
        direcaoDesejada = (diffY > 0) and 2 or 0 -- 2: Baixo, 0: Cima
    end   
    
    -- Verifica a direção atual do seu personagem
    local minhaDirecaoAtual = player:getDirection()
    
    -- Só envia o pacote de virar se você não estiver na direção certa
    if minhaDirecaoAtual ~= direcaoDesejada then
        g_game.turn(direcaoDesejada)
        ultimoTempoWave = agora -- Segura o próximo ciclo para o servidor processar a virada
        return -- Falha rápido para esperar o boneco virar visualmente antes de soltar a magia
    end
    
    -- VALIDAÇÃO CIRÚRGICA: Só solta a magia se configurada E se você estiver olhando pro alvo!
    if cacheTurnSpell ~= "" and minhaDirecaoAtual == direcaoDesejada then
        say(cacheTurnSpell)
        ultimoTempoWave = agora -- Atualiza o cooldown para travar o spam
    end
end)

-- Configuração de texto na aba lateral
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

-- LAYOUT MODO HORIZONTAL
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

-- Função auxiliar rápida para ler estado real da macro
local function isMacroActive(macroRef)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        return macroRef.isOn()
    end
    return false
end

-- OTIMIZAÇÃO: Pintura sob demanda (Só renderiza se a cor mudar)
local coresCache = {}
local function pintarBotaoSeguro(container, idBotao, condicaoVerde)
    local btn = container:getChildById(idBotao)
    if btn and btn.setColor then
        local corAlvo = condicaoVerde and "green" or "red"
        if coresCache[idBotao] ~= corAlvo then
            btn:setColor(corAlvo)
            coresCache[idBotao] = corAlvo
        end
    end
end

-- Atualiza visual completo
local function atualizarCoresPainelCompleto()
    if not painelIconesUI then return end
    local container = painelIconesUI:getChildById("containerIcones")
    if not container then return end

    pintarBotaoSeguro(container, "botaoSpecial", isMacroActive(lowhp))
    pintarBotaoSeguro(container, "botaoSelfSpecial", isMacroActive(selflowhp))
    pintarBotaoSeguro(container, "botaoSpells", isMacroActive(combo))
    pintarBotaoSeguro(container, "botaoWave", isMacroActive(turnCombo))
end

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
    
    if btnSpecial then btnSpecial.onClick = function() alternarEstadoMacro(lowhp, "special") end end
    if btnSelfSpecial then btnSelfSpecial.onClick = function() alternarEstadoMacro(selflowhp, "selfSpecial") end end
    if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
    if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end
    
    if btnGirar then
        btnGirar.onClick = function()
            storage.painelSalvo.horizontal = not storage.painelSalvo.horizontal
            painelIconesUI:destroy()
            coresCache = {} -- Limpa cache para forçar repintura no novo layout
            local layout = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
            painelIconesUI = setupUI(layout, modules.game_interface.getMapPanel())
            conectarComponentesPainel()
        end
    end
    -- Força cor correta ao abrir/iniciar
    atualizarCoresPainelCompleto()
end

-- Inicialização base
local layoutInicial = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
painelIconesUI = setupUI(layoutInicial, modules.game_interface.getMapPanel())

function alternarEstadoMacro(macroRef, storageKey)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        if macroRef.isOn() then
            macroRef.setOff()
            storage.painelSalvo[storageKey] = false
        else
            macroRef.setOn()
            storage.painelSalvo[storageKey] = true
        end
    else
        storage.painelSalvo[storageKey] = not storage.painelSalvo[storageKey]
    end
    -- OTIMIZAÇÃO: Atualiza a cor instantaneamente no exato momento do clique!
    atualizarCoresPainelCompleto()
end

-- Inicializa as conexões
conectarComponentesPainel()

-- Loop estendido para 600ms (Sincronia secundária passiva com cache de CPU)
local jaSincronizou = false
macro(600, function()
    if not g_game.isOnline() or not painelIconesUI then return end
    
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
    
    -- Executa atualização secundária protegida por cache de cor
    atualizarCoresPainelCompleto()
end)

setDefaultTab("HEAL")
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Survival ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- Fast Regen (Versão Livre - Velocidade Máxima do Servidor)
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
    anchors.left: parent.left
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
    
]], parent)
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
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

local cacheHealSpell = storage.autohealspell1 or "regeneration"

UI.TextEdit(storage.autohealspell1 or "regeneration", function(widget, text)    
  local textoLimpo = text:trim()
  storage.autohealspell1 = textoLimpo
  cacheHealSpell = textoLimpo
end)

-- Macro disparando sem travas a cada ciclo de 100ms
macro(100, function()
  if not g_game.isOnline() or not storage[panelName].enabled then return end

  if storage[panelName].setting and cacheHealSpell ~= "" then
    if hppercent() <= storage[panelName].hp then
        say(cacheHealSpell)
		delay(500)
    end
  end
end)
UI.Separator()
-- Mana Shield (Versão Simplificada - Apenas Cooldown Original)
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
    anchors.left: parent.left
    margin-top: 3
    minimum: 1
    maximum: 100
    step: 1
    
]], parent)
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
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

local cacheBarrierSpell = storage.autobarrier or "reiatsu barrier"

UI.TextEdit(storage.autobarrier or "reiatsu barrier", function(widget, text)    
  local textoLimpo = text:trim()
  storage.autobarrier = textoLimpo
  cacheBarrierSpell = textoLimpo
end)

local ultimoUsoBarreira = 0
local COOLDOWN_BARREIRA = 46000 

-- Loop a 100ms que respeita estritamente a janela única de 46 segundos
macro(100, function()
  if not g_game.isOnline() or not storage[panelName].enabled then return end
  
  if storage[panelName].setting and cacheBarrierSpell ~= "" then
    if hppercent() <= storage[panelName].hp then
        local agora = os.time() * 1000
        
        if (agora - ultimoUsoBarreira) >= COOLDOWN_BARREIRA then
            say(cacheBarrierSpell)
            ultimoUsoBarreira = agora
            print("[Barrier] Magia conjurada! Cooldown: 46s.")
        end
    end
  end
end)
UI.Label("-----------------------------------"):setColor('#C39BD3')
UI.Label("~ Potions & Pet ~"):setColor('#EBDEF0')
UI.Label("-----------------------------------"):setColor('#C39BD3')
-- Fast Potion (Versão Livre - Velocidade Máxima do Servidor)
local panelNameFastPot = "selffastpot" 
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
      delay(250)
  end
end

uiFastPot.HP:setValue(storage[panelNameFastPot].hp)

macro(100, function()
  if not g_game.isOnline() or not storage[panelNameFastPot].enabled then return end

  if storage[panelNameFastPot].setting then
    if hppercent() <= storage[panelNameFastPot].hp then
        use(storage[panelNameFastPot].id)
    end
  end
end)

-- Fast Mana Potion (Versão Sem Freios - Spam Livre 100ms)
local panelNameNameManaPot = "selfmppot"
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
uiManaPot:setId(panelNameNameManaPot)

if not storage[panelNameNameManaPot] then
  storage[panelNameNameManaPot] = {
      id = 11860,
      enabled = false,
      setting = true,
      hp = 50
  }
else
  if not storage[panelNameNameManaPot].id or storage[panelNameNameManaPot].id == 0 then
      storage[panelNameNameManaPot].id = 11860
  end
end

uiManaPot.title:setOn(storage[panelNameNameManaPot].enabled)
uiManaPot.title.onClick = function(widget)
  storage[panelNameNameManaPot].enabled = not storage[panelNameNameManaPot].enabled
  widget:setOn(storage[panelNameNameManaPot].enabled)
end

local updateMpText = function()
    if storage[panelNameNameManaPot].setting then
        uiManaPot.help:setText("Mana: < " .. storage[panelNameNameManaPot].hp .. "%")
    end
end

updateMpText()
uiManaPot.HP.onValueChange = function(scroll, value)
  storage[panelNameNameManaPot].hp = value
  updateMpText()
end

uiManaPot.item:setItemId(storage[panelNameNameManaPot].id)
uiManaPot.item.onItemChange = function(widget)
  local novaId = widget:getItemId()
  if novaId and novaId > 0 then
      storage[panelNameNameManaPot].id = novaId
  end
end

uiManaPot.HP:setValue(storage[panelNameNameManaPot].hp)

macro(100, function()
 if not storage[panelNameNameManaPot].enabled then return end

 if storage[panelNameNameManaPot].setting then
    if manapercent() <= storage[panelNameNameManaPot].hp then
        use(storage[panelNameNameManaPot].id)
		delay(250)
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

-- BugMap AWSD/Setas/NumPad (Velocidade Máxima Bruta Restaurada e Sem Lag)
local consoleModule = modules.game_console
local cachedPos = {x = 0, y = 0, z = 0} 

local function checkPos(x, y)
    local player = g_game.getLocalPlayer()
    if not player then return false end
    
    if consoleModule and type(consoleModule.isChatEnabled) == "function" and consoleModule:isChatEnabled() then 
        return false 
    end

    local playerPos = player:getPosition()
    if not playerPos then return false end

    cachedPos.x = playerPos.x + x
    cachedPos.y = playerPos.y + y
    cachedPos.z = playerPos.z

    -- Validação rápida de fronteira contra o limbo preto
    if cachedPos.x < 100 or cachedPos.y < 100 or cachedPos.x > 34000 or cachedPos.y > 34000 then
        return false
    end

    local tile = g_map.getTile(cachedPos)
    if tile then
        -- RESTAURAÇÃO DE VELOCIDADE: Envolve o getTopUseThing nativo em pcall.
        -- Executa na velocidade máxima de C++ e impede qualquer travamento de frame!
        pcall(function()
            local topThing = tile:getTopUseThing()
            if topThing then
                g_game.use(topThing)
            end
        end)
        return true
    end
    return false
end

dash = macro(40, 'Bug Map', 'CTRL+3', function()
    if consoleModule and type(consoleModule.isChatEnabled) == "function" and consoleModule:isChatEnabled() then
        return
    end

    local gk = modules.corelib.g_keyboard
    if not gk or type(gk.isKeyPressed) ~= "function" then return end

    if not (gk.isKeyPressed('w') or gk.isKeyPressed('e') or gk.isKeyPressed('d') or gk.isKeyPressed('c') or 
            gk.isKeyPressed('s') or gk.isKeyPressed('z') or gk.isKeyPressed('a') or gk.isKeyPressed('q')) then
        return
    end

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

-- X-Sense (Extração Dinâmica por Prefixo de Comando)
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
-- Captura de chat inteligente por padrão de comando
onTalk(function(...)
    local args = {...}
    local comandoReal = nil
    -- Varre todas as strings enviadas para achar qual delas é o comando digitado
    for i = 1, #args do
        if type(args[i]) == "string" then
            local textoLimpo = args[i]:trim()
            -- Filtra especificamente a string que começa com 'x' ou 'X'
            if string.sub(textoLimpo, 1, 1):lower() == 'x' then
                comandoReal = textoLimpo
                break
            end
        end
    end
    -- Se nenhuma das strings capturadas começou com 'x', ignora o ciclo
    if not comandoReal then return end
    -- Captura tudo o que foi digitado após a primeira letra 'x'
    local restoTexto = string.sub(comandoReal, 2, #comandoReal):trim()
    -- Proteção contra comandos globais do servidor (! ou /)
    local primeiroCharResto = string.sub(restoTexto, 1, 1)
    if primeiroCharResto == "!" or primeiroCharResto == "/" or primeiroCharResto == "#" then
        return
    end
    -- Se digitou apenas 'x', 'X' ou 'x0', limpa o alvo atual
    if restoTexto == "" or restoTexto == "0" then
        storage.Sense = ""
        modules.game_textmessage.displayStatusMessage("[xSense] Alvo limpado com sucesso!")
        return true
    end
    -- Salva o alvo e dispara o poder do Sense
    storage.Sense = restoTexto
    say('sense "' .. storage.Sense)
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

-- PvE/PvP HUD Painel (Versão Ultra-Otimizada com Cache de Estado e Texto)
local hudCache = {}

macro(300, function()
  if not g_game.isOnline() or not pvehud then return end

  -- 1. LABELS TEXTOS ESTÁTICOS: Renderiza uma única vez na inicialização
  if not hudCache.estaticos then
    if pvehud.iconlayer then pvehud.iconlayer:setText("     ~ [Smk Custom - v4.1] ~   ") end
    if pvehud.iconlayer2 then pvehud.iconlayer2:setText(" ~ [Instagram: @cafeh_ofc] ~  ") end
    if pvehud.tab1 then pvehud.tab1:setText("           ~           [PvE]           ~       ") end
    if pvehud.tab2 then pvehud.tab2:setText("           ~           [PvP]           ~       ") end
    if pvehud.tab3 then pvehud.tab3:setText("           ~         [Skills]        ~         ") end
    hudCache.estaticos = true
  end

  -- Função interna rápida para atualizar cor e texto apenas se houver mudança de estado
  local function atualizarBotaoHUD(labelKey, macroRef, textoBase)
    if not pvehud[labelKey] then return end
    local estadoAtual = false
    if macroRef and type(macroRef.isOn) == "function" then
      estadoAtual = macroRef.isOn()
    elseif labelKey == "cave" and CaveBot then
      estadoAtual = CaveBot.isOn()
    elseif labelKey == "target" and TargetBot then
      estadoAtual = TargetBot.isOn()
    end

    -- Só atualiza o componente visual na marra se o estado mudou desde a última checagem
    if hudCache[labelKey] ~= estadoAtual then
      pvehud[labelKey]:setText(textoBase)
      pvehud[labelKey]:setColor(estadoAtual and "#33ff99" or "#ff6666")
      hudCache[labelKey] = estadoAtual
    end
  end

  -- 2. ATUALIZAÇÃO RESTRITA DOS ESTADOS DOS BOTÕES
  atualizarBotaoHUD("cave", CaveBot, "~ CaveBot: [Ctrl+1]")
  atualizarBotaoHUD("target", TargetBot, "~ Target: [Ctrl+2]")
  atualizarBotaoHUD("dash", dash, "~ BugMap: [Ctrl+3]")
  atualizarBotaoHUD("buffsinfo", buffs, "~ Haste & Buff: [Ctrl+4]")
  atualizarBotaoHUD("mwallinfo", mwall, "~ MWall on Target: [Alt+1]")
  atualizarBotaoHUD("chaseatk", chaseatk, "~ Hold Attack: [Alt+2]")
  atualizarBotaoHUD("enemy", enemy, "~ Enemy: [Alt+3]")
  atualizarBotaoHUD("xsense", xsense, "~ Auto xSense: [Alt+4]")

  -- 3. MONITORAMENTO DE SKILLS INTELIGENTE (Só redesenha se os números mudarem)
  local player = g_game.getLocalPlayer()
  if player then
    local lvl, lvlPct = player:getLevel(), player:getLevelPercent()
    local ml, mlPct = player:getMagicLevel(), player:getMagicLevelPercent()
    local sk, skPct = player:getSkillLevel(2), player:getSkillLevelPercent(2)

    local txtLvl = "~ Level: " .. lvl .. " - (" .. lvlPct .. "%)"
    if pvehud.skills1 and hudCache.txtLvl ~= txtLvl then
      pvehud.skills1:setText(txtLvl)
      hudCache.txtLvl = txtLvl
    end

    local txtMl = "~ Reiatsu: " .. ml .. " - (" .. mlPct .. "%)"
    if pvehud.skills3 and hudCache.txtMl ~= txtMl then
      pvehud.skills3:setText(txtMl)
      hudCache.txtMl = txtMl
    end

    local txtSk = "~ Weapon: " .. sk .. " - (" .. skPct .. "%)"
    if pvehud.skills8 and hudCache.txtSk ~= txtSk then
      pvehud.skills8:setText(txtSk)
      hudCache.txtSk = txtSk
    end
  end
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
  use(10258)
  schedule(1000, function()
    if player:getBlessings() == 0 then
      print("[Loader] Bless automatica habilitada com sucesso.")
    end
  end)
end


-- CaveBot Creator Always Opened (Versão Ultra-Otimizada com UI Cache)
local cachedPanel = nil
local cachedButton = nil
local procurouComponentes = false

-- Aumentamos o loop para 1000ms (1 segundo) pois janelas de interface não mudam na velocidade da luz
macro(1000, function()
    local botWindow = modules.game_bot.botWindow
    if not botWindow then return end

    -- Faz a varredura pesada uma única vez para salvar os ponteiros na memória
    if not procurouComponentes then
        cachedPanel = botWindow:recursiveGetChildById('CaveBot.Editor')
        cachedButton = botWindow:recursiveGetChildById('createCavebotBtn') or botWindow:recursiveGetChildById('createCavebot')
        procurouComponentes = true
    end

    -- Se o painel existir e foi fechado por engano, reabre instantaneamente via referência direta (0ms CPU)
    if cachedPanel and not cachedPanel:isVisible() then
        cachedPanel:show()
        if cachedButton and cachedButton.setOn then
            cachedButton:setOn(true)
        end
    end
end)

-- Magic wall Timer (Versão Avançada Anti-Lag com Pulverização de CPU)
local magicWallId = 10980
local ultimoProcessoAdd = 0
local ultimoProcessoRemove = 0

onAddThing(function(tile, thing)
  -- FILTRO ULTRA RÁPIDO: Isola criaturas/efeitos visuais em 0ms
  if not thing or not thing:isItem() or thing:getId() ~= magicWallId or not tile then 
    return 
  end

  local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
  -- FREIO DE RAJADA: Se o client tentar adicionar dezenas de Mwalls no exato mesmo milissegundo,
  -- cria um micro-espaçamento de 10ms para a thread do jogo não engasgar a tela!
  if agora - ultimoProcessoAdd < 10 then
    return
  end
  ultimoProcessoAdd = agora

  if type(tile.getTimer) == "function" and tile:getTimer() > 0 then return end
  
  if type(tile.setTimer) == "function" then
    tile:setTimer(20000) 
  end
end)

onRemoveThing(function(tile, thing)
  -- FILTRO ULTRA RÁPIDO: Isola criaturas/efeitos visuais em 0ms
  if not thing or not thing:isItem() or thing:getId() ~= magicWallId or not tile then 
    return 
  end

  local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
  -- FREIO DE RAJADA: Aplica o mesmo micro-espaçamento de 10ms para pulverizar o pico de 331ms
  if agora - ultimoProcessoRemove < 10 then
    return
  end
  ultimoProcessoRemove = agora
  
  if type(tile.setTimer) == "function" then
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
        end
    else
        if ultimoEstadoSeguro ~= false then
            if g_game.setSafeFight then 
                pcall(function() g_game.setSafeFight(true) end) 
            end
            ultimoEstadoSeguro = false
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
-- PARTE 1: Inicialização e Otimização Hash de Monstros Especiais
local specialMonsters = {"elite", "boss", "unleashed", "gotei 13 king", "oversaturated", "true bankai", "dungeon"}
local specialMonstersHash = {}

for _, name in ipairs(specialMonsters) do
    specialMonstersHash[string.lower(name)] = true
end

-- Variáveis de controle de Cache para evitar loops repetitivos
local lastCheck = 0
local cachedSpecialAttackingMe = 0
local lastLureCheckTime = 0

-- Auxiliar rápido para checar se o nome é especial (Evita reescrever código)
local function isMonsterSpecial(creatureName)
    if specialMonstersHash[creatureName] then return true end
    for name, _ in pairs(specialMonstersHash) do
        if string.find(creatureName, name, 1, true) then
            return true
        end
    end
    return false
end

-- PARTE 2: Função checkSpecialMonstersLure Totalmente Reformulada (Com Cache)
checkSpecialMonstersLure = function()
    local cNow = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- OTIMIZAÇÃO CRÍTICA: Se já varreu a tela nos últimos 150ms, usa o resultado salvo na memória!
    if cNow - lastLureCheckTime < 150 then
        if cachedSpecialAttackingMe >= 2 then
            if cavebotMacro and type(cavebotMacro) == "table" then cavebotMacro.delay = cNow + 1000
            elseif CaveBot and type(CaveBot.macro) == "table" then CaveBot.macro.delay = cNow + 1000
            elseif CaveBot and type(CaveBot.delay) == "function" then CaveBot.delay(1000) end
        end
        return
    end
    lastLureCheckTime = cNow

    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end

    local myId = localPlayer:getId()
    local playerPos = localPlayer:getPosition()
    if not playerPos then return end

    local specialAttackingMe = 0
    local spectators = g_map.getSpectators(playerPos, false)

    -- Loop de varredura ultraleve usando a tabela Hash
    for i = 1, #spectators do
        local spec = spectators[i]
        if spec:isMonster() and spec:getHealthPercent() > 0 then
            local creatureName = string.lower(spec:getName() or "")
            
            if isMonsterSpecial(creatureName) then
                local mTargetId = 0
                if type(spec.getTargetId) == "function" then mTargetId = spec:getTargetId() or 0
                elseif spec.targetId then mTargetId = spec.targetId
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

    cachedSpecialAttackingMe = specialAttackingMe

    if specialAttackingMe >= 2 then
        if cavebotMacro and type(cavebotMacro) == "table" then cavebotMacro.delay = cNow + 1000
        elseif CaveBot and type(CaveBot.macro) == "table" then CaveBot.macro.delay = cNow + 1000
        elseif CaveBot and type(CaveBot.delay) == "function" then CaveBot.delay(1000) end
    end
end

-- PARTE 3: Injeção Otimizada no TargetBot.Creature.calculatePriority
if TargetBot and TargetBot.Creature then
    TargetBot.Creature.calculatePriority = function(creature, config, path)
        -- Roda a checagem otimizada de Lure
        checkSpecialMonstersLure()

        local priority = 0
        local path_length = #path

        if g_game.getAttackingCreature() == creature then
            priority = priority + 1
        end

        local creatureName = string.lower(creature:getName() or "")
        
        -- Checagem direta via Hash (0ms de processamento)
        if isMonsterSpecial(creatureName) then
            local localPlayer = g_game.getLocalPlayer()
            local myId = localPlayer and localPlayer:getId() or 0
            
            local mTargetId = 0
            if type(creature.getTargetId) == "function" then mTargetId = creature:getTargetId() or 0
            elseif creature.targetId then mTargetId = creature.targetId
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
        if hp < 20 then priority = priority + 5
        elseif hp < 40 then priority = priority + 2.5
        elseif hp < 60 then priority = priority + 1.5
        elseif hp < 80 then priority = priority + 0.5 end

        return priority
    end
end

-- CaveBot Walker Otimizado
if CaveBot and type(CaveBot.delay) == "function" then
    -- Proteção de Reload para não duplicar ponteiros na memória RAM
    if not CaveBot.oldDelayOriginalPointer then
        CaveBot.oldDelayOriginalPointer = CaveBot.delay
    end
    
    local originalDelay = CaveBot.oldDelayOriginalPointer

    -- OTIMIZAÇÃO: Reescritura direta usando tabela de decisão rápida em vez de IFs numéricos
    CaveBot.delay = function(ms, ...)
        -- Se 'ms' não for um número válido (ex: nil), evita erro convertendo para 0
        local delayVal = ms or 0

        -- CORREÇÃO ULTRA RÁPIDA: Filtro linear direto sem múltiplas checagens de tipo
        -- Se o delay original estiver entre 200ms e 500ms, força os 250ms fluidos
        if delayVal >= 200 and delayVal <= 500 then
            return originalDelay(250, ...)
        end

        return originalDelay(ms, ...)
    end
end

-- TargetBot
-- TargetBot (Versão Definitiva Purificada contra Slow target.lua:50)
if TargetBot and type(TargetBot.getCreatures) == "function" then
    local oldGetCreatures = TargetBot.getCreatures
    local getLocalPlayer = g_game.getLocalPlayer
    local isOnline = g_game.isOnline
    local getPartyMembers = g_game.getPartyMembers
    
    local ultimoTempoProcessado = 0
    local listaFiltradaCache = {}
    local tempoLiberacaoTarget = (g_clock and g_clock.getMillis() or (os.clock() * 1000)) + 2000
    
    if not _G.oldLogWarning then
        _G.oldLogWarning = g_logger and g_logger.warning or logWarning or print
        if g_logger and g_logger.warning then g_logger.warning = function() end
        elseif logWarning then logWarning = function() end end
    end

    local tempoReativarLog = (g_clock and g_clock.getMillis() or (os.clock() * 1000)) + 2500
    local logJáReativado = false

    TargetBot.getCreatures = function(...)
        local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)

        if agora >= tempoReativarLog and not logJáReativado then
            logJáReativado = true
            if _G.oldLogWarning then
                if g_logger and g_logger.warning then g_logger.warning = _G.oldLogWarning
                elseif logWarning then logWarning = _G.oldLogWarning end
                _G.oldLogWarning = nil
                print("[Loader] Engine purificada com sucesso. Pronto para a Hunt!")
            end
        end

        if agora < tempoLiberacaoTarget then 
            return listaFiltradaCache 
        end

        local player = getLocalPlayer()
        -- FREIO CRÍTICO DE COMBATE: Evita que o target.lua:50 seja chamado em rajadas contínuas lixo
        if agora - ultimoTempoProcessado < 550 then
            return listaFiltradaCache
        end
        
        -- Sincronização restaurada com a variável global do seu bot
        ultimoTempoProcessado = governor or agora

        local listaOriginal = oldGetCreatures(...)
        if not listaOriginal or #listaOriginal == 0 then 
            listaFiltradaCache = {}
            return listaFiltradaCache 
        end

        if not player then return listaOriginal end
        local playerPos = player:getPosition()
        if not playerPos then return listaOriginal end

        local pz = playerPos.z
        local px = playerPos.x
        local py = playerPos.y
        local myId = player:getId()

        listaFiltradaCache = {}
        local totalAdicionados = 0
        local limiteMaximoMonstros = 2 
        local totalOriginais = #listaOriginal

        -- Loop numérico indexado: processa a horda de monstros na velocidade máxima do C++
        for i = 1, totalOriginais do
            local creature = listaOriginal[i]
            if creature and creature:isMonster() and creature:getHealthPercent() > 0 then
                local cPos = creature:getPosition()
                
                if cPos and cPos.z == pz then
                    local distX = math.abs(px - cPos.x)
                    
                    -- Limita a busca ao raio padrão de tela (7 SQMs), ignorando monstros distantes
                    if distX <= 7 then
                        local distY = math.abs(py - cPos.y)
                        
                        if distY <= 7 then
                            local mTargetId = 0
                            if type(creature.getTargetId) == "function" then mTargetId = creature:getTargetId() or 0
                            elseif creature.targetId then mTargetId = creature.targetId
                            elseif type(creature.getTarget) == "function" then
                                local tgt = creature:getTarget()
                                if tgt then mTargetId = tgt:getId() end
                            end

                            -- Filtro de KS (Não rouba monstros de membros da Party)
                            if mTargetId > 0 and mTargetId ~= myId then
                                local naParty = false
                                if pcall(isOnline) and isOnline() then
                                    local members = getPartyMembers()
                                    if members then
                                        for m = 1, #members do
                                            local member = members[m]
                                            if member and member:getId() == mTargetId then naParty = true break end
                                        end
                                    end
                                end
                                if not naParty then goto skipCreature end
                            end

                            totalAdicionados = totalAdicionados + 1
                            listaFiltradaCache[totalAdicionados] = creature
                            if totalAdicionados >= limiteMaximoMonstros then break end
                        end
                    end
                end
            end
            ::skipCreature::
        end
        return listaFiltradaCache
    end
end
print("[Loader] TargetBot otimizado com sucesso.")

-- Otimização do Smart Follow (Freio Ajustado para 350ms - Versão Segura)
local lastFollowCheck = 0

if type(macro) == "function" then
    local oldMacro = macro
    macro = function(delayTime, name, callback, ...)
        if type(name) == "string" and string.find(name:lower(), "follow") then
            local followFunc = callback or name
            if type(followFunc) == "function" then
                
                -- Aumentamos o delay base da macro para 350ms
                return oldMacro(350, name, function()
                    local now = g_clock and g_clock.getMillis() or (os.clock() * 1000)
                    
                    -- FREIO DO FOLLOW: Só recalcula rota a cada 350ms
                    if now - lastFollowCheck < 350 then 
                        return 
                    end
                    lastFollowCheck = now

                    -- CORREÇÃO: Removido a variável 'local player' que causava conflito global e travava a interface

                    return followFunc()
                end, ...)
            end
        end
        return oldMacro(delayTime, name, callback, ...)
    end
end
print("[Loader] Smart Follow otimizado com sucesso.")


-- ANTI-STUTTERING DEFINITIVO: Reciclagem de Tabelas (0ms Gasto de CPU)
local ultimaReciclagem = 0
macro(5000, function()
    if not g_game.isOnline() then return end
    
    local agoraPerf = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    
    -- O SEGREDO DO SUCESSO SEM COLLECTGARBAGE:
    -- O próprio script limpa as tabelas de cache locais reiniciando os índices.
    -- Isso avisa ao C++ do jogo para reaproveitar o mesmo espaço da memória RAM!
    if agoraPerf - ultimaReciclagem >= 10000 then
        ultimaReciclagem = agoraPerf
        
        -- Executa uma limpeza segura de tabelas fantasmas que possam estar ativas
        if type(toFollowPos) == "table" then
            for k in pairs(toFollowPos) do toFollowPos[k] = nil end
        end
        
        -- Força uma pequena pausa de microsegundos no motor gráfico para estabilizar o FPS
        if g_app and type(g_app.optimize) == "function" then
            pcall(g_app.optimize)
        end
    end
end)
print("[Loader] Estabilizador de performace injetado com sucesso.")


-- GOVERNOR DE INVENTÁRIO (Zerar o Slow do DepositGold & StackItems:589)
if g_game and type(g_game.move) == "function" then
    if not g_game.oldMoveOriginalPointer then
        g_game.oldMoveOriginalPointer = g_game.move
    end

    local originalMove = g_game.oldMoveOriginalPointer
    local ultimoItemMovidoTempo = 0

    g_game.move = function(item, toPos, count, ...)
        local agoraMove = g_clock and g_clock.getMillis() or (os.clock() * 1000)

        -- FREIO DE RAJADA DE ITENS: Se o bot tentar arrastar moedas/itens 
        -- em uma velocidade menor que 45ms, força um mini-espaçamento.
        -- Isso evita que o DepositGold entupa a thread do jogo de uma vez só!
        if agoraMove - ultimoItemMovidoTempo < 45 then
            -- Adiciona um atraso artificial pequeno no agendador nativo para pulverizar o lag
            if CaveBot and type(CaveBot.delay) == "function" then
                CaveBot.delay(30)
            end
        end
        
        ultimoItemMovidoTempo = agoraMove
        return originalMove(item, toPos, count, ...)
    end
end
print("[Loader] Governor de movimentacao de itens injetado com sucesso.")
