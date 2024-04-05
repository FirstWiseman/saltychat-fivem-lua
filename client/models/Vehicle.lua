---@enum VehicleDoorIndex
VehicleDoorIndex = {
  FrontLeftDoor = 0,
  FrontRightDoor = 1,
  BackLeftDoor = 2,
  BackRightDoor = 3,
  Hood = 4,
  Trunk = 5
}

---@enum VehicleRoofState
VehicleRoofState = {
     Closed = 0,
     Closing = 1,
     Open = 2,
     Opening = 3,
     Broken = 6
};

---@enum VehicleSeat
VehicleSeat = {
  Driver = -1,
  Passenger = 0,
  BackDriverSide = 1,
  BackPassengerSide = 2,
}

---@class Vehicle
---@field Handle integer
---@field IsConvertible boolean
---@field RoofState integer
---@field Doors {Length: number, GetAll: fun(): {Index: integer, IsBroken: boolean, IsOpen: boolean}}
---@field Windows {AreAllIntact: boolean}
Vehicle = {}
Vehicle.__index = Vehicle

function Vehicle.new(vehicleHandle)
  local self = setmetatable({}, Vehicle)
  local metatable = {
      __index = function(list, key)
        if list.vehicle[key] then
            return list.vehicle[key]()
        else
            return nil
        end
      end
  }
  setmetatable(self, metatable)

  self.vehicle = {}
  self.vehicle.Handle = function ()
    return vehicleHandle
  end
  self.vehicle.IsConvertible = function ()
    return IsVehicleAConvertible(self.Handle, false)
  end
  self.vehicle.RoofState = function ()
    return GetConvertibleRoofState(self.Handle)
  end
  
  self.vehicle.Doors = function ()
    return {
      Length = GetNumberOfVehicleDoors(self.Handle),
      GetAll = function ()
        local doors = {}
        for i=0, GetNumberOfVehicleDoors(self.Handle) do
          if GetIsDoorValid(self.Handle, i) then
            table.insert(doors, {
              Index = i,
              IsBroken = IsVehicleDoorDamaged(self.Handle, i),
              IsOpen = IsVehicleDoorFullyOpen(self.Handle, i)
            })
          end
        end
        return doors
      end
    }
  end

  self.vehicle.Windows = function ()
    return {
      AreAllIntact = AreAllVehicleWindowsIntact(self.Handle),
      GetAllWindows = function ()
        local windows = {}
        for i = 0, GetNumberOfVehicleDoors(self.Handle) do
          if GetIsDoorValid(self.Handle, i) then
            if i ~= VehicleDoorIndex.Hood and i ~= VehicleDoorIndex.Trunk then
              table.insert(windows, {
                Intact = IsVehicleWindowIntact(self.Handle, i)
              })
            end
          end
        end

        for i = 6, 7 do
          table.insert(windows, {
            Intact = IsVehicleWindowIntact(self.Handle, i)
          })
        end
        return windows
      end
    }
  end
  return self
end