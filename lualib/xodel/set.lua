local isempty = require "table.isempty"
local pairs = pairs
local select = select
local table_concat = table.concat
local table_clear = table.clear

local function set_from_array(cls, t)
  local s = {}
  if t then
    for i = 1, #t do
      s[t[i]] = true
    end
  end
  return setmetatable(s, cls)
end

---@class Set
---@field __index Set
local Set = setmetatable({}, { __call = set_from_array })
Set.__index = Set
Set.__tostring = function(t)
  local keys = {}
  for k, _ in pairs(t) do
    keys[#keys + 1] = tostring(k)
  end
  return '{' .. table_concat(keys, ',') .. '}'
end
Set.new = set_from_array
-- Set operator:
-- + (union)
-- - (except)
-- * (intersect)
-- ^ (sym_except)
-- == (equals test)
-- + (UNION)
function Set.__add(t, o)
  local res = Set:new()
  for k, _ in pairs(t) do
    res[k] = true
  end
  for k, _ in pairs(o) do
    res[k] = true
  end
  return res
end

Set.union = Set.__add
-- * (INTERSECT)
function Set.__mul(t, o)
  local res = Set:new()
  for k, _ in pairs(t) do
    if o[k] then
      res[k] = true
    end
  end
  return res
end

Set.intersect = Set.__mul
-- - (EXCEPT)
function Set.__sub(t, o)
  local res = Set:new()
  for k, v in pairs(t) do
    if not o[k] then
      res[k] = true
    end
  end
  return res
end

Set.except = Set.__sub
-- ^ (symmetric except)
function Set.__pow(t, o)
  local res = Set:new()
  for k, _ in pairs(t) do
    if not o[k] then
      res[k] = true
    end
  end
  for k, _ in pairs(o) do
    if not t[k] then
      res[k] = true
    end
  end
  return res
end

Set.sym_except = Set.__pow
-- == (equals)
function Set.__eq(t, o)
  for k, _ in pairs(t) do
    if not o[k] then
      return false
    end
  end
  for k, _ in pairs(o) do
    if not t[k] then
      return false
    end
  end
  return true
end

Set.equals = Set.__eq

-- <=
function Set.__le(t, o)
  for key, _ in pairs(t) do
    if not o[key] then
      return false
    end
  end
  return true
end

function Set.contains(t, o)
  return Set.__eq(o, t)
end

function Set.add(t, ele)
  t[ele] = true
  return t
end

function Set.clear(t)
  return table_clear(t)
end

function Set.keys(t)
  local array = require("mvc.array")
  local keys = array {}
  for k, _ in pairs(t) do
    keys[#keys + 1] = k
  end
  return keys
end

function Set.empty(t)
  return isempty(t)
end

if select('#', ...) == 0 then
  local a = Set { 1, 2, 3 }
  local b = Set { 3, 4, 5 }
  assert(a + b == Set { 1, 2, 3, 4, 5 })
  assert(a * b == Set { 3 })
  assert(a ^ b == Set { 1, 2, 4, 5 })
  assert(a - b == Set { 1, 2 })
  assert(b - a == Set { 4, 5 })
  assert(Set { 1, 2, 3 } >= Set {})
  assert(Set { 1 } <= Set { 1, 2 })
  print("all tests passed!")
end

return Set
