local type = type
local math_floor = math.floor
local getenv = require("xodel.utils").getenv

local GOD_PERMISSION = tonumber(getenv('GOD_PERMISSION') or 9)
local function login_user(request, user)
  request.session().user = {
    id = user.id,
    xm = user.xm,
    username = user.username,
    permission = user.permission,
  }
end

local function check_password(database_password, post_password)
  return database_password == post_password
end

local function test_user(test_func, message)
  message = message or 'permission not allowed'
  local function user_require(view_func)
    local function wrap_view(request)
      local user = request.session().user
      if test_func(user) then
        request.user = user
        return view_func(request)
      else
        return nil, message, 403
      end
    end

    return wrap_view
  end

  return user_require
end

local function method_require(method)
  method = (method or 'GET'):upper()
  local function factory(view_func)
    local function wrap_view(request)
      if request.method == method then
        return view_func(request)
      else
        return nil, '请求方法错误', 405
      end
    end

    return wrap_view
  end

  return factory
end

local function is_user(u)
  return type(u) == 'table'
      and type(u.id) == 'number'
      and u.id == math_floor(u.id)
      and type(u.username) == 'string'
end

local function is_superuser(u)
  return is_user(u) and type(u.permission) == 'number' and u.permission > 0
end

-- is_superuser = ensure_realtime_permission(is_superuser)
local function is_goduser(u)
  return is_user(u) and u.permission == GOD_PERMISSION
end

local god_require = test_user(is_goduser, '权限不够')
local admin_require = test_user(is_superuser, '要求管理员权限')
local user_require = test_user(is_user, '请先登录')

local ANONYMOUS_USER = setmetatable({},
  { __newindex = function() error('anonymous user is readonly') end })

return {
  login_user = login_user,
  check_password = check_password,
  method_require = method_require,
  user_require = user_require,
  admin_require = admin_require,
  god_require = god_require,
  is_user = is_user,
  is_goduser = is_goduser,
  is_superuser = is_superuser,
  ANONYMOUS_USER = ANONYMOUS_USER,
}
