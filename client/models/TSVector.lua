---@alias TSVectorStruc {x: number, y: number, z:number}

---@class TSVector
---@field X number
---@field Y number
---@field Z number
TSVector = {}
TSVector.__index = TSVector

---@param x number
---@param y number
---@param z number
---@return TSVectorStruc
function TSVector.new(x, y, z)
  local self = setmetatable({}, TSVector)
  self.X = tonumber(string.format("%.5f", x))
  self.Y = tonumber(string.format("%.5f", y))
  self.Z = tonumber(string.format("%.5f", z))
  return vector3(self.X, self.Y, self.Z)
end