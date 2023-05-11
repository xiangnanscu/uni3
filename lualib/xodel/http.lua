local resty_http = require "resty.http"
local class = require "xodel.utils".class
local getenv = require "xodel.utils".getenv
local encode = require("cjson").encode
local decode = require("cjson").decode
local safe_decode = require("cjson.safe").decode

local default_content_type = getenv("NGINX_default_type") or "application/json;charset=utf-8"
local function normalize_headers(t)
  local headers = {}
  for key, value in pairs(t) do
    headers[key:gsub("_", "-")] = value
  end
  return headers
end

local DEFAULT_OPTS = {}
local function make_http_request(url, opts, method, post_data)
  opts = opts or DEFAULT_OPTS
  method = method or opts.method
  local query = opts.query
  if opts.base_url then
    url = opts.base_url .. url
  end
  local headers = normalize_headers(opts.headers or {})
  if not headers["Content-Type"] then
    headers["Content-Type"] = opts.content_type or default_content_type
  end
  if not headers["Accept"] then
    headers["Accept"] = '*/*'
  end
  local body = post_data or opts.body
  if type(body) == 'table' and headers["Content-Type"]:find('application/json', 1, true) then
    body = encode(body)
  end
  local response = assert(resty_http.new():request_uri(url, {
    method = method,
    body = body,
    headers = headers,
    query = query,
  }))
  if response.has_body then
    local ct = response.headers['Content-Type']
    if ct and ct:find('application/json', 1, true) then
      response.body = decode(response.body)
    else
      local json = safe_decode(response.body)
      if type(json) == 'table' then
        response.body = json
      end
    end
  end
  return response
end

local http = class({}, {
  __call = function(t, url, opts)
    return make_http_request(url, opts)
  end
})


function http.get(url, opts)
  return make_http_request(url, opts, 'GET')
end

function http.GET(url, opts)
  return make_http_request(url, opts, 'GET')
end

function http.post(url, data, opts)
  return make_http_request(url, opts, 'POST', data)
end

function http.POST(url, data, opts)
  return make_http_request(url, opts, 'POST', data)
end

return http
