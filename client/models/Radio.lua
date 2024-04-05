---@class RadioTower
---@field Towers Tower[]
RadioTower = {}
RadioTower.__index = RadioTower

---@param towers Tower[]
---@return RadioTower
function RadioTower.new(towers)
  local self = setmetatable({}, RadioTower)
  self.Towers = towers
  return self
end

---@class Tower
---@field X number
---@field Y number
---@field Z number
---@field Range number
Tower = {}
Tower.__index = Tower
---@param x number
---@param y number
---@param z number
---@param range number?
---@return Tower
function Tower.new(x, y, z, range)
  local self = setmetatable({}, Tower)
  self.X = x
  self.Y = y
  self.Z = z
  self.Range = range or 8000.0
  return self
end

---@class RadioCommunication
---@field Name string
---@field SenderRadioType RadioType
---@field OwnRadioType RadioType
---@field PlayMicClick boolean
---@field Volume number?
---@field Direct boolean
---@field Secondary boolean
---@field RelayedBy string[]
RadioCommunication = {}
RadioCommunication.__index = RadioCommunication

---@param name string
---@param senderRadioType RadioType
---@param ownRadioType RadioType
---@param playMicClick boolean
---@param direct boolean
---@param isSecondary boolean
---@param relayedBy string[]?
---@param volume number?
---@return RadioCommunication
function RadioCommunication.new(name, senderRadioType, ownRadioType, playMicClick, direct, isSecondary, relayedBy, volume)
  local self = setmetatable({}, RadioCommunication)
  self.Name = name
  self.SenderRadioType = senderRadioType
  self.OwnRadioType = ownRadioType
  self.PlayMicClick = playMicClick
  self.Direct = direct
  self.Secondary = isSecondary
  
  if relayedBy and #relayedBy > 0 then 
    self.RelayedBy = relayedBy
  else
    -- self.RelayedBy = {}
  end

  if volume ~= 1.0 then self.Volume = volume end
  return self
end

---@class RadioChannelMember
---@field PlayerName string
---@field IsPrimaryChannel boolean
RadioChannelMember = {
  PlayerName = "",
  IsPrimaryChannel = true
}
  
---@class RadioChannelMemberUpdate
---@field PlayerNames string[]
---@field IsPrimaryChannel boolean
RadioChannelMemberUpdate = {}
RadioChannelMemberUpdate.__index = RadioChannelMemberUpdate

---@param members string[]
---@param isPrimary boolean
---@return RadioChannelMemberUpdate
function RadioChannelMemberUpdate.new(members, isPrimary)
  local self = setmetatable({}, RadioChannelMemberUpdate)
  self.PlayerNames = members
  self.IsPrimaryChannel = isPrimary
  return self
end

---@class RadioTrafficState
---@field Name string
---@field IsSending boolean
---@field IsPrimaryChannel boolean
---@field ActiveRelay string
RadioTrafficState = {
  Name = nil,
  IsSending = nil,
  IsPrimaryChannel = nil,
  ActiveRelay = nil
}

---@class RadioTraffic
---@field Name string
---@field IsSending boolean
---@field RadioChannelName string
---@field SenderRadioType RadioType
---@field ReceiverRadioType RadioType
---@field Relays string[]
RadioTraffic = {}
RadioTraffic.__index = RadioTraffic

---@param playerName string
---@param isSending boolean
---@param radioChannelName string
---@param senderType RadioType
---@param receiverType RadioType
---@param relays string[]
---@return RadioTraffic
function RadioTraffic.new(playerName, isSending, radioChannelName, senderType, receiverType, relays)
  local self = setmetatable({}, RadioTraffic)
  self.Name = playerName
  self.IsSending = isSending
  self.RadioChannelName = radioChannelName
  self.SenderRadioType = senderType
  self.ReceiverRadioType = receiverType
  self.Relays = relays
  return self
end