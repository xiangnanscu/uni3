-- ngx.log(ngx.ERR, 'load Array:',keys(package.loaded))
local set = require("xodel.set")
local table_concat = table.concat
local table_remove = table.remove
local table_insert = table.insert
local table_sort = table.sort
local select = select
local error = error
local table_new, table_clear, clone
if ngx then
  table_clear = table.clear
  table_new = table.new
  clone = require("table.clone")
else
  local pairs = pairs
  table_new = function(narray, nhash)
    return {}
  end
  table_clear = function(self)
    for key, _ in pairs(self) do
      self[key] = nil
    end
  end
  clone = function(self)
    local copy = {}
    for key, value in pairs(self) do
      copy[key] = value
    end
    return copy
  end
end

local function resolve_index(self, index, is_end, no_max)
  if index == nil then
    return is_end and #self or 1
  elseif index == 0 then
    return 1
  elseif index < 0 then
    if #self + index >= 0 then
      return #self + index + 1
    else
      return 1
    end
    -- index >= 1
  elseif index > #self then
    if not no_max then
      return #self == 0 and 1 or #self
    else
      return index
    end
  else
    return index
  end
end

local Array = setmetatable({}, {
  __call = function(self, attrs)
    return setmetatable(attrs or {}, self)
  end
})
Array.__index = Array
function Array.new(cls, self)
  return setmetatable(self or {}, cls)
end

function Array.concat(...)
  local n = 0
  local m = select("#", ...)
  for i = 1, m do
    n = n + #select(i, ...)
  end
  local res = Array:new(table_new(n, 0))
  n = 0
  for i = 1, m do
    local e = select(i, ...)
    for j = 1, #e do
      res[n + j] = e[j]
    end
    n = n + #e
  end
  return res
end

function Array.entries(self)
  local n = #self
  local res = Array:new(table_new(n, 0))
  for i = 1, n do
    res[i] = { i, self[i] }
  end
  return res
end

function Array.every(self, callback)
  for i = 1, #self do
    if not callback(self[i], i, self) then
      return false
    end
  end
  return true
end

function Array.fill(self, v, s, e)
  s = resolve_index(self, s)
  e = resolve_index(self, e, true, true)
  for i = s, e do
    self[i] = v
  end
  return self
end

function Array.filter(self, callback)
  local res = Array:new()
  for i = 1, #self do
    if callback(self[i], i, self) then
      res[#res + 1] = self[i]
    end
  end
  return res
end

function Array.find(self, callback)
  if type(callback) == 'function' then
    for i = 1, #self do
      if callback(self[i], i, self) then
        return self[i]
      end
    end
  else
    for i = 1, #self do
      if self[i] == callback then
        return self[i]
      end
    end
  end
end

function Array.find_index(self, callback)
  for i = 1, #self do
    if callback(self[i], i, self) then
      return i
    end
  end
  return -1
end

Array.findIndex = Array.find_index

function Array.flat(self, depth)
  -- [0, 1, 2, [3, 4]] => [0, 1, 2, 3, 4]
  if depth == nil then
    depth = 1
  end
  if depth > 0 then
    local n = #self
    local res = Array:new(table_new(n, 0))
    for i = 1, #self do
      local v = self[i]
      if type(v) == "table" then
        local vt = Array.flat(v, depth - 1)
        for j = 1, #vt do
          res[#res + 1] = vt[j]
        end
      else
        res[#res + 1] = v
      end
    end
    return res
  else
    return Array:new(clone(self))
  end
end

function Array.flat_map(self, callback)
  -- equivalent to self:map(callback):flat(1), more efficient
  local n = #self
  local res = Array:new(table_new(n, 0))
  for i = 1, n do
    local v = callback(self[i], i, self)
    if type(v) == "table" then
      for j = 1, #v do
        res[#res + 1] = v[j]
      end
    else
      res[#res + 1] = v
    end
  end
  return res
end

Array.flatMap = Array.flat_map

function Array.for_each(self, callback)
  for i = 1, #self do
    callback(self[i], i, self)
  end
end

Array.forEach = Array.for_each

function Array.group_by(self, callback)
  local res = {}
  for i = 1, #self do
    local key = callback(self[i], i, self)
    if not res[key] then
      res[key] = Array:new()
    end
    res[key][#res[key] + 1] = self[i]
  end
  return res
end

function Array.includes(self, value, s)
  -- Array{'a', 'b', 'c'}:includes('c', 3)    // true
  -- Array{'a', 'b', 'c'}:includes('c', 100)  // false
  s = resolve_index(self, s, false, true)
  for i = s, #self do
    if self[i] == value then
      return true
    end
  end
  return false
end

function Array.index_of(self, value, s)
  s = resolve_index(self, s, false, true)
  for i = s, #self do
    if self[i] == value then
      return i
    end
  end
  return -1
end

Array.indexOf = Array.index_of

function Array.join(self, sep)
  return table_concat(self, sep)
end

function Array.keys(self)
  local n = #self
  local res = Array:new(table_new(n, 0))
  for i = 1, n do
    res[i] = i
  end
  return res
end

function Array.last_index_of(self, value, s)
  s = resolve_index(self, s, false, true)
  for i = s, 1, -1 do
    if self[i] == value then
      return i
    end
  end
  return -1
end

Array.lastIndexOf = Array.last_index_of

function Array.map(self, callback)
  local n = #self
  local res = Array:new(table_new(n, 0))
  for i = 1, n do
    res[i] = callback(self[i], i, self)
  end
  return res
end

function Array.pop(self)
  return table_remove(self)
end

function Array.push(self, ...)
  local n = #self
  for i = 1, select("#", ...) do
    self[n + i] = select(i, ...)
  end
  return #self
end

function Array.reduce(self, callback, init)
  local i = 1
  if init == nil then
    init = self[1]
    i = 2
  end
  if init == nil and #self == 0 then
    error("Reduce of empty Array with no initial value")
  end
  for j = i, #self do
    init = callback(init, self[j], j, self)
  end
  return init
end

function Array.reduce_right(self, callback, init)
  local i = #self
  if init == nil then
    init = self[i]
    i = i - 1
  end
  if init == nil and #self == 0 then
    error("Reduce of empty Array with no initial value")
  end
  for j = i, 1, -1 do
    init = callback(init, self[j], j, self)
  end
  return init
end

Array.reduceRright = Array.reduce_right

function Array.reverse(self)
  local n = #self
  local e = n % 2 == 0 and n / 2 or (n - 1) / 2
  for i = 1, e do
    self[i], self[n + 1 - i] = self[n + 1 - i], self[i]
  end
  return self
end

function Array.shift(self)
  return table_remove(self, 1)
end

function Array.slice(self, s, e)
  local res = Array:new()
  s = resolve_index(self, s)
  e = resolve_index(self, e, true)
  for i = s, e do
    res[#res + 1] = self[i]
  end
  return res
end

function Array.some(self, callback)
  for i = 1, #self do
    if callback(self[i], i, self) then
      return true
    end
  end
  return false
end

function Array.sort(self, callback)
  table_sort(self, callback)
  return self
end

function Array.splice(self, s, del_cnt, ...)
  local n = #self
  s = resolve_index(self, s)
  if del_cnt == nil or del_cnt >= n - s + 1 then
    del_cnt = n - s + 1
  elseif del_cnt <= 0 then
    del_cnt = 0
  end
  local removed = Array:new()
  for i = s, del_cnt + s - 1 do
    table_insert(removed, table_remove(self, s))
  end
  for i = select("#", ...), 1, -1 do
    local e = select(i, ...)
    table_insert(self, s, e)
  end
  return removed
end

function Array.unshift(self, ...)
  local n = select("#", ...)
  for i = n, 1, -1 do
    local e = select(i, ...)
    table_insert(self, 1, e)
  end
  return #self
end

function Array.values(self)
  return Array:new(clone(self))
end

-- other methods

function Array.group_by_key(self, key)
  local res = {}
  for i = 1, #self do
    local k = self[i][key]
    if not res[k] then
      res[k] = Array:new()
    end
    res[k][#res[k] + 1] = self[i]
  end
  return res
end

function Array.map_key(self, key)
  local n = #self
  local res = Array:new(table_new(n, 0))
  for i = 1, n do
    res[i] = self[i][key]
  end
  return res
end

Array.sub = Array.slice

function Array.clear(self)
  return table_clear(self)
end

function Array.dup(self)
  local already = {}
  for i = 1, #self do
    local e = self[i]
    if already[e] then
      return e
    else
      already[e] = true
    end
  end
end

Array.duplicate = Array.dup

local FIRST_DUP_ADDED = {}
function Array.dups(self)
  local already = {}
  local res = Array:new()
  for i = 1, #self do
    local e = self[i]
    local a = already[e]
    if a ~= nil then
      if a ~= FIRST_DUP_ADDED then
        res[#res + 1] = a
        already[e] = FIRST_DUP_ADDED
      end
      res[#res + 1] = e
    else
      already[e] = e
    end
  end
  return res
end

function Array.dup_map(self, callback)
  local already = {}
  for i = 1, #self do
    local e = self[i]
    local k = callback(e, i, self)
    if already[k] then
      return e
    else
      already[k] = true
    end
  end
end

function Array.dups_map(self, callback)
  local already = {}
  local res = Array:new()
  for i = 1, #self do
    local e = self[i]
    local k = callback(e, i, self)
    local a = already[k]
    if a ~= nil then
      if a ~= FIRST_DUP_ADDED then
        res[#res + 1] = a
        already[k] = FIRST_DUP_ADDED
      end
      res[#res + 1] = e
    else
      already[k] = e
    end
  end
  return res
end

function Array.uniq(self)
  local already = {}
  local res = Array:new()
  for i = 1, #self do
    local key = self[i]
    if not already[key] then
      res[#res + 1] = key
      already[key] = true
    end
  end
  return res
end

function Array.uniq_map(self, callback)
  local already = {}
  local res = Array:new()
  for i = 1, #self do
    local key = callback(self[i], i, self)
    if not already[key] then
      res[#res + 1] = self[i]
      already[key] = true
    end
  end
  return res
end

function Array.as_set(self)
  local res = set:new(table_new(0, #self))
  for i = 1, #self do
    res[self[i]] = true
  end
  return res
end

function Array.equals(self, o)
  if type(o) ~= 'table' or #o ~= #self then
    return false
  end
  for i = 1, #self do
    local tt, ot = type(self[i]), type(o[i])
    if tt ~= ot then
      return false
    elseif tt ~= 'table' then
      if self[i] ~= o[i] then
        return false
      end
    elseif not Array.equals(self[i], o[i]) then
      return false
    end
  end
  return true
end

-- {1,2} == {1,2}
Array.__eq = Array.equals
-- {1,2} + {2,3} = {1,2,2,3}
function Array.__add(self, o)
  return Array.concat(self, o)
end

-- {1,2} - {2,3} = {1}
function Array.__sub(self, o)
  local res = Array:new()
  local od = o:as_set()
  for i = 1, #self do
    if not od[self[i]] then
      res[#res + 1] = self[i]
    end
  end
  return res
end

function Array.exclude(self, callback)
  local res = Array:new()
  for i = 1, #self do
    if not callback(self[i], i, self) then
      res[#res + 1] = self[i]
    end
  end
  return res
end

function Array.count(self, callback)
  local res = 0
  for i = 1, #self do
    if callback(self[i], i, self) then
      res = res + 1
    end
  end
  return res
end

function Array.count_exclude(self, callback)
  local res = 0
  for i = 1, #self do
    if not callback(self[i], i, self) then
      res = res + 1
    end
  end
  return res
end

function Array.combine(self, n)
  if #self == n then
    return Array { self }
  elseif n == 1 then
    return Array.map(self, function(e)
      return Array { e }
    end)
  elseif #self > n then
    local head = self[1]
    local rest = Array.slice(self, 2)
    return Array.concat(Array.combine(rest, n), Array.combine(rest, n - 1):map(function(e)
      return Array { head, unpack(e) }
    end))
  else
    return Array {}
  end
end

if select('#', ...) == 0 then
  local inspect = require "resty.inspect"
  local utils = require "xodel.utils"
  local p = function(e)
    print(inspect(e))
  end
  assert(Array { 1, 2, 3 } + Array { 3, 4 } == Array { 1, 2, 3, 3, 4 })
  assert(Array { 1, 2, 3 } - Array { 3, 4 } == Array { 1, 2 })
  assert(Array { 'a', 'b', 'c' }:entries() == Array { { 1, 'a' }, { 2, 'b' }, { 3, 'c' } })
  assert(Array { 1, 2, 3 }:every(function(n)
    return n > 0
  end) == true)
  assert(Array { 0, 0, 0 }:fill(8) == Array { 8, 8, 8 })
  assert(Array { 0, 0, 0 }:fill(8, 2, 3) == Array { 0, 8, 8 })
  assert(Array { 1, 'not', 3, 'number' }:filter(function(e)
    return tonumber(e)
  end) == Array { 1, 3 })
  assert(Array { { id = 1 }, { id = 101 }, { id = 3 } }:find(function(e)
    return e.id == 101
  end).id == 101)
  assert(Array { { id = 1 }, { id = 101 }, { id = 3 } }:find_index(function(e)
    return e.id == 101
  end) == 2)
  assert(Array { 1, { 2 }, 3 }:flat() == Array { 1, 2, 3 })
  Array { 'a', 'b', 'c' }:for_each(print)
  assert(Array { 1, 2, 3 }:includes(1) == true)
  assert(Array { 1, 2, 3 }:includes(1, 4) == false)
  assert(Array { 1, 2, 3 }:includes(5) == false)
  assert(Array { 'a', 'b' }:index_of('b') == 2)
  assert(Array { 'a', 'b', 'c' }:join('|') == 'a|b|c')
  assert(Array { 'a', 'b', 'c' }:keys() == Array { 1, 2, 3 })
  assert(Array { 'a', 'b', 'b', 'c' }:last_index_of('b', -1) == 3)
  assert(Array { 'a', 'b', 'b', 'c' }:index_of('b') == 2)
  assert(Array { 1, 2, 3 }:map(function(n)
    return n + 10
  end) == Array { 11, 12, 13 })
  assert(Array { 1, 2, 100 }:pop() == 100)
  assert(Array { 1, 2, 3 }:reverse() == Array { 3, 2, 1 })
  local a = Array { 1, 2, 3 }
  assert(a:push(4, 5, 6) == 6)
  assert(a == Array { 1, 2, 3, 4, 5, 6 })
  assert(a:shift() == 1)
  assert(a == Array { 2, 3, 4, 5, 6 })
  assert(Array { 1, 2, 3 }:reduce(function(x, y)
    return x + y
  end) == 6)
  assert(Array { 1, 2, 3, 4 }:slice() == Array { 1, 2, 3, 4 })
  assert(Array { 1, 2, 3, 4 }:slice(2) == Array { 2, 3, 4 })
  assert(Array { 1, 2, 3, 4 }:slice(1, -1) == Array { 1, 2, 3, 4 })
  assert(Array { 1, 2, 3, 4 }:slice(2, 3) == Array { 2, 3 })
  assert(Array { 1, 2, 3 }:some(function(n)
    return n < 0
  end) == false)
  assert(Array { -1, 2, 3 }:some(function(n)
    return n < 0
  end) == true)
  local b = Array {}
  assert(b:splice(1, 0, 1, 2, 3, 4) == Array {})
  assert(b == Array { 1, 2, 3, 4 })
  assert(b:splice(1, 1) == Array { 1 })
  assert(b == Array { 2, 3, 4 })
  assert(b:splice(2, 1, 5, 6) == Array { 3 })
  assert(b == Array { 2, 5, 6, 4 })
  local c = Array {}
  assert(c:unshift('c', 'd', 'e') == 3)
  assert(c == Array { 'c', 'd', 'e' })
  p(c)
  assert(c:unshift('a', 'b') == 5)
  assert(c == Array { 'a', 'b', 'c', 'd', 'e' })
  assert(Array { { id = 1 }, { id = 101 }, { id = 3 } }:map_key('id') == Array { 1, 101, 3 })
  assert(Array { 1, 2, 2, 3 }:dup() == 2)
  assert(Array { 1, 2, 2, 3, 4, 4, 4, 5 }:dups() == Array { 2, 2, 4, 4, 4 })
  assert(Array { 1, 2, 2, 3, 4, 4, 4, 5 }:uniq() == Array { 1, 2, 3, 4, 5 })
  p(Array { 1, 2, 3, 4 }:combine(2))
  p(utils.combine({ 1, 2, 3 }, 2))
  print("all tests passed!")
end

return Array
