---@class VoiceClient
---@field ServerId integer
---@field Player ClientPlayer
---@field TeamSpeakName string
---@field VoiceRange number
---@field IsAlive boolean
---@field IsUsingMegaphone boolean
---@field LastPosition TSVector
---@field DistanceCulled boolean
VoiceClient = {}
VoiceClient.__index = VoiceClient

function VoiceClient.new(serverId, teamSpeakName, voiceRange, isAlive)
  local self = setmetatable({}, VoiceClient)
  self.ServerId = serverId
  self.Player = ClientPlayer.new(GetPlayerFromServerId(serverId))
  self.TeamSpeakName = teamSpeakName
  self.VoiceRange = voiceRange
  self.IsAlive = isAlive
  self.IsUsingMegaphone = nil
  self.LastPosition = nil
  self.DistanceCulled = nil
  return self
end

---@param voiceManager VoiceManager
function VoiceClient:SendPlayerStateUpdate(voiceManager)
  voiceManager:ExecutePluginCommand(PluginCommand.new(Command.PlayerStateUpdate, voiceManager.Configuration.ServerUniqueIdentifier, PlayerState.new(self.TeamSpeakName, self.LastPosition, self.VoiceRange, self.IsAlive, self.DistanceCulled)));
end