---@class MegaphoneCommunication
---@field Name string
---@field Range number
---@field Volume number?
MegaphoneCommunication = {}
MegaphoneCommunication.__index = MegaphoneCommunication

---@param name string
---@param range number
---@param volume number?
---@return MegaphoneCommunication
function MegaphoneCommunication.new(name, range, volume)
  local self = setmetatable({}, MegaphoneCommunication)
  self.Name = name
  self.Range = range
  self.Volume = volume or nil
  return self
end

---@return boolean
function MegaphoneCommunication:ShouldSerializeVolume()
  return self.Volume ~= nil
end