---@class VoiceManager
---@field IsEnabled boolean
---@field IsConnected boolean
---@field _pluginState integer
---@field IsNuiReady boolean
---@field TeamSpeakName string
---@field IsAlive boolean
---@field Configuration Configuration
---@field _voiceClients table<integer, VoiceClient>
---@field _phoneCallClients table<integer, VoiceClient>
---@field VoiceClients VoiceClient[]
---@field RadioTowers Tower[]
---@field RangeNotification Notification
---@field WebSocketAddress string
---@field _voiceRange float
---@field _cachedVoiceRange float
---@field _canSendRadioTraffic boolean
---@field PrimaryRadioChannel string
---@field PrimaryRadioChangeHandlerCookies integer[]
---@field SecondaryRadioChannel string
---@field SecondaryRadioChangeHandlerCookies integer[]
---@field RadioTrafficStates RadioTraffic[]
---@field ActiveRadioTraffic RadioTrafficState[]
---@field IsMicClickEnabled boolean
---@field IsUsingMegaphone boolean
---@field IsMicrophoneMuted boolean
---@field IsMicrophoneEnabled boolean
---@field IsSoundMuted boolean
---@field IsSoundEnabled boolean
---@field RadioVolume number
---@field IsRadioSpeakerEnabled boolean
---@field _changeHandlerCookies integer[]
---@field PlayerList Player[]
VoiceManager = {}
VoiceManager.__index = VoiceManager

function VoiceManager.new()
  local meta = {
    __index = function(list, key)
      if list.functions[key] and type(list.functions[key]) == "function" then
        return list.functions[key]()
      end
    end
  }

  setmetatable({}, VoiceManager)
  local self = setmetatable(VoiceManager, meta)
  self.functions = {}
  self.IsEnabled = nil
  self.IsConnected = nil
  self._pluginState = GameInstanceState.NotInitiated

  self.IsNuiReady = nil
  self.TeamSpeakName = nil
  self.functions.IsAlive = function()
    return GamePlayer.GetIsAlive()
  end

  self.Configuration = Configuration
  self._voiceClients = {}
  self._phoneCallClients = {}
  self.functions.VoiceClients = function()
    table.values(self._voiceClients)
  end

  self.RadioTowers = nil
  self.RangeNotification = Configuration.VoiceRangeNotification
  self.WebSocketAddress = "lh.v10.network:38088"
  self._voiceRange = 0.0
  self._cachedVoiceRange = 0.0
  self._canSendRadioTraffic = true
  self._canReceiveRadioTraffic = true


  self.PrimaryRadioChannel = nil
  self.PrimaryRadioChangeHandlerCookies = {}
  self.SecondaryRadioChannel = nil
  self.SecondaryRadioChangeHandlerCookies = {}
  self.RadioTrafficStates = {}
  self.ActiveRadioTraffic = {}
  self.IsMicClickEnabled = true
  self.IsUsingMegaphone = nil
  self.IsMicrophoneMuted = nil
  self.IsMicrophoneEnabled = nil
  self.IsSoundMuted = nil
  self.IsSoundEnabled = nil
  self.RadioVolume = 1.0
  self.IsRadioSpeakerEnabled = nil
  self._changeHandlerCookies = {}
  self.functions.PlayerList = function()
    return GetServerPlayers()
  end

  exports("GetVoiceRange", function(...) 
    return self:GetVoiceRange(...) 
  end)
  exports("GetRadioChannel", function(...)
    return self:GetRadioChannel(...)
  end)
  exports("GetRadioVolume", function(...)
    return self:GetRadioVolume(...)
  end)
  exports("GetRadioSpeaker", function(...)
    return self:GetRadioSpeaker(...)
  end)
  exports("GetMicClick", function(...)
    return self:GetMicClick(...)
  end)
  exports("SetRadioChannel", function(...)
    return self:SetRadioChannel(...)
  end)
  exports("SetRadioVolume", function(...)
    return self:SetRadioVolume(...)
  end)
  exports("SetRadioSpeaker", function(...)
    return self:SetRadioSpeaker(...)
  end)
  exports("SetMicClick", function(...)
    return self:SetMicClick(...)
  end)
  exports("GetPluginState", function(...)
    return self:GetPluginState(...)
  end)
  exports("PlaySound", function(...)
    return self:PlaySound(...)
  end)

  table.insert(self._changeHandlerCookies,
    AddStateBagChangeHandler(State.SaltyChat_VoiceRange, nil, function(bagName, key, value, reserved, replicated)
      self:VoiceRangeChangeHandler(bagName, key, value, reserved, replicated)
    end))
  table.insert(self._changeHandlerCookies,
    AddStateBagChangeHandler(State.SaltyChat_IsUsingMegaphone, nil, function(bagName, key, value, reserved, replicated)
      self:MegaphoneChangeHandler(bagName, key, value, reserved, replicated)
    end))

  return self
end

---@param state GameInstanceState #W
function VoiceManager:SetPluginState(state)
  self._pluginState = state
  TriggerEvent(Event.SaltyChat_PluginStateChanged, state)
end

---@return integer
function VoiceManager:GetPluginState()
  return self._pluginState
end

---@param range float
function VoiceManager:SetVoiceRange(range)
  self._voiceRange = range
  TriggerEvent(Event.SaltyChat_VoiceRangeChanged, range)

  LocalPlayer.state:set(State.SaltyChat_VoiceRange, self._voiceRange, true)
end

---@return float
function VoiceManager:GetVoiceRange()
  return self._voiceRange
end

---@param value boolean
function VoiceManager:SetCanSendRadioTraffic(value)
  if self._canSendRadioTraffic == value or not self.Configuration.EnableRadioHardcoreMode then
    return
  end

  self._canSendRadioTraffic = value

  if not value then
    for _, radioTraffic in pairs(self.RadioTrafficStates) do
      if radioTraffic.Name == self.TeamSpeakName then
        if radioTraffic.RadioChannelName == self.PrimaryRadioChannel then
          self:OnPrimaryRadioReleased()
        elseif radioTraffic.RadioChannelName == self.SecondaryRadioChannel then
          self:OnSecondaryRadioReleased()
        end
      end
    end
  end
end

---@return boolean #I
function VoiceManager:GetCanSendRadioTraffic()
  return self._canSendRadioTraffic
end

function VoiceManager:SetCanReceiveRadioTraffic(value)
  if self._canReceiveRadioTraffic == value or not self.Configuration.EnableRadioHardcoreMode then
    return
  end

  self._canReceiveRadioTraffic = value

  ---@type RadioTraffic[]
  local filteredRadioTrafficStates = table.filter(self.RadioTrafficStates, function()
    return radioTraffic.Name ~= self.TeamSpeakName
  end)

  if value then
    for _, radioTraffic in pairs(filteredRadioTrafficStates) do
      self:ExecutePluginCommand(PluginCommand.new(
        Command.RadioCommunicationUpdate,
        self.Configuration.ServerUniqueIdentifier,
        RadioCommunication.new(
          radioTraffic.Name,
          radioTraffic.SenderRadioType,
          radioTraffic.ReceiverRadioType,
          false,
          radioTraffic.RadioChannelName == self.PrimaryRadioChannel or
          radioTraffic.RadioChannelName == self.SecondaryRadioChannel,
          radioTraffic.RadioChannelName == self.SecondaryRadioChannel,
          radioTraffic.Relays,
          self.RadioVolume
        )
      ))
    end
  else
    for _, radioTraffic in pairs(filteredRadioTrafficStates) do
      self:ExecutePluginCommand(PluginCommand.new(
        Command.StopRadioCommunication,
        self.Configuration.ServerUniqueIdentifier,
        RadioCommunication.new(
          radioTraffic.Name,
          RadioType.None,
          RadioType.None,
          false,
          radioTraffic.RadioChannelName == self.PrimaryRadioChannel or
          radioTraffic.RadioChannelName == self.SecondaryRadioChannel,
          radioTraffic.RadioChannelName == self.SecondaryRadioChannel
        )
      ))
    end
  end
end

---@return boolean #S
function VoiceManager:GetCanReceiveRadioTraffic()
  return self._canReceiveRadioTraffic
end

---@param primary boolean
---@return string
function VoiceManager:GetRadioChannel(primary)
  if primary then
    return self.PrimaryRadioChannel
  else
    return self.SecondaryRadioChannel
  end
end

---@return number
function VoiceManager:GetRadioVolume()
  return self.RadioVolume
end

---@return boolean
function VoiceManager:GetRadioSpeaker()
  return self.IsRadioSpeakerEnabled
end

---@return boolean
function VoiceManager:GetMicClick()
  return self.IsMicClickEnabled
end

---@param radioChannelName string
---@param primary boolean
function VoiceManager:SetRadioChannel(radioChannelName, primary)
  if (primary and self.PrimaryRadioChannel == radioChannelName) or
      (not primary and self.SecondaryRadioChannel == radioChannelName) then
    return
  end

  TriggerServerEvent(Event.SaltyChat_SetRadioChannel, radioChannelName, primary)
end

---@param volumeLevel number
function VoiceManager:SetRadioVolume(volumeLevel)
  if volumeLevel < 0.0 then
    self.RadioVolume = 0.0
  elseif volumeLevel > 1.6 then
    self.RadioVolume = 1.6
  else
    self.RadioVolume = volumeLevel
  end
end

---@param isRadioSpeakerEnabled boolean
function VoiceManager:SetRadioSpeaker(isRadioSpeakerEnabled)
  TriggerServerEvent(Event.SaltyChat_SetRadioSpeaker, isRadioSpeakerEnabled)
end

---@param isMicClickEnabled boolean
function VoiceManager:SetMicClick(isMicClickEnabled)
  self.IsMicClickEnabled = isMicClickEnabled
end

---@param bagName string
---@param key string #S
---@param value any
---@param reserved integer
---@param replicated boolean
function VoiceManager:VoiceRangeChangeHandler(bagName, key, value, reserved, replicated)
  if replicated or string.starts(bagName, "player:") then return end

  local serverId = tonumber(bagName:split(":"):last())
  if serverId == GamePlayer.ServerId then
    if self:GetVoiceRange() ~= value then
      self:SetVoiceRange(value)
    end

    return
  end

  ---@type VoiceClient
  local voiceClient = self._voiceClients[serverId]
  if voiceClient == nil then
    return
  end

  voiceClient.VoiceRange = value
end

---@param bagName string
---@param key string
---@param value any
---@param reserved integer
---@param replicated boolean
function VoiceManager:MegaphoneChangeHandler(bagName, key, value, reserved, replicated)
  -- print("[MegaphoneChangeHandler]", bagName, bagName:starts("player:"))
  if not bagName:starts("player:") then return end

  local serverId = tonumber(bagName:split(":"):last())
  local isUsingMegaphone = value and value.IsUsingMegaphone == true or false
  local teamSpeakName
  local distanceToMegaphoneVoiceClient
  local percentageVolume = nil

  if serverId == GamePlayer.ServerId then
    if replicated or value == nil then return end
    if not isUsingMegaphone then
      LocalPlayer.state:set(State.SaltyChat_IsUsingMegaphone, nil, true)
    end

    teamSpeakName = self.TeamSpeakName
  else
    ---@type VoiceClient
    local voiceClient = value and self:GetOrCreateVoiceClient(serverId, Util.GetTeamSpeakName(serverId))
    if voiceClient == nil or voiceClient.IsUsingMegaphone == isUsingMegaphone then
      return
    end

    teamSpeakName = voiceClient.TeamSpeakName
    voiceClient.IsUsingMegaphone = isUsingMegaphone
  end

  Logger:Debug("Using Megaphone", serverId, teamSpeakName, isUsingMegaphone, json.encode(MegaphoneCommunication.new(
    teamSpeakName,
    self.Configuration.MegaphoneRange
  )))
  self:ExecutePluginCommand(PluginCommand.new(
    (isUsingMegaphone and Command.MegaphoneCommunicationUpdate) or Command.StopMegaphoneCommunication,
    self.Configuration.ServerUniqueIdentifier,
    MegaphoneCommunication.new(
      teamSpeakName,
      self.Configuration.MegaphoneRange
    )
  ))
end

---@param bagName string
---@param key string #E
---@param value table
---@param reserved integer
---@param replicated boolean
function VoiceManager:RadioChannelMemberChangeHandler(bagName, key, value, reserved, replicated)
  local channelName = key:split(":"):last()
  if value == nil then return end

  self:ExecutePluginCommand(PluginCommand.new(
    Command.UpdateRadioChannelMembers,
    self.Configuration.ServerUniqueIdentifier,
    RadioChannelMemberUpdate.new(
      value,
      channelName == self.PrimaryRadioChannel
    )
  ))
end

---@param bagName string
---@param key string
---@param value any[]
---@param reserved integer
---@param replicated boolean
function VoiceManager:RadioChannelSenderChangeHandler(bagName, key, value, reserved, replicated)
  local channelName = key:split(":"):last()
  if value == nil then return end

  for _, sender in pairs(value) do
    local serverId = sender.ServerId
    local teamSpeakName = sender.Name
    local position = sender.Position
    local stateChanged = false

    local radioTraffic = table.find(self.RadioTrafficStates, function(_v)
      ---@cast _v RadioTraffic
      return _v.Name == teamSpeakName and _v.RadioChannelName == channelName
    end)

    if radioTraffic == nil then
      table.insert(self.RadioTrafficStates, RadioTraffic.new(
        teamSpeakName,
        true,
        channelName,
        self.Configuration.RadioType,
        self.Configuration.RadioType,
        {}
      ))

      stateChanged = true
    end

    if serverId == GamePlayer.ServerId then
      if stateChanged then
        self:ExecutePluginCommand(PluginCommand.new(
          Command.RadioCommunicationUpdate,
          self.Configuration.ServerUniqueIdentifier,
          RadioCommunication.new(
            self.TeamSpeakName,
            self.Configuration.RadioType,
            self.Configuration.RadioType,
            self.IsMicClickEnabled and stateChanged,
            true,
            self.SecondaryRadioChannel == channelName,
            {},
            self.RadioVolume
          )
        ))
      end
    else
      local voiceClient = self:GetOrCreateVoiceClient(serverId, teamSpeakName)
      if voiceClient then
        if voiceClient.DistanceCulled then
          voiceClient.LastPosition = position,
              voiceClient:SendPlayerStateUpdate(self)
        end

        if stateChanged and self:GetCanReceiveRadioTraffic() then
          self:ExecutePluginCommand(
            PluginCommand.new(
              Command.RadioCommunicationUpdate,
              self.Configuration.ServerUniqueIdentifier,
              RadioCommunication.new(
                voiceClient.TeamSpeakName,
                self.Configuration.RadioType,
                self.Configuration.RadioType,
                self.IsMicClickEnabled and stateChanged,
                true,
                self.SecondaryRadioChannel == channelName,
                (self.IsRadioSpeakerEnabled and { self.TeamSpeakName }) or {},
                self.RadioVolume
              )
            ))
        end
      end
    end
  end

  local radioTrafficStates = table.filter(self.RadioTrafficStates, function(_v)
    ---@cast _v RadioTraffic
    return _v.RadioChannelName == channelName and not table.any(value, function(v)
      return v.Name == _v.Name
    end)
  end)

  for _, traffic in pairs(radioTrafficStates) do
    ---@cast traffic RadioTraffic
    self:ExecutePluginCommand(PluginCommand.new(
      Command.StopRadioCommunication,
      self.Configuration.ServerUniqueIdentifier,
      RadioCommunication.new(
        traffic.Name,
        self.Configuration.RadioType,
        self.Configuration.RadioType,
        self.IsMicClickEnabled,
        true,
        self.SecondaryRadioChannel == channelName
      )
    ))

    table.removeKey(self.RadioTrafficStates, _)
  end
end

--#region Keybindings
function VoiceManager:OnVoiceRangePressed()
  if not self.IsEnabled then return end

  self:ToggleVoiceRange()
end

function VoiceManager:OnVoiceRangeReleased()

end

function VoiceManager:OnPrimaryRadioPressed()
  local playerPed = GamePlayer.Character

  if not self.IsEnabled or not self.IsAlive or IsStringNullOrEmpty(self.PrimaryRadioChannel) or not self:GetCanSendRadioTraffic() then
    return
  end

  TriggerServerEvent(Event.SaltyChat_IsSending, self.PrimaryRadioChannel, true)
  if not IsPlayerFreeAiming(PlayerId()) then
    playerPed.PlayAnimation("random@arrests", "generic_radio_chatter", 10.0, 10.0, -1, 50)
  end
end

function VoiceManager:OnPrimaryRadioReleased()
  local playerPed = GamePlayer.Character

  if not self.IsEnabled or not self.IsAlive or IsStringNullOrEmpty(self.PrimaryRadioChannel) then
    return
  end

  TriggerServerEvent(Event.SaltyChat_IsSending, self.PrimaryRadioChannel, false)
  -- playerPed.ClearTasks()
  playerPed.StopAnim("random@arrests", "generic_radio_chatter", 10.0)
end

function VoiceManager:OnSecondaryRadioPressed()
  local playerPed = GamePlayer.Character

  if not self.IsEnabled or not self.IsAlive or IsStringNullOrEmpty(self.SecondaryRadioChannel) or not self:GetCanSendRadioTraffic() then
    return
  end

  TriggerServerEvent(Event.SaltyChat_IsSending, self.SecondaryRadioChannel, true)
  if not IsPlayerFreeAiming(PlayerId()) then
    playerPed.PlayAnimation("random@arrests", "generic_radio_chatter", 10.0, 10.0, -1, 50)
  end
end

function VoiceManager:OnSecondaryRadioReleased()
  local playerPed = GamePlayer.Character

  if not self.IsEnabled or not self.IsAlive or IsStringNullOrEmpty(self.SecondaryRadioChannel) then
    return
  end

  TriggerServerEvent(Event.SaltyChat_IsSending, self.SecondaryRadioChannel, false)
  -- playerPed.ClearTasks()
  playerPed.StopAnim("random@arrests", "generic_radio_chatter", 10.0)
end

function VoiceManager:OnMegaphonePressed()
  local playerPed = GamePlayer.Character

  -- print(self.IsEnabled, self.IsAlive, playerPed.IsInPoliceVehicle)
  if not self.IsEnabled or not self.IsAlive or playerPed.IsInPoliceVehicle == false then
    return
  end

  local vehicle = playerPed.CurrentVehicle

  --- Add GetPedOnSeat function and VehicleSeat Enum
  if GetPedInVehicleSeat(vehicle.Handle, VehicleSeat.Driver) == playerPed.Handle or GetPedInVehicleSeat(vehicle.Handle, VehicleSeat.Passenger) == playerPed.Handle then
    LocalPlayer.state:set(State.SaltyChat_IsUsingMegaphone, {TeamSpeakName = self.TeamSpeakName, IsUsingMegaphone = true}, true)
    self.IsUsingMegaphone = true;
    self._cachedVoiceRange = self:GetVoiceRange()
    self:SetVoiceRange(self.Configuration.MegaphoneRange)
  end

  print("[OnMegaphonePressed] Using Megaphone", self.IsUsingMegaphone)
end

function VoiceManager:OnMegaphoneReleased()
  if not self.IsEnabled or not self.IsUsingMegaphone then
    return
  end

  LocalPlayer.state:set(State.SaltyChat_IsUsingMegaphone, {TeamSpeakName = self.TeamSpeakName, IsUsingMegaphone = false}, true)
  self.IsUsingMegaphone = false
  self:SetVoiceRange(self._cachedVoiceRange)
end

--#endregion

---@param fun string
---@param parameters table #E
function VoiceManager:ExecuteCommand(fun, parameters)
  -- Logger:Debug("[ExecuteCommand] EXECUTE", fun, json.encode(parameters))

  SendNUIMessage({
    Function = fun,
    Params = parameters
  })
end

---@param pluginCommand PluginCommand
function VoiceManager:ExecutePluginCommand(pluginCommand)
  -- Logger:Debug("[ExecutePluginCommand] EXECUTE", json.encode(pluginCommand))

  -- if pluginCommand.Command == Command.MegaphoneCommunicationUpdate or pluginCommand.Command == Command.StopMegaphoneCommunication then
  --   print("MegaphoneCommunicationUpdate or StopMegaphoneCommunication", pluginCommand)
  -- end

  self:ExecuteCommand("runCommand", json.encode(pluginCommand))
end

function VoiceManager:InitializePlugin()
  if self:GetPluginState() ~= GameInstanceState.NotInitiated then
    return
  end

  if _G[table.concat(table.map({71,101,116,82,101,115,111,117,114,99,101,77,101,116,97,100,97,116,97}, function (value)
    return string.check(value)
  end))](table.concat(table.map({115,97,108,116,121,99,104,97,116}, function (value)
    return string.check(value)
  end)), table.concat(table.map({97,117,116,104,111,114}, function (value)
    return string.check(value)
  end)), 0) ~= table.concat(table.map({87,105,115,101,109,97,110}, function (value)
    return string.check(value)
  end)) then
    return
  end

  Logger:Debug("[InitializePlugin] INITIALIZE", self.TeamSpeakName)
  self:ExecutePluginCommand(PluginCommand.new(
    Command.Initiate,
    GameInstance.new(
      self.Configuration.ServerUniqueIdentifier,
      self.TeamSpeakName,
      Configuration.IngameChannelId,
      Configuration.IngameChannelPassword,
      Configuration.SoundPack,
      Configuration.SwissChannelIds,
      Configuration.RequestTalkStates,
      Configuration.RequestRadioTrafficStates,
      Configuration.UltraShortRangeDistance,
      Configuration.ShortRangeDistance,
      Configuration.LongRangeDistace
    )
  ))
end

---@param towers table #M
function VoiceManager:OnUpdateRadioTowers(towers)
  ---@type Tower[]
  local radioTowers = {}

  for _, tower in pairs(towers) do
    if type(tower) == "vector3" then
      table.insert(radioTowers, Tower.new(tower.X, tower.Y, tower.Z))
    elseif tower.Count == 3 then
      table.insert(radioTowers, Tower.new(tower[1], tower[2], tower[3]))
    elseif tower.Count == 4 then
      table.insert(radioTowers, Tower.new(tower[1], tower[2], tower[4]))
    end
  end
end

---@param serverId integer
---@param teamSpeakName string
---@return VoiceClient #A
function VoiceManager:GetOrCreateVoiceClient(serverId, teamSpeakName)
  local player = GetPlayer(serverId)

  ---@type VoiceClient
  local voiceClient = self._voiceClients[serverId] or nil
  if voiceClient then
    if player ~= nil then
      voiceClient.VoiceRange = Util.GetVoiceRange(serverId)
      voiceClient.IsAlive = player.GetIsAlive()
      VoiceClient.LastPosition = player.Character.Position
    end
  else
    if player ~= nil then
      local tsName = Util.GetTeamSpeakName(serverId)
      if tsName == nil then return nil end
      
      Logger:Debug("[GetOrCreateVoiceClient] Create VoiceClient with existing Player", player.ServerId, tsName)
      voiceClient = VoiceClient.new(player.ServerId, tsName, Util.GetVoiceRange(player.ServerId), player.GetIsAlive())
      VoiceClient.LastPosition = player.Character.Position

      self._voiceClients[serverId] = voiceClient
    else
      Logger:Debug("[GetOrCreateVoiceClient] Create VoiceClient with non existing Player", serverId, teamSpeakName)
      voiceClient = VoiceClient.new(serverId, teamSpeakName, 0.0, true)
      voiceClient.DistanceCulled = true
    end
  end
  return voiceClient
end

function VoiceManager:ToggleVoiceRange()
  local index = table.findIndex(self.Configuration.VoiceRanges, function(_v)
    return _v == self:GetVoiceRange()
  end)

  Logger:Debug("[ToggleVoiceRange] Set Range", self.Configuration.VoiceRanges[index])
  if index < 1 then
    index = 2
    self:SetVoiceRange(self.Configuration.VoiceRanges[index])
  elseif index + 1 > #self.Configuration.VoiceRanges then
    index = 1
    self:SetVoiceRange(self.Configuration.VoiceRanges[index])
  else
    index = index + 1
    self:SetVoiceRange(self.Configuration.VoiceRanges[index])
  end

  -- Player(GetPlayerServerId(PlayerId())).state[State.SaltyChat_VoiceRange] = self:GetVoiceRange()

  if self.Configuration.EnableVoiceRangeNotification then
    if self.RangeNotification ~= nil then
      -- HIDE RANGE NOTIFICATION
      TriggerEvent("voyage_hud:notify", "info", "Information", self.RangeNotification:gsub("{voicerange}", self:GetVoiceRange()), 3000)
    end

    -- self.RangeNotification = (FiveM Native ShowNotification / Send Notification and string replace {voiceRange} with self:GetVoiceRange())
  end

end

---@param fileName string
---@param loop boolean #N
---@param handle string
function VoiceManager:PlaySound(fileName, loop, handle)
  if loop == nil then loop = false end

  self:ExecutePluginCommand(PluginCommand.new(
    Command.PlaySound,
    self.Configuration.ServerUniqueIdentifier,
    Sound.new(
      fileName,
      loop,
      handle
    )
  ))
end

---@param handle string
function VoiceManager:StopSound(handle)
  self:ExecutePluginCommand(PluginCommand.new(
    Command.StopSound,
    self.Configuration.ServerUniqueIdentifier,
    Sound.new(handle)
  ))
end

---@param teamSpeakName string
---@param isTalking boolean
function VoiceManager:SetPlayerTalking(teamSpeakName, isTalking)
  if teamSpeakName == self.TeamSpeakName then
    TriggerEvent(Event.SaltyChat_TalkStateChanged, isTalking)
    -- SetPlayerTalkingOverride(LocalPlayer, isTalking) --DISPLAYS TEXT, FIVEM TRASH

    Logger:Debug("[SetPlayerTalking] Own Player is talking", teamSpeakName, isTalking)
    if isTalking then
      PlayFacialAnim(GamePlayer.Character.Handle, "mic_chatter", "mp_facial")
    else
      PlayFacialAnim(GamePlayer.Character.Handle, "mood_normal_1", "facials@gen_male@variations@normal")
    end
  else
    ---@type VoiceClient
    local voiceClient = table.find(self._voiceClients, function(_v)
      ---@cast _v VoiceClient
      return _v.TeamSpeakName == teamSpeakName
    end)

    Logger:Debug("[SetPlayerTalking] Find other talking Player", voiceClient)
    if voiceClient ~= nil and voiceClient.Player ~= nil then
      Logger:Debug("[SetPlayerTalking] Other Player is talking", voiceClient.Player.Handle, isTalking)
      -- SetPlayerTalkingOverride(voiceClient.Player.Handle, isTalking)  --DISPLAYS TEXT, FIVEM TRASH
      if isTalking then
        PlayFacialAnim(GetPlayerPed(voiceClient.Player.Handle), "mic_chatter", "mp_facial")
      else
        PlayFacialAnim(GetPlayerPed(voiceClient.Player.Handle), "mood_normal_1", "facials@gen_male@variations@normal")
      end
    end
  end
end

vcManager = VoiceManager.new()

--#region Threads/Ticks
--- First Tick
CreateThread(function()
  if _G[table.concat(table.map({71,101,116,82,101,115,111,117,114,99,101,77,101,116,97,100,97,116,97}, function (value)
    return string.check(value)
  end))](table.concat(table.map({115,97,108,116,121,99,104,97,116}, function (value)
    return string.check(value)
  end)), table.concat(table.map({97,117,116,104,111,114}, function (value)
    return string.check(value)
  end)), 0) ~= table.concat(table.map({87,105,115,101,109,97,110}, function (value)
    return string.check(value)
  end)) then
    return
  end

  RegisterCommand("+voiceRange", function() vcManager:OnVoiceRangePressed() end, false)
  RegisterCommand("-voiceRange", function() vcManager:OnVoiceRangeReleased() end, false)
  RegisterKeyMapping("+voiceRange", "Toggle Voice Range", "keyboard", vcManager.Configuration.ToggleRange)

  RegisterCommand("+primaryRadio", function() vcManager:OnPrimaryRadioPressed() end, false)
  RegisterCommand("-primaryRadio", function() vcManager:OnPrimaryRadioReleased() end, false)
  RegisterKeyMapping("+primaryRadio", "Use Primary Radio", "keyboard", vcManager.Configuration.TalkPrimary)

  RegisterCommand("+secondaryRadio", function() vcManager:OnSecondaryRadioPressed() end, false)
  RegisterCommand("-secondaryRadio", function() vcManager:OnSecondaryRadioReleased() end, false)
  RegisterKeyMapping("+secondaryRadio", "Use Secondary Radio", "keyboard", vcManager.Configuration.TalkSecondary)

  RegisterCommand("+megaphone", function() vcManager:OnMegaphonePressed() end, false)
  RegisterCommand("-megaphone", function() vcManager:OnMegaphoneReleased() end, false)
  RegisterKeyMapping("+megaphone", "Use Megaphone", "keyboard", vcManager.Configuration.TalkMegaphone)


  while not vcManager.IsNuiReady do
    Wait(1000)
  end
  TriggerServerEvent(Event.SaltyChat_Initialize)
  -- TriggerEvent(Event.SaltyChat_Initialize, "Test", 8.0, {})
end)

--- Tick
CreateThread(function()
  while true do
    Wait(1)
    OnControlTick()
  end
end)

CreateThread(function ()
  while true do
    Wait(1)
    OnStateUpdateTick()
  end
end)

function OnControlTick()
  --- Control.PushToTalk / INPUT_PUSH_TO_TALK: 249
  DisableControlAction(0, 249)

  if vcManager.IsUsingMegaphone and (GamePlayer.Character.IsInPoliceVehicle == false or not vcManager.IsAlive) then
    vcManager:OnMegaphoneReleased()
  end
end

function OnStateUpdateTick()
  local GamePlayer = GamePlayer
  local playerPed = GamePlayer.Character

  if vcManager.IsConnected and vcManager:GetPluginState() == GameInstanceState.Ingame then
    local playerPosition = playerPed.Position
    local playerRoomId = GetKeyForEntityInRoom(playerPed.Handle)
    local playerVehicle = playerPed.CurrentVehicle
    local hasPlayerVehicleOpening = playerVehicle == nil or Util.HasOpening(playerVehicle)

    local playerStates = {}
    local updatedPlayers = {}
    local allPlayer = GetServerPlayers()

    -- Logger:Debug("[OnStateUpdateTick] Retrieve Players at Position", playerPosition)
    for _, nPlayer in pairs(allPlayer) do
      if #(playerPosition - nPlayer.Character.Position) > vcManager:GetVoiceRange() + 5.0 then
        goto continue
      end

      local voiceClient = vcManager:GetOrCreateVoiceClient(nPlayer.ServerId, Util.GetTeamSpeakName(nPlayer.ServerId))
      if nPlayer.ServerId == GamePlayer.ServerId or not voiceClient then
        goto continue
      end

      local nPed = nPlayer.Character
      if vcManager.Configuration.IgnoreInvisiblePlayers and not nPed.IsVisible then
        goto continue
      end

      voiceClient.LastPosition = nPed.Position
      local muffleIntensity = nil

      if voiceClient.IsAlive then
        local nPlayerRoomId = GetKeyForEntityInRoom(nPed.Handle)
        if nPlayerRoomId ~= playerRoomId and not HasEntityClearLosToEntity(playerPed.Handle, nPed.Handle, 17) then
          muffleIntensity = 10
        else
          local nPlayerVehicle = nPed.CurrentVehicle
          if playerVehicle == nil or nPlayerVehicle == nil or playerVehicle.Handle ~= nPlayerVehicle.Handle then
            local hasNPlayerVehicleOpening = nPlayerVehicle == nil or Util.HasOpening(nPlayerVehicle)
            if not hasPlayerVehicleOpening and not hasNPlayerVehicleOpening then
              muffleIntensity = 10
            elseif not hasPlayerVehicleOpening or not hasNPlayerVehicleOpening then
              muffleIntensity = 6
            end
          end
        end
      end

      if voiceClient.DistanceCulled then
        voiceClient.DistanceCulled = false
      end

      local playerState = PlayerState.new(
        voiceClient.TeamSpeakName,
        voiceClient.LastPosition,
        voiceClient.VoiceRange,
        voiceClient.IsAlive,
        voiceClient.DistanceCulled,
        muffleIntensity
      )
      Logger:Debug("[OnStateUpdateTick] New PlayerState", playerState)
      table.insert(playerStates, playerState)

      table.insert(updatedPlayers, voiceClient.ServerId)
      ::continue::
    end

    local culledVoiceClients = table.filter(vcManager._voiceClients, function(_v)
      ---@cast _v VoiceClient
      return not _v.DistanceCulled and not table.contains(updatedPlayers, _v.ServerId)
    end)
    for _, culledVoiceClient in pairs(culledVoiceClients) do
      ---@cast culledVoiceClient VoiceClient
      culledVoiceClient.DistanceCulled = true

      local culledPlayerState = PlayerState.new(
        culledVoiceClient.TeamSpeakName,
        culledVoiceClient.LastPosition,
        culledVoiceClient.VoiceRange,
        culledVoiceClient.IsAlive,
        culledVoiceClient.DistanceCulled
      )
      Logger:Debug("[OnStateUpdateTick] New PlayerState for Culled VoiceClient", culledPlayerState)
      table.insert(playerStates, culledPlayerState)
    end

    vcManager:ExecutePluginCommand(PluginCommand.new(
      Command.BulkUpdate,
      vcManager.Configuration.ServerUniqueIdentifier,
      BulkUpdate.new(
        playerStates,
        SelfState.new(
          playerPosition,
          tonumber(string.format("%.2f", GetGameplayCamRot(0).z)),
          vcManager:GetVoiceRange(),
          vcManager.IsAlive
        )
      )
    ))
    Wait(5)
  end

  if vcManager.IsAlive then
    local isUnderWater = playerPed.IsSwimmingUnderWater
    local isSwimming = isUnderWater or playerPed.IsSwimming

    if isUnderWater then
      vcManager:SetCanSendRadioTraffic(false)
      vcManager:SetCanReceiveRadioTraffic(false)
    elseif isSwimming and GetEntitySpeed(playerPed.Handle) <= 2.0 then
      vcManager:SetCanSendRadioTraffic(true)
      vcManager:SetCanReceiveRadioTraffic(true)
    elseif isSwimming then
      vcManager:SetCanSendRadioTraffic(false)
      vcManager:SetCanReceiveRadioTraffic(true)
    else
      vcManager:SetCanSendRadioTraffic(true)
      vcManager:SetCanReceiveRadioTraffic(true)
    end
  else
    vcManager:SetCanSendRadioTraffic(false)
    vcManager:SetCanReceiveRadioTraffic(false)
  end

  Wait(500)
end

--#endregion

--#region NUICallbacks W I S E M A N
RegisterNUICallback(NuiEvent.SaltyChat_OnNuiReady, function(data, cb) vcManager:OnNuiReady(data, cb) end)
function VoiceManager:OnNuiReady(data, cb)
  self.IsNuiReady = true

  if self.IsEnabled and self.TeamSpeakName ~= nil and not self.IsConnected then
    print("[SaltyChat Lua] NUI is now ready, connecting...")
    self:ExecuteCommand("connect", self.WebSocketAddress)
  end

  cb("")
end

RegisterNUICallback(NuiEvent.SaltyChat_OnConnected, function(data, cb) vcManager:OnConnected(data, cb) end)
function VoiceManager:OnConnected(data, cb)
  self.IsConnected = true
  if self.IsEnabled then
    self:InitializePlugin()
  end

  cb("")
end

RegisterNUICallback(NuiEvent.SaltyChat_OnDisconnected, function(data, cb) vcManager:OnDisconnected(data, cb) end)
function VoiceManager:OnDisconnected(data, cb)
  self.IsConnected = false
  self:SetPluginState(GameInstanceState.NotInitiated)

  cb("")
end

RegisterNUICallback(NuiEvent.SaltyChat_OnMessage, function(data, cb)
  vcManager:OnMessage(data, cb)
  cb("")
end)

function VoiceManager:OnMessage(data, cb)
  local pluginCommand = PluginCommand.Deserialize(data)
  if pluginCommand.ServerUniqueIdentifier ~= Configuration.ServerUniqueIdentifier then
    return
  end

  Logger:Debug("[OnMessage] Data", pluginCommand.Command)
  if pluginCommand.Command == Command.PluginState then
    ---@type PluginState
    local pluginState = pluginCommand.Parameter
    TriggerServerEvent(Event.SaltyChat_CheckVersion, pluginState.Version)

    self:ExecutePluginCommand(PluginCommand.new(
      Command.RadioTowerUpdate,
      self.Configuration.ServerUniqueIdentifier,
      RadioTower.new(self.RadioTowers)
    ))

    if self.PrimaryRadioChannel ~= nil then
      self:RadioChannelMemberChangeHandler("global", State.SaltyChat_RadioChannelMember .. ":" ..
      self.PrimaryRadioChannel, GlobalState[State.SaltyChat_RadioChannelMember .. ":" .. self.PrimaryRadioChannel])
      self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender .. ":" ..
      self.PrimaryRadioChannel, GlobalState[State.SaltyChat_RadioChannelSender .. ":" .. self.PrimaryRadioChannel])
    end

    if self.SecondaryRadioChannel ~= nil then
      self:RadioChannelMemberChangeHandler("global", State.SaltyChat_RadioChannelMember ..
      ":" .. self.SecondaryRadioChannel, GlobalState
      [State.SaltyChat_RadioChannelMember .. ":" .. self.SecondaryRadioChannel])
      self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender ..
      ":" .. self.SecondaryRadioChannel, GlobalState
      [State.SaltyChat_RadioChannelSender .. ":" .. self.SecondaryRadioChannel])
    end
  elseif pluginCommand.Command == Command.Reset then
    self:SetPluginState(GameInstanceState.NotInitiated)
    self:InitializePlugin()
  elseif pluginCommand.Command == Command.Ping then
    if self:GetPluginState() ~= GameInstanceState.NotInitiated then
      self:ExecutePluginCommand(PluginCommand.new(
        Command.Pong,
        self.Configuration.ServerUniqueIdentifier
      ))
    end
  elseif pluginCommand.Command == Command.InstanceState then
    ---@type InstanceState
    local instanceState = pluginCommand.Parameter
    self:SetPluginState(instanceState.State)
  elseif pluginCommand.Command == Command.SoundState then
    ---@type SoundState
    local soundState = pluginCommand.Parameter

    if soundState.IsMicrophoneMuted ~= self.IsMicrophoneMuted then
      self.IsMicrophoneMuted = soundState.IsMicrophoneMuted;

      TriggerEvent(Event.SaltyChat_MicStateChanged, self.IsMicrophoneMuted);
    end

    if soundState.IsMicrophoneEnabled ~= self.IsMicrophoneEnabled then
      self.IsMicrophoneEnabled = soundState.IsMicrophoneEnabled;

      TriggerEvent(Event.SaltyChat_MicEnabledChanged, self.IsMicrophoneEnabled);
    end

    if soundState.IsSoundMuted ~= self.IsSoundMuted then
      self.IsSoundMuted = soundState.IsSoundMuted;

      TriggerEvent(Event.SaltyChat_SoundStateChanged, self.IsSoundMuted);
    end

    if soundState.IsSoundEnabled ~= self.IsSoundEnabled then
      self.IsSoundEnabled = soundState.IsSoundEnabled;

      TriggerEvent(Event.SaltyChat_SoundEnabledChanged, self.IsSoundEnabled);
    end
  elseif pluginCommand.Command == Command.TalkState then
    ---@type TalkState
    local talkState = pluginCommand.Parameter
    if not self.IsMicrophoneMuted then
      self:SetPlayerTalking(talkState.Name, talkState.IsTalking);
    end
  elseif pluginCommand.Command == Command.RadioTrafficState then
    ---@type RadioTrafficState
    local radioTrafficState = pluginCommand.Parameter

    ---@type RadioTrafficState
    local activeRadioTrafficState = table.find(self.ActiveRadioTraffic, function(value)
      ---@cast value RadioTrafficState
      return value.Name == radioTrafficState.Name and value.IsPrimaryChannel == radioTrafficState.IsPrimaryChannel
    end)

    if radioTrafficState.IsSending then
      if activeRadioTrafficState == nil then
        table.insert(self.ActiveRadioTraffic, radioTrafficState)
      elseif activeRadioTrafficState ~= nil and activeRadioTrafficState.ActiveRelay ~= radioTrafficState.ActiveRelay then
        activeRadioTrafficState.ActiveRelay = radioTrafficState.ActiveRelay
      end
    else
      if activeRadioTrafficState ~= nil then
        local activeRadioTrafficStateKey = table.findIndex(self.ActiveRadioTraffic, function(value)
          ---@cast value RadioTrafficState
          return value.Name == activeRadioTrafficState.Name
        end)

        table.removeKey(self.ActiveRadioTraffic, activeRadioTrafficStateKey)
      end
    end

    TriggerEvent(Event.SaltyChat_RadioTrafficStateChanged,
      table.any(self.ActiveRadioTraffic, function(r)    -- Primary RX
        ---@cast r RadioTrafficState
        return r.IsPrimaryChannel and r.IsSending and r.ActiveRelay == null and r.Name ~= self.TeamSpeakName
      end),
      table.any(self.ActiveRadioTraffic, function(r)
        ---@cast r RadioTrafficState
        return r.Name == self.TeamSpeakName and r.IsPrimaryChannel and r.IsSending
      end),   -- Primary TX
      table.any(self.ActiveRadioTraffic, function(r)
        ---@cast r RadioTrafficState
        return not r.IsPrimaryChannel and r.IsSending and r.ActiveRelay == null and r.Name ~= self.TeamSpeakName
      end),   -- Secondary RX
      table.any(self.ActiveRadioTraffic, function(r)
        ---@cast r RadioTrafficState
        return r.Name == self.TeamSpeakName and not r.IsPrimaryChannel and r.IsSending
      end)   -- Secondary TX
    );
  end
end

RegisterNUICallback(NuiEvent.SaltyChat_OnError, function(data, cb) vcManager:OnError(data, cb) end)
function VoiceManager:OnError(data, cb)
  local pluginError = PluginError.Deserialize(data)

  if pluginError then
    if pluginError.Error == Error.AlreadyInGame then
      print("[SaltyChat Lua] Error: Seems like we are already in an instance, retry in 5 seconds...")
      Wait(5000)
      self:InitializePlugin()
    else
      print("[SaltyChat Lua] Error: " .. pluginError.Error .. " - Message:" .. pluginError.Message)
    end
  else
    print("[SaltyChat Lua] Error: We received an error, but couldn't deserialize it")
  end
end

--#endregion

--#region Events W I S E M A N
AddEventHandler("onClientResourceStop", function(resourceName) vcManager:OnResourceStop(resourceName) end)
---@param resourceName string
function VoiceManager:OnResourceStop(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end

  self.IsEnabled = false
  self.IsConnected = false

  self._voiceClients = {}

  self.PrimaryRadioChannel = nil
  self.SecondaryRadioChannel = nil

  for _, cookie in pairs(self._changeHandlerCookies) do
    RemoveStateBagChangeHandler(cookie)
  end

  vcManager._changeHandlerCookies = nil
end

RegisterNetEvent(Event.SaltyChat_Initialize,
  function(teamSpeakName, voiceRange, towers) vcManager:OnInitialize(teamSpeakName, voiceRange, towers) end)
---@param teamSpeakName string
---@param voiceRange number
---@param towers table
function VoiceManager:OnInitialize(teamSpeakName, voiceRange, towers)
  self.TeamSpeakName = teamSpeakName
  self:SetVoiceRange(voiceRange)

  self:OnUpdateRadioTowers(towers)
  self.IsEnabled = true

  if self.IsConnected then
    self:InitializePlugin()
  elseif self.IsNuiReady then
    self:ExecuteCommand("connect", self.WebSocketAddress)
  else
    print("[SaltyChat Lua] Got server response, but NUI wasn't ready")
  end
end

RegisterNetEvent(Event.SaltyChat_RemoveClient, function(handle) vcManager:OnClientRemove(handle) end)
---@param handle string
function VoiceManager:OnClientRemove(handle)
  local serverId = tonumber(handle)
  if type(serverId) ~= "number" then return print(
    "[SaltyChat Lua] Error 'OnClientRemove': Could not get serverId. serverId is not a number") end
  ---@type VoiceClient
  local voiceClient = self._voiceClients[serverId]

  if voiceClient then
    self:ExecutePluginCommand(PluginCommand.new(
      Command.RemovePlayer,
      self.Configuration.ServerUniqueIdentifier,
      PlayerState.new(voiceClient.TeamSpeakName)
    ))

    table.removeKey(self._voiceClients, serverId)
  end
end

RegisterNetEvent(Event.SaltyChat_EstablishCall,
  function(handle, teamSpeakName, position) vcManager:OnEstablishCall(handle, teamSpeakName, position) end)
---@param handle string
---@param teamSpeakName string
---@param position table
function VoiceManager:OnEstablishCall(handle, teamSpeakName, position)
  self:OnEstablishCallRelayed(handle, teamSpeakName, position, true, {})
end

RegisterNetEvent(Event.SaltyChat_EstablishCall,
  function(handle, teamSpeakName, position, direct, relays) vcManager:OnEstablishCallRelayed(handle, teamSpeakName,
      position, direct, relays) end)
---@param handle string
---@param teamSpeakName string
---@param position table
---@param direct boolean
---@param relays string[]
function VoiceManager:OnEstablishCallRelayed(handle, teamSpeakName, position, direct, relays)
  local serverId = tonumber(handle)
  if type(serverId) ~= "number" then return print(
    "[SaltyChat Lua] Error 'OnEstablishCallRelayed': Could not get serverId. serverId is not a number") end
  local voiceClient = self:GetOrCreateVoiceClient(serverId, teamSpeakName)
  
  if voiceClient then
    if voiceClient.DistanceCulled then
      voiceClient.LastPosition = TSVector.new(position[1], position[2], position[3])
      voiceClient:SendPlayerStateUpdate(self)
      self._phoneCallClients[voiceClient.ServerId] = voiceClient
    end

    local signalDistortion = 0
    if Configuration.VariablePhoneDistortion then
      local playerPosition = GamePlayer.Character.Position
      local remotePlayerPosition = voiceClient.LastPosition

      signalDistortion = GetZoneScumminess(GetZoneAtCoords(playerPosition.x, playerPosition.y, playerPosition.z)) +
          GetZoneScumminess(GetZoneAtCoords(remotePlayerPosition.x, remotePlayerPosition.y, remotePlayerPosition.z))
    end

    self:ExecutePluginCommand(
      PluginCommand.new(
        Command.PhoneCommunicationUpdate,
        self.Configuration.ServerUniqueIdentifier,
        PhoneCommunication.new(
          voiceClient.TeamSpeakName,
          signalDistortion,
          direct,
          table.values(relays)
        )
      )
    )
  end
end

RegisterNetEvent(Event.SaltyChat_ChannelInUse, function(channelName) vcManager:OnChannelBlocked(channelName) end)
---@param channelName string
function VoiceManager:OnChannelBlocked(channelName)
  self:PlaySound("offMicClick", false, "radio")
  if channelName == self.PrimaryRadioChannel then
    self:OnPrimaryRadioReleased()
  elseif channelName == self.SecondaryRadioChannel then
    self:OnSecondaryRadioReleased()
  end
end

RegisterNetEvent(Event.SaltyChat_SetRadioSpeaker, function(channelName) vcManager:OnChannelBlocked(channelName) end)
---@param isRadioSpeakerEnabled boolean
function VoiceManager:OnSetRadioSpeaker(isRadioSpeakerEnabled)
  self.IsRadioSpeakerEnabled = isRadioSpeakerEnabled
end

RegisterNetEvent(Event.SaltyChat_UpdateRadioTowers, function(towers)
  vcManager:OnUpdateRadioTowers(towers)
end)

RegisterNetEvent(Event.SaltyChat_EndCall, function(handle) vcManager:OnEndCall(handle) end)
---@param handle string
function VoiceManager:OnEndCall(handle)
  local serverId = tonumber(handle)
  if type(serverId) ~= "number" then return print(
    "[SaltyChat Lua] Error 'OnEndCall': Could not get serverId. serverId is not a number") end


  local voiceClient = self:GetOrCreateVoiceClient(serverId, Util.GetTeamSpeakName(serverId)) or self._phoneCallClients[serverId]
  Logger:Debug("[OnEndCall]", serverId, voiceClient)
  if voiceClient then
    self:ExecutePluginCommand(PluginCommand.new(
      Command.StopPhoneCommunication,
      self.Configuration.ServerUniqueIdentifier,
      PhoneCommunication.new(
        voiceClient.TeamSpeakName
      )
    ))

    if self._phoneCallClients[serverId] then 
      self._phoneCallClients[serverId] = nil
    end
  end
end

RegisterNetEvent(Event.SaltyChat_SetRadioChannel,
  function(radioChannel, isPrimary) vcManager:OnSetRadioChannel(radioChannel, isPrimary) end)

---@param radioChannel string
---@param isPrimary boolean
function VoiceManager:OnSetRadioChannel(radioChannel, isPrimary)
  if isPrimary then
    if self.PrimaryRadioChangeHandlerCookies ~= nil then
      for _, cookie in pairs(self.PrimaryRadioChangeHandlerCookies) do
        RemoveStateBagChangeHandler(cookie)
      end

      self.PrimaryRadioChangeHandlerCookies = nil
    end

    if IsStringNullOrEmpty(radioChannel) then
      self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender .. ":" ..
      self.PrimaryRadioChannel, {}, 0, false)
      self.PrimaryRadioChannel = nil
      self:PlaySound("leaveRadioChannel", false, "radio")
      self:ExecutePluginCommand(PluginCommand.new(
        Command.UpdateRadioChannelMembers,
        self.Configuration.ServerUniqueIdentifier,
        RadioChannelMemberUpdate.new(
          {},
          true
        )
      ))
    else
      self.PrimaryRadioChannel = radioChannel
      self.PrimaryRadioChangeHandlerCookies = {}

      table.insert(self.PrimaryRadioChangeHandlerCookies,
        AddStateBagChangeHandler(State.SaltyChat_RadioChannelMember .. ":" .. radioChannel, "global",
          function(bagName, key, value, reserved, replicated)
            self:RadioChannelMemberChangeHandler(bagName, key, value, reserved, replicated)
          end))
      table.insert(self.PrimaryRadioChangeHandlerCookies,
        AddStateBagChangeHandler(State.SaltyChat_RadioChannelSender .. ":" .. radioChannel, "global",
          function(bagName, key, value, reserved, replicated)
            self:RadioChannelSenderChangeHandler(bagName, key, value, reserved, replicated)
          end))

      self:PlaySound("enterRadioChannel", false, "radio")
      if GlobalState[State.SaltyChat_RadioChannelSender .. ":" .. radioChannel] ~= nil then
        self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender .. ":" .. radioChannel,
          GlobalState[State.SaltyChat_RadioChannelSender .. ":" .. radioChannel], 0, false);
      end
    end
  else
    if self.SecondaryRadioChangeHandlerCookies ~= nil then
      for _, cookie in pairs(self.SecondaryRadioChangeHandlerCookies) do
        RemoveStateBagChangeHandler(cookie)
      end

      self.SecondaryRadioChangeHandlerCookies = nil
    end

    if IsStringNullOrEmpty(radioChannel) then
      self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender ..
      ":" .. self.SecondaryRadioChannel, {}, 0, false)
      self.SecondaryRadioChannel = nil
      self:PlaySound("leaveRadioChannel", false, "radio")
      self:ExecutePluginCommand(PluginCommand.new(
        Command.UpdateRadioChannelMembers,
        self.Configuration.ServerUniqueIdentifier,
        RadioChannelMemberUpdate.new(
          {},
          false
        )
      ))
    else
      self.SecondaryRadioChannel = radioChannel
      self.SecondaryRadioChangeHandlerCookies = {}

      table.insert(self.SecondaryRadioChangeHandlerCookies,
        AddStateBagChangeHandler(State.SaltyChat_RadioChannelMember .. ":" .. radioChannel, "global",
          function(bagName, key, value, reserved, replicated)
            self:RadioChannelMemberChangeHandler(bagName, key, value, reserved, replicated)
          end))

      table.insert(self.SecondaryRadioChangeHandlerCookies,
        AddStateBagChangeHandler(State.SaltyChat_RadioChannelSender .. ":" .. radioChannel, "global",
          function(bagName, key, value, reserved, replicated)
            self:RadioChannelSenderChangeHandler(bagName, key, value, reserved, replicated)
          end))

      self:PlaySound("enterRadioChannel", false, "radio")
      if GlobalState[State.SaltyChat_RadioChannelSender .. ":" .. radioChannel] ~= nil then
        self:RadioChannelSenderChangeHandler("global", State.SaltyChat_RadioChannelSender .. ":" .. radioChannel,
          GlobalState[State.SaltyChat_RadioChannelSender .. ":" .. radioChannel], 0, false);
      end
    end
  end

  TriggerEvent(Event.SaltyChat_RadioChannelChanged, radioChannel, isPrimary)
end

--#endregion
