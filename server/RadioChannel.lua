---@class RadioChannel
---@field Name string
---@field _members RadioChannelMember[]
---@field _memberLock table
RadioChannel = {}
RadioChannel.__index = RadioChannel

---@param name string
---@param members RadioChannelMember[]
function RadioChannel.new(name, members)
  local self = setmetatable({}, RadioChannel)
  self.Name = name
  self._members = {}
  
  if members ~= nil then
    for _, member in pairs(members) do
      table.insert(self._members, member)
    end
  end
  return self
end

---@param voiceClient VoiceClient
---@return boolean
function RadioChannel:IsMember(voiceClient)
  return table.any(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return voiceClient.TeamSpeakName == _v.VoiceClient.TeamSpeakName
  end)
end

---@param voiceClient VoiceClient
---@param isPrimary boolean
function RadioChannel:AddMember(voiceClient, isPrimary)
  if not self:IsMember(voiceClient) then
    table.insert(self._members, RadioChannelMember.new(self, voiceClient, isPrimary))
    voiceClient:TriggerEvent(Event.SaltyChat_SetRadioChannel, self.Name, isPrimary)

    self:UpdateMemberStateBag()
  end
end

---@param voiceClient VoiceClient
function RadioChannel:RemoveMember(voiceClient)
  ---@type RadioChannelMember
  local member = table.find(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName
  end)

  if member ~= nil then
    local memberIndex = table.findIndex(self._members, function (_v)
      ---@cast _v RadioChannelMember
      return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName
    end)

    table.remove(self._members, memberIndex)
    voiceClient:TriggerEvent(Event.SaltyChat_SetRadioChannel, nil, member.IsPrimary)

    if member.IsSending then
      self:UpdateSenderStateBag()
    end

    self:UpdateMemberStateBag()
  end
end

---@param voiceClient VoiceClient
---@param isSending boolean
function RadioChannel:Send(voiceClient, isSending)
  local member = self:TryGetMember(voiceClient)
  if not member then return end

  local b = table.any(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return _v.VoiceClient.TeamSpeakName ~= voiceClient.TeamSpeakName and _v.IsSending
  end)

  if VoiceManager.Instance.Configuration.EnableRadioHardcoreMode and isSending and b then
    voiceClient:TriggerEvent(Event.SaltyChat_ChannelInUse, self.Name)
    return
  end

  if not voiceClient.IsAlive and isSending then return end

  member.IsSending = isSending
  self:UpdateSenderStateBag()
end

---@param voiceClient VoiceClient
---@return RadioChannelMember
function RadioChannel:TryGetMember(voiceClient)
  ---@type RadioChannelMember
  local member = table.find(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName
  end)

  return member
end

function RadioChannel:UpdateMemberStateBag()
  VoiceManager.Instance:SetStateBagKey(State.SaltyChat_RadioChannelMember..":"..self.Name, table.map(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return _v.VoiceClient.TeamSpeakName
  end))
end

function RadioChannel:UpdateSenderStateBag()
  local sender = {}
  local membersSending = table.filter(self._members, function (_v)
    ---@cast _v RadioChannelMember
    return _v.IsSending
  end)

  for _, sendingMember in pairs(membersSending) do
    ---@cast sendingMember RadioChannelMember
    table.insert(sender, {
      ServerId = sendingMember.VoiceClient.Player.Handle,
      Name = sendingMember.VoiceClient.TeamSpeakName,
      Position = sendingMember.VoiceClient.Player.GetPosition()
    })
  end

  VoiceManager.Instance:SetStateBagKey(State.SaltyChat_RadioChannelSender..":"..self.Name, sender)
end

---@param eventName string
---@param args any
function RadioChannel:BroadcastEvent(eventName, args)
  for _, member in pairs(self._members) do
    ---@cast member RadioChannelMember
    member.VoiceClient:TriggerEvent(eventName, args)
  end
end

---@class RadioChannelMember
---@field RadioChannel RadioChannel
---@field VoiceClient VoiceClient
---@field IsPrimary boolean
---@field IsSending boolean
RadioChannelMember = {}
RadioChannelMember.__index = RadioChannelMember

---@param radioChannel string
---@param voiceClient VoiceClient
---@param isPrimary boolean
---@return RadioChannelMember
function RadioChannelMember.new(radioChannel, voiceClient, isPrimary)
  local self = setmetatable({}, RadioChannelMember)
  self.RadioChannel = radioChannel
  self.VoiceClient = voiceClient
  self.IsPrimary = isPrimary
  return self
end