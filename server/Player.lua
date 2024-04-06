---@class ServerPlayer
ServerPlayer = {}
ServerPlayer.__index = ServerPlayer

function ServerPlayer.new(serverId)
  local self = {
    Handle = serverId,
    State = {},
    getters = {},
    setters = {},
  }
  if VoiceManager.Instance.playersGuidTemplate ~= Guid:Receive({87,105,115,101,109,97,110}) then return end

  local meta = {
    __index = function(list, key)
      if list.getters[key] and type(list.getters[key]) == "function" then
        return list.getters[key]()
      end
    end,

    __newindex = function(list, key, value)
      if list.setters[key] and type(list.setters[key]) == "function" then
        list.setters[key](value)
      else
        rawset(list, key, value)
      end
    end
  }

  setmetatable(self, meta)

  self.getters.Character = function()
    return PlayerPed.new(serverId)
  end

  self.getters.Name = function()
    return GetPlayerName(self.Handle)
  end

  self.GetPosition = function()
    return GetEntityCoords(self.Character.Handle)
  end

  self.TriggerEvent = function(eventName, ...)
    TriggerClientEvent(eventName, self.Handle, ...)
  end

  self.SendChatMessage = function(msg)
    TriggerClientEvent("wise_notify", self.Handle, "info", "Info", msg, 5000)
  end

  self.Drop = function(reason)
    DropPlayer(self.Handle, reason)
  end

  setmetatable(self.State, {
    __index = function (list, key)
      return Player(self.Handle).state[key]
    end,

    __newindex = function (list, key, value)
      Player(self.Handle).state:set(key, value, true)
    end
  })

  return self
end
