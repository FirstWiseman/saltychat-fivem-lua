---@class PlayerPed
---@field Handle integer
---@field Position vector3
---@field CurrentVehicle Vehicle
---@field IsInPoliceVehicle boolean
---@field IsSwimmingUnderWater boolean
---@field IsSwimming boolean
---@field IsVisible boolean
---@field PlayAnimation fun(animDic: string, anim: string, blendInSpeed: number, blendOutSpeed: number, duration: integer, flag: integer)
---@field ClearTasks fun()
---@field StopAnim fun(animDic: string, anim: string, exitSpeed: number)
PlayerPed = {}
PlayerPed.__index = PlayerPed

function PlayerPed.new(playerIndex)
  local self = setmetatable({}, PlayerPed)
  local metatable = {
      __index = function(list, key)
        if list.ped[key] and type(list.ped[key]) == "function" then
            return list.ped[key]()
        else
            return nil
        end
      end
  }
  setmetatable(self, metatable)
 
  self.ped = {}
  self.ped.Handle = function ()
    return GetPlayerPed(playerIndex)
  end

  self.ped.Position = function ()
    local x, y, z = table.unpack(GetEntityCoords(self.Handle))
    return TSVector.new(x, y, z)
  end

  self.ped.CurrentVehicle = function ()
    local vehicleHandle = GetVehiclePedIsIn(self.Handle, false)
    local vehicle = Vehicle.new(vehicleHandle)
    return (vehicleHandle ~= 0 and vehicle) or nil
  end

  self.ped.IsInPoliceVehicle = function ()
    return IsPedInAnyPoliceVehicle(self.Handle)
  end

  self.ped.IsSwimmingUnderWater = function ()
    return IsPedSwimmingUnderWater(self.Handle)
  end

  self.ped.IsSwimming = function ()
    return IsPedSwimming(self.Handle)
  end

  self.ped.IsVisible = function ()
    return IsEntityVisible(self.Handle)
  end

  self.PlayAnimation = function (animDic, anim, blendInSpeed, blendOutSpeed, duration, flag)
    while (not HasAnimDictLoaded(animDic)) do
      RequestAnimDict(animDic)
      Wait(5)
    end

    TaskPlayAnim(self.Handle, animDic, anim, blendInSpeed, blendOutSpeed, duration, flag, 0, false, false, false)
  end

  self.ClearTasks = function ()
    ClearPedTasks(self.Handle)
  end

  self.StopAnim = function(animDic, anim, exitSpeed) 
    StopAnimTask(self.Handle, animDic, anim, exitSpeed)
  end

  return self
end