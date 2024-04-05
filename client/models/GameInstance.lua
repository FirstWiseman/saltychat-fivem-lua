GameInstance = {}
GameInstance.__index = GameInstance

---@param serverUniqueIdentifier string
---@param name string
---@param channelId number
---@param channelPassword string
---@param soundPack string
---@param swissChannels number[]
---@param sendTalkStates boolean
---@param sendRadioTrafficStates boolean
---@param ultraShortRangeDistance number
---@param shortRangeDistance number
---@param longRangeDistace number
---@return table
function GameInstance.new(serverUniqueIdentifier, name, channelId, channelPassword, soundPack, swissChannels, sendTalkStates, sendRadioTrafficStates, ultraShortRangeDistance, shortRangeDistance, longRangeDistace)
  local self = setmetatable({}, GameInstance)
  self.ServerUniqueIdentifier = serverUniqueIdentifier
  self.Name = name
  self.ChannelId = channelId
  self.ChannelPassword = channelPassword
  self.SoundPack = soundPack
  self.SwissChannelIds = swissChannels
  self.SendTalkStates = sendTalkStates
  self.SendRadioTrafficStates = sendRadioTrafficStates
  self.UltraShortRangeDistance = ultraShortRangeDistance
  self.ShortRangeDistance = shortRangeDistance
  self.LongRangeDistace = longRangeDistace
  return self
end