---@class VoiceClient
---@field Player ServerPlayer
---@field TeamSpeakName string
---@field VoiceRange number
---@field IsAlive boolean
---@field IsRadioSpeakerEnabled boolean
VoiceClient = {}
VoiceClient.__index = VoiceClient

function VoiceClient.new(player, teamSpeakName, voiceRange, isAlive)
  local self = {
    Player = player,
    TeamSpeakName = teamSpeakName,
    VoiceRange = voiceRange,
    IsAlive = isAlive,
    IsRadioSpeakerEnabled = nil,
    getters = {},
    setters = {}
  }

  local meta = {
    __index = function(list, key)
      if list.getters[key] and type(list.getters[key]) == "function" then
        return list.getters[key]()
      end
    end,

    __newindex = function(list, key, value)
      if list.setters[key] and type(list.setters[key]) == "function" then
        return list.setters[key](value)
      else
        rawset(list, key, value)
      end
    end
  }

  setmetatable(self, meta)

  self.getters.VoiceRange = function()
    return self.Player.State[State.SaltyChat_VoiceRange] or 0.0
  end
  self.setters.VoiceRange = function(value)
    self.Player.State[State.SaltyChat_VoiceRange] = value
  end

  self.getters.IsAlive = function()
    return self.Player.State[State.SaltyChat_IsAlive] == true
  end
  self.setters.IsAlive = function(value)
    self.Player.State[State.SaltyChat_IsAlive] = value
  end

  self.TriggerEvent = function (self, eventName, ...)
    self.Player.TriggerEvent(eventName, ...)
  end

  self.SetPhoneSpeakerEnabled = function (_self, isEnabled)
    for _, phoneCallMembership in pairs(VoiceManager.Instance:GetPlayerPhoneCallMembership(_self)) do
      phoneCallMembership.PhoneCall:SetSpeaker(self, isEnabled)
    end
  end

  self.Player.State[State.SaltyChat_TeamSpeakName] = teamSpeakName
  return self
end

-- ---@param eventName string
-- ---@param args any
-- function VoiceClient:TriggerEvent(eventName, ...)
--   self.Player.TriggerEvent(eventName, ...)
-- end

---@param isEnabled boolean
function VoiceClient:SetPhoneSpeakerEnabled(isEnabled)
  for _, phoneCallMember in pairs(VoiceManager.Instance:GetPlayerPhoneCallMembership(self)) do
    phoneCallMember.PhoneCall:SetSpeaker(self, isEnabled)
  end
end
