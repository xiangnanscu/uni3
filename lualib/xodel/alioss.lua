local cjson_encode = require "cjson".encode
local utils = require "xodel.utils"
local Array = require "xodel.array"
local env = require "xodel.utils".getenv
local encode_base64 = ngx.encode_base64
local hmac_sha1 = ngx.hmac_sha1
local ngx_time = ngx.time

local ALIOSS_KEY = env("ALIOSS_KEY") or ""
local ALIOSS_SECRET = env("ALIOSS_SECRET") or ""
local ALIOSS_BUCKET = env("ALIOSS_BUCKET")
-- Bytes
local ALIOSS_SIZE = utils.byte_size_parser(env("ALIOSS_SIZE") or "10MB")
local ALIOSS_LIFETIME = tonumber(env("ALIOSS_LIFETIME")) or 30 -- server side lifetime
local ALIOSS_EXPIRATION_DAYS = tonumber(env("ALIOSS_EXPIRATION_DAYS") or 180)
-- https://help.aliyun.com/document_detail/31988.html?spm=5176.doc32074.6.868.KQbmQM#title-5go-s2f-dnw
local function get_policy_time(seconds)
  local s = os.date("%Y-%m-%d %H:%M:%S", ngx_time() + seconds):gsub(' ', 'T') .. ".000Z"
  return s
end

-- https://help.aliyun.com/document_detail/31988.html?spm=5176.doc32074.6.868.KQbmQM#section-d5z-1ww-wdb
---@param options {size?:string,lifetime?:number, bucket?:string,key?:string}
---@return {conditions:table, expiration:string}
local function get_policy(options)
  local conditions = Array {}
  local policy = {
    conditions = conditions,
    expiration = get_policy_time(tonumber(options.lifetime or ALIOSS_LIFETIME)),
  }
  conditions:push { bucket = options.bucket or ALIOSS_BUCKET }
  local size = options.size
  if type(size) == "table" then
    conditions:push { "content-length-range", size[1], size[2] }
  elseif type(size) == 'string' or type(size) == 'number' then
    conditions:push { "content-length-range", 1, utils.byte_size_parser(size) }
  else
    conditions:push { "content-length-range", 1, ALIOSS_SIZE }
  end
  if options.key then
    conditions:push { "eq", "$key", options.key }
  end
  return policy
end

---@param options {size?:string, key?:string,bucket?:string,lifetime?:number, key_secret?: string,key_id?:string,success_action_status?:number}
---@return {policy:string, OSSAccessKeyId:string, signature:string, success_action_status?:number}
local function get_payload(options)
  -- https://github.com/ali-sdk/ali-oss/blob/master/lib/client.js#L134
  -- https://github.com/bungle/lua-resty-nettle/blame/master/README.md#L136
  local data = {}
  data.policy = encode_base64(cjson_encode(get_policy(options)))
  data.signature = encode_base64(hmac_sha1(options.key_secret or ALIOSS_SECRET, data.policy))
  data.OSSAccessKeyId = options.key_id or ALIOSS_KEY
  if options.success_action_status then
    data.success_action_status = options.success_action_status
  end
  return data
end

return {
  get_policy = get_policy,
  get_payload = get_payload
}
