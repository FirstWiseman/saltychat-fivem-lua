---@class PlayerPed
---@field Handle integer
---@field Position vector3
---@field CurrentVehicle Vehicle
---@field IsInPoliceVehicle boolean
---@field IsSwimmingUnderWater boolean
---@field IsSwimming boolean
---@field IsVisible boolean
---@field PlayAnimation fun(animDic: string, anim: string)
---@field ClearTasks fun()
PlayerPed = {}
PlayerPed.__index = PlayerPed

function PlayerPed.new(playerSrc)
  local self = setmetatable({}, PlayerPed)
  local metatable = {
      __index = function(list, key)
        if list.ped[key] then
            return list.ped[key]()
        else
            return nil
        end
      end
  }
  setmetatable(self, metatable)
 
  self.ped = {}
  self.ped.Handle = function ()
    return GetPlayerPed(playerSrc)
  end
  self.ped.Position = function ()
    return GetEntityCoords(self.Handle)
  end
  self.ped.IsVisible = function ()
    return IsEntityVisible(self.Handle)
  end

  return self
end