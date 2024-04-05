---@enum GameInstanceState
GameInstanceState = {
  NotInitiated = -1,
  NotConnected = 0,
  Connected = 1,
  Ingame = 2,
  InSwissChannel = 3,
}

---@class InstanceState
---@field IsConnectedToServer boolean
---@field IsReady boolean
---@field State GameInstanceState
InstanceState = {
  IsConnectedToServer = nil,
  IsReady = nil,
  State = nil
}