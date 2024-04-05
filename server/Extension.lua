---@class Extension
Extension = {}

function Extension.SendChatMessage(player, sender, message)
  player.TriggerEvent("chatMessage", sender, { 255, 0, 0 }, message);
end

function Extension.GetServerId(player)
  return (type(player.Handle) == "string" and tonumber(player.Handle)) or player.Handle
end