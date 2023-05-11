local Cipher            = require("resty.openssl.cipher")
local bn                = require "resty.openssl.bn"
local to_hex            = require "resty.string".to_hex
local utils             = require("xodel.utils")
local array             = require("xodel.array")

local http              = require("xodel.http")
local cjson_encode      = require("cjson.safe").encode
local time              = require("xodel.time")
local ngx_encode_base64 = ngx.encode_base64
local ngx_decode_base64 = ngx.decode_base64
local ngx_sha1_bin      = ngx.sha1_bin


local ffi = require('ffi')
ffi.cdef [[
  void *malloc (size_t __size);
  void *calloc (size_t nmemb, size_t __size);
  void free (void *__ptr);
]]
local C                   = ffi.os == "Windows" and ffi.load("msvcrt") or ffi.C

local WXQY_EXPIRE_SECONDS = 7100
local EncodingAESKey      = utils.getenv("WXQY_AESKEY") or ""
local WXQY_SUITE_SECRET   = utils.getenv("WXQY_SUITE_SECRET")
local WXQY_TOKEN          = utils.getenv("WXQY_TOKEN")
local SHM_NAME            = utils.getenv("SHM_NAME") or "CODE"
local WXQY_CORP_ID        = utils.getenv("WXQY_CORP_ID")
local WXQY_SUITE_ID       = utils.getenv("WXQY_SUITE_ID")

local AESKey              = ngx_decode_base64(EncodingAESKey .. '=')
local AESIv               = AESKey:sub(1, 16)

-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/access-token/auth.getAccessToken.html
local WXMINI_ERR_DICT     = {
  [-1] = '系统繁忙，稍候再试',
  [40001] = 'AppSecret 错误或者 AppSecret 不属于这个小程序，请开发者确认 AppSecret 的正确性',
  [40002] = '请确保 grant_type 字段值为 client_credential',
  [40013] = '不合法的 AppID，请开发者检查 AppID 的正确性，避免异常字符，注意大小写',
  [40029] = '不合法的code（code不存在、已过期或者使用过）',
  [45011] = '操作过于频繁', --频率限制，每个用户每分钟100次
  [40226] = '高风险等级用户，小程序登录拦截 。风险等级详见用户安全解方案',
  [60020] = 'not allow to access from your ip:client ip 47.109.88.16',
}

local function aes_256_cbc_decode(aes_msg)
  -- https://developer.work.weixin.qq.com/document/path/91144#%E5%8E%9F%E7%90%86%E8%AF%A6%E8%A7%A3
  -- https://github.com/fffonion/lua-resty-openssl/tree/master#restycipherdecrypt
  return assert(assert(Cipher.new("aes-256-cbc")):decrypt(AESKey, AESIv, ngx_decode_base64(aes_msg)))
end
local function aes_256_cbc_encode(aes_msg)
  return ngx_encode_base64(assert(assert(Cipher.new("aes-256-cbc")):encrypt(AESKey, AESIv, aes_msg)))
end

local function sha1(str)
  local bin = ngx_sha1_bin(str)
  return to_hex(bin)
end

local function get_signature(...)
  -- https://developer.work.weixin.qq.com/document/path/91144#%E6%B6%88%E6%81%AF%E4%BD%93%E7%AD%BE%E5%90%8D%E6%A0%A1%E9%AA%8C
  local sort_str  = array { WXQY_TOKEN, ... }:sort():join("")
  local signature = sha1(sort_str):lower()
  return signature
end

local function get_msg_len(string)
  local ctype = ffi.gc(ffi.cast("unsigned char*", C.malloc(#string)), C.free)
  ffi.copy(ctype, string, #string)
  return ctype[0] * 0x1000000 +
      bit.lshift(ctype[1], 16) +
      bit.lshift(ctype[2], 8) +
      ctype[3]
end


local function get_clear_text(echostr)
  -- https://developer.work.weixin.qq.com/document/path/91144#%E4%B8%BE%E4%BE%8B%E8%AF%B4%E6%98%8E
  -- "c0d7ed80696628d9\0\0\0\0191941400080766291965wwc723ddc6b66c397b"
  local rand_msg = aes_256_cbc_decode(echostr)
  local len      = get_msg_len(rand_msg:sub(17, 20))
  -- xml_len = socket.ntohl(struct.unpack("I", msg_len)[0])
  -- \0\0\1\b 264, \0\0\0\019 19, \0\0\1\30, 286
  local content  = rand_msg:sub(21, 20 + len)
  return content
end

local function get_suite_ticket(suite_id)
  local db = ngx.shared[SHM_NAME]
  return db:get(suite_id)
end

---@param body table
---@param success_callback? string|function
---@return any
local function handle_resonse_body(body, success_callback)
  if not body or not body.errcode or body.errcode == 0 then
    if not success_callback then
      return body
    elseif type(success_callback) == 'function' then
      return success_callback(body)
    elseif type(success_callback) == 'string' then
      return body[success_callback]
    else
      error("invalid argument for handle_resonse_body")
    end
  elseif WXMINI_ERR_DICT[body.errcode] then
    error(WXMINI_ERR_DICT[body.errcode])
  else
    error(cjson_encode(body))
  end
end

local function _get_suite_token(suite_id)
  local url = "https://qyapi.weixin.qq.com/cgi-bin/service/get_suite_token"
  local res = http.post(url,
    { suite_id = suite_id, suite_ticket = get_suite_ticket(suite_id), suite_secret = WXQY_SUITE_SECRET })
  return handle_resonse_body(res.body, "suite_access_token")
end

local get_suite_token = utils.cache_by_key_and_time(_get_suite_token, WXQY_EXPIRE_SECONDS)

local function get_permanent_code(opts)
  local url = "https://qyapi.weixin.qq.com/cgi-bin/service/get_permanent_code"
  local suite_token = get_suite_token(opts.suite_id)
  local res = http.post(url, { auth_code = opts.auth_code }, { query = { suite_access_token = suite_token } })
  return handle_resonse_body(res.body, opts.callback)
end

local function get_access_token(opts)
  local url = "https://qyapi.weixin.qq.com/cgi-bin/service/get_corp_token"
  local suite_token = get_suite_token(opts.suite_id)
  local res = http.post(url, { auth_corpid = opts.auth_corpid, permanent_code = opts.permanent_code },
    { query = { suite_access_token = suite_token } })
  return handle_resonse_body(res.body, opts.callback)
end

local externalcontact = {}

function externalcontact.get_groupchat_statistic(opts)
  local url = "https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/statistic"
  local res = http.post(url, {
    day_begin_time = opts.day_begin_time or ngx.time(),
    day_end_time = opts.day_end_time,
    owner_filter = opts.owner_filter,
    order_by = opts.order_by,
    order_asc = opts.order_asc,
    offset = opts.offset,
    limit = opts.limit,
  }, { query = { access_token = opts.access_token, } })
  return handle_resonse_body(res.body, opts.callback)
end

function externalcontact.get_groupchat_statistic_by_days(opts)
  local days = opts.days or 1
  local now = time.str2number(ngx.today() .. ' 00:00:00')
  return externalcontact.get_groupchat_statistic(utils.dict(opts,
    { day_begin_time = now - (days + 1) * 24 * 3600, day_end_time = now - 1 * 24 * 3600 }))
end

function externalcontact.get_user_behavior_data(opts)
  local url = "https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_user_behavior_data"
  local res = http.post(url, {
    day_begin_time = opts.day_begin_time or ngx.time(),
    day_end_time = opts.day_end_time,
    userid = opts.userid,
    partyid = opts.partyid,
  }, { query = { access_token = opts.access_token, } })
  return handle_resonse_body(res.body, opts.callback)
end

function externalcontact.get_user_behavior_data_by_days(opts)
  local days = opts.days or 1
  local now = time.str2number(ngx.today() .. ' 00:00:00')
  return externalcontact.get_user_behavior_data(utils.dict(opts,
    { day_begin_time = now - (days + 1) * 24 * 3600, day_end_time = now - 1 * 24 * 3600 }))
end

return {
  externalcontact = externalcontact,
  get_access_token = get_access_token,
  get_msg_len = get_msg_len,
  sha1 = sha1,
  decrypt = aes_256_cbc_decode,
  encrypt = aes_256_cbc_encode,
  get_signature = get_signature,
  get_clear_text = get_clear_text,
  get_permanent_code = get_permanent_code,
  get_suite_token = get_suite_token,
}
