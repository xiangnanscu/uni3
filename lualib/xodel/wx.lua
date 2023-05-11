local utils = require("xodel.utils")
local http = require("xodel.http")
local resty_rsa = require "resty.rsa"
local cjson_encode = require("cjson").encode
local cjson_decode = require("cjson").decode
local x509 = require("resty.openssl.x509")
local ngx_encode_base64 = ngx.encode_base64
local ngx_decode_base64 = ngx.decode_base64
local ngx_time = ngx.time
local format = string.format
local error = error

-- https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/

local WX_MINI_APPID = utils.getenv("WX_MINI_APPID")
local WX_MINI_SECRET = utils.getenv("WX_MINI_SECRET")
local WX_SERIAL_NO = utils.getenv("WX_SERIAL_NO")
local WX_MCID = utils.getenv("WX_MCID")
local NGINX_server_name = utils.getenv("NGINX_server_name")
local WX_MCH_KEY_PEM = utils.getenv("WX_MCH_KEY_PEM")
local WX_APIV3_HOST = "https://api.mch.weixin.qq.com"


-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/access-token/auth.getAccessToken.html
local WXMINI_ERR_DICT = {
  [-1] = '系统繁忙，稍候再试',
  [40001] = 'AppSecret 错误或者 AppSecret 不属于这个小程序，请开发者确认 AppSecret 的正确性',
  [40002] = '请确保 grant_type 字段值为 client_credential',
  [40013] = '不合法的 AppID，请开发者检查 AppID 的正确性，避免异常字符，注意大小写',
  [40029] = '不合法的code（code不存在、已过期或者使用过）',
  [45011] = '操作过于频繁', --频率限制，每个用户每分钟100次
  [40226] = '高风险等级用户，小程序登录拦截 。风险等级详见用户安全解方案',
}

---comment
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

-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/access-token/auth.getAccessToken.html
local function _get_access_token()
  local url = format("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s",
    WX_MINI_APPID, WX_MINI_SECRET)
  -- {
  --   "access_token":"ACCESS_TOKEN",
  --   "expires_in":7200
  --  }
  return handle_resonse_body(http.get(url).body)
end

_get_access_token = utils.cache_by_seconds(_get_access_token, 7100)


---@return string
local function get_access_token()
  return assert(_get_access_token()).access_token
end

-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/phonenumber/phonenumber.getPhoneNumber.html
---@param code string
---@return {phoneNumber: string, phoneNumber: string, countryCode:string, watermark: {appid: string, timestamp: number}}
local function get_phone_number(code)
  local access_token = get_access_token()
  local url = "https://api.weixin.qq.com/wxa/business/getuserphonenumber"
  local res = http.post(url, { code = code }, { query = { access_token = access_token } })
  return handle_resonse_body(res.body, function(body)
    return body.phone_info
  end)
end

local function jscode2session(code)
  local res = http.get(format(
    "https://api.weixin.qq.com/sns/jscode2session?appid=%s&secret=%s&js_code=%s&grant_type=authorization_code"
    , WX_MINI_APPID, WX_MINI_SECRET, code))
  return handle_resonse_body(res.body)
end

local function get_out_trade_no()
  return tostring(ngx_time())
end

local function sha256_sign(str)
  local priv = assert(resty_rsa:new({ private_key = WX_MCH_KEY_PEM, algorithm = "SHA256" }))
  local sig = assert(priv:sign(str))
  return ngx_encode_base64(sig)
end

local function get_header_signature(opts)
  local str = format("%s\n%s\n%s\n%s\n%s\n", opts.method, opts.url, opts.timestamp, opts.nonce_str or opts.timestamp,
    opts.body or "")
  return sha256_sign(str)
end

local function get_authorization_header(opts)
  return format([[WECHATPAY2-SHA256-RSA2048 mchid="%s",nonce_str="%s",timestamp="%s",serial_no="%s",signature="%s"]]
    ,
    opts.mchid or WX_MCID,
    opts.nonce_str or opts.timestamp or ngx_time(),
    opts.timestamp or ngx_time(),
    opts.serial_no or WX_SERIAL_NO,
    opts.signature or get_header_signature(opts)
  )
end

local function wx_request(opts)
  local timestamp = opts.timestamp or ngx_time()
  local url = opts.url
  local auth_opts = {
    method = opts.method,
    url = url,
    timestamp = timestamp,
  }
  if opts.method == 'POST' then
    auth_opts.body = cjson_encode(opts.data)
  end
  local auth_header = get_authorization_header(auth_opts)
  local req_opts = {
    method = opts.method,
    base_url = WX_APIV3_HOST,
    url = url,
    headers = {
      ['Authorization'] = auth_header,
      ['Accept'] = 'application/json',
    }
  }
  if opts.method == 'POST' then
    req_opts.body = auth_opts.body
  end
  return http(url, req_opts)
end

-- 根据cert证书获取证书序列号
-- https://myssl.com/cert_decode.html
local DEFAULT_NOTIFY_URL = format("https://%s/wx/notify", NGINX_server_name)
local function jsapi_preorder(opts)
  local timestamp = opts.timestamp or ngx_time()
  local notify_url = opts.notify_url or DEFAULT_NOTIFY_URL
  local post_data = {
    appid = opts.appid or WX_MINI_APPID,
    mchid = opts.mchid or WX_MCID,
    description = opts.description or "微信小程序订单",
    out_trade_no = opts.out_trade_no or tostring(timestamp),
    notify_url = notify_url,
    amount = {
      total = opts.total,
      currency = "CNY"
    },
    payer = {
      openid = opts.openid
    }
  }
  local res = wx_request {
    method = 'POST',
    url = '/v3/pay/transactions/jsapi',
    timestamp = timestamp,
    data = post_data,
  }
  return res.body.prepay_id
end

-- https://pay.weixin.qq.com/wiki/doc/apiv3/apis/chapter3_5_4.shtml
local function get_mini_sign2(opts)
  local str = format("%s\n%s\n%s\nprepay_id=%s\n", opts.appid or WX_MINI_APPID, opts.timestamp or ngx_time(),
    opts.nonce_str or ngx_time(), opts.prepay_id)
  return sha256_sign(str)
end

-- https://pay.weixin.qq.com/wiki/doc/apiv3/apis/chapter3_5_5.shtml
-- https://github.com/fffonion/lua-resty-openssl/blob/master/examples/aes-gcm-aead.lua#L62
local Cipher = require("resty.openssl.cipher")
local WX_APIV3 = utils.getenv("WX_APIV3")
local function aes_256_gcm_decode(opts)
  local mode = "aes-256-gcm"
  local cipher = assert(Cipher.new(mode))
  local key = opts.key or WX_APIV3
  local nonce = opts.nonce
  local associated_data = opts.associated_data
  local encrypt_bytes = ngx_decode_base64(opts.ciphertext)
  local real_bytes = encrypt_bytes:sub(1, -17)
  local tag = encrypt_bytes:sub(-16)
  local decrypted = assert(cipher:decrypt(key, nonce, real_bytes, false, associated_data, tag))
  return opts.json and cjson_decode(decrypted) or decrypted
end

-- {
--   /*7f6a60c71de8*/
--   body         : {
--     /*7f6a60c71f38*/
--     data: [
--       /*7f6a60c71f80*/
--       {
--         /*7f6a60c71fc8*/
--         effective_time     : "2023-01-21T16:30:47+08:00",
--         encrypt_certificate: {
--           /*7f6a6105c040*/
--           algorithm      : "AEAD_AES_256_GCM",
--           associated_data: "certificate",
--           ciphertext     : "4YdjxnkxTvyq02LXt5t047hpoV0vNwKgBj4aK6kMigH4CLUyGncsolHIq6PazzFl+ObcJD/aVU+AJDYFjR98WbpiR2V/hTnu8UbGoLQnsjffXyxAVi64ZSTxrg0R8udvU3TkGS7/QpHXFop0/HGPDFld/bhk06OIEMRKwVGu3AR8YzDttpyWnPdKIc/MrBjZqui3C+iP6dbPrtn36f98cfK5VNZa3/zQNtkfM9kLKq9cdSyQfDRhzC8w1qxZmlEuM//93txMQHQBcdk2Sie8exMYjNNy4bO0ArUoA2OmvgXOU1FzBx7kxNVz8LZRUoZTmrq17rNTD8zKReIuOSxU5mhDxSNFZl3dvN6m0YmKDJp9FfHGwJTuPYoAXwWsvaH5J6GWwf+duk2cUyMfA4xNPFKG5IQgIZ4Mt5n/PCOx6xju9zaDmpEx3K/4o+Nng2w0P5xOSr3yfmdGIanbQeryIfBx5i8fahEiVUC1xObEdMqFd1KAghl8D2K37MhQawgiDbbfwhDYKfbiw88yyv2n4SHmn9+YWc3o1gLsqD0twT/F0dRI760Qs0QvREsPKIDD5kCLVC+UCA1tvuxY/8I5nM/J9CRAN/BWtkJwUP8Skieb1zF+VjP1C/TDEF7L00P03nD0O+cemT0AY+amgow+wZ07x2gbwfM3IrzEM0x3zM6AC89u3B5kWeKxqY/ht/cLZ1b1hcvbSKeyf0QE+lOMwQ7bVQRSa0Q2BiVhX3Jzto2MG3ZWlFFi136lIegh5o31LFoztsK/SGbqTez/dC+qQCK4yUBhoDRHxFMJrapY3ZITo5AvoG8e0uj0SvtOaLREAnIgVOagNAQ+A3HofcGcHtW2wV955Da+4w5dS2M5B2JmQ8E1Ghwg2ge6TZHsCXKW/guColEy1RuRLcRHRwYugNDN7J2T1HadvWQ4WPrmaxpIc5l2fH3EjC+CBxDqrymHYe3/tFtcwluhMt91cyYj7a8fSbhMr8QZ9aQ3yyFxXHWmKca7jAR5adNgNJd7HO6vBMNlL4KSD7Mpx1TxBC79cOi3c+KOJTPq/LPFfFqn0Nq4I2NlvP0TIjH/frIYCjaKRecbf29hNSxBoFnmkegYXc6+RS/HTx7QkcKTsgq1Vg5L1VvyBIQ+F5lUqSa3hb+AKwn7Rnb5rR63OeIJdIYifIQkDqxR+aB4zSj6hvUTM1f6TzPc4s9dANIH/AEdV+HOnFaP0wx6Ck2PwskGtg8G3o5DeKwzFomnBH7z7dGmd3Dien2tGOmBt6MTYArc0uwd5b8Mjq0ng/WvDuFkmBpaXNq8qWwCH9Gm8K1zSm4GWTnnoykkIB+swxwg/9zGLWEyb1fbudjZzJYYIkz8a2/8unxyFO7WKx04Qk7A8YR6DhVInBGJkIVGBAalnL1YkNXehndTgod8H6Tw6/cWZRgDLPPbIEFkMEUlrZe4+1KntmnO25IY5KVZQypYxzDp5En+PR2rebZob3STWfMdn+dTchiQZyHKdcOLT3+UMa8SAWzqC66XwV3PqQ60l7Fham6padbVkZFy22arNKYKjD4G55cuvk9tO3JgHNqQRgOTUF8sVNEX1wKBNGnYmzWVVMr2RylwdEGl7zdIT8jkUIa1ID7HJYIIfB3/UyJOAVPn1CeghozQSCGSj2U6kxUosSPd+uCcq/s7NMQj8EYca7o65xosHLncGzQcOX2/6s6ZE1QZ7VMwN2/cS71OLzutMcvaHWUQjkOJWkKssiCtro7HvhAwMdq7wQX60EWhhycYyUU4JEZ2ohXIQCgHVcxdkdw8q7fo3LnDw95otJVbRc0vcG8hl1tbhvwOAsZ4gnhj/XPdBVrKooQXrvYJAnu1pyWPZrWPZ5Uyfu2PKD1Zy7jejh0RO/YSobS2ggTh8hprshXj5L3XnYv5e3+3Jo75fKJkVom0LNgMm/zexF8FFlTxMpWZBGebSlTngmXuQjLWd2x0drC7UL4orO6LWNU/gJ0M4Kwx",
--           nonce          : "758b6c2c38e3",
--         },
--         expire_time        : "2028-01-20T16:30:47+08:00",
--         serial_no          : "2291AB0C8D7D1FB7CE4E3BD3AD197B332734940E",
--       },
--     ],
--   },
--   body_reader  : "function: 0x7f6a60c71d38",
--   has_body     : true,
--   headers      : {
--     /*7f6a60c6fb70*/
--     "Cache-Control"           : "no-cache, must-revalidate",
--     "Content-Language"        : "zh-CN",
--     "Content-Length"          : "2268",
--     "Content-Type"            : "application/json; charset=utf-8",
--     "Keep-Alive"              : "timeout=8",
--     "Request-ID"              : "0883F1DD9E0610F10418B885F64D20C834288DE804-0",
--     "Wechatpay-Nonce"         : "fbefd2806f50378e505bad36d60403b2",
--     "Wechatpay-Serial"        : "2291AB0C8D7D1FB7CE4E3BD3AD197B332734940E",
--     "Wechatpay-Signature"     : "tXqRML25w2O5XZPtUtt/uL0lqiQ7Bbxjg4w5aKpy4ht4pIPZD3uioafBibpWSm8dhN34voTU+HbGPuKn/CuWpFbQFnrPRxC9OiuelTY/uMHNkeIEY1dmRXepuyV2HTKbhi0DhN+6WWdirejrbMSrGD6zsvwoKhG8RaYcHg991Cun08BpyF4xO7via5hUBYlgO6+17Bk5npTKu22i1iappC+pi02ST7KZXmC+9zqNSKBCHCalT5UgHqSJBgORZLwmuMDT2rI5RJ+hG2zOS/wCidFWMki4OB8rduRMQDbtVMCBnw/ci8CYPRGYqNHXy75rpvgyfdy4EkU/GVMATK165Q==",
--     "Wechatpay-Signature-Type": "WECHATPAY2-SHA256-RSA2048",
--     "Wechatpay-Timestamp"     : "1675065475",
--     "X-Content-Type-Options"  : "nosniff",
--     Connection                : "keep-alive",
--     Date                      : "Mon, 30 Jan 2023 07:57:55 GMT",
--     Server                    : "nginx",
--   },
--   read_body    : "function: 0x7f6a60eb8df0",
--   read_trailers: "function: 0x7f6a60eb8ea8",
--   reason       : "OK",
--   status       : 200,
-- }


local function get_certs()
  local resonse = wx_request {
    method = 'GET',
    url = '/v3/certificates',
    timestamp = ngx_time(),
  }
  local certs = {}
  for _, cert in ipairs(resonse.body.data) do
    local content = aes_256_gcm_decode(cert.encrypt_certificate)
    cert.pubkey = assert(assert(x509.new(content)):get_pubkey()):to_PEM()
    certs[cert.serial_no] = cert
  end
  return certs
end

get_certs = utils.cache_by_seconds(get_certs, 12 * 3600)

local function verify_jsapi_notice(opts)
  local pub = assert(resty_rsa:new({ public_key = opts.pubkey, algorithm = 'SHA256' }))
  local verify, err = pub:verify(opts.text, opts.signature)
  if not verify then
    return nil, err
  end
  return verify
end

-- {
--   bank_type: "ICBC_DEBIT",
--   mchid: "1637212382",
--   promotion_detail: [],
--   success_time: "2023-01-30T20:55:04+08:00",
--   out_trade_no: "1675083295",
--   attach: "",
--   transaction_id: "4200001750202301302839987692",
--   amount: { total: 1, payer_currency: "CNY", currency: "CNY", payer_total: 1 },
--   trade_state: "SUCCESS",
--   payer: { openid: "oExvK4knP5dGQbU1TWkUImhzbXg0" },
--   trade_state_desc: "支付成功",
--   trade_type: "JSAPI",
--   appid: "wxcec88a7e2c1e81c7",
-- };
local function get_order_status(out_trade_no, mchid)
  local resonse = wx_request {
    method = 'GET',
    url = format('/v3/pay/transactions/out-trade-no/%s?mchid=%s', out_trade_no, mchid or WX_MCID),
    timestamp = ngx_time(),
  }
  return resonse.body
end

return {
  get_order_status = get_order_status,
  wx_request = wx_request,
  get_certs = get_certs,
  verify_jsapi_notice = verify_jsapi_notice,
  aes_256_gcm_decode = aes_256_gcm_decode,
  get_mini_sign2 = get_mini_sign2,
  get_header_signature = get_header_signature,
  jsapi_preorder = jsapi_preorder,
  jscode2session = jscode2session,
  get_phone_number = get_phone_number,
  get_access_token = get_access_token,
}
