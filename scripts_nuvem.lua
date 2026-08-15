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
local initMacro = nil
local tempoInicial = g_clock and g_clock.getMillis() or (os.clock() * 1000)
initMacro = macro(1000, function()
    if not g_game.isOnline() then return end
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    if agora - tempoInicial < 3000 then return end
    if storage then
        pcall(function() sanitizarTabelaParaJson(storage) end)
    end
    pcall(conectarRepositorio)
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
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("      Smk Custom: v4.2      "):setColor('#DEB887')
UI.Label("        Since 2025       "):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
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
--Alarms Original
--Alarms Original Otimizado (Versão Ultra-Leve - Zero Lag / Zero Slow Macro)
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
addAlarm("ignoreFriends", "Ignore Friends", true, 1, 2)
addAlarm("flashClient", "Flash Client", true, 1, 2)
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
local lastCall = 0
local function alarm(file, windowText)
  local tempoAgora = os.clock() * 1000
  if tempoAgora - lastCall < 2000 then return end -- 2s delay
  lastCall = tempoAgora
  if not g_resources.fileExists(file) then
    file = "/sounds/alarm.ogg"
    lastCall = tempoAgora + 4000 -- alarm.ogg length is 6s
  end
  if modules.game_bot.g_app.getOs() == "windows" and config.flashClient.enabled then
    g_window.flash()
  end
  
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    g_window.setTitle(localPlayer:getName() .. " - " .. windowText)
  end
  playSound(file)
end
onTextMessage(function(mode, text)
  if not config.enabled then return end
  if mode == 22 and config.damageTaken.enabled then
    return alarm('/sounds/magnum.ogg', "Damage Received!")
  end
  if config.customMessage.enabled then
    local alertText = config.customMessage.value
    if alertText and alertText:len() > 0 then
      text = text:lower()
      local parts = string.split(alertText, ",")
      for i=1,#parts do
        local part = parts[i]
        if part then
          part = string.trim(part):lower()
          if text:find(part, 1, true) then
            return alarm('/sounds/magnum.ogg', "Special Message!")
          end
        end
      end
    end
  end
end)
onTalk(function(name, level, mode, text, channelId, pos)
  if not config.enabled then return end
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or name == localPlayer:getName() then return end 
  if config.ignoreFriends.enabled and isFriend(name) then return end 
  if mode == 1 and config.defaultMsg.enabled then
    return alarm("/sounds/magnum.ogg", "Default Message!")
  end
  if mode == 4 and config.privateMsg.enabled then
    return alarm("/sounds/Private_Message.ogg", "Private Message!")
  end
end)
macro(400, function() 
  if not config.enabled then return end
  
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end
  if config.lowHealth.enabled then
    if hppercent() < config.lowHealth.value then
      return alarm("/sounds/Low_Health.ogg", "Low Health!")
    end
  end
  if config.lowMana.enabled then
    local currentMana = type(manapercent) == "function" and manapercent() or 100
    if currentMana < config.lowMana.value then
      return alarm("/sounds/Low_Mana.ogg", "Low Mana!")
    end
  end
  local myPos = localPlayer:getPosition()
  if not myPos then return end
  local espectadores = g_map.getSpectators(myPos, false)
  if not espectadores then return end
  for i = 1, #espectadores do
    local spec = espectadores[i]
    if spec and spec ~= localPlayer and not (config.ignoreFriends.enabled and isFriend(spec:getName())) then
      if config.creatureDetected.enabled and spec:isMonster() and spec:getHealthPercent() > 0 then
        return alarm("/sounds/magnum.ogg", "Creature Detected!")
      end
      if spec:isPlayer() and spec:getHealthPercent() > 0 then 
        if spec:isTimedSquareVisible() and config.playerAttack.enabled then
          return alarm("/sounds/Player_Attack.ogg", "Player Attack!")
        end
        if config.playerDetected.enabled then
          return alarm("/sounds/Player_Detected.ogg", "Player Detected!")
        end
      end
      if config.creatureName.enabled and config.creatureName.value ~= "" then
        local name = string.lower(spec:getName())
        local fragments = string.split(config.creatureName.value, ",")
        
        for f = 1, #fragments do
          if fragments[f] then
            local frag = string.lower(string.trim(fragments[f]))
            if frag ~= "" and string.find(name, frag, 1, true) then
              return alarm("/sounds/alarm.ogg", "Special Creature Detected!")
            end
          end
        end
      end
    end
  end
end)
UI.Separator()
-- Smart Follow
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
local objectsHash = {}
for i = 1, #Objects do objectsHash[Objects[i]] = true end
local doorsHash = {}
for i = 1, #Doors do doorsHash[Doors[i]] = true end
local toFollowPos = {}
local lastWalkTarget = nil
local lastWalkTime = 0
local cachedTargetName = ""
local function atualizarNomeCache(nome)
    local txt = tostring(nome or "")
    cachedTargetName = txt:gsub("^%s*(.-)%s*$", "%1"):lower()
end
atualizarNomeCache(storage.followTargetName)
local function stableWalk(targetPos)
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end
    local now = os.clock()
    -- Evita spam de Pathfinding na mesma coordenada (Janela curta de 200ms para manter a fluidez máxima)
    if myPlayer:isWalking() and lastWalkTarget and lastWalkTarget.x == targetPos.x and lastWalkTarget.y == targetPos.y and lastWalkTarget.z == targetPos.z and (now - lastWalkTime < 0.2) then
        return
    end
    lastWalkTarget = targetPos
    lastWalkTime = now
    -- BLINDAGEM ANTI-CONFLITO: Desativa a rota de caminhada do TargetBot para dar prioridade ao Follow
    if TargetBot then
        TargetBot.currentPath = nil
        if type(TargetBot.stopWalking) == "function" then TargetBot.stopWalking() end
    end
    if type(autoWalk) == "function" then
        autoWalk(targetPos, 20, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    elseif g_game.autoWalk then
        g_game.autoWalk(targetPos, { ignoreCreatures = false, ignoreNonPathable = true, precision = 1 })
    end
end
local function checkAndUseAdjacentItems(myPos, hashFilter)
    for x = -1, 1 do
        for y = -1, 1 do
            if x ~= 0 or y ~= 0 then
                local tile = g_map.getTile({x = myPos.x + x, y = myPos.y + y, z = myPos.z})
                if tile then
                    local topItem = tile:getTopUseThing()
                    if topItem and hashFilter[topItem:getId()] then
                        g_game.use(topItem)
                        return true
                    end
                end
            end
        end
    end
    return false
end
macro(200, "Smart Follow", function() 
    if not g_game.isOnline() then return end
    if cachedTargetName == "" or cachedTargetName == "nome do player" then return end
    local myPlayer = g_game.getLocalPlayer()
    if not myPlayer then return end
    local myPos = myPlayer:getPosition()
    local target = nil
    local spectators = getSpectators(myPos)
    for i = 1, #spectators do
        local spec = spectators[i]
        if spec and spec:isPlayer() and spec:getName():lower() == cachedTargetName then
            target = spec
            break
        end
    end
    if target then
        local tpos = target:getPosition()
        toFollowPos[tpos.z] = tpos
        local dist = getDistanceBetween(myPos, tpos)
        -- Se colou no líder, zera o alvo para dar liberdade ao TargetBot de virar de frente ou bater
        if dist <= 1 then
            lastWalkTarget = nil
            return
        end
        stableWalk(tpos)
        checkAndUseAdjacentItems(myPos, doorsHash)
        return
    end
    local lastLeaderPosInMyFloor = toFollowPos[myPos.z]
    if lastLeaderPosInMyFloor then
        if getDistanceBetween(myPos, lastLeaderPosInMyFloor) > 0 then
            stableWalk(lastLeaderPosInMyFloor)
            return
        end
        checkAndUseAdjacentItems(myPos, objectsHash)
    end
end)
addTextEdit("followTargetName", storage.followTargetName or "Nome do Player", function(widget, text)
    storage.followTargetName = text
    atualizarNomeCache(text)
end)
onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos or cachedTargetName == "" then return end
    if creature:getName():lower() == cachedTargetName then
        toFollowPos[newPos.z] = newPos
    end
end)
UI.Separator()
--STACK & DEPOSIT (VERSÃO EXCLUSIVA PARA SERVIDORES COM ITENS ÚNICOS - LIMITE 10000)
local processandoAgora = false
local hashInventarioAnterior = ""
local function pegarDescricaoItem(item)
    if not item then return "" end
    local desc = ""
    if type(item.getTooltip) == "function" then
        desc = item:getTooltip()
    elseif type(item.getDescription) == "function" then
        desc = item:getDescription()
    end
    return desc:lower()
end
local function executarFluxoStackEDeposit()
  if not g_game.isOnline() or processandoAgora then return end
  processandoAgora = true
  -- 1. CHECAGEM E DEPÓSITO DE COINS
  local coinIds = { 3031, 3035, 3043, 10137 } 
  for i = 1, #coinIds do
    local itemCoin = findItem(coinIds[i])
    if itemCoin and itemCoin:getCount() >= 1 then
      say("!deposit all")
      processandoAgora = false
      return
    end
  end
  -- 2. AGRUPAMENTO (STACK) DE ITENS
  local containers = g_game.getContainers()
  local itemGroups = {}
  
  for index, container in pairs(containers) do
    if container and not container.lootContainer then
      local items = container:getItems()
      for i = 1, #items do
        local item = items[i]  
        -- Verifica se o item é empilhável e não atingiu o limite máximo do servidor
        if item and item:isStackable() and item:getCount() < 10000 then
          local itemId = item:getId()
          local desc = pegarDescricaoItem(item)
          -- SEGUNDA TRAVA AUTOMÁTICA: Ignora completamente qualquer item que tenha dono
          if not string.find(desc, "belongs to") and not string.find(desc, "pessoal") then
            local assinaturaUnica = tostring(itemId)
            
            if not itemGroups[assinaturaUnica] then
              itemGroups[assinaturaUnica] = {}
            end
            table.insert(itemGroups[assinaturaUnica], {
              count = item:getCount(),
              itemObj = item,
              descText = desc -- Guarda o texto exato para comparação no próximo passo
            })
          end
        end
      end
    end
  end
  -- Processa e agrupa apenas os itens comuns legítimos
  for assinatura, slots in pairs(itemGroups) do
    if #slots > 1 then
      local maiorSlot = nil
      local menorSlot = nil
      
      for s = 1, #slots do
        local slotAtual = slots[s]
        if slotAtual.count < 10000 then
          if not maiorSlot or slotAtual.count > maiorSlot.count then
            maiorSlot = slotAtual
          end
        end
        if not menorSlot or slotAtual.count < menorSlot.count then
          menorSlot = slotAtual
        end
      end
      -- TRAVA ABSOLUTA: Só move se os dois objetos forem válidos, diferentes, E se as descrições forem 100% IDÊNTICAS!
      if maiorSlot and menorSlot and maiorSlot.itemObj ~= menorSlot.itemObj then
        if maiorSlot.descText == menorSlot.descText then
          local espacoDisponivel = 10000 - maiorSlot.count
          local quantidadeParaMover = math.min(espacoDisponivel, menorSlot.count)
          
          if quantidadeParaMover > 0 then
            g_game.move(menorSlot.itemObj, maiorSlot.itemObj:getPosition(), quantidadeParaMover)
            processandoAgora = false
            return -- Move apenas um por ciclo para manter zero lag de rede
          end
        end
      end
    end
  end
  
  processandoAgora = false
end
-- Macro principal com leitura de Hash estável
macro(500, "Stack & Deposit", function()
    if not g_game.isOnline() then return end
    
    local containers = g_game.getContainers()
    local hashAtual = ""
    for index, container in pairs(containers) do
        if container and not container.lootContainer then
            local totalItens = #container:getItems()
            hashAtual = hashAtual .. index .. "_" .. totalItens .. "_"
            
            local primeiroItem = container:getItem(0)
            if primeiroItem then
                hashAtual = hashAtual .. primeiroItem:getId() .. "_" .. primeiroItem:getCount() .. "|"
            end
        end
    end
    if hashAtual ~= hashInventarioAnterior then
        hashInventarioAnterior = hashAtual
        executarFluxoStackEDeposit()
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
    return os.time() * 500
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
local function findMassiveSafePosition(playerPos)
    if not playerPos then return nil end
    
    local candidates = {}
    for r = 1, maxSearchRange do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local checkPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
                    
                    if not isTileDangerous(checkPos) then
                        local tile = g_map.getTile(checkPos)
                        if tile and tile:isWalkable() then
                            if r <= 2 then
                                return checkPos
                            end
                            table.insert(candidates, checkPos)
                        end
                    end
                end
            end
        end
        if #candidates > 0 then break end
    end
    local limit = math.min(#candidates, 3)
    for i = 1, limit do
        if findPath(playerPos, candidates[i], maxSearchRange, moveFlags) then
            return candidates[i]
        end
    end
    return candidates[1]
end
macro(100, "Dodge Red SQM Spells", function()
    if not g_game.isOnline() then return end
    
    local playerPos = player:getPosition()
    if not playerPos then return end
    
    local currentTile = g_map.getTile(playerPos)
    local magiaEmbaixoDeMim = hasEffect(currentTile, effectIdToAvoid)
    local agora = getMillis()
    if magiaEmbaixoDeMim or isTileDangerous(playerPos) or agora < manterBotsDesativadosAte then
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
--Enter Dungeons
local window_name = "Dungeons"
macro(2000, "Enter Dungeon", function()
  if not g_game.isOnline() then return end
  if not isInPz() then 
    return 
  end
  for i, rootW in pairs(g_ui.getRootWidget():getChildren()) do
    if string.find(rootW:getText():lower(), window_name:lower()) then
      for i, child in pairs(rootW:getChildren()) do
          if child:getText() == "Start" then
             child:onClick()
             delay(1000)
             break
           end
      end
      break
    end
  end
end)
-- Enter Rift
local portalId = 11843
local ultimoCheckMapa = 0
-- Variáveis de estado para controle do CaveBot e Teleporte
local aguardandoEntrada = false
local posAnteriorTeleporte = nil
local tempoLimiteEntrada = 0
macro(250, "Enter Rift", function()
    local currentTime = now
    local player = g_game.getLocalPlayer()
    if not player then return end
    local playerPos = player:getPosition()
    if not playerPos then return end
    -- 1. VERIFICAÇÃO DE SUCESSO: Se fomos teleportados, religa o CaveBot
    if aguardandoEntrada then
        -- Se mudou de andar (Z) ou se moveu mais de 10 SQMs, o teleporte funcionou!
        if posAnteriorTeleporte and (playerPos.z ~= posAnteriorTeleporte.z or getDistanceBetween(playerPos, posAnteriorTeleporte) > 10) then
            print("[Dungeon] Entrada na Rift detectada! Ligando CaveBot e indo para a Label.")
            -- Reativa o CaveBot
            if CaveBot and CaveBot.setOn then CaveBot.setOn(true) end
            -- Envia para a label da Rift
            if CaveBot and type(CaveBot.gotoLabel) == "function" then
                CaveBot.gotoLabel("Rift")
                if type(CaveBot.preNext) == "function" then 
                    CaveBot.preNext()
                elseif type(CaveBot.reload) == "function" then 
                    CaveBot.reload() 
                end
            end 
            aguardandoEntrada = false
            return
        end
        -- Se estourar o tempo de 5 segundos sem entrar, religa por segurança e tenta de novo
        if currentTime > tempoLimiteEntrada then
            print("[Dungeon] Tempo limite esgotado sem entrar. Reativando CaveBot.")
            if CaveBot and CaveBot.setOn then CaveBot.setOn(true) end
            aguardandoEntrada = false
        end
    end
    -- 2. RADAR LEVE: Busca o portal usando o cache nativo (Roda apenas de 1 em 1 segundo)
    if not aguardandoEntrada and (currentTime - ultimoCheckMapa >= 1000) then
        ultimoCheckMapa = currentTime
        local currentZ = playerPos.z
        for _, tile in ipairs(g_map.getTiles(currentZ)) do
            local tilePos = tile:getPosition()
            -- Filtro matemático rápido por aproximação (Raio 10) antes de ler os itens
            if math.abs(playerPos.x - tilePos.x) <= 10 and math.abs(playerPos.y - tilePos.y) <= 10 then
                local items = tile:getItems()
                if items then
                    for i = 1, #items do
                        local item = items[i]
                        -- Se achou o portal real
                        if item and item:getId() == portalId then
                            print("[Dungeon] Rift REAL encontrada na coordenada X:" .. tilePos.x .. " Y:" .. tilePos.y)
                            -- DESLIGA O CAVEBOT ANTES DE ENTRAR
                            if CaveBot and CaveBot.isOn and CaveBot.isOn() then
                                CaveBot.setOn(false)
                            end
                            -- Toca o aviso sonoro e usa o portal
                            pcall(playSound, "/sounds/magnum.ogg")
                            g_game.use(item)
                            -- Ativa as travas de monitoramento de teleporte
                            posAnteriorTeleporte = playerPos
                            aguardandoEntrada = true
                            tempoLimiteEntrada = currentTime + 5000 -- Espera até 5 segundos pelo teleporte
                            return
                        end
                    end
                end
            end
        end
    end
end)
-- Enter Garganta
local gargantaId = 12613
local windowTitle = "Hollow Garganta"
local enterCooldown = 0
local ultimoCheckMapa = 0 -- Controla o radar do mapa para poupar CPU
-- State variables for entry tracking
local isEntering = false
local posBeforeEnter = nil
local enterTimeout = 0
-- Otimizado: Busca apenas nos filhos diretos e painéis do primeiro nível da janela, poupando CPU
local function findButtonByText(widget, buttonText)
    local txtLower = buttonText:lower()
    for _, child in pairs(widget:getChildren()) do
        if child.getText and child:getText():lower() == txtLower then 
            return child 
        end
        -- Em vez de recursão infinita, busca apenas um nível abaixo (comum para botões de janela)
        for _, subChild in pairs(child:getChildren()) do
            if subChild.getText and subChild:getText():lower() == txtLower then
                return subChild
            end
        end
    end
    return nil
end
-- Intervalo aumentado para 250ms (Reduz drasticamente o uso de CPU)
macro(250, "Enter Garganta", function()
    local currentTime = now
    local pPos = player:getPosition()
    if not pPos then return end
    -- Check if we are currently waiting to enter
    if isEntering then
        -- 1. Success check: Character changed floors or moved far away
        if posBeforeEnter and (pPos.z ~= posBeforeEnter.z or getDistanceBetween(pPos, posBeforeEnter) > 10) then
            warn("Garganta: Entry detected! Resuming CaveBot.")
            if CaveBot then CaveBot.setOn() end
            isEntering = false
            return
        end
        -- 2. Timeout check: 5 seconds passed without entering
        if currentTime > enterTimeout then
            if CaveBot then CaveBot.setOn() end
            isEntering = false
        end
    end
    -- 3. Check for the Garganta UI Window to click "Enter"
    local root = g_ui.getRootWidget()
    if root then
        local wTitleLower = windowTitle:lower()
        for _, window in pairs(root:getChildren()) do
            if window.getText and string.find(window:getText():lower(), wTitleLower, 1, true) then
                local enterBtn = findButtonByText(window, "Enter")
                if enterBtn then
                    if CaveBot and CaveBot.isOn() then 
                        CaveBot.setOn(false) 
                    end 
                    enterBtn:onClick()  
                    posBeforeEnter = pPos
                    isEntering = true
                    enterTimeout = currentTime + 3000
                    enterCooldown = currentTime + 3000
                    return
                end
            end
        end
    end
    -- 4. Check for the Garganta portal/item nearby to use (SÓ RODA DE 1 EM 1 SEGUNDO)
    if currentTime > enterCooldown and not isEntering and (currentTime - ultimoCheckMapa >= 1000) then
        ultimoCheckMapa = currentTime -- Atualiza o tempo do radar
        local currentZ = posz()
        for _, tile in ipairs(g_map.getTiles(currentZ)) do
            local tilePos = tile:getPosition()
            -- Filtro rápido de distância matemática antes de ler todos os itens do tile (Poupa muita CPU)
            if math.abs(pPos.x - tilePos.x) <= 10 and math.abs(pPos.y - tilePos.y) <= 10 then
                local items = tile:getItems()
                if items then
                    for i = 1, #items do
                        local item = items[i]
                        if item and item:getId() == gargantaId then
                            -- Pause CaveBot before using the item
                            if CaveBot and CaveBot.isOn() then
                                CaveBot.setOn(false)
                            end
                            g_game.use(item)
                            -- Track position to verify we actually get teleported
                            posBeforeEnter = pPos
                            isEntering = true
                            enterTimeout = currentTime + 3000
                            enterCooldown = currentTime + 3000
                            return
                        end
                    end
                end
            end
        end
    end
end)
-- Auto Subir/Descer Escadas
Stairs = {}
Stairs.saveStatus = {}
Stairs.pos = nil
Stairs.bestTile = nil
Stairs.lastPos = ""
Stairs.config = {
    ids = {
        1666, 6207, 1948, 435, 7771, 5542, 8657, 6264, 1646, 1648,
        1678, 5291, 1680, 6905, 6262, 1664, 13296, 1067, 13861,
        11931, 1949, 6896, 6205, 13926, 1947, 1968, 5111, 5102,
        7725, 7727, 5229
    },
    stairsHash = {},
    excludeHash = {},
    stand = now,
    tryWalk = nil,
    checked = nil,
    ultimoSucessoRadar = 0
}
for i = 1, #Stairs.config.ids do 
    Stairs.config.stairsHash[Stairs.config.ids[i]] = true 
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
Stairs.checkTile = function(tile)
    if not tile then return false end
    local tilePos = tile:getPosition()
    if not tilePos then return end
    local onString = Stairs.postostring(tilePos)
    local checkStatus = Stairs.saveStatus[onString]
    local itemsOnTile = tile:getItems()
    if checkStatus and ((type(checkStatus) == "number" and #itemsOnTile == checkStatus) or checkStatus == true) then
        return checkStatus
    end
    local topThing = tile:getTopUseThing()
    if not topThing then return false end
    for i = 1, #itemsOnTile do
        if Stairs.config.excludeHash[itemsOnTile[i]:getId()] then
            Stairs.saveStatus[onString] = {#itemsOnTile, false}
            return false
        end
    end
    if Stairs.config.stairsHash[topThing:getId()] then
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
Stairs.getPosition = function(pos, dir)
    if dir == 0 then pos.y = pos.y - 1
    elseif dir == 1 then pos.x = pos.x + 1
    elseif dir == 2 then pos.y = pos.y + 1
    else pos.x = pos.x - 1 end
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
    if dir == 0 then return 2
    elseif dir == 1 then return 3
    elseif dir == 2 then return 0
    elseif dir == 3 then return 1 end
end
Stairs.goUse = function(pos)
    local playerPos = player:getPosition()
    local path = findPath(pos, playerPos)
    if not path then return end
    
    path = table.reverse(path)
    for i, v in ipairs(path) do
        if i > 5 then break end
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
Stairs.checkAll = function()
    local playerObj = g_game.getLocalPlayer()
    if not playerObj then return nil end
    local pPos = playerObj:getPosition()
    if not pPos then return nil end
    local bestTileFound = nil
    local bestDistance = 9999
    for x = -3, 3 do
        for y = -3, 3 do
            local stairPos = {x = pPos.x + x, y = pPos.y + y, z = pPos.z}
            local tile = g_map.getTile(stairPos)
            
            if tile and Stairs.checkTile(tile) then
                local dist = Stairs.accurateDistance(pPos, stairPos)
                
                if dist < bestDistance then
                    if findPath(stairPos, pPos) then
                        bestDistance = dist
                        bestTileFound = tile
                    end
                end
            end
        end
    end
    if bestTileFound then
        Stairs.config.ultimoSucessoRadar = now
    end
    return bestTileFound
end
onPlayerPositionChange(function(newPos, oldPos)
    if not Stairs or not Stairs.config or not AutoEscadasMacroObjeto then
        return
    end
    if AutoEscadasMacroObjeto:isOff() then
        return
    end
    Stairs.config.stand = now
    Stairs.config.tryWalk = nil
    if newPos.z ~= oldPos.z or getDistanceBetween(oldPos, newPos) > 1 or table.equals(Stairs.pos, newPos) then
        Stairs.walk.setOff()
    end
    if Stairs.walk.isOff() then
        Stairs.config.checked = nil
    end
end)
onAddThing(function(tile, thing)
    if not Stairs or not Stairs.config or not AutoEscadasMacroObjeto or AutoEscadasMacroObjeto:isOff() then 
        return 
    end
    
    if type(Stairs.pos) == "table" and tile and table.equals(tile:getPosition(), Stairs.pos) then
        Stairs.bestTile = tile
    end
end)
function markOnThing(thing, color)
    if not Stairs or not Stairs.config or not AutoEscadasMacroObjeto or AutoEscadasMacroObjeto:isOff() then 
        return false 
    end
    
    if thing then
        if thing:getPosition() then
            local topThing = thing:getTopUseThing()
            if topThing and type(topThing.setText) == "function" then
                if color == "#00FF00" then
                    topThing:setText("AQUI", "green")
                elseif color == "#FF0000" then
                    topThing:setText("AQUI", "red")
                else
                    topThing:setText("")
                end
                return true
            end
        end
    end
    return false
end
Stairs.walk = macro(40, function()
    if not Stairs or not Stairs.config then return Stairs.walk.setOff() end
    if modules.corelib and modules.corelib.g_keyboard and type(modules.corelib.g_keyboard.isKeyPressed) == "function" then
        if not modules.corelib.g_keyboard.isKeyPressed("Space") then
            return Stairs.walk.setOff()
        end
    end
    if modules.corelib.g_keyboard.isKeyPressed("Escape") then
        return Stairs.walk.setOff()
    end
    player:lockWalk(300)
    if Stairs.config.tryWalk then return end
    markOnThing(Stairs.bestTile, "#00FF00")
    if Stairs.bestTile and Stairs.bestTile:isWalkable() then
        if not Stairs.bestTile:isPathable() then
            if autoWalk(Stairs.pos, 1) then
                Stairs.config.tryWalk = true
                return
            end
        end
    end
    return Stairs.goUse(Stairs.pos)
end)
Stairs.walk.setOff()
AutoEscadasMacroObjeto = macro(150, "Auto Escadas", function()
    if not Stairs or not Stairs.config then return end
    if Stairs.walk.isOn() then 
        if modules.corelib.g_keyboard and not modules.corelib.g_keyboard.isKeyPressed("Space") then
            Stairs.walk.setOff()
        end
        return 
    end
    
    local espacoPressionado = false
    if modules.corelib and modules.corelib.g_keyboard and type(modules.corelib.g_keyboard.isKeyPressed) == "function" then
        if modules.corelib.g_keyboard.isKeyPressed("Space") and modules.game_console and not modules.game_console:isChatEnabled() then
            espacoPressionado = true
        end
    end
    local currentPos = Stairs.postostring(pos())
    if currentPos ~= Stairs.lastPos then
        local resultadoProvisorio = Stairs.checkAll()
        if resultadoProvisorio then
            markOnThing(Stairs.bestTile, "")
            Stairs.bestTile = resultadoProvisorio
            Stairs.pos = Stairs.bestTile and Stairs.bestTile:getPosition()
            Stairs.lastPos = currentPos
        elseif now - Stairs.config.ultimoSucessoRadar > 500 then
            markOnThing(Stairs.bestTile, "")
            Stairs.bestTile = nil
            Stairs.pos = nil
        end
    end
    
    if espacoPressionado and Stairs.bestTile then
        Stairs.walk.setOn()
        return
    else
        return markOnThing(Stairs.bestTile, "#FF0000")
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
storage.boostId1 = storage.boostId1 or 0
storage.boostId2 = storage.boostId2 or 0
storage.boostId3 = storage.boostId3 or 0
ui.boostItem1:setItemId(storage.boostId1)
ui.boostItem2:setItemId(storage.boostId2)
ui.boostItem3:setItemId(storage.boostId3)
ui.boostItem1.onItemChange = function(widget)
    storage.boostId1 = widget:getItemId()
end
ui.boostItem2.onItemChange = function(widget)
    storage.boostId2 = widget:getItemId()
end
ui.boostItem3.onItemChange = function(widget)
    storage.boostId3 = widget:getItemId()
end
ui.titleBoost:setOn(config.enabled)
ui.titleBoost.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end
local boostCooldowns = {0, 0, 0}
macro(100, function()
    if not config.enabled or isInPz() then return end
    local currentTime = now
    local boostIds = {storage.boostId1, storage.boostId2, storage.boostId3}
    for index, id in ipairs(boostIds) do
        if id and id > 0 then
            if currentTime - boostCooldowns[index] >= 10000 then
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
                if itemFound then
                    g_game.use(itemFound)
                    boostCooldowns[index] = currentTime
                    break
                end
            end
        end
    end
end)
UI.Separator()
UI.Button("Screen: +  Zoom", function() zoomIn() end)
UI.Button("Screen: -  Zoom", function() zoomOut() end)
UI.Label("-----------------------------------"):setColor('#FFDEAD')
setDefaultTab("Fight")
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Spell Caster ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
--    SMART CAST INTEGRADO (VERSÃO ULTRA-OTIMIZADA COM OS.CLOCK PURO - ZERO LAG)
lowhp = {
    isOn = function() return false end,
    setOn = function() end,
    setOff = function() end
}
local alcanceMaximoTarget = 4 
local raioDeAreaDoMonstro = 3 
local amountOfMonsters = 2
local indexArea, indexSingle = 1, 1
local cacheAreaSpells = {}
local cacheSingleSpells = {}
local cacheHpSpell = ""
local ultimoTempoCombo = 0 -- Armazena em segundos decimais puros
-- Configuração do painel de HP integrado
local panelNameTarget = "hpbelowconfig"
if storage[panelNameTarget] == nil then storage[panelNameTarget] = { hp = 80 } end
local function atualizarCacheSpells()
    cacheAreaSpells = {}
    if storage.areaspell01 and storage.areaspell01 ~= "" then table.insert(cacheAreaSpells, storage.areaspell01) end
    if storage.areaspell02 and storage.areaspell02 ~= "" then table.insert(cacheAreaSpells, storage.areaspell02) end
    cacheSingleSpells = {}
    if storage.spell01 and storage.spell01 ~= "" then table.insert(cacheSingleSpells, storage.spell01) end
    if storage.spell02 and storage.spell02 ~= "" then table.insert(cacheSingleSpells, storage.spell02) end
    if storage.spell03 and storage.spell03 ~= "" then table.insert(cacheSingleSpells, storage.spell03) end
    cacheHpSpell = storage.hpspell or ""
end
-- CONTADOR DE MONSTROS ULTRA-LEVE (POUPA CPU NO PVE)
local function contarMonstrosAoRedor(targetPos)
    local total = 0
    local mobsAoRedorDoAlvo = g_map.getSpectatorsInRange(targetPos, false, raioDeAreaDoMonstro, raioDeAreaDoMonstro)
    if mobsAoRedorDoAlvo then
        local totalMobs = #mobsAoRedorDoAlvo
        for i = 1, totalMobs do
            local mob = mobsAoRedorDoAlvo[i]
            -- O filtro nativo do getSpectatorsInRange já limita o raio horizontal, reduzindo matemática redundante
            if mob and mob:isMonster() and mob:getHealthPercent() > 0 then
                local mobPos = mob:getPosition()
                if mobPos and mobPos.z == targetPos.z then
                    total = total + 1
                    -- PULO DO GATO: Se já atingiu a meta de monstros para usar área, encerra o loop IMEDIATAMENTE
                    if total >= amountOfMonsters then 
                        break 
                    end
                end
            end
        end
    end
    return total
end
combo = macro(200, "Smart Cast", function()
    if not g_game.isOnline() or not g_game.isAttacking() then return end     
    local agora = os.clock()
    if agora - ultimoTempoCombo < 0.2 then
        return
    end
    local target = g_game.getAttackingCreature()
    if not target then return end
    local targetPos = target:getPosition()
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer or not targetPos then return end
    
    local minhaPos = localPlayer:getPosition()
    if not minhaPos or minhaPos.z ~= targetPos.z then return end
    if math.abs(minhaPos.x - targetPos.x) > alcanceMaximoTarget or math.abs(minhaPos.y - targetPos.y) > alcanceMaximoTarget then 
        return 
    end
    local targetHp = target:getHealthPercent()
    local atacandoPlayer = target:isPlayer()
    if atacandoPlayer then
        if targetHp <= storage[panelNameTarget].hp and cacheHpSpell ~= "" then
            ultimoTempoCombo = agora
            say(cacheHpSpell)
            return
        end
        local totalSingle = #cacheSingleSpells
        if totalSingle > 0 then
            if indexSingle > totalSingle then indexSingle = 1 end
            ultimoTempoCombo = agora
            say(cacheSingleSpells[indexSingle])
            indexSingle = indexSingle + 1
        end
        return 
    end
    local specAmount = contarMonstrosAoRedor(targetPos)
    
    if specAmount >= amountOfMonsters then
        local totalArea = #cacheAreaSpells
        if totalArea > 0 then
            if indexArea > totalArea then indexArea = 1 end
            ultimoTempoCombo = agora
            say(cacheAreaSpells[indexArea])
            indexArea = indexArea + 1
        end
    else
        local totalSingle = #cacheSingleSpells
        if totalSingle > 0 then
            if indexSingle > totalSingle then indexSingle = 1 end
            ultimoTempoCombo = agora
            say(cacheSingleSpells[indexSingle])
            indexSingle = indexSingle + 1
        end
    end
end)
UI.Separator()
UI.Label("Area (2+ Mobs)"):setColor('#F5F5DC')
UI.Separator()
UI.TextEdit(storage.areaspell01 or "", function(widget, text) storage.areaspell01 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.areaspell02 or "", function(widget, text) storage.areaspell02 = text; atualizarCacheSpells() end)
UI.Separator()
UI.Label("Single"):setColor('#F5F5DC')
UI.Separator()
UI.TextEdit(storage.spell01 or "", function(widget, text) storage.spell01 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.spell02 or "", function(widget, text) storage.spell02 = text; atualizarCacheSpells() end)
UI.TextEdit(storage.spell03 or "", function(widget, text) storage.spell03 = text; atualizarCacheSpells() end)
UI.Separator()
UI.Label("Spell at Target HP"):setColor('#F5F5DC')
UI.Separator()
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
UI.TextEdit(storage.hpspell or "", function(widget, text) 
    storage.hpspell = text 
    atualizarCacheSpells()
end)
atualizarCacheSpells()
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Others ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
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
selflowhp = macro(100, "Spell at Self HP", function()
    if not g_game.isOnline() then return end   
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    if agora - ultimoTempoUso < 200 then
        return
    end
    if hppercent() <= storage[panelNameSelf].hp and cacheSelfHpSpell ~= "" then
        say(cacheSelfHpSpell)
        ultimoTempoUso = agora
    end
end)
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
turnCombo = macro(100, "Auto Wave", function()
    if not g_game.isOnline() then return end
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
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
    local direcaoDesejada = 0
    if math.abs(diffX) >= math.abs(diffY) then
        direcaoDesejada = (diffX > 0) and 1 or 3
    else
        direcaoDesejada = (diffY > 0) and 2 or 0
    end   
    local minhaDirecaoAtual = player:getDirection()
    if minhaDirecaoAtual ~= direcaoDesejada then
        g_game.turn(direcaoDesejada)
        ultimoTempoWave = agora
        return
    end
    if cacheTurnSpell ~= "" and minhaDirecaoAtual == direcaoDesejada then
        say(cacheTurnSpell)
        ultimoTempoWave = agora
    end
end)
addTextEdit("spellTurnConfig", storage.turnSpell or "", function(widget, text)
    local textoLimpo = text:trim()
    storage.turnSpell = textoLimpo
    cacheTurnSpell = textoLimpo
end)
macro(200, function()
    if not g_game.isOnline() then return end
    storage.painelSalvo.wave = turnCombo.isOn()
end)
UI.Label("-----------------------------------"):setColor('#FFDEAD')
--    HOTKEY PANEL - PARTE 1 (RESOLUÇÃO DO CONGELAMENTO VERTICAL)
if storage.painelSalvo == nil then storage.painelSalvo = {} end
if storage.painelSalvo.spells == nil then storage.painelSalvo.spells = false end
if storage.painelSalvo.wave == nil then storage.painelSalvo.wave = false end
if storage.painelSalvo.revideAtivo == nil then storage.painelSalvo.revideAtivo = false end
if storage.painelSalvo.horizontal == nil then storage.painelSalvo.horizontal = true end 
if storage.painelSalvo.modoPvP == nil then storage.painelSalvo.modoPvP = false end
painelIconesUI = nil 
ultimoIdPlayerPainel = 0
pcall(function()
    local root = g_ui.getRootWidget()
    if root then
        local antigo = root:recursiveGetChildById("painelMacrosJanela")
        if antigo then antigo:destroy() end
    end
    local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
    if mapPanel then
        local filhos = mapPanel:getChildren()
        for i = 1, #filhos do
            if filhos[i] and filhos[i]:getId() == "painelMacrosJanela" then
                filhos[i]:destroy()
            end
        end
    end
end)
-- LAYOUT MODO VERTICAL (Botoes amarrados direto no parent para nao congelar)
layoutVertical = [[
UIWidget
  id: painelMacrosJanela
  background-color: #1a1a1aef
  border: 1 #3a3a3a
  border-radius: 4
  size: 114 178
  focusable: false
  draggable: false
  phantom: false
  UILabel
    id: tituloPainel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 5
    color: #FFDEAD
    font: verdana-11px-rounded
    text: Hotkeys
    text-auto-resize: true
  Panel
    id: containerIcones
    anchors.fill: parent
    phantom: false
    Button
      id: botaoSpells
      !text: tr('Spells')
      size: 102 22
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 25
    Button
      id: botaoWave
      !text: tr('Wave')
      size: 102 22
      anchors.top: botaoSpells.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
    Button
      id: botaoRevidePK
      !text: tr('Revide')
      size: 102 22
      anchors.top: botaoWave.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
    Button
      id: botaoCaveTarget
      !text: tr('Stop Bot')
      size: 102 22
      anchors.top: botaoRevidePK.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
    Button
      id: botaoSetEquip
      !text: tr('Change Set')
      size: 102 22
      anchors.top: botaoCaveTarget.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
    Button
      id: botaoGirar
      !text: tr('Switch')
      size: 80 18
      anchors.top: botaoSetEquip.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
]]
-- LAYOUT MODO HORIZONTAL FIXO
layoutHorizontal = [[
UIWidget
  id: painelMacrosJanela
  background-color: #1a1a1aef
  border: 1 #3a3a3a
  border-radius: 4
  size: 537 52
  focusable: false
  draggable: false
  phantom: false
  UILabel
    id: tituloPainel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 5
    color: #FFDEAD
    font: verdana-11px-rounded
    text: Hotkeys
    text-auto-resize: true
  Panel
    id: containerIcones
    anchors.fill: parent
    phantom: false
    Button
      id: botaoSpells
      !text: tr('Spells')
      size: 88 22
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      margin-bottom: 6
      margin-left: 6
    Button
      id: botaoWave
      !text: tr('Wave')
      size: 88 22
      anchors.bottom: parent.bottom
      anchors.left: botaoSpells.right
      margin-bottom: 6
      margin-left: 5
    Button
      id: botaoRevidePK
      !text: tr('Revide')
      size: 88 22
      anchors.bottom: parent.bottom
      anchors.left: botaoWave.right
      margin-bottom: 6
      margin-left: 5
    Button
      id: botaoCaveTarget
      !text: tr('Stop Bot')
      size: 88 22
      anchors.bottom: parent.bottom
      anchors.left: botaoRevidePK.right
      margin-bottom: 6
      margin-left: 5
    Button
      id: botaoSetEquip
      !text: tr('Change Set')
      size: 88 22
      anchors.bottom: parent.bottom
      anchors.left: botaoCaveTarget.right
      margin-bottom: 6
      margin-left: 5
    Button
      id: botaoGirar
      !text: tr('Switch')
      size: 60 22
      anchors.bottom: parent.bottom
      anchors.left: botaoSetEquip.right
      margin-bottom: 6
      margin-left: 10
]]
-- FUNÇÃO DE ANCORAGEM FIXA GEOGRÁFICA
function reposicionarPainelSpellCaster()
    if not painelIconesUI then return end
    
    local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
    if not mapPanel then return end
    
    local mapHeight = mapPanel:getHeight()
    local mapX = mapPanel:getX()
    local mapY = mapPanel:getY()
    
    -- Alinhamento perfeito travado na quina inferior esquerda da Game Window
    local posX = mapX + 3
    local posY = mapY + mapHeight - painelIconesUI:getHeight() - 5
    
    painelIconesUI:setPosition({ x = posX, y = posY })
end
--    HOTKEY PANEL - PARTE 2 (VERSÃO CORRIGIDA CONTRA FANTASMAS GRÁFICOS)
local function isMacroActive(macroRef)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        local status, resultado = pcall(macroRef.isOn)
        if status then return resultado end
    end
    return false
end
local function forcarModoAtaquePeloBotao(modo)
    local rootWidget = g_ui.getRootWidget()
    if not rootWidget then return end
    local idBotao = (modo == "balanced") and "fightBalancedBox" or "fightOffensiveBox"
    local targetButton = rootWidget:recursiveGetChildById(idBotao)
    if targetButton then pcall(function() targetButton:onClick() end) end
end
local function pintarBotaoSeguro(container, idBotao, condicaoVerde)
    local btn = container:getChildById(idBotao)
    if btn and type(btn.setColor) == "function" then
        local corAlvo = condicaoVerde and "#32CD32" or "#FF6347"
        pcall(function() btn:setColor(corAlvo) end)
    end
end
local function atualizarCoresPainelCompleto()
    if not g_game.isOnline() or not painelIconesUI then return end
    local container = painelIconesUI:getChildById("containerIcones")
    if not container then return end
    pintarBotaoSeguro(container, "botaoSpells", isMacroActive(combo))
    pintarBotaoSeguro(container, "botaoWave", isMacroActive(turnCombo))
    pintarBotaoSeguro(container, "botaoRevidePK", isMacroActive(revidePKMacro))
    
    local btnCaveTarget = container:getChildById("botaoCaveTarget")
    if btnCaveTarget and type(btnCaveTarget.setColor) == "function" then
        pcall(function() btnCaveTarget:setColor("#FFFFFF") end)
    end
    local btnSet = container:getChildById("botaoSetEquip")
    if btnSet and type(btnSet.setColor) == "function" then 
        pcall(function() btnSet:setColor("#FFFFFF") end) 
    end
end
local conectarComponentesPainel
local function alternarEstadoMacro(macroRef, storageKey)
    if macroRef and type(macroRef) == "table" and type(macroRef.isOn) == "function" then
        if isMacroActive(macroRef) then
            pcall(function() macroRef.setOff() end)
            if storage.painelSalvo then storage.painelSalvo[storageKey] = false end
        else
            pcall(function() macroRef.setOn() end)
            if storage.painelSalvo then storage.painelSalvo[storageKey] = true end
        end
    else
        if storage and storage.painelSalvo then
            storage.painelSalvo[storageKey] = not storage.painelSalvo[storageKey]
        end
    end
    atualizarCoresPainelCompleto()
end
conectarComponentesPainel = function()
    if not painelIconesUI then return end
    painelIconesUI.onMousePress = function() return true end
    painelIconesUI.onMouseRelease = function() return true end
    
    local container = painelIconesUI:getChildById("containerIcones")
    if not container then return end
    
    local btnSpells = container:getChildById("botaoSpells")
    local btnWave = container:getChildById("botaoWave")
    local btnRevidePK = container:getChildById("botaoRevidePK")
    local btnCaveTarget = container:getChildById("botaoCaveTarget")
    local btnSetEquip = container:getChildById("botaoSetEquip")
    local btnGirar = container:getChildById("botaoGirar")
    
    if btnSpells then btnSpells.onClick = function() alternarEstadoMacro(combo, "spells") end end
    if btnWave then btnWave.onClick = function() alternarEstadoMacro(turnCombo, "wave") end end
    if btnRevidePK then btnRevidePK.onClick = function() alternarEstadoMacro(revidePKMacro, "revideAtivo") end end
    
    if btnCaveTarget then
        btnCaveTarget.onClick = function()
            local caveLigado = CaveBot and type(CaveBot.isOn) == "function" and CaveBot.isOn()
            local targetLigado = TargetBot and type(TargetBot.isOn) == "function" and TargetBot.isOn()
            
            if caveLigado or targetLigado then
                if CaveBot and type(CaveBot.setOff) == "function" then CaveBot.setOff()
                elseif CaveBot and type(CaveBot.stop) == "function" then CaveBot.stop() end
                if TargetBot and type(TargetBot.setOff) == "function" then TargetBot.setOff()
                elseif TargetBot and type(TargetBot.stop) == "function" then TargetBot.stop() end
            end
            atualizarCoresPainelCompleto()
        end
    end
    if btnSetEquip then
        btnSetEquip.onClick = function()
            if storage.painelSalvo and g_game.isOnline() then
                local rootWidget = g_ui.getRootWidget()
                local bBalanced = rootWidget and rootWidget:recursiveGetChildById("fightBalancedBox")
                local modoPvP = bBalanced and (bBalanced:isOn() or bBalanced:isChecked())
                forcarModoAtaquePeloBotao(modoPvP and "offensive" or "balanced")
                atualizarCoresPainelCompleto()
            end
        end
    end
    
    if btnGirar then
        btnGirar.onClick = function()
            if storage and storage.painelSalvo and type(layoutHorizontal) == "string" then
                storage.painelSalvo.horizontal = not storage.painelSalvo.horizontal
                if painelIconesUI then painelIconesUI:destroy() end
                
                local layout = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
                painelIconesUI = setupUI(layout, modules.game_interface.getMapPanel())
                conectarComponentesPainel()
                if type(reposicionarPainelSpellCaster) == "function" then
                    reposicionarPainelSpellCaster()
                end
            end
        end
    end
    atualizarCoresPainelCompleto()
end
local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
if mapPanel and storage and storage.painelSalvo and type(layoutHorizontal) == "string" then
    local janelasNoPainel = mapPanel:getChildren()
    if janelasNoPainel then
        for i = 1, #janelasNoPainel do
            local j = janelasNoPainel[i]
            if j and j:getId() == "painelMacrosJanela" then j:destroy() end
        end
    end
    local layoutInicial = storage.painelSalvo.horizontal and layoutHorizontal or layoutVertical
    painelIconesUI = setupUI(layoutInicial, mapPanel)
    conectarComponentesPainel()
    if type(reposicionarPainelSpellCaster) == "function" then
        reposicionarPainelSpellCaster()
    end
end
macro(400, function() 
    if not g_game.isOnline() or not painelIconesUI then return end
    if type(reposicionarPainelSpellCaster) == "function" then
        reposicionarPainelSpellCaster()
    end
    atualizarCoresPainelCompleto()
end)
setDefaultTab("HEAL")
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Survival ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
-- Fast Regen (Versão Otimizada - Velocidade PVP com Proteção de CPU)
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
local ultimoCastHeal = 0 -- Trava nativa estável de tempo de CPU
UI.TextEdit(storage.autohealspell1 or "regeneration", function(widget, text)    
  local textoLimpo = text:trim()
  storage.autohealspell1 = textoLimpo
  cacheHealSpell = textoLimpo
end)
macro(100, function()
  if not g_game.isOnline() or not storage[panelName].enabled then return end
  local agora = os.clock()
  if agora - ultimoCastHeal < 0.25 then return end
  if storage[panelName].setting and cacheHealSpell ~= "" then
    if hppercent() <= storage[panelName].hp then
        ultimoCastHeal = agora
        say(cacheHealSpell)
    end
  end
end)
UI.Separator()
-- Mana Shield
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
      hp = 60
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
macro(100, function()
  if not g_game.isOnline() or not storage[panelName].enabled then return end
  if storage[panelName].setting and cacheBarrierSpell ~= "" then
    if hppercent() <= storage[panelName].hp then
        local agora = os.time() * 1000
        if (agora - ultimoUsoBarreira) >= COOLDOWN_BARREIRA then
            say(cacheBarrierSpell)
            ultimoUsoBarreira = agora
        end
    end
  end
end)
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Potions & Pet ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
-- Fast Potion
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
-- Fast Mana Potion
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
-- Pet on Hp
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
local COOLDOWN_PADRAO = 24000 
local ultimoUsoDoPet = 0
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
                if currentTime - ultimoUsoDoPet >= COOLDOWN_PADRAO then
                    use(currentId)
                    ultimoUsoDoPet = currentTime 
                end
            end
        end
    end
end)
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Haste & Buff ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
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
 UI.Separator()
macro(100, "Buffs", "CTRL+4", function()
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
UI.Label("-----------------------------------"):setColor('#FFDEAD')
setDefaultTab("Extra")
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ Utility ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
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
--AutoLegendary (Versão Ultra-Otimizada - Zero Lag / Zero Slow no Chat)
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
onTextMessage(function(mode, text)
    if not config.enabled or not text then return end
    if mode == 12 or mode == 20 or mode == 21 or mode == 19 then
        local textoLimpo = tostring(text):lower()
        if string.find(textoLimpo, "legendary", 1, true) or string.find(textoLimpo, "kami", 1, true) then
            config.enabled = false
            ui.title:setOn(false)
        end
    end
end)
UI.Separator()
--Swap Set
do
  local defenseToggle = {
    panelName = "autoOffensiveMode" -- Mantido o nome do storage para não resetar sua configuração salva
  }
  -- Inicializa o armazenamento estruturado
  if not storage[defenseToggle.panelName] then
    storage[defenseToggle.panelName] = {
        enabled = false,
        hp = 50
    }
  end
  -- Configuração da interface visual compacta e sem espaços vazios
  defenseToggle.ui = setupUI([[
Panel
  height: 35
    
  BotSwitch
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center
    text: Swap Tank Set - (3rd Slot)

  HorizontalScrollBar
    id: hpScroll
    anchors.top: title.bottom
    anchors.right: parent.right
    anchors.left: parent.left
    margin-top: 0
    minimum: 1
    maximum: 100
    step: 1
]])

  -- Sincroniza o botão principal de ligar/desligar
  defenseToggle.ui.title:setOn(storage[defenseToggle.panelName].enabled)
  defenseToggle.ui.title.onClick = function(widget)
    storage[defenseToggle.panelName].enabled = not storage[defenseToggle.panelName].enabled
    widget:setOn(storage[defenseToggle.panelName].enabled)
  end
  -- Atualiza o texto dinâmico na ScrollBar
  defenseToggle.updateText = function()
    defenseToggle.ui.hpScroll:setText("HP < " .. storage[defenseToggle.panelName].hp .. "%")
  end
  -- Sincroniza a ScrollBar com o storage
  defenseToggle.ui.hpScroll.onValueChange = function(scroll, value)
    storage[defenseToggle.panelName].hp = value
    defenseToggle.updateText()
  end
  defenseToggle.ui.hpScroll:setValue(storage[defenseToggle.panelName].hp)
  defenseToggle.updateText()
  -- Função segura para clicar nos botões nativos do OTClient
  defenseToggle.mudarModoAtaque = function(targetButton)
    if targetButton then
        pcall(function() targetButton:onClick() end)
    end
  end
  -- Macro principal rodando a cada 100ms
  macro(100, function()
    if not g_game.isOnline() or not storage[defenseToggle.panelName].enabled then return end
    
    local root = g_ui.getRootWidget()
    if not root then return end

    local player = g_game.getLocalPlayer()
    if not player then return end

    -- Captura os botões da interface nativa do OTClient
    local btnBalanced = root:recursiveGetChildById("fightBalancedBox")
    local btnDefensive = root:recursiveGetChildById("fightDefensiveBox")
    
    if not btnBalanced or not btnDefensive then return end

    local hpAtual = player:getHealthPercent()

    -- Verifica se o jogador está atualmente no modo DEFENSIVO
    local estaEmDefensive = (btnDefensive:isOn() or btnDefensive:isChecked())
    
    -- Verifica se o jogador está atualmente no modo BALANCEADO
    local estaEmBalanced = (btnBalanced:isOn() or btnBalanced:isChecked())

    -- LÓGICA DE ENTRADA: Se a vida cair e você estiver no Balanced -> vai para o Defensivo
    if hpAtual < storage[defenseToggle.panelName].hp then
        if estaEmBalanced then
            defenseToggle.mudarModoAtaque(btnDefensive)
        end
    else
        -- LÓGICA DE RETORNO: Se a vida subiu e você ainda está preso no Defensivo -> volta para o Balanced
        if estaEmDefensive then
            defenseToggle.mudarModoAtaque(btnBalanced)
        end
    end
  end)
end
UI.Separator()
--Swap Ring/Necklace
storage.swapRingPve = storage.swapRingPve or 0
storage.swapRingPvp = storage.swapRingPvp or 0
storage.swapNeckPve = storage.swapNeckPve or 0
storage.swapNeckPvp = storage.swapNeckPvp or 0
storage.swapMacroEnabled = storage.swapMacroEnabled or false

local ui = setupUI([[
Panel
  height: 130
  
  BotSwitch
    id: macroToggle
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Swap Trinckets

  Label
    id: ringLabel
    anchors.top: macroToggle.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 5
    text: Ring (PvE/PvP):

  BotItem
    id: ringPve
    anchors.top: ringLabel.bottom
    anchors.right: parent.horizontalCenter
    margin-top: 3
    margin-right: 5
    width: 34
    height: 34

  BotItem
    id: ringPvp
    anchors.top: ringLabel.bottom
    anchors.left: parent.horizontalCenter
    margin-top: 3
    margin-left: 5
    width: 34
    height: 34

  Label
    id: neckLabel
    anchors.top: ringPve.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 5
    text: Neck (PvE/PvP):

  BotItem
    id: neckPve
    anchors.top: neckLabel.bottom
    anchors.right: parent.horizontalCenter
    margin-top: 3
    margin-right: 5
    width: 34
    height: 34

  BotItem
    id: neckPvp
    anchors.top: neckLabel.bottom
    anchors.left: parent.horizontalCenter
    margin-top: 3
    margin-left: 5
    width: 34
    height: 34
]])

-- Sincroniza o estado visual do botão no topo
ui.macroToggle:setOn(storage.swapMacroEnabled)
ui.macroToggle.onClick = function(widget)
    storage.swapMacroEnabled = not storage.swapMacroEnabled
    widget:setOn(storage.swapMacroEnabled)
end
-- Vincula os slots às variáveis salvas do bot
ui.ringPve:setItemId(storage.swapRingPve)
ui.ringPve.onItemChange = function(w) storage.swapRingPve = w:getItemId() end
ui.ringPvp:setItemId(storage.swapRingPvp)
ui.ringPvp.onItemChange = function(w) storage.swapRingPvp = w:getItemId() end
ui.neckPve:setItemId(storage.swapNeckPve)
ui.neckPve.onItemChange = function(w) storage.swapNeckPve = w:getItemId() end
ui.neckPvp:setItemId(storage.swapNeckPvp)
ui.neckPvp.onItemChange = function(w) storage.swapNeckPvp = w:getItemId() end
-- Função de busca em mochilas abertas
local function buscarItemNaBolsa(id)
    if not id or id <= 0 then return nil end
    local item = findItem(id)
    if item then return item end
    for _, container in pairs(g_game.getContainers()) do
        for _, slotItem in pairs(container:getItems()) do
            if slotItem:getId() == id then
                return slotItem
            end
        end
    end
    return nil
end
-- Mapeamento dos slots nativos de inventário do Tibia 8.54 (Apenas Ring e Neck)
local pieces = {
  { slotId = 9, getPveId = function() return storage.swapRingPve end,   getPvpId = function() return storage.swapRingPvp end },   
  { slotId = 2, getPveId = function() return storage.swapNeckPve end,   getPvpId = function() return storage.swapNeckPvp end }    
}
-- Macro integrado ao botão superior e aos botões de combate visuais
macro(200, function()
  if not storage.swapMacroEnabled then return end
  if not g_game.isOnline() then return end
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end
  local rootWidget = g_ui.getRootWidget()
  if not rootWidget then return end
  local btnBalanced = rootWidget:recursiveGetChildById("fightBalancedBox")
  local btnOffensive = rootWidget:recursiveGetChildById("fightOffensiveBox")
  local isPvE = true 
  if btnBalanced and (btnBalanced:isOn() or btnBalanced:isChecked()) then
      isPvE = false 
  elseif btnOffensive and (btnOffensive:isOn() or btnOffensive:isChecked()) then
      isPvE = true  
  end
  for _, p in ipairs(pieces) do
    local targetItemId = isPvE and p.getPveId() or p.getPvpId()  
    if targetItemId and targetItemId > 0 then
      local currentItem = localPlayer:getInventoryItem(p.slotId)   
      if not currentItem or currentItem:getId() ~= targetItemId then
        local itemToEquip = buscarItemNaBolsa(targetItemId)     
        if itemToEquip then
          g_game.move(itemToEquip, {x = 65535, y = p.slotId, z = 0}, 1)
        end
      end
    end
  end
end)
UI.Label("-----------------------------------"):setColor('#FFDEAD')
UI.Label("~ HUD Hotkeys ~"):setColor('#DEB887')
UI.Label("-----------------------------------"):setColor('#FFDEAD')
--    CONTROLE CAVE/TARGET (VERSÃO SUPREMA PURISTA - ZERO DEPENDÊNCIAS DE TEMPO)
local ultimoApertoCave = 0
local ultimoApertoTarget = 0
local alternandoMotoresAtivo = false
local motorAlvoLigar = false
local timestampAlternancia = 0
local passoSincronismo = 0
local function alternarMotoresHunt(forcarLigar)
    motorAlvoLigar = forcarLigar
    alternandoMotoresAtivo = true
    timestampAlternancia = os.clock()
    passoSincronismo = 1
end
-- 1. START/STOP CAVEBOT
hotkey("CTRL+1", function()
    local agora = os.clock()
    if agora - ultimoApertoCave < 0.3 then return end 
    if SMK_MudandoDeMapaMute then return end
    ultimoApertoCave = agora
    if CaveBot and type(CaveBot.isOn) == "function" then
        if CaveBot.isOn() then
            if type(CaveBot.stop) == "function" then CaveBot.stop() 
            elseif type(CaveBot.setOff) == "function" then CaveBot.setOff() end
        else
            if type(CaveBot.start) == "function" then CaveBot.start() 
            elseif type(CaveBot.setOn) == "function" then CaveBot.setOn() end
        end
    end
end)
-- 2. START/STOP TARGETBOT
hotkey("CTRL+2", function()
    local agora = os.clock()
    if agora - ultimoApertoTarget < 0.3 then return end 
    if SMK_MudandoDeMapaMute then return end
    ultimoApertoTarget = agora
    if TargetBot and type(TargetBot.isOn) == "function" then
        if TargetBot.isOn() then
            if type(TargetBot.stop) == "function" then TargetBot.stop() 
            elseif type(TargetBot.setOff) == "function" then TargetBot.setOff() end
        else
            if type(TargetBot.start) == "function" then TargetBot.start() 
            elseif type(TargetBot.setOn) == "function" then TargetBot.setOn() end
        end
    end
end)
-- 3. ESCALONADOR NATAL DE FRAMES
macro(30, function()
    if not alternandoMotoresAtivo then return end
    local agora = os.clock()
    if passoSincronismo == 1 then
        -- Passo 1: Liga ou desliga o CaveBot
        if motorAlvoLigar then
            if CaveBot and type(CaveBot.setOn) == "function" then CaveBot.setOn()
            elseif CaveBot and type(CaveBot.start) == "function" then CaveBot.start() end
        else
            if CaveBot and type(CaveBot.setOff) == "function" then CaveBot.setOff()
            elseif CaveBot and type(CaveBot.stop) == "function" then CaveBot.stop() end
        end
        passoSincronismo = 2
        timestampAlternancia = agora
    elseif passoSincronismo == 2 then
        -- Passo 2: Espera um fôlego de pelo menos 50 milissegundos (0.05s) para não chocar as threads
        if agora - timestampAlternancia >= 0.05 then
            if motorAlvoLigar then
                if TargetBot and type(TargetBot.setOn) == "function" then TargetBot.setOn()
                elseif TargetBot and type(TargetBot.start) == "function" then TargetBot.start() end
            else
                if TargetBot and type(TargetBot.setOff) == "function" then TargetBot.setOff()
                elseif TargetBot and type(TargetBot.stop) == "function" then TargetBot.stop() end
            end
            -- Finaliza o ciclo de alternância completamente
            alternandoMotoresAtivo = false
            passoSincronismo = 0
        end
    end
end)
-- 4. GANCHO OPERACIONAL DO PAINEL
if CaveBot and TargetBot then
    if type(CaveBot.isOn) == "function" then
        pcall(function()
            CaveBot.Extensions = CaveBot.Extensions or {}
            CaveBot.Extensions.MasterControl = function()
                local caveLigado = CaveBot.isOn()
                local targetLigado = TargetBot.isOn()
                
                if caveLigado or targetLigado then
                    alternarMotoresHunt(false)
                else
                    alternarMotoresHunt(true)
                end
            end
        end)
    end
end
-- BugMap AWSD/Setas/NumPad (Versão Definitiva Purificada e Sem Lag)
local consoleModule = modules.game_console
local cachedPos = {x = 0, y = 0, z = 0} 
local ultimoUsoDash = 0
local offsetsTeclas = {
    {tecla = 'w', x = 0,  y = -5},
    {tecla = 'd', x = 5,  y = 0},
    {tecla = 's', x = 0,  y = 5},
    {tecla = 'a', x = -5, y = 0},
    {tecla = 'e', x = 3,  y = -3},
    {tecla = 'c', x = 3,  y = 3},
    {tecla = 'z', x = -3, y = 3},
    {tecla = 'q', x = -3, y = -3}
}
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
    if cachedPos.x < 100 or cachedPos.y < 100 or cachedPos.x > 34000 or cachedPos.y > 34000 then
        return false
    end
    local tile = g_map.getTile(cachedPos)
    if tile then
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
dash = macro(60, 'Bug Map', 'CTRL+3', function()
    if not g_game.isOnline() then return end
    
    if consoleModule and type(consoleModule.isChatEnabled) == "function" and consoleModule:isChatEnabled() then
        return
    end
    local gk = modules.corelib.g_keyboard
    if not gk or type(gk.isKeyPressed) ~= "function" then return end
    local agora = g_clock and g_clock.getMillis() or (os.clock() * 1000)
    if agora - ultimoUsoDash < 50 then return end
    for i = 1, #offsetsTeclas do
        local config = offsetsTeclas[i]
        if gk.isKeyPressed(config.tecla) then
            checkPos(config.x, config.y)
            ultimoUsoDash = agora
            return
        end
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
--HoldAttack Otimizado (Blindado contra erro de Invalid Stackpos no Battle)
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
  
  if g_keyboard.isKeyPressed("Escape") then
    storage.uiTargetId = nil
    storage.manualStop = true
    return
  end
  
  if storage.manualStop then
    return
  end
  
  if storage.uiTargetId then
    local reattackDone = false
    
    -- Busca direta na lista de Battle de forma segura por API de Criaturas
    if modules.game_battle and modules.game_battle.battleButtons then
      for _, button in pairs(modules.game_battle.battleButtons) do
        if button and button.creature and button.creature:getId() == storage.uiTargetId then
          if button.creature:getHealthPercent() > 0 then
            -- CORREÇÃO SUPREMA: Ataca a criatura diretamente por C++ nativo.
            -- Remove a simulação de mouse que quebrava o stackpos do client.
            g_game.attack(button.creature)
            reattackDone = true
          end
          break
        end
      end
    end
    
    -- Se o monstro sumiu do Battle mas ainda está na tela (Spectators)
    if not reattackDone then
      local pos = player:getPosition()
      if pos then
        local specs = g_map.getSpectators(pos, false) or {}
        for _, spec in ipairs(specs) do
          if spec and spec:getId() == storage.uiTargetId and spec:getHealthPercent() > 0 then
            g_game.attack(spec)
            break
          end
        end
      end
    end
  end
end)

if chaseatk and chaseatk.setOff then
    chaseatk.setOff()
end

-- Enemy (Versão Corrigida - Apenas Radar, Ataque PVP e Anti-VIP Supremo)
local function definirModoAtaque(modo)
    local fightMode = 2
    if modo == "offensive" then
        fightMode = 1
    end
    
    if g_game and type(g_game.setFightMode) == "function" then
        pcall(function() g_game.setFightMode(fightMode) end)
    else
        local rootWidget = g_ui.getRootWidget()
        if not rootWidget then return end 
        local idBotao = modo == "balanced" and "fightBalancedBox" or "fightOffensiveBox"
        local targetButton = rootWidget:recursiveGetChildById(idBotao)
        if targetButton then
            pcall(function() targetButton:onClick() end)
        end
    end
end
local function estaNaVipList(nomeJogador)
    if not nomeJogador or nomeJogador == "" then return false end
    if not g_game or type(g_game.getVips) ~= "function" then return false end
    
    local vips = g_game.getVips() or {}
    local nomeLimpoAlvo = string.lower(string.trim(tostring(nomeJogador)))
    
    for i, vip in pairs(vips) do
        if vip then
            local nomeVipRaw = nil
            if type(vip) == "table" and vip.name then
                nomeVipRaw = vip.name
            elseif type(vip) == "table" and vip[1] then
                nomeVipRaw = vip[1]
            end
            
            if nomeVipRaw then
                local nomeVip = string.lower(string.trim(tostring(nomeVipRaw)))
                if nomeVip == nomeLimpoAlvo then
                    return true
                end
            end
        end
    end
    return false
end
local estadoAnteriorMacro = false
enemy = macro(150, 'Enemy', "ALT+3", function()
    if not g_game.isOnline() then return end
    if not estadoAnteriorMacro then
        definirModoAtaque("balanced")
        estadoAnteriorMacro = true
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
            local specName = creature:getName()
            
            if specHp and specHp > 0 and specPos and specPos.z == myPos.z then
                if not estaNaVipList(specName) then
                    local specSkull = creature:getSkull()
                    local specShield = creature:getShield()
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
    end
    
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        pcall(function() g_game.attack(actualTarget) end)
    end
end)
macro(500, function()
    if enemy and type(enemy.isOn) == "function" then
        if not enemy.isOn() and estadoAnteriorMacro then
            estadoAnteriorMacro = false
        end
    end
end)
-- X-Sense
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
    local comandoReal = nil
    for i = 1, #args do
        if type(args[i]) == "string" then
            local textoLimpo = args[i]:trim()
            if string.sub(textoLimpo, 1, 1):lower() == 'x' then
                comandoReal = textoLimpo
                break
            end
        end
    end
    if not comandoReal then return end
    local restoTexto = string.sub(comandoReal, 2, #comandoReal):trim()
    local primeiroCharResto = string.sub(restoTexto, 1, 1)
    if primeiroCharResto == "!" or primeiroCharResto == "/" or primeiroCharResto == "#" then
        return
    end
    if restoTexto == "" or restoTexto == "0" then
        storage.Sense = ""
        modules.game_textmessage.displayStatusMessage("[xSense] Alvo limpado com sucesso!")
        return true
    end
    storage.Sense = restoTexto
    say('sense "' .. storage.Sense)
    return true
end)
-- REVIDE PK
local botsDesligadosPVP = false
local ultimoModoAtaque = nil
local ultimoTempoTentativaAtaque = 0
local ultimaPosX = 0
local ultimaPosY = 0
local ultimoTickRadar = 0
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
revidePKMacro = macro(250, 'Revide PK', function()
    if not g_game.isOnline() then return end
    
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end
    local myPos = localPlayer:getPosition()
    if not myPos then return end
    local tempoAtual = os.clock() * 1000
    
    local andou = (myPos.x ~= ultimaPosX or myPos.y ~= ultimaPosY)
    if not andou and (tempoAtual - ultimoTickRadar < 400) then
        return
    end
    ultimoTickRadar = tempoAtual
    ultimaPosX, ultimaPosY = myPos.x, myPos.y  
    local agressorTarget = nil
    local agressorHp = 101
    local agressorDist = 100
    local spectators = getSpectators(myPos)
    for i = 1, #spectators do
        local creature = spectators[i]
        if creature and creature:isPlayer() and creature ~= localPlayer then
            local targetPos = creature:getPosition()
            local dx = math.abs(myPos.x - targetPos.x)
            local dy = math.abs(myPos.y - targetPos.y)
            
            if dx <= 13 and dy <= 7 and targetPos.z == myPos.z then
                local estaMeAtacando = false
                if creature.isAttacking then
                    estaMeAtacando = creature:isAttacking()
                else
                    estaMeAtacando = (g_game.getAttackingCreature() == creature or creature:isTimedSquareVisible())
                end
                
                if estaMeAtacando then
                    local specHp = creature:getHealthPercent()
                    local specDist = dx + dy
                    
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
        if not botsDesligadosPVP then
            if CaveBot and CaveBot.setOff then CaveBot.setOff() end
            if TargetBot and TargetBot.setOff then TargetBot.setOff() end  
            definirModoAtaque("balanced")
            botsDesligadosPVP = true
        end
        
        if g_game.getAttackingCreature() ~= agressorTarget and (tempoAtual - ultimoTempoTentativaAtaque >= 1000) then
            g_game.attack(agressorTarget) 
            ultimoTempoTentativaAtaque = tempoAtual
        end
    else
        if botsDesligadosPVP then
            local alvoAtualJogo = g_game.getAttackingCreature()
            if not alvoAtualJogo or not alvoAtualJogo:isPlayer() then
                if CaveBot and CaveBot.setOn then CaveBot.setOn() end
                if TargetBot and TargetBot.setOn then TargetBot.setOn() end   
                botsDesligadosPVP = false
            end
        end
    end
end)
--SAFE FIGHT SYNC
local ultimoEstadoSeguro = nil
local botaoBalancedCache = nil
macro(300, function()
    if not g_game.isOnline() then return end
    if not botaoBalancedCache then
        local rootWidget = g_ui.getRootWidget()
        if rootWidget then
            botaoBalancedCache = rootWidget:recursiveGetChildById("fightBalancedBox")
        end
    end
    if not botaoBalancedCache then return end
    local estaNoBalanced = (botaoBalancedCache:isOn() or botaoBalancedCache:isChecked())
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
UI.Label("-----------------------------------"):setColor('#FFDEAD')
-- HUD PVE/PVP PREMIUM - SMK CUSTOM v4.2
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
    color: #FFDEAD
    font: verdana-11px-rounded
    background-color: #000000
    anchors.top: parent.top
    margin-top: 25
    opacity: 0.87
    text-auto-resize: true
    text-align: center
  Label
    id: iconlayer2
    height: 12
    color: #FFDEAD
    font: verdana-11px-rounded
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
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
    background-color: #000000
    anchors.top: parent.top
    margin-top: 235
    opacity: 0.87
    text-auto-resize: true
    text-align: center
  Label
    id: skills3
    height: 12
    color: #FFDEAD
    font: verdana-11px-rounded
    background-color: #000000
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
    background-color: #000000
    anchors.top: parent.top
    margin-top: 265
    opacity: 0.87
    text-auto-resize: true
    text-align: center
]], modules.game_interface.getMapPanel())
-- PvE/PvP HUD Painel (Versão Ultra-Otimizada com Cache de Estado e Texto)
local hudCache = {}
local ultimoIdPlayerCache = 0
macro(300, function()
  if not g_game.isOnline() or not pvehud then return end
  local player = g_game.getLocalPlayer()
  if not player then return end 
  local playerIdAtual = player:getId() or 0
  if playerIdAtual ~= ultimoIdPlayerCache then
    ultimoIdPlayerCache = playerIdAtual
    hudCache.estaticos = false
    hudCache.cave = nil
    hudCache.target = nil
    hudCache.dash = nil
    hudCache.buffsinfo = nil
    hudCache.mwallinfo = nil
    hudCache.chaseatk = nil
    hudCache.enemy = nil
    hudCache.xsense = nil
    hudCache.txtLvl = nil
    hudCache.txtMl = nil
    hudCache.txtSk = nil
  end
  if not hudCache.estaticos then
    if pvehud.iconlayer then pvehud.iconlayer:setText("     ~ [Smk Custom - v4.2] ~   ") pvehud.iconlayer:setColor("#FFDEAD") end
    if pvehud.iconlayer2 then pvehud.iconlayer2:setText(" ~ [Instagram: @cafeh_ofc] ~  ") pvehud.iconlayer2:setColor("#FFDEAD") end
    if pvehud.tab1 then pvehud.tab1:setText("           ~           [PvE]           ~       ") pvehud.tab1:setColor("#FFFFF0") end
    if pvehud.tab2 then pvehud.tab2:setText("           ~           [PvP]           ~       ") pvehud.tab2:setColor("#FFFFF0") end
    if pvehud.tab3 then pvehud.tab3:setText("           ~         [Skills]        ~         ") pvehud.tab3:setColor("#FFFFF0") end
    hudCache.estaticos = true
  end
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
    if hudCache[labelKey] ~= estadoAtual then
      pvehud[labelKey]:setText(textoBase)
      hudCache[labelKey] = estadoAtual
    end
    pvehud[labelKey]:setOpacity(0.87)
    local corAlvo = estadoAtual and "#32CD32" or "#FF6347"
    pvehud[labelKey]:setColor(corAlvo)
  end
  atualizarBotaoHUD("cave", CaveBot, "~ CaveBot: [Ctrl+1]")
  atualizarBotaoHUD("target", TargetBot, "~ Target: [Ctrl+2]")
  atualizarBotaoHUD("dash", dash, "~ BugMap: [Ctrl+3]")
  atualizarBotaoHUD("buffsinfo", buffs, "~ Haste & Buff: [Ctrl+4]")
  atualizarBotaoHUD("mwallinfo", mwall, "~ MWall on Target: [Alt+1]")
  atualizarBotaoHUD("chaseatk", chaseatk, "~ Hold Attack: [Alt+2]")
  atualizarBotaoHUD("enemy", enemy, "~ Enemy: [Alt+3]")
  atualizarBotaoHUD("xsense", xsense, "~ Auto xSense: [Alt+4]")
  local lvl, lvlPct = player:getLevel(), player:getLevelPercent()
  local ml, mlPct = player:getMagicLevel(), player:getMagicLevelPercent()
  local sk, skPct = player:getSkillLevel(2), player:getSkillLevelPercent(2)
  if lvl and lvl > 0 then
    local txtLvl = "~ Level: " .. lvl .. " - (" .. lvlPct .. "%)"
    if pvehud.skills1 and hudCache.txtLvl ~= txtLvl then
      pvehud.skills1:setText(txtLvl)
      hudCache.txtLvl = txtLvl
    end
    if pvehud.skills1 then pvehud.skills1:setColor("#8FBC8F") pvehud.skills1:setOpacity(0.87) end
    local txtMl = "~ Reiatsu: " .. ml .. " - (" .. mlPct .. "%)"
    if pvehud.skills3 and hudCache.txtMl ~= txtMl then
      pvehud.skills3:setText(txtMl)
      hudCache.txtMl = txtMl
    end
    if pvehud.skills3 then pvehud.skills3:setColor("#DDA0DD") pvehud.skills3:setOpacity(0.87) end
    local txtSk = "~ Weapon: " .. sk .. " - (" .. skPct .. "%)"
    if pvehud.skills8 and hudCache.txtSk ~= txtSk then
      pvehud.skills8:setText(txtSk)
      hudCache.txtSk = txtSk
    end
    if pvehud.skills8 then pvehud.skills8:setColor("#B0E0E6") pvehud.skills8:setOpacity(0.87) end
  end
end)
-- Ice Hud HP Percent
macro(200, function()
local hp = g_ui.getRootWidget():recursiveGetChildById("healthCircleFront")
hp:setText("   ".. hppercent().. "             ") 
hp:setColor("white")
end)
-- Ice Hud MP Percent
macro(200, function()
local hp = g_ui.getRootWidget():recursiveGetChildById("manaCircleFront")
hp:setText("                   ".. manapercent().. "          ") 
hp:setColor("white")
end)
-- Auto Bless
local player = g_game.getLocalPlayer()
if player and player:getBlessings() == 0 then
    local itemBless = findItem(10258)
    if not itemBless then
        print("[Loader] Soul Bless nao encontrada, nao foi possivel renovar.")
    else
        say("!bless")
        use(itemBless)
        
        schedule(1000, function()
            local pCheck = g_game.getLocalPlayer()
            if pCheck and pCheck:getBlessings() == 0 then
                print("[Loader] Soul Bless renovada com sucesso.")
            end
        end)
    end
end
-- CaveBot Creator Always Opened
local cachedPanel = nil
local cachedButton = nil
local procurouComponentes = false
macro(1000, function()
    local botWindow = modules.game_bot.botWindow
    if not botWindow then return end
    if not procurouComponentes then
        cachedPanel = botWindow:recursiveGetChildById('CaveBot.Editor')
        cachedButton = botWindow:recursiveGetChildById('createCavebotBtn') or botWindow:recursiveGetChildById('createCavebot')
        procurouComponentes = true
    end
    if cachedPanel and not cachedPanel:isVisible() then
        cachedPanel:show()
        if cachedButton and cachedButton.setOn then
            cachedButton:setOn(true)
        end
    end
end)
-- MAGIC WALL TIMER
local magicWallId = 10980
local ultimoProcessoAdd = 0
local ultimoProcessoRemove = 0
local temSetTimer = nil
local temGetTimer = nil
local function checarMetodosTile(tile)
    if temSetTimer == nil and tile then
        temSetTimer = (type(tile.setTimer) == "function")
        temGetTimer = (type(tile.getTimer) == "function")
    end
end
onAddThing(function(tile, thing)
    if not thing or not tile or thing:getId() ~= magicWallId then 
        return 
    end
    local agora = os.clock()
    if agora - ultimoProcessoAdd < 0.01 then
        return
    end
    ultimoProcessoAdd = agora
    checarMetodosTile(tile)
    if temGetTimer and tile:getTimer() > 0 then 
        return 
    end
  
    if temSetTimer then
        tile:setTimer(20000) 
    end
end)
onRemoveThing(function(tile, thing)
    if not thing or not tile or thing:getId() ~= magicWallId then 
        return 
    end
    local agora = os.clock()
    if agora - ultimoProcessoRemove < 0.01 then
        return
    end
    ultimoProcessoRemove = agora
  
    checarMetodosTile(tile)
    if temSetTimer then
        tile:setTimer(0) 
    end
end)
-- TARGET HEALTH BAR
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
local targetCache = { name = "", percent = -1, visible = false, lastMapWidth = 0, lastMapX = 0 }
local function updateTargetWidget(targetNameText, percent, hasTarget)
    local target = panel['targetWidget']
    if not target then return end
    if targetCache.visible ~= hasTarget then
        target:setVisible(hasTarget)
        targetCache.visible = hasTarget
    end
    if not hasTarget then return end
    local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
    if mapPanel then
        local mapWidth = mapPanel:getWidth()
        local mapX = mapPanel:getX()
     
        if targetCache.lastMapWidth ~= mapWidth or targetCache.lastMapX ~= mapX then
            local posX = mapX + (mapWidth / 2) - (target:getWidth() / 2)
            local posY = 150
            
            target:setPosition({ x = posX, y = posY })
            targetCache.lastMapWidth = mapWidth
            targetCache.lastMapX = mapX
        end
    end
    if targetCache.percent ~= percent or targetCache.name ~= targetNameText then
        target.targetTitle:setText(targetNameText)    
        target.progressBar:setText(string.format("%d%%", percent))
        target.progressBar:setPercent(percent)
        target.progressBar:setBackgroundColor(getColorByPercent(percent, lifeColors))
        
        targetCache.percent = percent
        targetCache.name = targetNameText
    end
end
macro(400, function()
    if not g_game.isOnline() then return end 
    local name, percent = "", 100
    local hasTarget = false   
    
    local target = g_game.getAttackingCreature()
    if target then
        name = target:getName()
        percent = target:getHealthPercent()
        hasTarget = true
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
-- Creature_Priority (Corrigido para evitar troca frenética de alvos e esquivas)
local specialMonsters = {"elite", "boss", "unleashed", "gotei 13 king", "oversaturated", "true bankai", "dungeon"}
local function isMonsterSpecial(creatureName)
  if not creatureName then return false end
  local nomeLimpo = string.lower(creatureName)
  for i = 1, #specialMonsters do
    if string.find(nomeLimpo, specialMonsters[i], 1, true) then
      return true
    end
  end
  return false
end
TargetBot.Creature.calculatePriority = function(creature, config, path)
  local priority = 0
  local path_length = #path
  if g_game.getAttackingCreature() == creature then
    priority = priority + 10 -- Aumentado para manter o foco no alvo atual por mais tempo
  end
  if path_length > config.maxDistance then
    return priority
  end 
  priority = priority + config.priority
  -- PROGRESSÃO SUAVE: Evita picos de 5000 pontos que fazem o bot surtar mudando de alvo.
  -- Agora os monstros colados ou muito próximos mantêm uma pontuação firme e estável.
  if path_length == 1 then
    priority = priority + 100 -- Monstro colado tem preferência
  elseif path_length == 2 then
    priority = priority + 50  -- Monstro a 2 passos ainda é muito relevante
  elseif path_length <= 4 then
    priority = priority + 20  -- Monstro a 3-4 passos é considerado
  end
  -- 2. AJUSTE CRÍTICO DE ELITES: Elites/Bosses ganham um peso fixo maior 
  -- para que o bot sempre foque neles antes dos monstros comuns do mesmo raio.
  if isMonsterSpecial(creature:getName()) then
    priority = priority + 500
  end
  -- extra priority for low health
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
--TARGETBOT INTEGRADO: FILTRO DE PARTY, ANTI-LURE ALHEIO E REGRA DE GUILD V4 CORRIGIDO SEM RETROCESSO
local specialMonsters = {"elite", "boss", "unleashed", "gotei 13 king", "oversaturated", "true bankai", "dungeon"}
local function isMonsterSpecial(creatureName)
    if not creatureName then return false end
    local nomeLimpo = string.lower(creatureName)
    for i = 1, #specialMonsters do
        if string.find(nomeLimpo, specialMonsters[i], 1, true) then
            return true
        end
    end
    return false
end

local cacheIdsParty = {}
local ultimoTempoCheckParty = 0

-- 2. GANCHO DE COMPORTAMENTO WITH TRAVA DE PARTY E INIMIGOS ALHEIOS
if TargetBot and TargetBot.Creature and type(TargetBot.Creature.calculateParams) == "function" then
    local oldCalculateParams = TargetBot.Creature.calculateParams
    local getLocalPlayer = g_game.getLocalPlayer
    local isOnline = g_game.isOnline
    local monstrosProcessadosNoCiclo = 0
    local ultimoTickCiclo = 0
    
    TargetBot.Creature.calculateParams = function(creature, path, ...)
        local player = getLocalPlayer()
        if not player or not creature then return { danger = 0, priority = 0 } end
        local cName = creature:getName()
        if not cName then return { danger = 0, priority = 0 } end
        local nomeLimpoCreature = string.lower(cName)
        
        -- [REGRA SUPREMA DE GUILD]: SE HOUVER "GUILD" NO NOME, ATACA NA HORA!
        if string.find(nomeLimpoCreature, "guild", 1, true) then
            local res = oldCalculateParams(creature, path, ...)
            if res then
                res.danger = 10
                res.priority = 10000 
                return res
            end
            return { danger = 10, priority = 10000 }
        end
        
        -- OTIMIZAÇÃO INTERNA DO TARGET: Se o monstro estiver fora do andar ou muito longe na tela (X ou Y > 7)
        local pPos = player:getPosition()
        local cPos = creature:getPosition()
        if not pPos or not cPos or pPos.z ~= cPos.z then
            return { danger = 0, priority = 0 }
        end
        
        local distX = math.abs(pPos.x - cPos.x)
        local distY = math.abs(pPos.y - cPos.y)
        if distX > 7 or distY > 7 then
            return { danger = 0, priority = 0 }
        end

        -- [MODO PADRÃO]: RESTO DA LOGICA PARA MONSTROS COMUNS E ELITES
        local agora = os.clock() * 1000
        if agora - ultimoTickCiclo > 50 then
            monstrosProcessadosNoCiclo = 0
            ultimoTickCiclo = agora
        end
        
        -- Sincronização do cache da Party (Apenas a cada 5 segundos)
        if agora - ultimoTempoCheckParty >= 5000 then
            cacheIdsParty = {}
            if pcall(isOnline) and isOnline() then
                local members = type(g_game.getPartyList) == "function" and g_game.getPartyList()
                if members then
                    for m = 1, #members do
                        local member = members[m]
                        if member and member:getId() then
                            cacheIdsParty[member:getId()] = true
                        end
                    end
                end
            end
            ultimoTempoCheckParty = agora
        end
        
        local ehElite = isMonsterSpecial(cName)
        local deveIgnorarMonstro = false
        
        -- CHECAGEM DIRETA DE TARGET ID (Método Rápido em C++)
        local mTargetId = 0
        if type(creature.getTargetId) == "function" then mTargetId = creature:getTargetId() or 0
        elseif creature.targetId then mTargetId = creature.targetId
        elseif type(creature.getTarget) == "function" then
            local tgt = creature:getTarget()
            if tgt then mTargetId = tgt:getId() or 0 end
        end
        
        -- Se o Elite tiver um alvo definido que não seja você e não seja da Party
        if ehElite and mTargetId > 0 and mTargetId ~= player:getId() and not cacheIdsParty[mTargetId] then
            deveIgnorarMonstro = true
        end
        
        -- IDENTIFICAÇÃO DE ALVOS ALHEIOS POR PROXIMIDADE
        if not deveIgnorarMonstro then
            local specs = g_map.getSpectatorsInRange(cPos, false, 1, 1)
            if specs then
                for s = 1, #specs do
                    local spec = specs[s]
                    if spec and spec:isPlayer() and spec:getId() ~= player:getId() then
                        local sPos = spec:getPosition()
                        if sPos and sPos.z == cPos.z then
                            local estranhoAlvoId = spec:getId()
                            if estranhoAlvoId and not cacheIdsParty[estranhoAlvoId] then
                                deveIgnorarMonstro = true
                                break
                            end
                        end
                    end
                end
            end
        end
        
        -- CORREÇÃO CRÍTICA: Se deve ignorar o monstro, zera a relevância dele no target
        if deveIgnorarMonstro then
            local res = oldCalculateParams(creature, path, ...)
            if res then
                res.danger = 0
                res.priority = 0
                return res
            end
            return { danger = 0, priority = 0 }
        end
        
        -- OTIMIZAÇÃO DE CICLO DE CPU (Evita recalcular se a fila do frame já estiver cheia)
        if monstrosProcessadosNoCiclo >= 3 then
            local res = oldCalculateParams(creature, path, ...)
            if res then res.priority = 1 return res end
            return { danger = 0, priority = 0 }
        end
        
        monstrosProcessadosNoCiclo = monstrosProcessadosNoCiclo + 1
        return oldCalculateParams(creature, path, ...)
    end
end
print("[Loader] TargetBot otimizado com sucesso.")
