local utils     = require("xodel.utils")
local wxqy      = require "xodel.wxqy"
local view      = require("xodel.view")
local xmlparser = require("xodel.xmlparser")
local Org       = require("models.models").Org

local SHM_NAME  = utils.getenv("SHM_NAME") or "CODE"

local main      = view:class {}
function main:get(request)
  -- https://developer.work.weixin.qq.com/document/path/91116#31-%E6%94%AF%E6%8C%81http-get%E8%AF%B7%E6%B1%82%E9%AA%8C%E8%AF%81url%E6%9C%89%E6%95%88%E6%80%A7
  local query         = request.get_uri_args()
  local msg_signature = query.msg_signature
  local timestamp     = query.timestamp
  local nonce         = query.nonce
  local echostr       = query.echostr
  local signature     = wxqy.get_signature(timestamp, nonce, echostr)
  assert(signature == msg_signature, "wxqy signature verified failed")
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
    xodel("wxqy signature verified failed", query, data, signature)
    error("wxqy signature verified failed")
  end
  local content = wxqy.get_clear_text(msg_encrypt)
  -- <xml><SuiteId><![CDATA[wwb83a9f918d1d681d]]></SuiteId><InfoType><![CDATA[suite_ticket]]></InfoType><TimeStamp>1681217834</TimeStamp><SuiteTicket><![CDATA[wL-gs9zQWR-NuHCSFI18_FyfPPRATmf0YcFk3Gpfsvedq843qNmCrQ2ciYZdHU5y]]></SuiteTicket></xml>
  local res = xmlparser(content)
  if res.InfoType ~= 'suite_ticket' then
    xodel("wxqy directives post", query, data, res)
  end
  local info_type_handler = main[res.InfoType or ""]
  if not info_type_handler then
    return error("info_type_handler not found: " .. tostring(res.InfoType))
  end
  return info_type_handler(self, request, res)
end

function main:suite_ticket(request, data)
  -- {
  --   InfoType   : "suite_ticket",
  --   SuiteId    : "wwb83a9f918d1d681d",
  --   SuiteTicket: "wL-gs9zQWR-NuHCSFI18_Ldmn7KNARMEppjHThRz-r5O4eR2xYGvjkTOnlvAth4R",
  --   TimeStamp  : "1681290485",
  -- }
  local db = ngx.shared[SHM_NAME]
  db:set(data.SuiteId, data.SuiteTicket)
  return "success"
end

function main:create_auth(request, data)
  -- {
  --   AuthCode : "RDUmemiLqrEwnmcDdP-44WW5gBwVVS1fyJyBEI0UZQcH-6ydMk0LyLW5bU6qz08c2LvlYCEcq171M5tuEdXE2dxFYiATBWU2zAz0xpg5tW8",
  --   InfoType : "create_auth",
  --   SuiteId  : "wwb83a9f918d1d681d",
  --   TimeStamp: "1681288539",
  -- }
  -- {
  --   /*7f0e3be2a4f0*/
  --   access_token        : "JMGRg52VxXiIuiCsIMYLPJDHsoix0vFE0Rh78o4-qJdK7_JCqH1TMxaQgR8dOh4ayfcS8UiVJwOkK02HRWlG4_axOs4aABpCV7eU7ILhIr_w7Wvr3Bky0TwZCOoSA0-8DiphRycyVnk4R6Ji0-1l28m8aWQiWfFqMO9KMmJ0r8uoc4A6bkdQ5uoF63h4RN_IzH4r-cD8VEA8cKc1-6WIrQ",
  --   avatar              : "https://rescdn.qqmail.com/node/wwmng/wwmng/style/images/independent/DefaultAvatar$73ba92b5.png",
  --   corp_full_name      : "江安县委组织部",
  --   corp_industry       : "政府",
  --   corp_name           : "江安县委组织部",
  --   corp_round_logo_url : "http://p.qpic.cn/pic_wework/1415612393/74723564f7cc73a584ad90fdffe98eb1639e6b1e9557edae/0",
  --   corp_scale          : "501-1000人",
  --   corp_square_logo_url: "https://wework.qpic.cn/wwpic/7103_9tk7wt8mQJ-UwzA_1677495017/0",
  --   corp_sub_industry   : "党政机关",
  --   corp_type           : "verified",
  --   corp_user_max       : 1000,
  --   corp_wxqrcode       : "https://wework.qpic.cn/wwpic/349792_2LIMmXPcSTeMwhp_1681637164/0",
  --   corpid              : "wpyDUMCgAA3H8_gw7O1aQLCMnDxcouCA",
  --   expires_in          : 7200,
  --   location            : "",
  --   name                : "woyDUMCgAAduLGoRDoggAxYIBq5I0GJQ",
  --   open_userid         : "woyDUMCgAAduLGoRDoggAxYIBq5I0GJQ",
  --   permanent_code      : "sj5mhNEzHq_v6Ud7Rmdy78iTAVYxzFjfdEZ-vbn7Hxs",
  --   subject_type        : 2,
  --   userid              : "woyDUMCgAAduLGoRDoggAxYIBq5I0GJQ",
  --   verified_end_time   : 1709031016,
  -- }
  local auth_data = wxqy.get_permanent_code { auth_code = data.AuthCode, suite_id = data.SuiteId }
  local org_data = request.object.flat(auth_data)
  org_data.auth_data = auth_data
  org_data.status = 'on'
  org_data.suite_id = data.SuiteId
  local corp, created = Org:get_or_create({ corpid = org_data.corpid }, org_data)
  if not created then
    corp(org_data):save()
  end
  -- permanent_code: bK0fJyTWKxZg2TmT03lFF3oTG4mZ8c5KHr_MsYHcM6o
  return "success"
end

function main:cancel_auth(request, data)
  -- {
  --   /*7f0e3bbf8e58*/
  --   AuthCorpId: "wpyDUMCgAA3H8_gw7O1aQLCMnDxcouCA",
  --   InfoType  : "cancel_auth",
  --   SuiteId   : "wwb83a9f918d1d681d",
  --   TimeStamp : "1681630980",
  -- }
  Org:update { status = 'off' }:where { suite_id = data.SuiteId, corpid = data.AuthCorpId }:execr()
  return "success"
end

return main
