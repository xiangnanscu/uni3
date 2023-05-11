local nkeys = require "table.nkeys"
local isarray = require "table.isarray"
local array = require("xodel.array")
local pairs = pairs
local ipairs = ipairs
local select = select


local Object = setmetatable({}, {
  __call = function(t, attrs)
    return setmetatable(attrs or {}, t)
  end
})

Object.__index = Object

function Object.new(cls, t)
  return setmetatable(t or {}, cls)
end

function Object.assign(t, ...)
  local n = select("#", ...)
  for i = 1, n do
    for k, v in pairs(select(i, ...)) do
      t[k] = v
    end
  end
  return t
end

function Object.entries(t)
  local res = array:new()
  for k, v in pairs(t) do
    res[#res + 1] = { k, v }
  end
  return res
end

function Object.from_entries(arr)
  local res = Object:new()
  for _, e in ipairs(arr) do
    res[e[1]] = e[2]
  end
  return res
end

Object.fromEntries = Object.from_entries

function Object.keys(t)
  local res = array:new()
  for k, _ in pairs(t) do
    res[#res + 1] = k
  end
  return res
end

function Object.values(t)
  local res = array:new()
  for _, v in pairs(t) do
    res[#res + 1] = v
  end
  return res
end

function Object.contains(t, o)
  for k, v in pairs(o) do
    if t[k] ~= v and (type(v) ~= 'table' or type(t[k]) ~= 'table' or not Object.equals(v, t[k])) then
      return false
    end
  end
  return true
end

function Object.equals(t, o)
  local nt = nkeys(t)
  local no = nkeys(o)
  if nt ~= no then
    return false
  else
    return Object.contains(t, o)
  end
end

Object.__eq = Object.equals

function Object.copy(t)
  local v_copy = Object:new {}
  for key, value in pairs(t) do
    if type(value) == 'table' then
      v_copy[key] = Object.copy(value)
    else
      v_copy[key] = value
    end
  end
  return v_copy
end

function Object.flat(t)
  local res = Object:new()
  for k, v in pairs(t) do
    if type(v) ~= 'table' or isarray(v) then
      res[k] = v
    else
      Object.assign(res, Object.flat(v))
    end
  end
  return res
end

if select('#', ...) == 0 then
  assert(Object { a = 1, b = 2, c = 3 }:keys():as_set() == array { 'a', 'b', 'c' }:as_set())
  assert(Object { a = 1, b = 2, c = 3 }:values():as_set() == array { 1, 2, 3 }:as_set())
  assert(Object { a = 1, b = 2 } == Object { a = 1, b = 2 })
  assert(Object { a = 1, b = { c = 3, d = 4 } } == Object { a = 1, b = { c = 3, d = 4 } })
  assert(Object { a = 1, b = { c = 3, d = 4 } } ~= Object { a = 1, b = { c = 3, d = 5 } })
  assert(Object { a = 1 }:assign({ b = 2 }, { c = 3 }) == Object { a = 1, b = 2, c = 3 })
  assert(Object.from_entries(Object { a = 1, b = 2 }:entries():map(function(e)
      return { 'k' .. e[1], 100 + e[2] }
    end)) == Object { ka = 101, kb = 102 })
  local o = Object { a = 1, b = { c = 3, d = 4 } }
  assert(o:copy() == o)
  print("all tests passed!")
end

return Object
