local utils     = require("xodel.utils")
local wxqy      = require "xodel.wxqy"
local view      = require("xodel.view")
local xmlparser = require("xodel.xmlparser")


local main = view:class {}
function main:get(request)
  -- https://developer.work.weixin.qq.com/document/path/91116#31-%E6%94%AF%E6%8C%81http-get%E8%AF%B7%E6%B1%82%E9%AA%8C%E8%AF%81url%E6%9C%89%E6%95%88%E6%80%A7
  local query         = request.get_uri_args()
  local msg_signature = query.msg_signature
  local timestamp     = query.timestamp
  local nonce         = query.nonce
  local echostr       = query.echostr
  local signature     = wxqy.get_signature(timestamp, nonce, echostr)
  if signature ~= msg_signature then
    xodel("wxqy signature verified failed", query, signature)
    error("wxqy signature verified failed")
  end
  local clear_text = wxqy.get_clear_text(echostr)
  return clear_text
end

function main:post(request)
  local query         = request.get_uri_args()
  local data          = request.get_post_data()
  local method        = request.get_method()
  local msg_signature = query.msg_signature
  local timestamp     = query.timestamp
  local nonce         = query.nonce
  local msg_encrypt   = data.Encrypt
  local signature     = wxqy.get_signature(timestamp, nonce, msg_encrypt)
  if signature ~= msg_signature then
    xodel("wxqy signature verified failed", query, data.signature)
    error("wxqy signature verified failed")
  end
  local content = wxqy.get_clear_text(msg_encrypt)
  -- <xml><SuiteId><![CDATA[wwb83a9f918d1d681d]]></SuiteId><InfoType><![CDATA[suite_ticket]]></InfoType><TimeStamp>1681217834</TimeStamp><SuiteTicket><![CDATA[wL-gs9zQWR-NuHCSFI18_FyfPPRATmf0YcFk3Gpfsvedq843qNmCrQ2ciYZdHU5y]]></SuiteTicket></xml>
  local res = xmlparser(content)
  xodel("wxqy events post", query, data, res)
  local event_handler = main[res.Event or ""]
  if not event_handler then
    return error("event_handler not found: " .. tostring(res.Event))
  end
  return event_handler(self, request, res)
end

function main:enter_agent(request, data)
  -- {
  --   /*7f0e3b9b4340*/
  --   AgentID     : "1000046",
  --   CreateTime  : "1681535848",
  --   Event       : "enter_agent",
  --   EventKey    : "",
  --   FromUserName: "woyDUMCgAAduLGoRDoggAxYIBq5I0GJQ",
  --   MsgType     : "event",
  --   ToUserName  : "wpyDUMCgAA3H8_gw7O1aQLCMnDxcouCA",
  -- }
  -- 本事件在成员进入企业微信的应用时触发
  -- https://developer.work.weixin.qq.com/document/path/90240#%E8%BF%9B%E5%85%A5%E5%BA%94%E7%94%A8
  return "success"
end

function main:change_app_admin(request, data)
  -- {
  --   /*7f0e3bcdc940*/
  --   AgentID     : "1000042",
  --   CreateTime  : "1681481765",
  --   Event       : "change_app_admin",
  --   FromUserName: "sys",
  --   MsgType     : "event",
  --   ToUserName  : "wpyDUMCgAA3H8_gw7O1aQLCMnDxcouCA",
  -- }
  -- 应用管理员变更通知
  -- https://developer.work.weixin.qq.com/document/path/95038
  return "success"
end

function main:subscribe(request, data)
  -- {
  --   /*7f0e3bc6ad88*/
  --   AgentID     : "1000042",
  --   CreateTime  : "1681481765",
  --   Event       : "subscribe",
  --   FromUserName: "woyDUMCgAAduLGoRDoggAxYIBq5I0GJQ",
  --   MsgType     : "event",
  --   ToUserName  : "wpyDUMCgAA3H8_gw7O1aQLCMnDxcouCA",
  -- }
  -- 成员关注及取消关注事件
  -- https://developer.work.weixin.qq.com/document/path/90240#%E6%88%90%E5%91%98%E5%85%B3%E6%B3%A8%E5%8F%8A%E5%8F%96%E6%B6%88%E5%85%B3%E6%B3%A8%E4%BA%8B%E4%BB%B6
  return "success"
end

return main
