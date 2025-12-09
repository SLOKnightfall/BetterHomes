local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

-- Base64 decoder (Lua 5.1 compatible)
local function base64_decode(data)
  local b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local map = {}
  for i = 1, #b64 do map[b64:sub(i,i)] = i - 1 end
  data = data:gsub('%s+', ''):gsub('[^'..b64..'=]', '')
  local bytes = {}
  local i = 1
  while i <= #data do
    local c1 = data:sub(i,i); i=i+1
    local c2 = data:sub(i,i); i=i+1
    local c3 = data:sub(i,i); i=i+1
    local c4 = data:sub(i,i); i=i+1
    local a = map[c1]
    local b = map[c2]
    local c = (c3 == '=') and nil or map[c3]
    local d = (c4 == '=') and nil or map[c4]
    local n1 = (a * 4) + math.floor(b / 16)
    local n2 = ((b % 16) * 16) + (c and math.floor(c / 4) or 0)
    local n3 = ((c and (c % 4) or 0) * 64) + (d or 0)
    bytes[#bytes+1] = string.char(n1)
    if c ~= nil then bytes[#bytes+1] = string.char(n2) end
    if d ~= nil then bytes[#bytes+1] = string.char(n3) end
  end
  return table.concat(bytes)
end

-- Robust JSON decoder (objects, arrays, strings w/ escapes, numbers, booleans, null)
local function json_decode(str)
  local pos, len = 1, #str

  local function skip_ws()
    while true do
      local c = str:sub(pos,pos)
      if c == ' ' or c == '\n' or c == '\r' or c == '\t' then
        pos = pos + 1
      else
        break
      end
    end
  end

  local parse_value

  local function parse_string()
    local i = pos + 1
    local out = {}
    while i <= len do
      local c = str:sub(i,i)
      if c == '"' then
        pos = i + 1
        return table.concat(out)
      elseif c == '\\' then
        local esc = str:sub(i+1,i+1)
        if esc == '"' then out[#out+1] = '"'
        elseif esc == '\\' then out[#out+1] = '\\'
        elseif esc == '/' then out[#out+1] = '/'
        elseif esc == 'b' then out[#out+1] = '\b'
        elseif esc == 'f' then out[#out+1] = '\f'
        elseif esc == 'n' then out[#out+1] = '\n'
        elseif esc == 'r' then out[#out+1] = '\r'
        elseif esc == 't' then out[#out+1] = '\t'
        elseif esc == 'u' then
          local hex = str:sub(i+2,i+5)
          if hex:match('^%x%x%x%x$') then
            local cp = tonumber(hex, 16)
            if cp <= 0x7F then
              out[#out+1] = string.char(cp)
            elseif cp <= 0x7FF then
              out[#out+1] = string.char(0xC0 + math.floor(cp/64), 0x80 + (cp % 64))
            else
              out[#out+1] = string.char(0xE0 + math.floor(cp/4096), 0x80 + (math.floor(cp/64) % 64), 0x80 + (cp % 64))
            end
            i = i + 4
          end
        else
          out[#out+1] = esc
        end
        i = i + 2
      else
        out[#out+1] = c
        i = i + 1
      end
    end
    error('Unterminated string at position '..pos)
  end

  local function parse_number()
    local s,e = str:find('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    if not s then error('Invalid number at position '..pos) end
    local n = tonumber(str:sub(s,e))
    pos = e + 1
    return n
  end

  local function parse_array()
    pos = pos + 1
    skip_ws()
    local arr = {}
    if str:sub(pos,pos) == ']' then
      pos = pos + 1
      return arr
    end
    while true do
      arr[#arr+1] = parse_value()
      skip_ws()
      local c = str:sub(pos,pos)
      if c == ']' then
        pos = pos + 1
        break
      elseif c == ',' then
        pos = pos + 1
        skip_ws()
      else
        error('Expected , or ] at position '..pos)
      end
    end
    return arr
  end

  local function parse_object()
    pos = pos + 1
    skip_ws()
    local obj = {}
    if str:sub(pos,pos) == '}' then
      pos = pos + 1
      return obj
    end
    while true do
      if str:sub(pos,pos) ~= '"' then error('Expected string key at position '..pos) end
      local key = parse_string()
      skip_ws()
      if str:sub(pos,pos) ~= ':' then error('Expected : after key at position '..pos) end
      pos = pos + 1
      skip_ws()
      obj[key] = parse_value()
      skip_ws()
      local c = str:sub(pos,pos)
      if c == '}' then
        pos = pos + 1
        break
      elseif c == ',' then
        pos = pos + 1
        skip_ws()
      else
        error('Expected , or } at position '..pos)
      end
    end
    return obj
  end

  parse_value = function()
    skip_ws()
    local c = str:sub(pos,pos)
    if c == '"' then return parse_string()
    elseif c == '{' then return parse_object()
    elseif c == '[' then return parse_array()
    elseif str:sub(pos,pos+3) == 'true' then pos = pos + 4; return true
    elseif str:sub(pos,pos+4) == 'false' then pos = pos + 5; return false
    elseif str:sub(pos,pos+3) == 'null' then pos = pos + 4; return nil
    else return parse_number() end
  end

  return parse_value()
end

-- Decode payload and assign addon.ProfessionData
do
  local encoded = addon and addon.EncodedData
  if type(encoded) == "string" and #encoded > 0 then
    local decoded = base64_decode(encoded)
    local ok, data = pcall(json_decode, decoded)
    if ok and data then
      addon.ProfessionData = data
    else
      addon.ProfessionData = {}
    end
  else
    addon.ProfessionData = {}
  end
end


-- Decode vendor data
do
  local encoded = addon and addon.EncodedVendors
  if type(encoded) == "string" and #encoded > 0 then
    local decoded = base64_decode(encoded)
    local ok, data = pcall(json_decode, decoded)
    if ok and data then
      addon.VendorData = data
    else
      addon.VendorData = {}
    end
  else
    addon.VendorData = {}
  end
end

-- Decode QuestData
do
  local encoded = addon and addon.EncodedQuestData
  if type(encoded) == "string" and #encoded > 0 then
    local decoded = base64_decode(encoded)
    local ok, data = pcall(json_decode, decoded)
    if ok and data then
      addon.QuestData = data
    else
      addon.QuestData = {}
    end
  else
    addon.QuestData = {}
  end
end