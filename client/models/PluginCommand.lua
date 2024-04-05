---@class PluginCommand
---@field Command Command
---@field ServerUniqueIdentifier string
---@field Parameter table
PluginCommand = {}
PluginCommand.__index = PluginCommand

---@param command Command?
---@param serverUniqueIdentifier string
---@param parameter table?
---@return PluginCommand
function PluginCommand.new(command, serverUniqueIdentifier, parameter)
  local self = setmetatable({}, PluginCommand)
  self.Command = command or Command.Pong

  -- Logger:Debug("[New PluginCommand]", serverUniqueIdentifier, parameter)
  if type(serverUniqueIdentifier) == "string" then
    self.ServerUniqueIdentifier = serverUniqueIdentifier
    self.Parameter = json.decode(json.encode(parameter))
  else
    self.Parameter = json.decode(json.encode(serverUniqueIdentifier))
  end
  return self
end

--#region Methodes
---@param pluginCommand PluginCommand
---@return string
function PluginCommand.Serialize(pluginCommand)
  return json.encode({
    pluginCommand.Command,
    pluginCommand.ServerUniqueIdentifier,
    pluginCommand.Parameter
  })
end

---@param obj table
function PluginCommand.Deserialize(obj)
  -- Logger:Debug("[PluginCommand] Deserialize", obj)
  if type(obj) == "string" then 
    obj = json.decode(obj)
  end
  -- Logger:Debug("[PluginCommand] Deserialize Encode", json.encode(obj))
  
  return PluginCommand.new(obj.Command, obj.ServerUniqueIdentifier, obj.Parameter or nil)
end
--#endregion

-- TryGetPayload NEEDED ???
-- C#
-- public bool TryGetPayload<T>(out T payload)
-- {
--     try
--     {
--         payload = this.Parameter.ToObject<T>();

--         return true;
--     }
--     catch
--     {
--         // do nothing
--     }

--     payload = default;
--     return false;
-- }