Packer = {}

function Packer.Serialize(obj, remote)
  if obj ~= nil then
      ts_remote = remote or false

      local serialized = json.encode(obj)

      local byteArray = {}
      for i = 1, #serialized do
          table.insert(byteArray, string.byte(serialized, i))
      end

      return byteArray
  end

  return { 0xC0 }
end