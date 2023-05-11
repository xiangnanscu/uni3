local json = require "cjson.safe"
local xmlparser = require("xodel.xmlparser")
local cookie = require "xodel.cookie"
local utils = require "xodel.utils"
local array = require "xodel.array"
local object = require "xodel.object"
local http = require "xodel.http"
local decode = json.decode
local encode = json.encode
local ngx_header = ngx.header
local get_post_args = ngx.req.get_post_args
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local ngx_var = ngx.var
local ngx_req = ngx.req
local get_cookie_table = cookie.get_cookie_table
local bake = cookie.bake
local assert = assert
local rawget = rawget
local setmetatable = setmetatable

local _c = {}
local READONLY_EMPTY_TABLE = utils.READONLY_EMPTY_TABLE
local COOKIE_PATH = _c.COOKIE_PATH or '/'
local COOKIE_EXPIRES = _c.COOKIE_EXPIRES or 30 * 24 * 3600   -- 30 days
local SESSION_PATH = _c.SESSION_PATH or '/'
local SESSION_EXPIRES = _c.SESSION_EXPIRES or 30 * 24 * 3600 -- 30 days


local function make_cookie_proxy(http_cookie, self)
  -- self 是Request实例, 获取它的属性时会调用Request.__index,
  -- 为了性能和避免starckover flow风险 统一用rawget(req, key)
  local function __newindex(_, k, v)
    if type(v) == 'string' then
      v = { key = k, value = v, path = COOKIE_PATH, max_age = COOKIE_EXPIRES }
    elseif v == nil then
      v = { key = k, value = '', path = COOKIE_PATH, max_age = 0 }
    else
      v = {
        key = k,
        value = v.value,
        path = v.path,
        max_age = v.max_age,
        domain = v.domain,
        secure = v.secure,
        httponly = v.httponly,
        samesite = v.samesite,
        extension = v.extension
      }
    end
    if rawget(self, '_set_cookie') == nil then
      self._set_cookie = {}
    end
    self._set_cookie[k] = v
  end

  local function __index(_, k)
    if rawget(self, '_cookie') == nil then
      self._cookie = get_cookie_table(http_cookie)
    end
    return self._cookie[k]
  end

  local function __call()
    if rawget(self, '_cookie') == nil then
      self._cookie = get_cookie_table(http_cookie)
    end
    return self._cookie
  end

  return setmetatable({}, {
    __call = __call,
    __index = __index,
    __newindex = __newindex,
  })
end

-- https://github.com/openresty/encrypted-session-nginx-module
-- AES-256 with MAC
local encrypt_callbacks = {
  encode,
  ndk.set_var.set_encrypt_session,
  ndk.set_var.set_encode_base64,
}
local decrypt_callbacks = {
  ndk.set_var.set_decode_base64,
  ndk.set_var.set_decrypt_session,
  decode,
}

local function encrypt_session(text)
  for _, en in ipairs(encrypt_callbacks) do
    text = en(text)
    if not text then
      return nil, 'encrypt session error'
    end
  end
  return text
end

local function decrypt_session(text)
  if not text then
    return nil, 'you must provide a string'
  end
  for _, de in ipairs(decrypt_callbacks) do
    text = de(text)
    if not text then
      return nil, 'decrypt session error'
    end
  end
  return text
end

local function make_session_proxy(cookie_proxy, self)
  -- self 是Request实例, 获取它的属性时会调用Request.__index,
  -- 为了性能和避免starckover flow风险 统一用rawget(req, key)
  -- ignore errors when decrypting session (return a table)
  local function __newindex(_, k, v)
    self._session_changed = true
    if rawget(self, '_session') == nil then
      self._session = decrypt_session(cookie_proxy.session) or {}
    end
    self._session[k] = v
  end

  local function __index(_, k)
    if rawget(self, '_session') == nil then
      self._session = decrypt_session(cookie_proxy.session) or {}
    end
    return self._session[k]
  end

  local function __call()
    if rawget(self, '_session') == nil then
      self._session = decrypt_session(cookie_proxy.session) or {}
    end
    return self._session
  end

  return setmetatable({}, {
    __call = __call,
    __index = __index,
    __newindex = __newindex,
  })
end

local Request = {
  EMPTY = READONLY_EMPTY_TABLE,
  http = http,
  utils = utils,
  array = array,
  object = object,
  encode = encode,
  decode = decode,
  match = ngx.re.match,
  format = string.format,
  getenv = utils.getenv,
  empty = utils.empty,
  loger = utils.loger,
}
function Request.__index(self, key)
  if Request[key] ~= nil then
    return Request[key]
  elseif ngx_req[key] ~= nil then
    return ngx_req[key]
  elseif key == 'cookie' then
    self.cookie = make_cookie_proxy(ngx_var.http_cookie, self)
    return rawget(self, 'cookie')
  elseif key == 'session' then
    self.session = make_session_proxy(self.cookie, self)
    return rawget(self, 'session')
  elseif key == 'user' then
    self.user = self.session.user
    return rawget(self, 'user')
  else
    return nil
  end
end

function Request.new(cls, self)
  return setmetatable(self or {}, cls)
end

function Request.get_post_data(self)
  read_body()
  local type_string = ngx_var.content_type or ''
  if type_string:find('application/json', 1, true) then
    return decode(assert(get_body_data()))
  elseif type_string:find('text/xml', 1, true) then
    local xml = assert(get_body_data())
    return xmlparser(xml)
  else
    return get_post_args(1000)
  end
end

function Request.get_user(self)
  return self.session.user
end

function Request.is_login(self)
  return not not self.session.user
end

function Request.is_ajax()
  return ngx_var.http_x_requested_with == 'XMLHttpRequest'
end

function Request.set_cookie_if_needed(self)
  if rawget(self, '_session_changed') then
    self.cookie.session = {
      value   = assert(encrypt_session(rawget(self, '_session'))),
      path    = SESSION_PATH,
      max_age = SESSION_EXPIRES,
    }
  end
  local _set_cookie = rawget(self, '_set_cookie')
  if _set_cookie and next(_set_cookie) then
    local c = {}
    for _, v in pairs(_set_cookie) do
      c[#c + 1] = assert(bake(v))
    end
    ngx_header.set_cookie = c
  end
  return true
end

return Request
