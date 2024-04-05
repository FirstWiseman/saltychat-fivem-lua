---@class PhoneCall
---@field Identifier string
---@field Members PhoneCallMember[]
PhoneCall = {}
PhoneCall.__index = PhoneCall

---@param identifier string
---@return PhoneCall
function PhoneCall.new(identifier)
  local self = setmetatable({}, PhoneCall)
  self.Identifier = identifier
  self.Members = {}
  return self
end

---@param voiceClient VoiceClient
function PhoneCall:IsMember(voiceClient)
  return table.any(self.Members, function (_v)
    ---@cast _v PhoneCallMember
    return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName
  end)
end

---@param voiceClient VoiceClient
function PhoneCall:AddMember(voiceClient)
  local callMember = PhoneCallMember.new(self, voiceClient)

  if self:IsMember(voiceClient) then return end
  table.insert(self.Members, callMember)

  local handle = voiceClient.Player.Handle
  local tsName = voiceClient.TeamSpeakName
  local position = voiceClient.Player.GetPosition()
  local fRelays = table.filter(self.Members, function(_v) --[[@cast _v PhoneCallMember]] return _v.IsSpeakerEnabled end)
  local relays = table.map(fRelays, function (_v)--[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName end)

  local fMembers = table.filter(self.Members, function (_v)
    ---@cast _v PhoneCallMember
    return _v.VoiceClient.TeamSpeakName ~= voiceClient.TeamSpeakName
  end)
  for _, member in pairs(fMembers) do
    ---@cast member PhoneCallMember
    voiceClient:TriggerEvent(Event.SaltyChat_EstablishCall, member.VoiceClient.Player.Handle, member.VoiceClient.TeamSpeakName, member.VoiceClient.Player.GetPosition())

    if table.size(relays) == 0 then
      member.VoiceClient:TriggerEvent(Event.SaltyChat_EstablishCall, handle, tsName, position)
    end
  end

  if table.size(relays) > 0 then
    for _, client in pairs(VoiceManager.Instance._voiceClients) do
      client:TriggerEvent(
        Event.SaltyChat_EstablishCallRelayed,
        handle,
        tsName,
        position,
        table.any(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == client.TeamSpeakName end),
        relays
      )
    end
  end
end

---@param voiceClient VoiceClient
function PhoneCall:RemoveMember(voiceClient)
  ---@type PhoneCallMember
  local callMember = table.find(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)
  local callMemberIndex = table.findIndex(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)

  if callMember == nil then
    return
  end

  table.removeKey(self.Members, callMemberIndex)

  local handle = voiceClient.Player.Handle
  local fRelays = table.filter(self.Members, function(_v) --[[@cast _v PhoneCallMember]] return _v.IsSpeakerEnabled end)
  local relays = table.map(fRelays, function (_v)--[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName end)

  if table.size(relays) == 0 and callMember.IsSpeakerEnabled then
    for _, client in pairs(VoiceManager.Instance._voiceClients) do
      if client.TeamSpeakName == voiceClient.TeamSpeakName then
        for _, member in pairs(self.Members) do
          voiceClient:TriggerEvent(Event.SaltyChat_EndCall, member.VoiceClient.Player.Handle)
        end
      elseif table.any(self.Members, function(_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == client.TeamSpeakName end) then
        client:TriggerEvent(Event.SaltyChat_EndCall, handle)
      else
        for _, member in pairs(self.Members) do
          client:TriggerEvent(Event.SaltyChat_EndCall, member.VoiceClient.Player.Handle)
        end
      end
    end
  elseif table.size(relays) > 0 then
    for _, client in pairs(VoiceManager.Instance._voiceClients) do
      client:TriggerEvent(Event.SaltyChat_EndCall, handle)

      if callMember.IsSpeakerEnabled or client.TeamSpeakName == voiceClient.TeamSpeakName then
        for _, member in pairs(self.Members) do
          client:TriggerEvent(
            Event.SaltyChat_EstablishCallRelayed,
            member.VoiceClient.Player.Handle,
            member.VoiceClient.TeamSpeakName,
            member.VoiceClient.Player.GetPosition(),
            table.any(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == client.TeamSpeakName end),
            relays
          )
        end
      end
    end
  else
    for _, member in pairs(self.Members) do
      voiceClient:TriggerEvent(Event.SaltyChat_EndCall, member.VoiceClient.Player.Handle)

      member.VoiceClient:TriggerEvent(Event.SaltyChat_EndCall, handle)
    end
  end
end

---@param voiceClient VoiceClient
---@param isEnabled boolean
function PhoneCall:SetSpeaker(voiceClient, isEnabled)
  ---@type PhoneCallMember
  local callMember = table.find(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)
  if callMember == nil or callMember.IsSpeakerEnabled == isEnabled then
    return
  end
  local fRelays = table.filter(self.Members, function(_v) --[[@cast _v PhoneCallMember]] return _v.IsSpeakerEnabled end)
  local relays = table.map(fRelays, function (_v)--[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName end)

  if table.size(relays) == 0 then
    for _, client in pairs(VoiceManager.Instance._voiceClients) do
      if client.TeamSpeakName == voiceClient.TeamSpeakName or table.any(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end) then
        goto continue
      else
        for _, member in pairs(self.Members) do
          client:TriggerEvent(Event.SaltyChat_EndCall, member.VoiceClient.Player.Handle)
        end
      end
    end
  else
    for _, client in pairs(VoiceManager.Instance._voiceClients) do
      if client.TeamSpeakName == voiceClient.TeamSpeakName or table.any(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end) then
        goto continue
      else
        for _, member in pairs(self.Members) do
          client:TriggerEvent(Event.SaltyChat_EstablishCallRelayed, member.VoiceClient.Player.Handle, member.VoiceClient.TeamSpeakName, member.VoiceClient.Player.GetPosition(), false, relays)
        end
      end
    end
  end
    ::continue::
end

---@param voiceClient VoiceClient
function PhoneCall:TryGetMember(voiceClient)
  local callMember = table.find(self.Members, function (_v) --[[@cast _v PhoneCallMember]] return _v.VoiceClient.TeamSpeakName == voiceClient.TeamSpeakName end)

  return callMember
end

---@class PhoneCallMember
---@field PhoneCall PhoneCall
---@field VoiceClient VoiceClient
---@field IsSpeakerEnabled boolean
PhoneCallMember = {}
PhoneCallMember.__index = PhoneCallMember

---@param phoneCall PhoneCall
---@param voiceClient VoiceClient
---@return PhoneCallMember
function PhoneCallMember.new(phoneCall, voiceClient)
  local self = setmetatable({}, PhoneCallMember)
  self.PhoneCall = phoneCall
  self.VoiceClient = voiceClient
  self.IsSpeakerEnabled = false
  return self
end