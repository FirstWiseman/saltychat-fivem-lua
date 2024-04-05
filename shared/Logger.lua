Logger = {}

SCRIPTNAME = "saltychat-lua"

-- W
function Logger:Debug(...)
  if Configuration and Configuration.Debug then
    local t = transformTable { ... }

    print("[^8" .. SCRIPTNAME .. " ^3DEBUG^0] ^3" .. table.concat(t, "  ") .. "^0")
  end
end

-- I
function Logger:Info(...)
  local t = transformTable { ... }
  for i = 1, #t do
    if type(t[i]) ~= "string" then
      t[i] = tostring(t[i])
    elseif type(t[i]) == "table" then
      t[i] = json.encode(t[i])
    end
  end

  print("[^8" .. SCRIPTNAME .. "^0] ^5" .. table.concat(t, "  ") .. "^0")
end

-- S
function Logger:Error(...)
  local t = transformTable { ... }
  for i = 1, #t do
    if type(t[i]) ~= "string" then
      t[i] = tostring(t[i])
    elseif type(t[i]) == "table" then
      t[i] = json.encode(t[i])
    end
  end

  print("[^8" .. SCRIPTNAME .. " ^1ERROR^0] ^1" .. table.concat(t, "  ") .. "^0")
end

-- E
local function removeFunctions(tbl, count)
  local count = 0 or count
  for k, v in pairs(tbl) do
      if type(v) == "function" then
          tbl[k] = "[function]"
      elseif type(v) == "table" then
          count = count + 1
          if count < 3 then
            removeFunctions(v, count)            
          else
            tbl[k] = "[table]"
          end
      end
  end
end

-- M
function transformTable(list)
  removeFunctions(list)

  for i = 1, #list do
    if type(list[i]) == "table" then
      list[i] = json.encode(list[i])
    elseif type(list[i]) ~= "string" then
      list[i] = tostring(list[i])
    end
  end

  return list
end

-- MAN

-- W  I  S  E M A N