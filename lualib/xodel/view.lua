local select = select
local class = require "xodel.utils".class
local getenv = require "xodel.utils".getenv
local format = string.format
local ngx = ngx

local GOD_PERMISSION = tonumber(getenv('GOD_PERMISSION') or 9)

local function request_call(view, request)
  local method = request.method:lower()
  if not view[method] then
    return nil, 'method not allowed', 405
  else
    local self, new_err = view:new { request = request }
    if not self then
      return nil, new_err
    end
    if view.init then
      local _, err = view.init(self, request)
      if err then
        return nil, err
      end
    end
    return view[method](self, request)
  end
end

local classview = class({}, { __call = request_call })
function classview.new(cls, self)
  setmetatable(self, cls)
  if cls.user_require or cls.admin_require or cls.god_require then
    self.user = self.request.session.user
    if not self.user then
      return nil, "anonymous request not allowed", 403
    end
  end
  if cls.admin_require and self.user.permission < 1 then
    return nil, "permission not allowed", 403
  end
  if cls.god_require and self.user.permission ~= GOD_PERMISSION then
    return nil, "permission not allowed", 403
  end
  return self
end

return classview
