---@class PhoneCommunication
---@field Name string
---@field SignalStrength integer?
---@field Volume number?
---@field Direct boolean
---@field RelayedBy string[]
PhoneCommunication = {}
PhoneCommunication.__index = PhoneCommunication

---@param name string
---@param signalStrength integer?
---@param volume number?
---@param direct boolean?
---@param relayedBy string[]?
---@return PhoneCommunication
function PhoneCommunication.new(name, signalStrength, volume, direct, relayedBy)
  local self = setmetatable({}, PhoneCommunication)
  self.Name = name
  self.SignalStrength = signalStrength
  self.Volume = volume
  
  if direct then
    self.Direct = direct
  else
    self.Direct = true
  end

  if relayedBy then
    self.RelayedBy = relayedBy
  else
    self.RelayedBy = {}
  end
  return self
end
