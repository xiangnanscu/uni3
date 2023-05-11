local request = require "xodel.request"
local utils = require "xodel.utils"
local encode = require "cjson.safe".encode
local trace_back = debug.traceback
local ngx = ngx
local ngx_header = ngx.header
local ngx_print = ngx.print
local var = ngx.var
local string_format = string.format

local AppMeta = {}
local App = setmetatable({}, AppMeta)
App.error_status = 512
App.__index = App
function App.new(cls, opts)
  return setmetatable({ router = opts.router, models = opts.models }, cls)
end

function App.__call(self, path)
  -- App '/foo' (function ... end)
  -- App '/bar' {method='get', handler=function ... end}
  local function bind_route_to_path(route)
    if utils.callable(route) then
      self:insert_route { path = path, handler = route }
    elseif type(route) == 'table' then
      local nroute = { path = path, handler = route.handler, method = route.method }
      if self:is_route(nroute) then
        self:insert_route(nroute)
      else
        error("invalid route")
      end
    else
      error("invalid route")
    end
  end

  return bind_route_to_path
end

function App.insert_route(self, route)
  return self.router:insert(route.path, route)
end

function App.is_route(self, o)
  if type(o) == 'table' and type(o.path or o[1]) == 'string' and utils.callable(o.handler or o[2]) then
    return true
  end
  return false
end

function App.normalize_route(self, o)
  return { path = o.path or o[1], handler = o.handler or o[2], method = o.method or o[3] }
end


function App.error_response(self, message, status)
  ngx.status = status or self.error_status
  ngx_header.content_type = 'text/plain; charset=utf-8'
  ngx.ctx.error_message = message
  ngx.ctx.error_status = ngx.status
  return ngx_print(message)
end

function App.dispatch_response(self, resp, req, status)
  local resp_type = type(resp)
  if resp_type == 'table' or resp_type == 'boolean' or resp_type == 'number' then
    local json, err = encode(resp)
    if not json then
      return self:error_response("error when encoding json response: ".. err)
    else
      ngx.status = status or ngx.status
      ngx_header.cache_control = 'no-store'
      ngx_header.content_type = 'application/json; charset=utf-8'
      return ngx_print(json)
    end
  elseif resp_type == 'string' then
    ngx.status = status or ngx.status
    ngx_header.cache_control = 'no-store'
    if resp:sub(1, 1) == '<' then
      ngx_header.content_type = 'text/html; charset=utf-8'
    else
      ngx_header.content_type = 'text/plain; charset=utf-8'
    end
    return ngx_print(resp)
  elseif resp_type == 'function' then
    -- custom callback, skip the dispatch_response logic
    -- such as you want return json string as json response directly
    local ok, resp, err = xpcall(resp, trace_back, req)
    if not ok then
      return self:error_response('unhandled error in callback response: '..tostring(resp))
    elseif resp == nil then
      return self:error_response('error in callback response: '..tostring(err))
    else
      return 1
    end
  else
    return self:error_response('invalid response type: ' .. resp_type)
  end
end

local function is_model_error(err)
  return type(err) == 'table' and err.http_code and err.message and err.label and err.name
end

function App.dispatch(self, uri, method)
  local handler, re_captured, route_error_status = self.router:match(uri, method)
  if handler then
    local req = request:new {
      params = re_captured,
      uri = uri,
      method = method,
    }
    local ok, resp, err, status = xpcall(handler, trace_back, req)
    if not ok then
      if is_model_error(resp) then
        return self:dispatch_response(resp, req, resp.http_code)
      else
        return self:error_response(resp)
      end
    elseif resp == nil then
      if is_model_error(err) then
        return self:dispatch_response(err, req, status or err.http_code)
      else
        return self:dispatch_response(err, req, status)
      end
    else
      ok, err = xpcall(req.set_cookie_if_needed, trace_back, req)
      if not ok then
        return self:error_response("error when saving response cookies: " .. tostring(err))
      end
      return self:dispatch_response(resp, req)
    end
  elseif re_captured then
    return self:dispatch_response(re_captured, nil, route_error_status or self.error_status)
  else
    -- shouldn't reach here
    return self:error_response("unexpected error when matching route")
  end
end

return App
