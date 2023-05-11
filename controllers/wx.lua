local wx = require("xodel.wx")
local Usr = require("models.models").Usr
local Orders = require("models.models").Orders
local Models = require("models.models")
local cjson_decode = require("cjson").decode
local utils = require("xodel.utils")
local ngx_time = ngx.time

local function wx_main(request)
  return ""
end

-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/phonenumber/phonenumber.getPhoneNumber.html
local function wx_phone(request)
  return wx.get_phone_number(request.get_post_data().code)
end

local function wx_login(request)
  local data = wx.jscode2session(request.get_post_data().code)
  local openid = data.openid
  local user = Usr:select("id", "nickname", "avatar", "openid", "permission"):get_or_create { openid = openid }
  request.session.user = user
  return user
end

-- https://pay.weixin.qq.com/wiki/doc/apiv3/apis/chapter3_5_1.shtml
local function wx_jsapi_mini_preorder(request)
  local data = request.get_post_data()
  local feeplan_id = data.feeplan_id
  local plan = Models.Feeplan:get { id = feeplan_id }
  local total = plan.total
  local session = wx.jscode2session(data.code)
  local openid = session.openid
  local timestamp = ngx_time()
  local out_trade_no = tostring(timestamp)
  local prepay_id = wx.jsapi_preorder {
    out_trade_no = out_trade_no,
    description = plan.title,
    timestamp = timestamp,
    total = total,
    openid = openid
  }
  local signature = wx.get_mini_sign2 {
    nonce_str = timestamp,
    timestamp = timestamp,
    prepay_id = prepay_id
  }
  Orders:create {
    description = plan.title,
    out_trade_no = out_trade_no,
    feeplan_id = feeplan_id,
    prepay_id = prepay_id,
    openid = openid,
    total = total,
  }
  local pre_result = {
    prepay_id = prepay_id,
    signature = signature,
    nonce_str = timestamp,
    timestamp = timestamp
  }
  return pre_result
end

-- https://pay.weixin.qq.com/wiki/doc/apiv3/apis/chapter3_5_5.shtml
-- {
--   /*7f7ab94dbed8*/
--   create_time  : "2023-01-28T14:25:02+08:00",
--   event_type   : "TRANSACTION.SUCCESS",
--   id           : "b47405c6-b4ba-5ffb-b946-895236c543c5",
--   resource     : {
--     /*7f7ab94dc110*/
--     algorithm      : "AEAD_AES_256_GCM",
--     associated_data: "transaction",
--     ciphertext     : "Fv0Lo+9D/umAGsuf0me2hfeKKSYzCwRga2ZNyap+ITSVB1lkiRYfaxQIxcQ+DFzsmhcBfP7lqmyK+ldu17vdXoh2ctIcdXO7skKFnLVQhTbE/pPqoAt/npXqa4YGAmUZXFDw1i/OM5muoKE3uOK54JqahsovwP7ixkb09gkoUnpOFQVu57glYn79XwoE3iVGLIojdszqCVaSS3a7EbIDKmSEvWsT0HB4eC2t5J6NhFyn/MCC5d1tcmmqcoa3hIdL4qDS2v4PiOis3x11dkDbcBYCRxwo4t+H78QgVUl/40ZcLAwYNF9rdfyFSt9lWedSHCPt0ulGebvrXLg+7CqMqL4QD4c/t007beHZgR5paMY6HOhOcHv/njETITx5m1tRUNOeatxNmdq5Q3J0BeB9GDcV5mGlgcx2njEfjnoWn3aPRfeTIYYzLT7BZP2hifhkJlF2qSTx3/So55qVtFLzt8DhBSKyzUrR40/Eb/pgmduiFxo/HfTvgDu9Cumphy1aB4UqvUks9+fK7JOiLN7To2rkXJsJFfqPCOrSN/u0ZFYgIFylOmTxPo11gThp6ldZaomAaeB1",
--     nonce          : "gLm1Ft8R0tva",
--     original_type  : "transaction",
--   },
--   resource_type: "encrypt-resource",
--   summary      : "支付成功",
-- }
-- {
--   /*7f528e24f188*/
--   "content-length"          : "903",
--   "content-type"            : "application/json",
--   "user-agent"              : "Mozilla/4.0",
--   "wechatpay-nonce"         : "vZNVygf69Q4xufLBr76tlmvCKcgf78i6",
--   "wechatpay-serial"        : "2291AB0C8D7D1FB7CE4E3BD3AD197B332734940E",
--   "wechatpay-signature"     : "DpcV21QmtxbCYHp5SvuhCKw1UDDW3gWg6pgmFqfGCu2LjYZDSWOSprsJ267D8kvDnIXrfhrQgdDzdatPlDVvYx58uXzriQUlVThzJqcY+9l6XKyUqS98k1rdxPQOG2v9Uo6FXvoXfaql+gNjvXpp7C0GyzFDiX/fAIDNJn/VlWBagCvVY+P5UpusUDvnp1jQH3Raw2tR9BnSzPC4DimsO8CTMuzVEbjsQ+dLBLzV9tp2vDfS8PC+NLrBepElf2R3s9zBxydrXFuNiQnJkUq1allGgOHOYeSVetT1S+neJ1Dc8ZETiDh/Sxicj2Mj++ws3woGxd1H2VRLG86OobmzCQ==",
--   "wechatpay-signature-type": "WECHATPAY2-SHA256-RSA2048",
--   "wechatpay-timestamp"     : "1675069761",
--   accept                    : "*/*",
--   connection                : "Keep-Alive",
--   host                      : "jaqn.jahykj.cn",
--   pragma                    : "no-cache",
-- }
local ngx_decode_base64 = ngx.decode_base64
local function wx_jsapi_mini_notify(request)
  request.read_body()
  local body = request.get_body_data()
  local ok, data = pcall(cjson_decode, body)
  if not ok then
    return ""
  end
  local notice = cjson_decode(wx.aes_256_gcm_decode(data.resource))
  local headers = request.get_headers()
  local certs = wx.get_certs()
  local cert = certs[headers['Wechatpay-Serial']]
  if not cert then
    return ""
  end
  local notice_sign = ngx_decode_base64(headers['Wechatpay-Signature'])
  local text = request.format("%s\n%s\n%s\n", headers['Wechatpay-Timestamp'], headers['Wechatpay-Nonce'], body)
  local verify_ok, err = wx.verify_jsapi_notice {
    pubkey = cert.pubkey,
    text = text,
    signature = notice_sign
  }
  if not verify_ok then
    return ""
  end
  -- {
  --   mchid: "1637212382",
  --   appid: "wxcec88a7e2c1e81c7",
  --   out_trade_no: "1674977689",
  --   transaction_id: "4200001657202301297488263484",
  --   trade_type: "JSAPI",
  --   trade_state: "SUCCESS",
  --   trade_state_desc: "支付成功",
  --   bank_type: "ICBC_DEBIT",
  --   attach: "",
  --   success_time: "2023-01-29T15:34:57+08:00",
  --   payer: { openid: "oExvK4knP5dGQbU1TWkUImhzbXg0" },
  --   amount: {
  --     total: 10,
  --     payer_total: 10,
  --     currency: "CNY",
  --     payer_currency: "CNY",
  --   },
  -- }
  local openid = notice.payer.openid
  local order_ins = Orders:try_get { out_trade_no = notice.out_trade_no, openid = openid }
  if order_ins then
    -- 正常情况下应该要找得到
    order_ins(notice):save()
    return ""
  else
    -- 如果找不到, 也不能漏了通知
    notice.openid = openid
    notice.total = notice.amount.total
    Orders:create(notice)
    return ""
  end
end

local function wx_jsapi_mini_sign(request)
  local timestamp = request.get_post_data().timestamp
  return wx.get_header_signature {
    'post',
    url = '/v3/pay/transactions/jsapi',
    timestamp = timestamp,
  }
end

local function get_certs()
  return wx.get_certs()
end

local function get_order_status(request)
  return wx.get_order_status(request.params.out_trade_no)
end

return {
  { "get_order_status/:out_trade_no", get_order_status,       "get" },
  { "",                               get_certs,              "get" },
  { "phone",                          wx_phone,               "post" },
  { "login",                          wx_login,               "post" },
  -- { "jsapi_mini_sign", wx_jsapi_mini_sign, "post" },
  { "jsapi_mini_notify",              wx_jsapi_mini_notify,   "post" },
  { "notify",                         wx_jsapi_mini_notify,   "post" },
  { "jsapi_mini_preorder",            wx_jsapi_mini_preorder, "post" },
}
