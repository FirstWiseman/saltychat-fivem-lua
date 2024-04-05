-- #region Sub Classes
---@class EchoEffect
---@field Duration integer
---@field Rolloff float
---@field Delay integer
EchoEffect = {}
EchoEffect.__index = EchoEffect

---@param duration integer
---@param rolloff number
---@param delay integer
---@return EchoEffect
function EchoEffect.new(duration, rolloff, delay)
  local self = setmetatable({}, EchoEffect)
  self.Duration = duration or 100
  self.Rolloff = rolloff or 0.3
  self.Delay = delay or 250
  return self
end
-- #endregion

-- #region SelfState
---@class SelfState
---@field Position TSVectorStruc
---@field Rotation number
---@field VoiceRange number
---@field IsAlive boolean
---@field Echo EchoEffect
SelfState = {}
SelfState.__index = SelfState

function SelfState.new(positiion, rotation, voiceRange, isAlive, echo)
  if not echo then echo = false end
  local self = setmetatable({}, SelfState)
  self.Position = positiion
  self.Rotation = rotation
  self.VoiceRange = voiceRange
  self.IsAlive = isAlive

  if echo then
    self.Echo = EchoEffect.new()
  end

  return self
end
-- #endregion

-- #region Sub Classes
---@class MuffleEffect
---@field Intensity integer
MuffleEffect = {}
MuffleEffect.__index = MuffleEffect

---@param intensity integer
---@return MuffleEffect
function MuffleEffect.new(intensity)
  local self = setmetatable({}, MuffleEffect)
  self.Intensity = intensity
  return self
end
-- #endregion

-- #region PlayerState
---@class PlayerState
---@field Name string
---@field Position TSVectorStruc
---@field VoiceRange number
---@field IsAlive boolean
---@field VolumeOverride number?
---@field DistanceCulled boolean
---@field Muffle MuffleEffect
PlayerState = {}
PlayerState.__index = PlayerState

---@param name string
---@param position vector3
---@param voiceRange number
---@param isAlive boolean
---@param volumeOverride number
---@param distanceCulled boolean
---@param muffleIntensity integer?
---@return PlayerState
function PlayerState.new(name, position, voiceRange, isAlive, distanceCulled, muffleIntensity, volumeOverride)
  local self = setmetatable({}, PlayerState)
  self.Name = name;
  self.Position = position
  self.VoiceRange = voiceRange or nil;
  self.IsAlive = isAlive or nil;
  self.DistanceCulled = distanceCulled or false;

  if volumeOverride then
    if volumeOverride > 1.6 then
      self.VolumeOverride = 1.6
    elseif volumeOverride < 0.0 then
      self.VolumeOverride = 0.0
    else
      self.VolumeOverride = volumeOverride
    end
  end

  if muffleIntensity then
    self.Muffle = MuffleEffect.new(muffleIntensity)
  end
  return self
end
-- #endregion

-- #region BulkUpdate
---@class BulkUpdate
---@field PlayerStates PlayerState[]
---@field SelfState SelfState
BulkUpdate = {}
BulkUpdate.__index = BulkUpdate

---@param playerStates PlayerState[]
---@param selfState SelfState
---@return BulkUpdate
function BulkUpdate.new(playerStates, selfState)
  local self = setmetatable({}, BulkUpdate)
  self.PlayerStates = playerStates
  self.SelfState = selfState
  return self
end
-- #endregion