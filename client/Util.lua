---@class Util
Util = {
  -- #region Player Extensions
  ---@param netid integer
  ---@return string
  GetTeamSpeakName = function (netid)
    --- WHERE TO GET FROM????
    return Player(netid).state[State.SaltyChat_TeamSpeakName]
  end,

  ---@param netid integer
  ---@return number
  GetVoiceRange = function (netid)
    return Player(netid).state[State.SaltyChat_VoiceRange] or 0.0
  end,

  ---@param netid integer
  ---@return boolean
  GetIsAlive = function (netid)
    return Player(netid).state[State.SaltyChat_IsAlive] == true
  end,
  -- #endregion

  -- #region Vehicle Extensions
  ---@param vehicle Vehicle
  ---@return boolean
  HasOpening = function (vehicle)
    if type(vehicle) ~= "table" then return nil end

    local doors = vehicle.Doors
    return doors.Length == 0 or table.any(doors.GetAll(), function (d) 
      return d.Index ~= VehicleDoorIndex.Hood and (d.IsBroken or d.IsOpen) 
    end) or not vehicle.Windows.AreAllIntact or table.any(vehicle.Windows.GetAllWindows(), function (a)
      return not a.Intact
    end) or (vehicle.IsConvertible and vehicle.RoofState ~= VehicleRoofState.Closed)
  end
  -- #endregion
}