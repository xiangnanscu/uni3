local utils = require("xodel.utils")
local env = utils.getenv()

local function encode_set(v)
  if type(v) ~= 'string' then
  elseif v == "" then
    v = "''"
  elseif v:match('%s') then
    v = string.format("'%s'", v)
  end
  return v
end

print(utils.entries(env)
  :filter(function(e) return e[1]:sub(1, 4) ~= 'npm_' and e[1] ~= '_' end)
  :sort(function(a, b) return b[1] > a[1] end)
  :map(function(e)
    return string.format("set $%s %s;", e[1], encode_set(e[2]))
  end):join('\n'))
