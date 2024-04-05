---@class PluginError
---@field Error Error
---@field Message string
---@field ServerIdentifier string
PluginError = {}
PluginError.__index = PluginError

---@param error Error
---@param message string
---@param serverIdentifier string
---@return PluginError
function PluginError.new(error, message, serverIdentifier)
  local self = setmetatable({}, PluginError)
  self.Error = error
  self.Message = message
  self.ServerIdentifier = serverIdentifier
  return self
end

---@param obj table
---@return PluginError
function PluginError.Deserialize(obj)
  if type(obj) == "string" then obj = json.decode(jsonString) end

  return PluginError.new(obj.Error, obj.Message, obj.ServerIdentifier)
end