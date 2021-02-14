local helpers = {}

function helpers.clamp(val,min,max)
  return val < min and min or val > max and max or val
end

function helpers.table_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function helpers.splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

return helpers