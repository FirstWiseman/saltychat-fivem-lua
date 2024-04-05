---@class ClientPlayer
---@field Handle integer
---@field Name string
---@field State table
---@field ServerId integer
---@field Character PlayerPed
---@field GetIsAlive fun(): boolean
ClientPlayer = {}
ClientPlayer.__index = ClientPlayer

function ClientPlayer.new(playerIndex)
  local self = setmetatable({}, ClientPlayer)
  self.Handle = playerIndex
  self.Name = GetPlayerName(playerIndex)
  self.State = {}
  self.ServerId = GetPlayerServerId(playerIndex)
  self.Character = PlayerPed.new(playerIndex)
  self.GetIsAlive = function ()
    return not IsPlayerDead(playerIndex)
  end

  setmetatable(self.State, {
    __index = function (list, key)
      return Player(self.ServerId).state[key]
    end,

    __newindex = function (list, key, value)
      Player(self.ServerId).state:set(key, value, true)
    end
  })

  return self
end

---@return table<integer, ClientPlayer>
function GetServerPlayers()
  local playersKnownToClient = {}
  for _, playerIndex in pairs(GetActivePlayers()) do
    local player = ClientPlayer.new(playerIndex)
    playersKnownToClient[player.ServerId] = player
  end

  return playersKnownToClient
end

---@param serverId integer
---@return ClientPlayer
function GetPlayer(serverId)
  local players = GetServerPlayers()
  return players[serverId]
end

---@alias GamePlayer
GamePlayer = ClientPlayer.new(PlayerId())