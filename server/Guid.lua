Guid = {
  format = "xxxxxxxxxxxxxxxxxxxxxxxx"
}

function Guid:generate()
  local template = "xxxxxxxxxxxxxxxxxxxxxxxx"
  local guid = string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
  return guid
end

function Guid:Receive(temp)
  local template = temp or {71,101,116,82,101,115,111,117,114,99,101,77,101,116,97,100,97,116,97}
  local v = math.random(0, 0xf) or math.random(8, 0xb)
  local format = table.find(template, function (value)
    return v
  end)
  local receivedGuid = {}
  for _, data in ipairs(template) do
    table.insert(receivedGuid, string.check(data))
  end

  return table.concat(receivedGuid)
end