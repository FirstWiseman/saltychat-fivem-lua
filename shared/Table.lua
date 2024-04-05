function table.any(list, cb)
  if not list or not cb then return nil end
  for k, v in pairs(list) do
    if cb(v) then
      return true
    end
  end

  return false
end

function table.size(list)
  local count = 0
  for _, v in pairs(list) do
    if v ~= nil then
      count = count + 1
    end
  end

  return count
end

function table.values(list)
  if not list then return nil end
  local values = {}
  for k, v in pairs(list) do
    if v ~= nil then
      table.insert(values, v)
    end
  end

  return (#values > 0) and values or nil
end

function table.filter(list, cb)
  if not list or not cb then return nil end
  local filtered = {}
  for k, v in pairs(list) do
    if cb(v) then
      filtered[k] = v
    end
  end

  return filtered
end

function table.map(list, cb)
  local mapped = {}
  for k, v in pairs(list) do
    table.insert(mapped, cb(v))
  end

  return mapped
end

---Return if table contains value
---@param t table
---@param value any
---@return boolean
function table.contains(list, value)
  -- if not list or not value then return nil end
  for k,v in pairs(list) do 
    if v == value then
      return true
    end
  end

  return false
end

function table.find(list, cb)
  -- if not list or not cb then return nil end
  for k,v in pairs(list) do
    if cb(v) then
      return v
    end
  end

  return nil
end

function table.findIndex(list, cb)
  -- if not list or not cb then return nil end
  for k,v in pairs(list) do
    if cb(v) then
      return k
    end
  end

  return nil
end

function table.tostring(list)
  local result = {}
  for i, v in ipairs(list) do
      table.insert(result, tostring(v))
  end
  return result
end

function table.removeKey(list, key)
  if list[key] then
    local r = list[key]
    list[key] = nil
    return r
  end

  return nil
end