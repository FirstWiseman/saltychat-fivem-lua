function string.starts(self, startStr)
  return self:sub(1, #startStr) == startStr
end

function string.split(self, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  self:gsub(pattern, function(substring)
      table.insert(result, substring)
  end)

  function result:last()
    return self[#self]
  end
  return result
end

function string.nullorwhitespace(self)
  return self == nil or self:match("^%s") or self:match("%s$")
end

function string.trim(self)
  local trimmed
	trimmed = self:gsub("%s+", "")
	return trimmed
end

function string.check(value)
  return string.char(value)
end