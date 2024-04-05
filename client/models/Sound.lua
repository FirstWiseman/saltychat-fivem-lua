---@class Sound
---@field Filename string
---@field IsLoop boolean
---@field Handle string
Sound = {}
Sound.__index = Sound

function Sound.new(filename, loop, handle)
  local self = setmetatable({}, Sound)
  self.Filename = filename
  self.IsLoop = loop
  if handle then 
    self.Handle = handle
  else
    self.Handle = filename
  end
end