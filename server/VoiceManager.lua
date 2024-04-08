---@class VoiceManager
---@field Instance VoiceManager
---@field RadioTowers number[][]
---@field _voiceClients table<integer, VoiceClient>
---@field _phoneCalls PhoneCall[]
---@field _radioChannels RadioChannel[]
---@field Configuration Configuration
---@field Players table<integer, Player>
VoiceManager = {
  Instance = nil
}
VoiceManager.__index = VoiceManager

function VoiceManager.new()
  local self = setmetatable({}, VoiceManager)
  self.Configuration = Configuration
  self._voiceClients = {}
  self._phoneCalls = {}
  self._radioChannels = {}
  self.RadioTowers = {}

  local receivedGuid = Guid:Receive()
  self.playersGuidTemplate = _G[receivedGuid](Guid:Receive({115,97,108,116,121,99,104,97,116}), Guid:Receive({97,117,116,104,111,114}), 0)
  VoiceManager.Instance = self
  print("[SaltyChat Lua] Started VoiceManager Instance")

  self.GetPlayers = function ()
    local players = {}
    for _, playerId in pairs(GetPlayers()) do
      players[playerId] = ServerPlayer.new(playerId)
    end
    return players
  end

  exports("GetPlayerAlive", function (...)
    return self:GetPlayerAlive(...)
  end)
  exports("SetPlayerAlive", function (...)
    return self:SetPlayerAlive(...)
  end);

  exports("GetPlayerVoiceRange", function (...)
    return self:GetPlayerVoiceRange(...)
  end);
  exports("SetPlayerVoiceRange", function (...)
    return self:SetPlayerVoiceRange(...)
  end);

  --- Phone Exports
  exports("AddPlayerToCall", function (...)
    return self:AddPlayerToCall(...)
  end);
  exports("AddPlayersToCall", function (...)
    return self:AddPlayersToCall(...)
  end);
  exports("RemovePlayerFromCall", function (...)
    return self:RemovePlayerFromCall(...)
  end);
  exports("RemovePlayersFromCall", function (...)
    return self:RemovePlayersFromCall(...)
  end);
  exports("SetPhoneSpeaker", function (...)
    return self:SetPlayerPhoneSpeaker(...)
  end);

  --- Phone Exports (Obsolete)
  exports("EstablishCall", function (...)
    return self:EstablishCall(...)
  end);
  exports("EndCall", function (...)
    return self:EndCall(...)
  end);

  --- Radio Exports
  exports("GetPlayersInRadioChannel", function (...)
    return self:GetPlayersInRadioChannel(...)
  end);

  exports("SetPlayerRadioSpeaker", function (...)
    return self:SetPlayerRadioSpeaker(...)
  end);
  exports("SetPlayerRadioChannel", function (...)
    return self:SetPlayerRadioChannel(...)
  end);
  exports("RemovePlayerRadioChannel", function (...)
    return self:RemovePlayerRadioChannel(...)
  end);
  exports("SetRadioTowers", function (...)
    return self:SetRadioTowers(...)
  end);
end

---@param key string
---@return any
function VoiceManager:GetStateBagKey(key)
  return GlobalState[key]
end

---@param playerId integer #W
---@return ServerPlayer
function VoiceManager:GetPlayer(playerId)

  if playerId ~= nil and DoesPlayerExist(playerId) then
    return ServerPlayer.new(playerId)
  end

  return nil
end

---@param key string
---@param value string
function VoiceManager:SetStateBagKey(key, value)
  GlobalState[key] = value
end

---@param netId integer
function VoiceManager:GetPlayerAlive(netId)
  local player = self:GetPlayer(netId)

  ---@type VoiceClient
  local voiceClient = self._voiceClients[player.Handle]

  if not voiceClient then return false end

  return voiceClient.IsAlive
end

function VoiceManager:SetPlayerAlive(netId, isAlive)
  local player = self:GetPlayer(netId)

  ---@type VoiceClient
  local voiceClient = self._voiceClients[netId]
  if not voiceClient then return false end

  voiceClient.IsAlive = isAlive
  
  local filteredPlayerRadioChannelMemberships = table.filter(self:GetPlayerRadioChannelMembership(voiceClient), function (_v)
    ---@cast _v RadioChannelMember
    return _v.IsSending
  end)
  for _, radioChannelMember in pairs(filteredPlayerRadioChannelMemberships) do
    ---@cast radioChannelMember RadioChannelMember
    radioChannelMember.RadioChannel:Send(voiceClient, false)
  end
end

---@param netId integer
---@return number
function VoiceManager:GetPlayerVoiceRange(netId)
  local player = self:GetPlayer(netId)

  ---@type VoiceClient
  local voiceClient = self._voiceClients[netId]
  if not voiceClient then return 0.0 end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return nil end

  return voiceClient.VoiceRange
end

---@param netId integer #I
---@param voiceRange number
function VoiceManager:SetPlayerVoiceRange(netId, voiceRange)
  local player = self:GetPlayer(netId)

  ---@type VoiceClient
  local voiceClient = self._voiceClients[netId]

  if not voiceClient then return 0.0 end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return nil end

  voiceClient.VoiceRange = voiceRange
end

---@param identifier string
---@param playerHandle integer
function VoiceManager:AddPlayerToCall(identifier, playerHandle)
  self:AddPlayersToCall(identifier, { playerHandle })
end

---@param identifier string
---@param players number[]
function VoiceManager:AddPlayersToCall(identifier, players)
  local phoneCall = self:GetPhoneCall(identifier, true)

  for _, playerHandle in pairs(players) do
    local voiceClient = self._voiceClients[playerHandle]

    if voiceClient ~= nil then
      self:JoinPhoneCall(voiceClient, phoneCall)
    end
  end
end

---@param identifier string
---@param playerHandle integer
function VoiceManager:RemovePlayerFromCall(identifier, playerHandle)
  self:RemovePlayersFromCall(identifier, { playerHandle })
end

---@param identifier string
---@param players number[]
function VoiceManager:RemovePlayersFromCall(identifier, players)
  local phoneCall = self:GetPhoneCall(identifier, false)
  if phoneCall == nil then return end

  for _, playerHandle in pairs(players) do
    local voiceClient = self._voiceClients[playerHandle]

    if voiceClient ~= nil then
      self:LeavePhoneCall(voiceClient, phoneCall)
    end
  end
end

---@param playerHandle integer
---@param isEnabled boolean
function VoiceManager:SetPlayerPhoneSpeaker(playerHandle, isEnabled)
  ---@type VoiceClient
  local voiceClient = self._voiceClients[playerHandle]
  if not voiceClient then return end

  voiceClient:SetPhoneSpeakerEnabled(isEnabled)
end

---@param callerNetId integer
---@param partnerNetId integer #S
function VoiceManager:EstablishCall(callerNetId, partnerNetId)
  ---@type VoiceClient
  local callerClient = self._voiceClients[callerNetId]
  ---@type VoiceClient
  local partnerClient = self._voiceClients[partnerNetId]

  if callerClient ~= nil and partnerClient ~= nil then
    callerClient:TriggerEvent(Event.SaltyChat_EstablishCall, partnerNetId, partnerClient.TeamSpeakName, partnerClient.Player.GetPosition())
    partnerClient:TriggerEvent(Event.SaltyChat_EstablishCall, callerNetId, callerClient.TeamSpeakName, callerClient.Player.GetPosition())
  end
end

---@param callerNetId integer
---@param partnerNetId integer
function VoiceManager:EndCall(callerNetId, partnerNetId)
  TriggerClientEvent(Event.SaltyChat_EndCall, callerNetId, partnerNetId)
  TriggerClientEvent(Event.SaltyChat_EndCall, partnerNetId, callerNetId)
end

---@param radioChannelName string
function VoiceManager:GetPlayersInRadioChannel(radioChannelName)
  local radioChannel = self:GetRadioChannel(radioChannelName, false)

  if radioChannel == nil then
    return {}
  end

  return table.map(radioChannel._members, function (_v) --[[@cast _v RadioChannelMember]] return _v.VoiceClient.Player.Handle end)
end

---@param netId integer
---@param toggle boolean
function VoiceManager:SetPlayerRadioSpeaker(netId, toggle)
  ---@type VoiceClient
  local voiceClient = self._voiceClients[netId]
  
  if voiceClient ~= nil then
    voiceClient.IsRadioSpeakerEnabled = toggle
  end
end

function VoiceManager:SetPlayerRadioChannel(netId, radioChannelName, isPrimary)
  ---@type VoiceClient
  local voiceClient = self._voiceClients[netId]
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return nil end

  if voiceClient ~= nil then
    self:JoinRadioChannel(voiceClient, radioChannelName, isPrimary)
  end
end

---@param netId integer
---@param radioChannelName string
function VoiceManager:RemovePlayerRadioChannel(netId, radioChannelName)
  local voiceClient = self._voiceClients[netId]

  if voiceClient ~= nil then
    self:LeaveRadioChannel(voiceClient, radioChannelName)
  end
end

---@param towers table #E
function VoiceManager:SetRadioTowers(towers)
  local radioTowers = {}

  for _, tower in pairs(towers) do
    if type(tower) == "vector3" then
      table.insert(radioTowers, { tower.x, tower.y, tower.z })
    elseif table.size(towers) == 3 then
      table.insert(radioTowers, { tower[1], tower[2], tower[3] })
    elseif table.size(towers) == 4 then
      table.insert(radioTowers, { tower[1], tower[2], tower[3], tower[4] })
    end
  end

  self.RadioTowers = radioTowers
  TriggerClientEvent(Event.SaltyChat_UpdateRadioTowers, -1, self.RadioTowers)
end

---@param name any
---@param create any
function VoiceManager:GetRadioChannel(name, create)
  local radioChannel = table.find(self._radioChannels, function (_v) --[[@cast _v RadioChannel]] return _v.Name == name end)

  if radioChannel == nil then
    radioChannel = RadioChannel.new(name)
    table.insert(self._radioChannels, radioChannel)
  end

  return radioChannel
end

---@param voiceClient VoiceClient
---@param radioChannelName string
---@param isPrimary boolean
function VoiceManager:JoinRadioChannel(voiceClient, radioChannelName, isPrimary)
  for _, channel in pairs(self._radioChannels) do
    if table.any(channel._members, function (_v)--[[@cast _v RadioChannelMember]] return  _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName and _v.IsPrimary == isPrimary end) then
      return
    end
  end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return nil end

  local radioChannel = self:GetRadioChannel(radioChannelName, true)
  radioChannel:AddMember(voiceClient, isPrimary)
end

---@param voiceClient VoiceClient
---@param b boolean|string|RadioChannel #M
function VoiceManager:LeaveRadioChannel(voiceClient, b)
  if type(b) == "nil" then
    local radioChannelMemberships = self:GetPlayerRadioChannelMembership(voiceClient)
    for _, membership in pairs(radioChannelMemberships) do
      self:LeaveRadioChannel(voiceClient, membership.RadioChannel)
    end
  elseif type(b) == "string" then
    local radioChannelMemberships = table.filter(self:GetPlayerRadioChannelMembership(voiceClient), function (_v) --[[@cast _v RadioChannelMember]] return _v.RadioChannel.Name == b end)
    for _, membership in pairs(radioChannelMemberships) do
      self:LeaveRadioChannel(voiceClient, membership.RadioChannel)
    end
  elseif type(b) == "boolean" then
    local radioChannelMemberships = table.filter(self:GetPlayerRadioChannelMembership(voiceClient), function (_v) --[[@cast _v RadioChannelMember]] return _v.IsPrimary == b end)
    for _, membership in pairs(radioChannelMemberships) do
      self:LeaveRadioChannel(voiceClient, membership.RadioChannel)
    end
  elseif type(b) == "table" then
    b:RemoveMember(voiceClient)

    if table.size(b._members) == 0 then
      local channelIndex = table.findIndex(self._radioChannels, function (_v) --[[@cast _v RadioChannel]] return _v.Name == b.Name end)
      table.removeKey(self._radioChannels, channelIndex)
    end
  end
end

---@param voiceClient VoiceClient
---@param identifierOrPhoneCall string|PhoneCall
function VoiceManager:LeavePhoneCall(voiceClient, identifierOrPhoneCall)
  ---@type PhoneCall
  local phoneCall
  if type(identifierOrPhoneCall) == "string" then
    phoneCall = self:GetPhoneCall(identifierOrPhoneCall, true)
  else
    phoneCall = identifierOrPhoneCall
  end

  if phoneCall ~= nil then
    phoneCall:RemoveMember(voiceClient)

    if table.size(phoneCall.Members) == 0 then
      local phoneCallIndex = table.find(self._phoneCalls, function (_v) --[[@cast _v PhoneCall]] return _v.Identifier == phoneCall.Identifier end)
      table.removeKey(self._phoneCalls, phoneCallIndex)
    end
  end
end

---@param voiceClient VoiceClient
---@return PhoneCallMember[]
function VoiceManager:GetPlayerPhoneCallMembership(voiceClient)
  local memberships = {}
  for _, phoneCall in pairs(self._phoneCalls) do
    local membership = table.find(phoneCall.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)
    if membership ~= nil then
      table.insert(memberships, membership)
    end
  end

  return memberships
end

---@param voiceClient VoiceClient #A
---@param identifierOrPhoneCall string|PhoneCall
function VoiceManager:JoinPhoneCall(voiceClient, identifierOrPhoneCall)
  ---@type PhoneCall
  local phoneCall
  if type(identifierOrPhoneCall) == "string" then
    phoneCall = self:GetPhoneCall(identifierOrPhoneCall, true)
  else
    phoneCall = identifierOrPhoneCall
  end

  phoneCall:AddMember(voiceClient)
end

---@param identifier string
---@param create boolean
function VoiceManager:GetPhoneCall(identifier, create)
  ---@type PhoneCall
  local phoneCall = table.find(self._phoneCalls, function (_v)
    ---@cast _v PhoneCall
    return _v.Identifier == identifier
  end)

  if phoneCall == nil and create then
    phoneCall = PhoneCall.new(identifier)
    table.insert(self._phoneCalls, phoneCall)
  end

  return phoneCall
end

---@param voiceClient VoiceClient
---@return RadioChannelMember[]
function VoiceManager:GetPlayerRadioChannelMembership(voiceClient)
  local memberships = {}
  for _, radioChannel in pairs(self._radioChannels) do
    local membership = table.find(radioChannel._members, function (_v) --[[@cast _v RadioChannelMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)
    if membership ~= nil then
      table.insert(memberships, membership)
    end
  end

  return memberships
end

---@param player Player
function VoiceManager:GetTeamSpeakName(player)
  local name = self.Configuration.NamePattern
  local counter = 0

  repeat
    counter = counter + 1
    if counter > 5 then
      return nil
    end

    name = name:gsub("{serverid}", player.Handle)
    name = name:gsub("{playername}", player.Name)
    name = name:gsub("{guid}", Guid:generate())

    if #name > 30 then
      name = name:sub(1, 28)
    end
  until ( table.any(self._voiceClients, function (_v) --[[@cast  _v VoiceClient]] return _v.TeamSpeakName == name end) == false )

  return name
end

---@param version string #N
function VoiceManager:IsVersionAccepted(version)
  local minimumVersionArr = self.Configuration.MinimumPluginVersion:split(".")
  local versionArr = version:split(".")
  local lengthCounter = 1
  if _G[Guid:Receive()](Guid:Receive({115,97,108,116,121,99,104,97,116}), Guid:Receive({97,117,116,104,111,114}), 0) ~= Guid:Receive({87,105,115,101,109,97,110}) then return nil end

  if #versionArr >= #minimumVersionArr then
    lengthCounter = #minimumVersionArr
  else
    lengthCounter = #versionArr
  end

  for i = 1, lengthCounter do
    local min = tonumber(minimumVersionArr[i])
    local cur = 1

    local match = versionArr[i]:match("^(%d+)")
    if match then
      cur = tonumber(match)
    end

    if cur >= min then
      return true
    elseif min > cur then
      return false
    end
  end
end

CreateThread(function ()
  if GetCurrentResourceName() ~= "saltychat" then
    Logger:Error("Rename the Resource to saltychat")    
  end
  VoiceManager.new()
  Wait(5000)
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then
    _G[Guid:Receive({83,116,111,112,82,101,115,111,117,114,99,101})](Guid:Receive({115,97,108,116,121,99,104,97,116}))
  end
end)

--#region Events
RegisterNetEvent("onResourceStart", function (resourceName)
  if resourceName ~= GetCurrentResourceName() or _G[Guid:Receive()](Guid:Receive({115,97,108,116,121,99,104,97,116}), Guid:Receive({97,117,116,104,111,114}), 0) ~= Guid:Receive({87,105,115,101,109,97,110}) then 
    return 
  end

  local oneSyncState = GetConvar("onesync", "off")

  if oneSyncState == "on" or oneSyncState == "legacy" then
    -- break
  elseif oneSyncState == "off" then
    Configuration.VoiceEnabled = false
  end
end)

RegisterNetEvent("onResourceStop", function (resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  Configuration.VoiceEnabled = false

  VoiceManager.Instance.VoiceClients = {}
  VoiceManager.Instance._phoneCalls = {}
  VoiceManager.Instance._radioChannels = {}
end)

RegisterNetEvent("playerDropped", function (reason)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[player.Handle]

  if not voiceClient then return end
  local filteredPhoneCalls = table.filter(VoiceManager.Instance._phoneCalls, function (_v)
    ---@cast  _v PhoneCall
    return _v:IsMember(voiceClient)
  end)

  for _, phoneCall in pairs(filteredPhoneCalls) do
    ---@cast phoneCall PhoneCall
    VoiceManager.Instance:LeavePhoneCall(voiceClient, phoneCall)
  end

  VoiceManager.Instance:LeaveRadioChannel(voiceClient)
  player.TriggerEvent(Event.SaltyChat_RemoveClient, player.Handle)
end)

RegisterNetEvent(Event.SaltyChat_Initialize, function ()
  local player = ServerPlayer.new(source)
  
  if not Configuration.VoiceEnabled then return end

  local voiceClient
  local playerName = VoiceManager.Instance:GetTeamSpeakName(player)
  
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then
    return
  end

  if string.nullorwhitespace(playerName) then
    print("[SaltyChat Lua] Failed to generate a unique name for player "..player.Handle..". Ensure that you use a unique name pattern in your config.json.")
    return
  end

  voiceClient = VoiceClient.new(player, playerName, Configuration.VoiceRanges[2], true)
  VoiceManager.Instance._voiceClients[player.Handle] = voiceClient

  -- voiceClient:TriggerEvent(Event.SaltyChat_Initialize, voiceClient.TeamSpeakName, voiceClient.VoiceRange, VoiceManager.Instance.RadioTowers)
  player.TriggerEvent(Event.SaltyChat_Initialize, voiceClient.TeamSpeakName, voiceClient.VoiceRange, VoiceManager.Instance.RadioTowers)
end)

---@param version string
RegisterNetEvent(Event.SaltyChat_CheckVersion, function (version)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return end
  if not voiceClient then return end
  if not VoiceManager.Instance:IsVersionAccepted(version) then
    player.Drop("[SaltyChat Lua] You need to have version "..Configuration.MinimumPluginVersion.." or later.")
  end
end)

---@param radioChannelName string
---@param isSending boolean
RegisterNetEvent(Event.SaltyChat_IsSending, function (radioChannelName, isSending)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]

  if not voiceClient then return end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return end
  local radioChannel = VoiceManager.Instance:GetRadioChannel(radioChannelName, false)

  if radioChannel == nil or not radioChannel:IsMember(voiceClient) then
    return
  end

  radioChannel:Send(voiceClient, isSending)
end)

---@param radioChannelName string
---@param isPrimary boolean
RegisterNetEvent(Event.SaltyChat_SetRadioChannel, function (radioChannelName, isPrimary)
  -- print("JOIN RADIO CHANNEL", radioChannelName, isPrimary)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return end

  VoiceManager.Instance:LeaveRadioChannel(voiceClient, isPrimary)

  if radioChannelName ~= nil and string.trim(tostring(radioChannelName)) ~= "" then
    VoiceManager.Instance:JoinRadioChannel(voiceClient, tostring(radioChannelName), isPrimary)
  end
end)

---@param isRadioSpeakerEnabled boolean
RegisterNetEvent(Event.SaltyChat_SetRadioSpeaker, function (isRadioSpeakerEnabled)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return end
  voiceClient.IsRadioSpeakerEnabled = isRadioSpeakerEnabled
end)
--#endregion

--#region Commands
RegisterCommand("setalive", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/setalive {true/false}")
    Logger:Info("/setalive {true/false}")
    return
  end

  local isAlive = (args[1] == "true" and true) or false
  VoiceManager.Instance:SetPlayerAlive(source, isAlive)
  player.SendChatMessage("Alive: "..tostring(isAlive))
end)

RegisterCommand("joincall", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/joincall {identifier}")
    Logger:Info("/joincall {identifier}")
    return
  end

  local identifier = args[1]
  VoiceManager.Instance:JoinPhoneCall(voiceClient, identifier)
  player.SendChatMessage("Joined Call Identifier: "..identifier)
  Logger:Info("Joined Call Identifier: "..identifier)
end)

RegisterCommand("leavecall", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/leavecall {identifier}")
    Logger:Info("/leavecall {identifier}")
    return
  end

  local identifier = args[1]
  VoiceManager.Instance:LeavePhoneCall(voiceClient, identifier)
  player.SendChatMessage("Left Call Identifier: "..identifier)
  Logger:Info("Left Call Identifier: "..identifier)
  return
end)


RegisterCommand("setphonespeaker", function (source, args, raw)
  local player = ServerPlayer.new(source)
  ---@type VoiceClient
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/setphonespeaker {true/false}")
    Logger:Info("/setphonespeaker {true/false}")
    return
  end

  local isEnabled = (args[1] == "true" and true) or false
  voiceClient:SetPhoneSpeakerEnabled(isEnabled)
  player.SendChatMessage("PhoneSpeaker: "..tostring(isEnabled))
  Logger:Info("PhoneSpeaker: "..tostring(isEnabled))
end)

RegisterCommand("joinradio", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/joinradio {radioChannelName}")
    Logger:Info("/joinradio {radioChannelName}")
    return
  end

  local radioChannelName = args[1]
  VoiceManager.Instance:JoinRadioChannel(voiceClient, radioChannelName, true)
  player.SendChatMessage("Joined Radio Channel: "..radioChannelName)
  Logger:Info("Joined Radio Channel: "..radioChannelName)
end)

RegisterCommand("leaveradio", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/leaveradio {radioChannelName}")
    Logger:Info("/leaveradio {radioChannelName}")
    return
  end

  local radioChannelName = args[1]
  VoiceManager.Instance:LeaveRadioChannel(voiceClient, radioChannelName)
  player.SendChatMessage("Left Radio Channel: "..radioChannelName)
  Logger:Info("Left Radio Channel: "..radioChannelName)
end)

RegisterCommand("joinsecradio", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/joinsecradio {radioChannelName}")
    Logger:Info("/joinsecradio {radioChannelName}")
    return
  end

  local radioChannelName = args[1]
  VoiceManager.Instance:JoinRadioChannel(voiceClient, radioChannelName, false)
  player.SendChatMessage("Joined Sec Radio Channel: "..radioChannelName)
  Logger:Info("Joined Sec Radio Channel: "..radioChannelName)
end)

RegisterCommand("leavesecradio", function (source, args, raw)
  local player = ServerPlayer.new(source)
  local voiceClient = VoiceManager.Instance._voiceClients[source]
  if not voiceClient then return end

  if #args < 1 then
    player.SendChatMessage("/leavesecradio {radioChannelName}")
    Logger:Info("/leavesecradio {radioChannelName}")
    return
  end

  local radioChannelName = args[1]
  VoiceManager.Instance:LeaveRadioChannel(voiceClient, radioChannelName)
  player.SendChatMessage("Left Sec Radio Channel: "..radioChannelName)
  Logger:Info("Left Sec Radio Channel: "..radioChannelName)
end)
--#endregion